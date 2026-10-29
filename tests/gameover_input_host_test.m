// Actual queued keyDown -> pollMenu frame gate and terminal drawRect, no score writes.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static unsigned exit_case,records,clockReads,keyPolls,alerts;
static AstroScoreEditor *observedEditor;
static uint32_t *observedWall;
static BOOL observing,hudClockModel;
static AstroUIRenderer *observedUI;
static void eventValue(char code,unsigned value){
    if(!observing)return;records++;
    printf("%u,%c,%u,%d,%d,%d,%u,",exit_case,code,value,!observedUI.gameOverClosing,[[observedUI valueForKey:@"pressed"]isEqual:@"GameOverOK"]?901:900,observedEditor->submitted,*observedWall);
    for(unsigned i=0;i<strlen(observedEditor->name);i++)printf("%02x",(unsigned char)observedEditor->name[i]);printf(",%d\n",observedEditor->cursor);
}
static void event(char code){eventValue(code,0);}
@interface AstroUIRenderer (ExitProbe)
- (void)beginGameOverExit;
- (void)finishGameOverExit;
@end
@interface ExitUI:AstroUIRenderer
@end
@implementation ExitUI
- (void)beginGameOverExit {[super beginGameOverExit];assert([[self valueForKey:@"gameOverClosing"] boolValue]);event('P');}
- (void)animateTicks:(unsigned)ticks {[super animateTicks:ticks];event('A');}
- (void)drawSprites:(AstroUISpriteDrawer)draw texture:(AstroUITextureLoader)texture {event('O');}
- (void)finishGameOverExit {
    [super finishGameOverExit];for(NSDictionary *object in [self valueForKey:@"objects"])assert((![@[@"GameOverOK",@"GameOverFade"]containsObject:object[@"name"]]));event('B');event('F');
}
@end
@interface ExitHUD:AstroHUDRenderer
@end
@implementation ExitHUD
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)w height:(GLsizei)h {event('H');if(observing&&hudClockModel){AstroHUDCommand c[32];size_t n=astro_hud_commands(state,c,32);for(size_t i=0;i<n;i++)if(c[i].kind==ASTRO_HUD_SPRITE)self.didDrawSprite(c[i].sprite,c[i].x,c[i].y,c[i].width,c[i].height);}}
@end
@interface InputAudio:AstroAudio
@end
@implementation InputAudio
- (void)serviceMusic {event('S');}
- (void)stop {}
@end
@interface ExitView:AstroView
- (void)checkExit;
@end
@implementation ExitView
- (void)display {if(observing){event('R');[self drawRect:self.bounds];}}
- (void)presentFrame {event('W');}
- (void)saveScores {event('I');}
- (BOOL)continueScoreOverflow:(NSData *)left right:(NSData *)right {assert(left.length==255&&right.length==1);alerts++;return YES;}
- (uint32_t)currentGameTick {if(!observing)return 1000;uint32_t tick=1000+clockReads++;eventValue('T',tick);return tick;}
- (void)copyKeyMap:(unsigned char *)bytes {memset(bytes,0,16);BOOL any=exit_case>=3||++keyPolls>=2;if(any)bytes[0]=1;eventValue('K',any);}
- (BOOL)editScoreByte:(unsigned)ch {eventValue('E',ch);return [super editScoreByte:ch];}
- (void)sprite:(NSInteger)n x:(double)x y:(double)y width:(double)w height:(double)h {if(!observing)[super sprite:n x:x y:y width:w height:h];}
- (void)checkExit {
    [timer invalidate];timer=nil;[audio stop];audio=[InputAudio new];selftestPath=campaignTestPath=nil;spriteMapsPreloaded=YES;splashVisible=NO;flow.phase=ASTRO_FLOW_PLAY;campaign.level=4;
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));enemies=[NSMutableArray array];world=[NSMutableArray array];visualEffects=[NSMutableArray array];specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];playerVisualDeleted=YES;playerHitVisual.active=NO;engineGlow=departureTrail=NO;
    hudClockModel=getenv("ASTRO_HUD_CLOCK_MODEL")!=NULL;AstroUISpriteDrawer callback=hud.didDrawSprite;ui=[[ExitUI alloc]initWithAssets:assetPath error:NULL];hud=[[ExitHUD alloc]initWithGame:game ui:ui];hud.didDrawSprite=callback;observedUI=ui;observedEditor=&scoreEditor;observedWall=&observedWallTick;
    [[self openGLContext]makeCurrentContext];GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);while(glGetError()!=GL_NO_ERROR){}
    for(exit_case=0;exit_case<6;exit_case++){
        [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=exit_case>=3;ui.frameInterval=exit_case%3+1;ui.editingName=@"TEST";
        score=exit_case>=3?100:0;astro_score_editor_begin(&scoreEditor);[self refreshScoreEditor];astro_scores_clear(highscores);menuVisible=gameOver=YES;gameEndRequested=gameEndHighscores=NO;deferPresent=NO;records=clockReads=keyPolls=0;observedWallTick=1000;
        if(exit_case>=3){
            for(NSDictionary *input in @[@{@"code":@0,@"text":@"A"},@{@"code":@11,@"text":@"B"},@{@"code":@123,@"text":@""},@{@"code":@8,@"text":@"C"},@{@"code":@36,@"text":@""}]){
                NSEvent *key=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:input[@"text"] charactersIgnoringModifiers:input[@"text"] isARepeat:NO keyCode:[input[@"code"]unsignedShortValue]];[self keyDown:key];
            }
            assert(!scoreEditor.name[0]&&!scoreEditor.submitted&&!gameEndRequested);
        }
        observing=YES;for(unsigned poll=0;poll<100&&!gameEndRequested;poll++)[self pollMenu];event('Z');observing=NO;
        assert(gameEndRequested&&!menuVisible&&!gameOver&&gameEndHighscores==(exit_case>=3)&&!deferPresent);
        assert(glGetError()==GL_NO_ERROR);
        if(exit_case>=3)assert(highscores[0].score==100&&!strcmp(highscores[0].name,"ACB"));
    }
    [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=1;ui.frameInterval=1;
    menuVisible=gameOver=YES;gameEndRequested=NO;queuedKeyEvents=nil;astro_score_editor_begin(&scoreEditor);
    memset(scoreEditor.name,'A',255);scoreEditor.name[255]=0;scoreEditor.cursor=255;[self refreshScoreEditor];
    NSEvent *overflow=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:@"BC" charactersIgnoringModifiers:@"BC" isARepeat:NO keyCode:0];
    [self keyDown:overflow];[self keyDown:overflow];assert(!alerts&&scoreEditor.cursor==255);observedWallTick=1000;[self pollMenu];assert(!alerts&&queuedKeyEvents.count==2);
    for(unsigned i=1;i<=2;i++){observedWallTick=999;[self pollMenu];assert(alerts==i&&queuedKeyEvents.count==2-i&&scoreEditor.cursor==255+(int)i&&strlen(scoreEditor.name)==255&&!scoreEditor.alert);}
    fputs("PASS queued overflow waits for eligible frame and resolves once per event\n",stderr);
    astro_score_editor_begin(&scoreEditor);[self refreshScoreEditor];queuedKeyEvents=[NSMutableArray arrayWithObject:[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:@"X" charactersIgnoringModifiers:@"X" isARepeat:NO keyCode:7]];
    [NSApp discardEventsMatchingMask:NSEventMaskAny beforeEvent:nil];
    for(unsigned i=0;i<2;i++)[NSApp postEvent:[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:i windowNumber:0 context:nil characters:i?@"B":@"A" charactersIgnoringModifiers:i?@"B":@"A" isARepeat:i!=0 keyCode:i?11:0] atStart:NO];
    observedWallTick=1000;[self pollMenu];assert(!scoreEditor.name[0]&&queuedKeyEvents.count==1);
    observedWallTick=999;[self pollMenu];assert(!strcmp(scoreEditor.name,"X"));
    assert([NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO].keyCode==0);
    observedWallTick=999;[self pollMenu];assert(!strcmp(scoreEditor.name,"XA"));
    assert([NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO].keyCode==11);
    observedWallTick=999;[self pollMenu];assert(!strcmp(scoreEditor.name,"XAB"));
    assert(![NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO]);
    fputs("PASS GameOver pending Cocoa keys/repeat consumed at eligible field phase after earlier delivered events\n",stderr);
    NSEvent *remaining=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:9 windowNumber:0 context:nil characters:@"Z" charactersIgnoringModifiers:@"Z" isARepeat:NO keyCode:6];
    [self keyDown:remaining];assert(queuedKeyEvents.count==1);
    [self finishGameOver];assert(queuedKeyEvents.count==1&&queuedKeyEvents[0]==remaining);
    [NSApp postEvent:remaining atStart:NO];[self flushGameEvents];assert(!queuedKeyEvents.count);
    assert(![NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO]);
    fputs("PASS GameOver return retains unconsumed events until the game-loop flush clears delivered and pending keys\n",stderr);
    glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    ExitView *view=[[ExitView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkExit];
}}
