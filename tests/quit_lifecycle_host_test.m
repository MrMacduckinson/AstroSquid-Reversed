// Actual host deferred quit, native terminal-tail projection and AppKit routing.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing,shutdownMode,reminderActive;
static unsigned currentCase,clockReads,keyPolls,menuCode,scoreSaves;
static uint32_t fixedTick=100,cardTick=100;
static NSMutableArray *actual,*expected,*shutdownEvents;
static BOOL rawQuit;
@interface QuitAudio : AstroAudio
@end
@implementation QuitAudio
- (void)stopMusic {if(shutdownMode)[shutdownEvents addObject:@"music_stop"];if(observing)[actual addObject:@"stop_track"];}
- (BOOL)playMusic:(int)n {if(observing){assert(n==1);[actual addObject:@"play_track"];}return YES;}
- (void)serviceMusic {if(observing)[actual addObject:@"music"];}
- (void)stopEffects {if(shutdownMode)[shutdownEvents addObject:@"sound_stop"];}
- (void)stop {}
@end
@interface QuitView : AstroView
@end
@implementation QuitView
- (void)drawRegistrationReminder {assert(reminderActive);}
- (void)delayGameTicks:(uint32_t)ticks {if(reminderActive)assert(ticks==300);else [super delayGameTicks:ticks];}
- (BOOL)menuMouseButtonPressed {return reminderActive?YES:[super menuMouseButtonPressed];}
- (uint32_t)currentGameTick {if(observing){clockReads++;[actual addObject:@"clock"];}return fixedTick;}
- (uint32_t)playerClockTick {return [self currentGameTick];}
- (uint32_t)cardDelayClockTick {return cardTick;}
- (void)display {if(observing){assert(ui.activeRegistrationField==(currentCase==5?0:-1));menuCode=[ui.anchor isEqual:@"Highscores Menu"]?2:1;[actual addObject:@"menu"];}}
- (void)setGameCursorHidden:(BOOL)hidden {if(observing){assert(!hidden);[actual addObject:@"cursor"];}}
- (void)presentFrame {}
- (void)copyKeyMap:(unsigned char *)bytes {
    memset(bytes,0,16);keyPolls++;
    if(observing)[actual addObject:@"keys"];
    BOOL pressed=observing?(currentCase==0||currentCase==5||((currentCase==4||currentCase==6)&&keyPolls==2)):rawQuit;
    if(pressed){bytes[6]=0x80;bytes[1]=0x10;}
    else if(observing&&currentCase==6){bytes[6]=1;bytes[1]=8;}
}
- (void)deleteActor:(id)object {[super deleteActor:object];if(observing)[actual addObject:@"dispose_entity"];}
- (void)destroyGameWorld {[super destroyGameWorld];if(shutdownMode)[shutdownEvents addObject:@"destroy"];}
- (void)reloadMainMenu {
    if(observing){assert(!world.count&&!mapPlacements.count&&!gameLoopActive);[actual addObject:@"controls"];}
    // The native quit fixture observes PUTCONTROLS as one boundary; menu_setup covers its clocks.
    BOOL previous=observing;observing=NO;[super reloadMainMenu];observing=previous;
}
- (void)flushGameEvents {if(observing){assert(ui.activeRegistrationField==-1);[actual addObject:@"flush"];}}
- (void)completeGameLoopIfRequested {
    BOOL wasActive=gameLoopActive;[super completeGameLoopIfRequested];
    if(observing&&wasActive&&!gameLoopActive)[actual addObject:@"return"];
}
- (void)releaseGraphics {[super releaseGraphics];if(shutdownMode)[shutdownEvents addObject:@"graphics"];}
- (void)saveSettings {if(shutdownMode)[shutdownEvents addObject:@"settings"];}
- (void)saveScores {scoreSaves++;if(shutdownMode)[shutdownEvents addObject:@"scores"];}
- (void)terminateApplication {assert(terminationAllowed&&!gameLoopActive&&!world.count&&!mapPlacements.count);[shutdownEvents addObject:@"terminate"];}
- (void)makeNewSprites {} // Fixed closed-clock tests; no map factory work requested.
@end
@implementation AstroView (QuitCheck)
- (void)resetQuit {
    observing=shutdownMode=NO;[timer invalidate];timer=nil;[audio stop];audio=[QuitAudio new];
    selftestPath=campaignTestPath=nil;
    quitRequested=gameEndRequested=gameEndHighscores=terminationAllowed=graphicsReleased=NO;gameLoopActive=YES;
    menuVisible=paused=splashVisible=gameOver=gameOverPending=changingStage=NO;
    respawnPending=NO;respawnTick=invulnerableUntil=0;flow.phase=ASTRO_FLOW_PLAY;editingKey=-1;
    world=[NSMutableArray arrayWithObject:[NSNull null]];enemies=[NSMutableArray array];
    mapPlacements=[NSMutableArray arrayWithObject:@{}];playerNextActor=nil;
    fixedTick=100;clockReads=keyPolls=menuCode=0;rawQuit=NO;memset(keys,0,sizeof(keys));
    // The native fixture stubs PUTCONTROLS/MOVEMENUTO; their internal clocks have separate menu tests.
    ui.readTick=^{return fixedTick;};
    actual=[NSMutableArray array];shutdownEvents=[NSMutableArray array];
}
- (void)checkQuit {
    for(unsigned c=0;c<8;c++){
        // Signed quit=-1 remains diagnostic; end=1 is reachable through REGREMINDER.
        if(c==2)continue;
        [self resetQuit];currentCase=c;quitRequested=c==1||c==7;respawnPending=c==4;gameEndHighscores=c==5;ui.activeRegistrationField=c==5?0:-1;
        if(c==3||c==7){
            paused=YES;reminderActive=YES;[self showRegistrationReminder];reminderActive=NO;
            assert(gameEndRequested&&!paused);keyPolls=0;
        }
        FILE *f=fopen("tests/quit_loop_native.csv","r");assert(f);char line[256];assert(fgets(line,sizeof(line),f));
        expected=[NSMutableArray array];unsigned nativeReads=0,nativePolls=0,nativeMenu=0;
        while(fgets(line,sizeof(line),f)){
            unsigned id,reads,polls,disposed,menu;int quit,end,activeFlag,entities,map;char event[32];
            assert(sscanf(line,"%u,%31[^,],%u,%u,%d,%d,%d,%d,%d,%u,%u",&id,event,&reads,&polls,&quit,&end,&activeFlag,&entities,&map,&disposed,&menu)==11);
            if(id!=c)continue;
            if(!strcmp(event,"music")||!strcmp(event,"clock")||!strcmp(event,"keys")||!strcmp(event,"dispose_entity")||!strcmp(event,"controls")||
               !strcmp(event,"menu")||!strcmp(event,"flush")||!strcmp(event,"stop_track")||!strcmp(event,"play_track")||!strcmp(event,"cursor")||!strcmp(event,"return"))
                [expected addObject:[NSString stringWithUTF8String:event]];
            if(!strcmp(event,"return")){nativeReads=reads;nativePolls=polls;nativeMenu=menu;assert(!activeFlag&&!entities&&!map&&disposed==3&&quit==(c!=3));}
        }
        assert(!ferror(f));fclose(f);assert(nativeReads&&expected.count);
        observing=YES;[self beginGameLoop];for(unsigned i=0;gameLoopActive&&i<3;i++)[self pollGame];observing=NO;
        assert(!gameLoopActive&&quitRequested==(c!=3)&&!terminationAllowed&&menuVisible&&!world.count&&!mapPlacements.count&&playerVisualDeleted);
        if(![actual isEqual:expected]||clockReads!=nativeReads||keyPolls!=nativePolls||menuCode!=nativeMenu)
            fprintf(stderr,"quit case%u actual=%s expected=%s clocks%u/%u keys%u/%u menu%u/%u\n",c,actual.description.UTF8String,expected.description.UTF8String,clockReads,nativeReads,keyPolls,nativePolls,menuCode,nativeMenu);
        assert([actual isEqual:expected]&&clockReads==nativeReads&&keyPolls==nativePolls&&menuCode==nativeMenu);
        if(c==3){assert(!gameEndRequested);continue;}
        shutdownMode=YES;[self closeDown];[self closeDown];shutdownMode=NO;
        assert(([shutdownEvents isEqual:@[@"settings",@"graphics",@"sound_stop",@"destroy",@"music_stop",@"terminate"]]));
    }
    puts("PASS7 native exit-tail projections including reminder end-on-entry: music/input order, clock totals, cleanup/menu/flush/music then return; shutdown follows return and is idempotent");
    [self resetQuit];rawQuit=YES;[self readSpecialKeys];assert(quitRequested&&gameLoopActive&&!terminationAllowed);
    respawnTick=1;respawnWaitStartTick=100;fixedTick=160;gameEndRequested=YES;
    world=[NSMutableArray array];[self pollRespawnWait];[self completeGameLoopIfRequested];assert(respawnTick&&gameLoopActive);
    fixedTick=161;[self pollRespawnWait];assert(!respawnTick&&invulnerableUntil&&world.count==1);
    gameEndRequested=NO;fixedTick=200;[self pollRespawnBlink];[self completeGameLoopIfRequested];assert(invulnerableUntil&&gameLoopActive);
    gameEndRequested=YES;[self pollRespawnBlink];assert(!invulnerableUntil);[self completeGameLoopIfRequested];assert(!gameLoopActive&&!terminationAllowed);
    [self resetQuit];quitRequested=YES;initialReadyCard=YES;astro_flow_ready(&flow,1,1);cardClockStarted=YES;cardDelayStartTick=100;
    rawQuit=YES;cardTick=159;[self tickWallClock];assert(gameLoopActive&&!terminationAllowed&&flow.phase==ASTRO_FLOW_READY);
    cardTick=160;[self tickWallClock];assert(gameLoopActive&&!terminationAllowed&&flow.phase==ASTRO_FLOW_PLAY);
    shutdownMode=YES;[self tickWallClock];shutdownMode=NO;assert(!gameLoopActive&&terminationAllowed);
    [self resetQuit];quitRequested=YES;menuVisible=gameOver=YES;ui.editingHighscore=1;[ui show:@"GameOver"];
    [self completeGameLoopIfRequested];assert(gameLoopActive&&!terminationAllowed);
    score=0;ui.editingHighscore=0;[self finishGameOver];assert(gameEndRequested&&!menuVisible);
    shutdownMode=YES;[self tickWallClock];shutdownMode=NO;assert(!gameLoopActive&&terminationAllowed);
    [self resetQuit];menuVisible=gameOver=YES;ui.editingHighscore=0;[ui show:@"GameOver"];[ui animateTicks:60];
    observedWallTick=100;[self keyDown:[self testEvent:NSKeyDown code:0]];assert(gameOver&&!gameEndRequested);
    [self pollMenu];assert(gameOver&&!gameEndRequested);
    rawQuit=YES;fixedTick=101;[self pollMenu];assert(!gameOver&&gameEndRequested&&quitRequested);
    [self pollGame];assert(!gameLoopActive&&!terminationAllowed);
    puts("PASS non-editing GameOver keyboard exits only at an eligible raw-input frame, not keyDown");
    [self resetQuit];quitRequested=YES;changingStage=YES;[self completeGameLoopIfRequested];assert(gameLoopActive);
    changingStage=NO;[self pollGame];assert(!gameLoopActive&&!terminationAllowed);
    [self resetQuit];[self enterPause];[self performMenuAction:@"PauseQuit"];assert(gameEndRequested&&gameLoopActive&&world.count);
    [self pollGame];assert(!gameLoopActive&&!quitRequested&&!terminationAllowed&&[ui.anchor isEqual:@"Play Menu"]);
    puts("PASS deferred special/WAIT/blink/card/highscore/transition/normal game exit boundaries; app quit does not shorten blink but game end does");
    [self resetQuit];respawnPending=YES;[self enterPause];[self resumePause];
    assert(!paused&&!menuVisible&&ui.panelOffset==0);
    puts("PASS source-backed death-pending flag suppresses reverse pause transition, as original58c!=0");
    [self resetQuit];AstroEnemy *parent=[AstroEnemy new],*child=[AstroEnemy new];
    child->parent=parent;world=[NSMutableArray arrayWithObjects:parent,child,[NSNull null],nil];
    enemies=[NSMutableArray arrayWithObjects:parent,child,nil];[self syncActorLinks];
    quitRequested=YES;[self completeGameLoopIfRequested];
    assert(!world.count&&!enemies.count&&!parent->nextActor&&!child->nextActor&&!child->parent&&!playerNextActor);
    puts("PASS terminal actor cleanup clears retained next/parent links and all logical world/map/effect lists");
    [self resetQuit];AstroDelegate *delegate=[AstroDelegate new];
    NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,480) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed=NO;window.contentView=self;delegate.window=window;
    assert([delegate applicationShouldTerminate:NSApp]==NSTerminateCancel&&quitRequested);
    assert(![delegate windowShouldClose:window]&&gameLoopActive);
    [self pollGame];shutdownMode=YES;[self closeDown];shutdownMode=NO;
    assert([delegate applicationShouldTerminate:NSApp]==NSTerminateNow&&[delegate windowShouldClose:window]);
    window.contentView=nil;[window close];
    [self resetQuit];gameLoopActive=NO;menuVisible=YES;[self requestQuit];shutdownMode=YES;[self tickWallClock];shutdownMode=NO;
    assert(terminationAllowed);puts("PASS actual AppKit delegate defers quit/window close until lifecycle completion; menu quit closes without a game tail");
    [self resetQuit];astro_scores_clear(highscores);score=100;strcpy(scoreEditor.name,"Score Test");ui.editingHighscore=1;
    unsigned saved=scoreSaves;[self finishGameOver];assert(scoreSaves==saved+1&&highscores[0].score==100);
    [self resetQuit];ui.editingHighscore=0;saved=scoreSaves;[self finishGameOver];assert(scoreSaves==saved);
    puts("PASS qualifying GameOver saves once after terminal redraws; nonqualifying GameOver and normal shutdown add no score writes");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[QuitView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkQuit];
}}
