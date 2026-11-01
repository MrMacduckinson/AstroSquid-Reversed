// Actual production cleanup/death/map path; compare with the original native composite.
#define ASTRO_WORLD_TRACE_LIBRARY
#include "world_trace_host.m"
#import <objc/runtime.h>
static const char *retainedStarPath;
static unsigned compositeClocks;static BOOL advancing,outerFrame,loopMode,resumeMode,midMode,midFull,endMode,endFull,resumeLong,gameoverEntry,gameoverReached,warmMode;
static unsigned followRemaining;
static BOOL normalStart;
static BOOL resetTraceIDsOnLoad;
static BOOL realHUD,panelMode,panelInput,panelCleanup,panelTail,cleanupDone,destroyMode,menuMode,noScore,menuReturn,readyActive;
@interface CompositeHUD:AstroHUDRenderer
@end
@implementation CompositeHUD
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)width height:(GLsizei)height {
 AstroHUDCommand commands[32];size_t n=astro_hud_commands(state,commands,32);
 for(size_t i=0;i<n;i++)if(commands[i].kind==ASTRO_HUD_SPRITE){AstroHUDCommand c=commands[i];self.didDrawSprite(c.sprite,c.x,c.y,c.width,c.height);}
}
@end
static unsigned warmFrames;static unsigned loopStep;static char resumeLabel[32];
static __weak AstroView *midView;
@interface AstroView(MidCapture)
- (void)captureMidFrame;
@end
@interface CompositeArenaAudio:AstroTraceAudio
@end
@implementation CompositeArenaAudio
- (void)serviceMusic {if(normalStart){if(readyActive)return;[midView dumpWorldTrace:@"normal-first-game"];printf("NK\t%u\t%u\t%u\n",compositeClocks,[[midView valueForKey:@"observedWallTick"]unsignedIntValue],[[midView valueForKey:@"worldRenderTick"]unsignedIntValue]);puts("W\tnormal-first-game");@throw [NSException exceptionWithName:@"NormalStartFinished" reason:nil userInfo:nil];}if(readyActive&&getenv("ASTRO_WORLD_ENDING")){puts("M");return;}if(midMode&&(!readyActive||followRemaining))[midView captureMidFrame];else [super serviceMusic];}
- (void)stopMusic {puts("A\tstop");}
- (BOOL)playMusic:(int)track {if(normalStart&&track==1){puts("A\tplay1");return YES;}if(track==3)puts("A\tplay3");else if(track==1&&((midMode&&!readyActive)||(menuReturn&&cleanupDone))){puts("A\tplay1");}else {assert(track==2);puts("A\tplay2");}return YES;}
@end
@interface CompositeArenaView:AstroTraceView
@end
@implementation CompositeArenaView
- (void)loadCampaignStage:(AstroCampaign)stage {
    if(resetTraceIDsOnLoad){
        resetTraceIDsOnLoad=NO;nextEntityID=playerTraceID=0;entityIDs=[NSMapTable strongToStrongObjectsMapTable];
    }
    [super loadCampaignStage:stage];
}
- (void)dumpWorldTrace:(NSString *)phase {
 [super dumpWorldTrace:phase];
 if(normalStart){for(unsigned i=0;i<3000;i++){unsigned char bytes[32];be64(bytes,stars[i].brightness);be64(bytes+8,stars[i].x);be64(bytes+16,stars[i].y);be64(bytes+24,stars[i].speed);printf("NS\t%s\t%u\t",phase.UTF8String,i);dump(bytes,32);putchar('\n');}}

 if(!panelMode||warmFrames!=10)return;
 NSDictionary *states=[ui valueForKey:@"orbStates"],*deadlines=[ui valueForKey:@"hoverDeadlines"];unsigned index=0;
 for(NSDictionary *object in [ui valueForKey:@"objects"]){NSString *name=object[@"name"];AstroUIMotion *state=[states[name] mutableBytes];
  printf("P\t%s\t%u\t%d\t%d\t%u\t%d",phase.UTF8String,index++,[object[@"kind"]intValue],state->sprite,[deadlines[name]unsignedIntValue],state->counter);
  double values[]={state->x,state->y,state->width,state->height};for(unsigned i=0;i<4;i++){unsigned char bytes[8];be64(bytes,values[i]);putchar('\t');dump(bytes,8);}putchar('\n');
 }
}
- (uint32_t)cardDelayClockTick {return readyActive?100+compositeClocks:[super cardDelayClockTick];}
- (void)readKeyMap {if(readyActive&&getenv("ASTRO_WORLD_FOLLOW")&&flow.phase==ASTRO_FLOW_PLAY){[super readKeyMap];return;}if(readyActive){if(getenv("ASTRO_WORLD_ENDING"))puts("I");memset(keys,0,sizeof(keys));keys[0]=YES;return;}if(gameOver&&warmFrames==10&&ui.editingHighscore<=0){memset(keys,0,sizeof(keys));keys[0]=YES;return;}[super readKeyMap];}
- (uint32_t)currentGameTick {if(readyActive||(panelMode&&warmFrames==10))return [self playerClockTick];return [super currentGameTick];}
- (void)flushGameEvents {if(menuReturn&&cleanupDone){assert(ui.activeRegistrationField==-1);puts("RETURN-FLUSH");return;}if(panelMode&&warmFrames==10){tracePhase="panel-ready";[self dumpWorldTrace:@"panel-ready"];
 NSDictionary *states=[ui valueForKey:@"orbStates"],*deadlines=[ui valueForKey:@"hoverDeadlines"];unsigned index=0;
 for(NSDictionary *object in [ui valueForKey:@"objects"]){NSString *name=object[@"name"];AstroUIMotion *state=[states[name] mutableBytes];NSData *label=[name dataUsingEncoding:NSMacOSRomanStringEncoding];printf("U\t%u\t",index++);dump(label.bytes,label.length);printf("\t%d\t%d\t%u\t%d",[object[@"kind"]intValue],state->sprite,[deadlines[name]unsignedIntValue],state->counter);double values[]={state->x,state->y,state->width,state->height};for(unsigned i=0;i<4;i++){unsigned char bytes[8];be64(bytes,values[i]);putchar('\t');dump(bytes,8);}putchar('\n');}assert(index==3);
 if(ui.editingHighscore<=0){puts("F\tinactive");}else {NSRect field=ui.scoreField;AstroScoreCaret caret;[[ui valueForKey:@"caret"]getValue:&caret];double values[]={field.origin.x,field.origin.y,field.size.width,field.size.height};printf("F");for(unsigned i=0;i<4;i++){unsigned char bytes[8];be64(bytes,values[i]);putchar('\t');dump(bytes,8);}printf("\t%u\n",caret.deadline);}
 printf("K\tpanel\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);gameoverReached=YES;puts("W\tpanel-complete");if(panelInput){splashVisible=NO;
 for(NSDictionary *item in @[@{@"code":@0,@"text":@"A"},@{@"code":@11,@"text":@"B"},@{@"code":@123,@"text":@""},@{@"code":@8,@"text":@"C"},@{@"code":@36,@"text":@""}]){[self keyDown:[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:item[@"text"] charactersIgnoringModifiers:item[@"text"] isARepeat:NO keyCode:[item[@"code"]unsignedShortValue]]];}
 for(unsigned i=0;i<100&&!gameEndRequested;i++)[self pollMenu];if(panelTail&&cleanupDone)return;assert(0);
 }@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}[super flushGameEvents];}
- (void)saveScores {if(panelInput){[self dumpWorldTrace:@"panel-submit"];printf("V\t%u\t%u\t",compositeClocks,observedWallTick);dump((const unsigned char *)scoreEditor.name,strlen(scoreEditor.name));printf("\nQ\t%d\n",ui.editingHighscore);for(unsigned i=0;i<10;i++){printf("H\t%u\t%d\t",i+1,highscores[i].score);dump((const unsigned char *)highscores[i].name,strlen(highscores[i].name));putchar('\n');}puts("W\tinput-complete");if(panelCleanup)return;@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}[super saveScores];}
- (void)finishGameOver {[super finishGameOver];if(panelCleanup){NSArray *objects=[ui valueForKey:@"objects"];assert(objects.count==1&&[objects[0][@"name"]isEqual:@"Unnamed"]);tracePhase="panel-cleanup";[self dumpWorldTrace:@"panel-cleanup"];printf("Z\t%u\t%u\n",compositeClocks,observedWallTick);puts("W\tcleanup-complete");cleanupDone=YES;if(panelTail)return;@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}}
- (BOOL)menuMouseButtonPressed {return panelInput?NO:[super menuMouseButtonPressed];}
- (void)pollMenuMouse {if(!panelInput)[super pollMenuMouse];}
- (void)reloadMainMenu {if(destroyMode&&!menuMode&&cleanupDone){assert(!world.count&&!enemies.count&&!mapPlacements.count);printf("DEND\t%u\t0\t0\n",compositeClocks);puts("W\tdestroy-complete");@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}[super reloadMainMenu];}
- (void)beginGameOver {if(followRemaining||(getenv("ASTRO_WORLD_ENDING")&&!getenv("ASTRO_WORLD_GAMEOVER_WARM"))||(gameoverEntry&&!warmMode)||(getenv("ASTRO_WORLD_GAMEOVER")&&!getenv("ASTRO_WORLD_GAMEOVER_WARM"))){gameoverReached=YES;[self dumpWorldTrace:@"gameover-entry"];printf("K\tentry\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}if(getenv("ASTRO_WORLD_ENDING"))readyActive=NO;[super beginGameOver];}
- (void)delayGameTicks:(uint32_t)ticks {
 if(!warmMode&&!getenv("ASTRO_WORLD_GAMEOVER_WARM")){[super delayGameTicks:ticks];return;}
 static const unsigned expected[]={0,1,1,2,3,3,4,4,5,6};assert(warmFrames<10&&ticks==expected[warmFrames]);
 snprintf(resumeLabel,sizeof resumeLabel,"warm%u",warmFrames);tracePhase=resumeLabel;[self dumpWorldTrace:[NSString stringWithUTF8String:tracePhase]];
 printf("D\t%u\t%u\t%u\n",warmFrames++,ticks,compositeClocks);compositeClocks+=ticks;
}
- (void)setGameCursorHidden:(BOOL)hidden {if(normalStart){assert(hidden);return;}if(menuReturn&&cleanupDone){assert(!hidden);Ivar ivar=class_getInstanceVariable([AstroUIRenderer class],"_registrationCarets");assert(ivar);AstroScoreCaret *carets=(AstroScoreCaret *)((unsigned char *)(__bridge void *)ui+ivar_getOffset(ivar));for(unsigned i=0;i<2;i++)printf("CF\t%u\t%u\t%d\n",i,carets[i].deadline,carets[i].visible);printf("RETURN\t%u\n",compositeClocks);@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}if(warmMode||getenv("ASTRO_WORLD_GAMEOVER_WARM")){assert(!hidden&&warmFrames==10);if(panelMode){puts("W\twarm-complete");return;}gameoverReached=YES;puts("W\tcomplete");@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}[super setGameCursorHidden:hidden];}
- (void)display {if(normalStart){if(realHUD)[self drawHUD:!panelTransitionRender];return;}if(menuMode&&cleanupDone&&!gameLoopActive){unsigned char bytes[32];printf("MENU\t%u\t%08x\t",compositeClocks,randomSeed);be64(bytes,ui.cameraX);be64(bytes+8,ui.cameraY);dump(bytes,16);putchar('\t');be64(bytes,menuScroll.x);be64(bytes+8,menuScroll.y);dump(bytes,16);putchar('\n');for(unsigned i=0;i<3000;i++){printf("MS\t%u\t",i);be64(bytes,stars[i].brightness);be64(bytes+8,stars[i].x);be64(bytes+16,stars[i].y);be64(bytes+24,stars[i].speed);dump(bytes,32);putchar('\n');}NSDictionary *states=[ui valueForKey:@"orbStates"],*deadlines=[ui valueForKey:@"hoverDeadlines"];unsigned count=0;for(NSDictionary *object in [ui valueForKey:@"objects"]){NSString *name=object[@"name"];AstroUIMotion *state=[states[name] mutableBytes];NSData *label=[name dataUsingEncoding:NSMacOSRomanStringEncoding];printf("MU\t%u\t",count++);dump(label.bytes,label.length);printf("\t%d\t%d\t%u\t%d\t",[object[@"kind"]intValue],state->sprite,[deadlines[name]unsignedIntValue],state->counter);be64(bytes,state->x);be64(bytes+8,state->y);be64(bytes+16,state->width);be64(bytes+24,state->height);dump(bytes,32);putchar('\n');}assert(count==52);puts("W\tmenu-constructed");if(menuReturn){[self.openGLContext makeCurrentContext];[ui drawSprites:^(NSInteger sprite,double x,double y,double width,double height){} texture:^GLuint(NSInteger texture){return 0;}];return;}@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}if(loopMode||midMode){if(nestedWorldRender&&getenv("ASTRO_WORLD_FLIGHT")){AstroSceneSink sink={.context=(__bridge void *)self,.sprite=sceneSprite};[self renderBeams:&sink];}if(realHUD)[self drawHUD:!(panelTransitionRender||(panelInput&&warmFrames==10))];else if(hudRedraws)hudRedraws--;if(!nestedWorldRender&&getenv("ASTRO_WORLD_FLIGHT")){AstroSceneSink sink={.context=(__bridge void *)self,.sprite=sceneSprite};[self renderBeams:&sink];}}else [super display];}
- (void)copyKeyMap:(unsigned char *)bytes {
    if(normalStart){memset(bytes,0,16);return;}
    if(midMode&&!getenv("ASTRO_WORLD_INPUT")){memset(bytes,0,16);if(getenv("ASTRO_WORLD_BOSS")){bytes[55>>3]|=1u<<(55&7);if([world containsObject:[NSNull null]]){if(((getenv("ASTRO_WORLD_BOSS_SPECIAL")&&playerEntityX>=1100)||(getenv("ASTRO_WORLD_STAGE3_SPECIAL")&&campaign.level==3&&playerEntityX>=500))&&inventory.specials>0){bytes[55>>3]&=~(1u<<(55&7));bytes[58>>3]|=1u<<(58&7);}if(getenv("ASTRO_WORLD_BOSS_CROSS")&&(!getenv("ASTRO_WORLD_CROSS_LEVEL")||campaign.level==atoi(getenv("ASTRO_WORLD_CROSS_LEVEL")))){int start=atoi(getenv("ASTRO_WORLD_BOSS_CROSS"));if(start==1)start=900;int end=getenv("ASTRO_WORLD_BOSS_CROSS_END")?atoi(getenv("ASTRO_WORLD_BOSS_CROSS_END")):start+220;assert(start>=0&&start<=30000&&end>start&&end<=32000);if(playerEntityX>=start&&playerEntityX<end)bytes[124>>3]|=1u<<(124&7);}int target=getenv("ASTRO_WORLD_BOSS_Y")?atoi(getenv("ASTRO_WORLD_BOSS_Y")):95;assert(target>=20&&target<=340);if(getenv("ASTRO_WORLD_BOSS_AIM")){double nearest=600;for(id object in world){if(object==[NSNull null])continue;AstroEnemy *e=object;double dx=e->state.x-playerEntityX;if(e->kind==5&&!e->state.remove&&dx>80&&dx<nearest){nearest=dx;target=(e->bounds.top+e->bounds.bottom)/2-16;}}if(getenv("ASTRO_WORLD_BOSS_OBJECTIVE")){nearest=600;for(id object in world){if(object==[NSNull null])continue;AstroEnemy *e=object;int tag=[e->placement[@"tag"]intValue];double dx=e->state.x-playerEntityX;if((tag==-1||tag==-2)&&!e->state.remove&&dx>80&&dx<nearest){nearest=dx;target=(e->bounds.top+e->bounds.bottom)/2-16;}}}if(target<20)target=20;if(target>340)target=340;}if(getenv("ASTRO_WORLD_STAGE3_BEAM_ROUTE")&&campaign.level==3&&playerEntityX>=4150&&playerEntityX<4650)target=165;if(getenv("ASTRO_WORLD_BOSS_AVOID")){for(int avoidancePass=0;avoidancePass<(getenv("ASTRO_WORLD_BOSS_AVOID_FALLBACK")?3:1);avoidancePass++){int safe[65]={0},anchor=-1;double distance=1e30;int best=target;double cost=1e30;for(int candidate=20;candidate<=340;candidate+=5){BOOL blocked=NO;for(id object in world){if(object==[NSNull null])continue;AstroEnemy *e=object;BOOL hostileBullet=getenv("ASTRO_WORLD_PREDICT_ENEMIES")&&campaign.level>=3&&e->kind==2&&(e->layer==1||e->layer==2);double sweepX=0,sweepY=0;if((e->kind==5||hostileBullet)&&getenv("ASTRO_WORLD_PREDICT_ENEMIES")&&campaign.level>=3){sweepX=16*e->state.velocity.x;sweepY=16*e->state.velocity.y;}if(((e->kind>=20&&e->kind<=29)||(!avoidancePass&&getenv("ASTRO_WORLD_BOSS_AVOID_ENEMIES")&&(e->kind==5||hostileBullet)))&&!e->state.remove&&e->bounds.left+fmin(0,sweepX)<playerEntityX+(avoidancePass==2||(!avoidancePass&&getenv("ASTRO_WORLD_PREDICT_ENEMIES")&&campaign.level>=3)?100:180)&&e->bounds.right+fmax(0,sweepX)>playerEntityX-20&&e->bounds.top+fmin(0,sweepY)<candidate+45&&e->bounds.bottom+fmax(0,sweepY)>candidate-10){blocked=YES;break;}}if(!blocked){int index=(candidate-20)/5;safe[index]=1;double d=fabs(candidate-playerEntityY);if(d<distance){distance=d;anchor=index;}}}if(anchor>=0){int low=anchor,high=anchor;while(low>0&&safe[low-1])low--;while(high<64&&safe[high+1])high++;for(int i=low;i<=high;i++){int candidate=20+5*i;double score=abs(candidate-target);if(score<cost){cost=score;best=candidate;}}}target=best;if(anchor>=0)break;}}double controlY=playerEntityY+(getenv("ASTRO_WORLD_BOSS_BRAKE")?9*playerVelocity.y:0);if(controlY>target+5)bytes[126>>3]|=1u<<(126&7);if(controlY<target-5)bytes[125>>3]|=1u<<(125&7);}}return;}
    if(!loopMode&&!midMode){[super copyKeyMap:bytes];return;}
    memset(bytes,0,16);unsigned input=(loopStep/8)%16;int codes[5]={126,125,123,124,55};
    for(unsigned i=0;i<5;i++)if(i==4?loopStep%7==0:(input&(1u<<i)))bytes[codes[i]>>3]|=1u<<(codes[i]&7);
    if(getenv("ASTRO_WORLD_SPECIAL_INPUT")&&loopStep%11==0)bytes[58>>3]|=1u<<(58&7);
}
- (void)createPlayerAtX:(double)x y:(double)y {if(normalStart||readyActive||((resumeMode||midMode)&&loopStep))playerTraceID=++nextEntityID;[super createPlayerAtX:x y:y];}
- (void)handleMiscKeys {
    if(panelTail&&cleanupDone){[self dumpWorldTrace:@"gameover-tail"];printf("Y\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);puts("W\ttail-complete");if(destroyMode)return;@throw [NSException exceptionWithName:midMode?@"MidTraceFinished":@"TraceFinished" reason:nil userInfo:nil];}
    if(!loopMode&&!midMode){[super handleMiscKeys];return;}
    if(resumeMode){[self dumpWorldTrace:[NSString stringWithUTF8String:tracePhase]];
        printf("K\t%u\t%u\t%u\t%u\n",loopStep,compositeClocks,observedWallTick,worldRenderTick);
        if(resumeLong&&!gameoverEntry&&((respawnPending&&inventory.lives==0)||gameOverPending||gameEndRequested||campaignAction!=ASTRO_CAMPAIGN_NONE)){
            printf("B\t%u\t%d\t%d\n",loopStep,gameEndRequested?1:(respawnPending||gameOverPending)?-1:0,campaignAction!=ASTRO_CAMPAIGN_NONE);
            @throw [NSException exceptionWithName:@"TraceFinished" reason:nil userInfo:nil];
        }
        if(++loopStep==(gameoverEntry?4096:resumeLong?1024:256))@throw [NSException exceptionWithName:@"TraceFinished" reason:nil userInfo:nil];
        snprintf(resumeLabel,sizeof resumeLabel,"loop%u",loopStep);tracePhase=resumeLabel;
    }
}
- (uint32_t)specialClockTick {return [self playerClockTick];}
- (uint32_t)playerClockTick {unsigned index=compositeClocks++;return 100+(advancing&&tracePhase&&strcmp(tracePhase,"before")?index:0);}
- (void)renderTick {if(!outerFrame)[super renderTick];}
@end
@implementation AstroView(CompositeArena)
- (void)captureMidFrame {
    [self dumpWorldTrace:[NSString stringWithUTF8String:tracePhase]];printf("K\t%u\t%u\t%u\t%u\n",loopStep,compositeClocks,observedWallTick,worldRenderTick);
    if(followRemaining&&!--followRemaining){puts("W\tfollow-complete");@throw [NSException exceptionWithName:@"MidTraceFinished" reason:nil userInfo:nil];}
    if(++loopStep==(endMode?256:16)&&!midFull&&!endFull)@throw [NSException exceptionWithName:@"MidTraceFinished" reason:nil userInfo:nil];
    snprintf(resumeLabel,sizeof resumeLabel,"mid%u",loopStep);tracePhase=resumeLabel;
}
- (void)runCompositeArena:(const char *)phaseOutput {
    normalStart=phaseOutput&&!strcmp(phaseOutput,"normal1A");
    realHUD=getenv("ASTRO_WORLD_REAL_HUD")!=NULL;panelMode=getenv("ASTRO_WORLD_PANEL")!=NULL;panelInput=getenv("ASTRO_WORLD_PANEL_INPUT")!=NULL;panelCleanup=getenv("ASTRO_WORLD_PANEL_CLEANUP")!=NULL;panelTail=getenv("ASTRO_WORLD_PANEL_TAIL")!=NULL;destroyMode=getenv("ASTRO_WORLD_DESTROY")!=NULL;menuMode=getenv("ASTRO_WORLD_MENU")!=NULL;menuReturn=getenv("ASTRO_WORLD_MENU_RETURN")!=NULL;assert(!menuReturn||menuMode);noScore=getenv("ASTRO_WORLD_NO_SCORE")!=NULL;assert(!noScore||menuMode);assert(!menuMode||destroyMode);if(menuMode){ui.musicVolume=1;ui.unlockedLevel=16;ui.registered=NO;}assert(!destroyMode||panelTail);assert(!panelTail||panelCleanup);assert(!panelCleanup||panelInput);assert(!panelInput||panelMode);if(panelInput)memset(highscores,0,sizeof(highscores));if(noScore)for(unsigned i=0;i<10;i++)highscores[i].score=1000000;assert(!panelMode||realHUD);if(realHUD){CompositeHUD *observer=[[CompositeHUD alloc]initWithGame:game ui:ui];observer.didDrawSprite=hud.didDrawSprite;hud=observer;}
    warmMode=phaseOutput&&!strncmp(phaseOutput,"resumewarm",10);gameoverEntry=warmMode||(phaseOutput&&!strncmp(phaseOutput,"resumegameover",14));resumeLong=gameoverEntry||(phaseOutput&&!strncmp(phaseOutput,"resumelong",10));endFull=phaseOutput&&!strncmp(phaseOutput,"endfull",7);endMode=phaseOutput&&!strncmp(phaseOutput,"end",3);midFull=phaseOutput&&!strncmp(phaseOutput,"midfull",7);midMode=endMode||(phaseOutput&&!strncmp(phaseOutput,"mid",3));resumeMode=phaseOutput&&!strncmp(phaseOutput,"resume",6);loopMode=resumeMode||(phaseOutput&&!strncmp(phaseOutput,"loop",4));
    if(getenv("ASTRO_WORLD_REGISTERED"))ui.registered=YES;
    if(panelMode)assert(warmMode||getenv("ASTRO_WORLD_GAMEOVER_WARM"));
    BOOL chainMode=phaseOutput&&!strcmp(phaseOutput,"chain");
    BOOL runMode=phaseOutput&&!strncmp(phaseOutput,"run",3);
    BOOL startMode=midMode||loopMode||chainMode||runMode||(phaseOutput&&!strncmp(phaseOutput,"start",5));
    BOOL inputs=phaseOutput&&!strcmp(phaseOutput,"outer-input256");
    [timer invalidate];timer=nil;[audio stop];audio=[[CompositeArenaAudio alloc]initWithAssets:assetPath error:NULL];assert(audio);
    entityIDs=[NSMapTable strongToStrongObjectsMapTable];nextEntityID=1;playerTraceID=1;
    world=[NSMutableArray array];enemies=[NSMutableArray array];visualEffects=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];starsInitialized=YES;renderClock=0;simulationTick=100;
    campaign=(AstroCampaign){8,2,0,0};inventory=(AstroInventory){0};selectedLevel=[levels indexOfObject:@"Data 8B"];
    if(normalStart){
        assert(realHUD&&!panelMode&&!getenv("ASTRO_WORLD_BOSS")&&!getenv("ASTRO_WORLD_FLIGHT")&&getenv("ASTRO_WORLD_READY"));
        randomSeed=123;compositeClocks=0;traceTick=100;tracePhase="normal-start";nextEntityID=playerTraceID=0;
        ui.musicVolume=1;splashVisible=NO;midView=self;
        [self performMenuAction:@"New Game"];
        assert(initialReadyCard&&flow.phase==ASTRO_FLOW_READY&&playerCombat.hit_points==100&&inventory.lives==1&&inventory.weapon==10&&!inventory.upgrade&&inventory.specials==1&&!score);
        readyActive=YES;BOOL oldHUD=hudClockActive;hudClockActive=YES;[self drawHUD:NO];hudClockActive=oldHUD;
        tracePhase="normal-ready";[self dumpWorldTrace:@"normal-ready"];printf("ND\t60\t%u\n",compositeClocks);
        [self recordCardPresentation];compositeClocks+=60;[self pollFlowCard];readyActive=NO;
        assert(flow.phase==ASTRO_FLOW_PLAY&&gameLoopActive);
        @try {for(unsigned poll=0;poll<1000;poll++)[self pollGame];assert(0);}
        @catch(NSException *e){assert([e.name isEqual:@"NormalStartFinished"]);}
        return;
    }
    if(phaseOutput&&(!strncmp(phaseOutput,"load",4)||startMode)){for(unsigned chain=0;chain<(chainMode?17u:1u);chain++){
        unsigned level=0;char half=0,extra=0;if(chainMode){level=chain/2+1;half=chain==16?'B':chain%2?'B':'A';}else assert(sscanf(phaseOutput+((midFull||endFull)?7:midMode?3:warmMode?10:gameoverEntry?14:resumeLong?10:resumeMode?6:loopMode?4:runMode?3:startMode?5:4),"%u%c%c",&level,&half,&extra)==2&&level>=1&&level<=9&&(half=='A'||half=='B'));
        selectedLevel=[levels indexOfObject:[NSString stringWithFormat:@"Data %u%c",level,half]];assert(selectedLevel!=NSNotFound);
        if(!chain){randomSeed=123;compositeClocks=0;}camera=-0.0;traceTick=100;char label[24];snprintf(label,sizeof label,"load%u%c",level,half);tracePhase=chainMode?label:"load";nextEntityID=playerTraceID=0;entityIDs=[NSMapTable strongToStrongObjectsMapTable];
        if(retainedStarPath&&!chain){NSData *d=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:retainedStarPath]];assert(d.length==96004);const unsigned char *b=d.bytes;
            for(unsigned i=0;i<12000;i++){uint64_t v=0;for(unsigned j=0;j<8;j++)v=(v<<8)|b[i*8+j];memcpy((unsigned char *)stars+i*8,&v,8);}randomSeed=((uint32_t)b[96000]<<24)|((uint32_t)b[96001]<<16)|((uint32_t)b[96002]<<8)|b[96003];}
        [self resetLevelWorld];
        if(startMode){inventory.lives=1;playerTraceID=++nextEntityID;[self createPlayerAtX:30 y:190];[self finishPlayerStart];inventory.weapon=playerWeapon=10;inventory.specials=1;}
        if(panelInput&&getenv("ASTRO_WORLD_FLIGHT"))score=1;
        if(getenv("ASTRO_WORLD_SPECIAL_WEAPON")){int weapon=atoi(getenv("ASTRO_WORLD_SPECIAL_WEAPON"));assert(weapon>=10&&weapon<=53&&weapon%10<=3&&weapon/10!=2);inventory.weapon=weapon/10*10;playerWeapon=weapon;inventory.upgrade=weapon%10;}
        if(getenv("ASTRO_WORLD_BOSS")){inventory.weapon=40;inventory.upgrade=3;playerWeapon=43;}
        if(getenv("ASTRO_WORLD_FLIGHT")){if(!getenv("ASTRO_WORLD_NORMAL_HEALTH"))playerCombat.hit_points=30000;int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);}
        if(getenv("ASTRO_WORLD_FRACTIONAL_CAMERA")){camera=worldLeft=.25;worldRight=640.25;}
        [self dumpWorldTrace:[NSString stringWithUTF8String:tracePhase]];
        unsigned index=0;unsigned char bytes[38];
        for(NSDictionary *m in mapPlacements){be64(bytes,number(m,@"x"));be64(bytes+8,number(m,@"y"));be64(bytes+16,number(m,@"width"));be64(bytes+24,number(m,@"height"));be16(bytes+32,[m[@"attribute"] intValue]);be32(bytes+34,[m[@"tag"] intValue]);printf("P\t%u\t",index++);dump(bytes,38);putchar('\n');}
        for(index=0;index<3000;index++){be64(bytes,stars[index].brightness);be64(bytes+8,stars[index].x);be64(bytes+16,stars[index].y);be64(bytes+24,stars[index].speed);printf("T\t%u\t",index);dump(bytes,32);putchar('\n');}
        if(midMode&&getenv("ASTRO_WORLD_MARKER")&&getenv("ASTRO_WORLD_NEXT_LOAD"))[self beginGameLoop];
        if(runMode||(midMode&&getenv("ASTRO_WORLD_PRELUDE"))){tickedScroll=1;for(unsigned step=0;step<(runMode?256u:64u);step++){
            char label[32];snprintf(label,sizeof label,"run%u",step);tracePhase=label;
            unsigned input=(step/8)%16;int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);memset(keys,0,sizeof keys);keys[126]=(input&1)!=0;keys[125]=(input&2)!=0;keys[123]=(input&4)!=0;keys[124]=(input&8)!=0;keys[55]=step%7==0;
            [self cleanupWorld];[self calculateActors];[self handleVisualEffects];[self makeNewSprites];
            [self dumpWorldTrace:[NSString stringWithUTF8String:label]];
        }}
        if(midMode&&getenv("ASTRO_WORLD_MARKER")&&!getenv("ASTRO_WORLD_FLIGHT")){
            assert(level==1&&half=='A');if(getenv("ASTRO_WORLD_NEXT_LOAD"))playerVisual.x+=10700-camera;camera=worldLeft=10700;worldRight=11340;
            if(!getenv("ASTRO_WORLD_ENCOUNTER")){[self makeNewSprites];[self calculateActors];assert(campaignAction==ASTRO_CAMPAIGN_LOAD);tracePhase="marker-trigger";[self dumpWorldTrace:@"marker-trigger"];
            assert(campaign.level==1&&campaign.half==1&&pendingCampaign.level==1&&pendingCampaign.half==2);
            if(!getenv("ASTRO_WORLD_NEXT_LOAD")){[self beginStageTransition];assert(campaign.half==1&&pendingCampaign.half==2&&transition.mode==ASTRO_TRANSITION_MID);return;}}
        }
        if(midMode){
            ui.musicVolume=1;gameLoopActive=YES;menuVisible=paused=gameOver=NO;flow.phase=ASTRO_FLOW_PLAY;automatic=YES;tracePhase="mid0";if(getenv("ASTRO_WORLD_DISPATCH")||!(getenv("ASTRO_WORLD_MARKER")&&getenv("ASTRO_WORLD_NEXT_LOAD")))[self beginGameLoop];
            if(!getenv("ASTRO_WORLD_MARKER")){if(endMode){campaign.level++;campaign.half=1;}else campaign.half=2;}tickedScroll=0;if(!getenv("ASTRO_WORLD_DISPATCH"))[self beginStageTransition];
            midView=self;loopStep=0;@try {if(getenv("ASTRO_WORLD_DISPATCH")){for(unsigned poll=0;flow.phase==ASTRO_FLOW_PLAY;poll++){assert(poll<(getenv("ASTRO_WORLD_FLIGHT")?40000u:1000u));[self pollGame];if(getenv("ASTRO_WORLD_BOSS")&&campaignAction!=ASTRO_CAMPAIGN_NONE){if(!getenv("ASTRO_WORLD_BOSS_END"))break;[self dumpWorldTrace:@"boss-defeated"];printf("KB\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);}}}else if(endMode){[self runEndlevelTransition];}else [self runMidlevelTransition];}@catch(NSException *e){assert([e.name isEqual:@"MidTraceFinished"]);}
            if(getenv("ASTRO_WORLD_GAMEOVER")){assert(gameoverReached);return;}
            if(getenv("ASTRO_WORLD_BOSS_END")){assert(flow.phase==ASTRO_FLOW_END_CARD);[self dumpWorldTrace:@"end-pre-card"];printf("K\tend\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);if(getenv("ASTRO_WORLD_ENDING")){assert(flow.complete&&campaign.level==8);readyActive=YES;@try {for(unsigned page=0;page<5;page++){assert(flow.phase==(page?ASTRO_FLOW_ENDING:ASTRO_FLOW_END_CARD));if(page)assert(flow.ending_page==(int)page-1);if(page)[self drawHUD:NO];printf("C\t%u\n",page);[self recordCardPresentation];if(page){puts("CD\t60");compositeClocks+=60;}[self pollFlowCard];}if(panelTail){assert(cleanupDone&&gameEndRequested);[self pollGame];assert(0);}}@catch(NSException *e){assert([e.name isEqual:@"MidTraceFinished"]);}assert(gameoverReached);if(panelCleanup)assert(cleanupDone);else assert(flow.phase==ASTRO_FLOW_FINISHED);return;}if(!getenv("ASTRO_WORLD_BOSS_NEXT"))return;readyActive=YES;tracePhase="end-pre-card";nextEntityID=playerTraceID=0;entityIDs=[NSMapTable strongToStrongObjectsMapTable];[self recordCardPresentation];[self pollFlowCard];assert(flow.phase==ASTRO_FLOW_READY&&campaign.level==level+1&&campaign.half==1);}
            if(getenv("ASTRO_WORLD_BOSS")&&!getenv("ASTRO_WORLD_BOSS_NEXT")){assert(campaignAction==(finalArena?ASTRO_CAMPAIGN_COMPLETE:ASTRO_CAMPAIGN_LOAD));if(finalArena)assert(pendingCampaign.complete&&campaign.level==8&&campaign.half==2);[self dumpWorldTrace:@"boss-defeated"];printf("KB\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);return;}
            if(endFull){[self dumpWorldTrace:@"end-pre-card"];printf("K\tend\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);}
            if(midFull&&!getenv("ASTRO_WORLD_DISPATCH")){[self dumpWorldTrace:@"mid-end"];printf("K\tend\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);}
            if(getenv("ASTRO_WORLD_NEXT_LOAD")){assert(midFull&&!endMode);if(!getenv("ASTRO_WORLD_BOSS_NEXT")){nextEntityID=playerTraceID=0;entityIDs=[NSMapTable strongToStrongObjectsMapTable];}if(getenv("ASTRO_WORLD_READY")){readyActive=YES;BOOL previousHUDClock=hudClockActive;hudClockActive=YES;[self drawHUD:NO];hudClockActive=previousHUDClock;[self recordCardPresentation];compositeClocks+=60;for(unsigned poll=0;flow.phase==ASTRO_FLOW_READY;poll++){assert(poll<1000);[self pollFlowCard];}readyActive=NO;}else {[self loadCampaignStage:pendingCampaign];playerTraceID=++nextEntityID;[self createPlayerAtX:30 y:190];[self finishPlayerStart];inventory.weapon=playerWeapon=10;}tracePhase="next-load";[self dumpWorldTrace:@"next-load"];
                for(unsigned i=0;i<3000;i++){printf("NS\t%u\t",i);be64(bytes,stars[i].brightness);be64(bytes+8,stars[i].x);be64(bytes+16,stars[i].y);be64(bytes+24,stars[i].speed);dump(bytes,32);putchar('\n');}
                if(getenv("ASTRO_WORLD_DISPATCH"))printf("KD\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);
                if(getenv("ASTRO_WORLD_FOLLOW")){followRemaining=atoi(getenv("ASTRO_WORLD_FOLLOW"));assert(followRemaining>0&&followRemaining<=36000);@try {while(followRemaining){
                    if(flow.phase==ASTRO_FLOW_PLAY){[self pollGame];continue;}
                    if(flow.phase==ASTRO_FLOW_END_CARD){
                        assert(!flow.complete);int completedLevel=campaign.level;
                        [self dumpWorldTrace:@"end-pre-card"];printf("K\tend\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);
                        readyActive=YES;resetTraceIDsOnLoad=YES;
                        [self recordCardPresentation];[self pollFlowCard];
                        assert(flow.phase==ASTRO_FLOW_READY&&campaign.level==completedLevel+1&&campaign.half==1);
                    }
                    assert(flow.phase==ASTRO_FLOW_READY);
                    readyActive=YES;
                    if(readyLoadPending){nextEntityID=playerTraceID=0;entityIDs=[NSMapTable strongToStrongObjectsMapTable];}
                    BOOL previousHUDClock=hudClockActive;hudClockActive=YES;[self drawHUD:NO];hudClockActive=previousHUDClock;
                    [self recordCardPresentation];compositeClocks+=60;
                    for(unsigned poll=0;flow.phase==ASTRO_FLOW_READY;poll++){assert(poll<1000);[self pollFlowCard];}
                    readyActive=NO;assert(flow.phase==ASTRO_FLOW_PLAY);
                }}@catch(NSException *e){assert([e.name isEqual:@"MidTraceFinished"]);}assert(!followRemaining||gameoverReached);}
            }
        }
        if(loopMode){
            gameLoopActive=YES;menuVisible=paused=gameOver=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;automatic=YES;campaign.arena=0;
            int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);memset(keys,0,sizeof keys);
            tracePhase="loop0";[self beginGameLoop];
            if(resumeMode){loopStep=0;@try {while(loopStep<(gameoverEntry?4096:resumeLong?1024:256))[self pollGame];}@catch(NSException *e){assert([e.name isEqual:@"TraceFinished"]);}}
            else for(loopStep=0;loopStep<256;loopStep++){char label[32];snprintf(label,sizeof label,"loop%u",loopStep);tracePhase=label;[self pollGame];[self dumpWorldTrace:[NSString stringWithUTF8String:label]];
                printf("K\t%u\t%u\t%u\t%u\n",loopStep,compositeClocks,observedWallTick,worldRenderTick);if(respawnPending||gameEndRequested||campaignAction!=ASTRO_CAMPAIGN_NONE){printf("B\t%u\t%d\t%d\n",loopStep,gameEndRequested?1:(respawnPending||gameOverPending)?-1:0,campaignAction!=ASTRO_CAMPAIGN_NONE);break;}}
        }
        if(gameoverEntry)assert(gameoverReached);
        fprintf(stderr,"LOAD %u%c maps%lu scenes%lu clocks%u RNG%08x\n",level,half,(unsigned long)mapPlacements.count,(unsigned long)backgrounds.count,compositeClocks,randomSeed);}return;
    }
    randomSeed=123;camera=0;tickedScroll=0;[self createPlayerAtX:1400 y:180];playerCombat=(AstroCombatState){.kind=1,.hit_points=73};playerState.frame=1;
    for(int i=0;i<2;i++){
        NSDictionary *a=game[@"attributes"][@"73"];int sprite=[a[@"sprite"] intValue];
        AstroEnemy *e=[self entityForPlacement:@{@"attribute":@73,@"x":@(1500+i*100),@"y":@(i?100:180),
            @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height),@"tag":@(i?0:-2)}];
        e->active=YES;if(!i)e->state.remove=-1;else e->hitPoints=71;[self prependEnemy:e];
    }
    camera=1234.25;ui.musicVolume=1;traceTick=100;tracePhase="before";[self dumpWorldTrace:@"before"];
    outerFrame=phaseOutput&&(!strcmp(phaseOutput,"outer")||!strcmp(phaseOutput,"outer64")||!strcmp(phaseOutput,"outer-map256")||inputs);
    if(outerFrame){
        campaign.arena=1;observedWallTick=100;compositeClocks=0;tracePhase="outer";[self advanceWorldForWait:NO];[self dumpWorldTrace:@"outer"];
        assert(compositeClocks==211&&camera==1&&randomSeed==0xf8ce7428&&nextEntityID==33&&renderClock==52);
        fprintf(stderr,"HOST outerbody camera%.17g clocks%u RNG%08x entities%u images%llu\n",camera,compositeClocks,randomSeed,nextEntityID,(unsigned long long)renderClock);if(strcmp(phaseOutput,"outer"))for(unsigned step=1;step<((!strcmp(phaseOutput,"outer-map256")||inputs)?256u:64u);step++){
            char label[32];snprintf(label,sizeof label,"follow%u",step);tracePhase=label;
            if(inputs){unsigned input=(step/8)%16;int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);inventory.weapon=playerWeapon=10;memset(keys,0,sizeof keys);keys[126]=(input&1)!=0;keys[125]=(input&2)!=0;keys[123]=(input&4)!=0;keys[124]=(input&8)!=0;keys[55]=step%7==0;}
            [self cleanupWorld];[self calculateActors];[self handleVisualEffects];
            if(!strcmp(phaseOutput,"outer-map256")||inputs)[self makeNewSprites];
            [self dumpWorldTrace:[NSString stringWithUTF8String:label]];
        }
        return;
    }
    compositeClocks=0;tracePhase="cleanup";[self cleanupWorld];[self dumpWorldTrace:@"cleanup"];
    fprintf(stderr,"HOST finalarena composite clocks%u RNG%08x entities%u images%llu backgrounds%lu\n",compositeClocks,randomSeed,nextEntityID,(unsigned long long)renderClock,(unsigned long)backgrounds.count);
    if(phaseOutput){
        [world removeAllObjects];[enemies removeAllObjects];[self calculateActors];
        assert(worldTop==0&&signbit(worldTop)&&worldBottom==380);FILE *out=fopen(phaseOutput,"wb");assert(out);
        unsigned char bytes[32];for(unsigned i=0;i<3000;i++){be64(bytes,stars[i].brightness);be64(bytes+8,stars[i].x);be64(bytes+16,stars[i].y);be64(bytes+24,stars[i].speed);assert(fwrite(bytes,1,32,out)==32);}
        const AstroParallax *p=parallaxData.bytes;for(unsigned i=0;i<backgrounds.count;i++){be64(bytes,p[i].x);be64(bytes+8,p[i].y);be32(bytes+16,p[i].depth);assert(fwrite(bytes,1,20,out)==20);}
        assert(!fclose(out));fprintf(stderr,"HOST first CALC star phase RNG%08x\n",randomSeed);
    }
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc>=2&&argc<=5);if(argc==5)retainedStarPath=argv[4];advancing=argc>=3;if(advancing)assert(!strcmp(argv[2],"advancing"));[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    CompositeArenaView *view=[[CompositeArenaView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view runCompositeArena:argc>=4?argv[3]:NULL];
}}
