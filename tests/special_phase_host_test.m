// Actual synchronous production stack; only OS clock, keys, GL/audio observed.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
static unsigned clockReads,innerFrames,presents,outerFrames,animations,posttails,beams,depth;
static unsigned clockMode;
static uint32_t latestTick;
static BOOL fixedWorldClock;
static BOOL outerClockTest;
static unsigned outerClockReads;
static uint32_t outerClock(void){static const uint32_t ticks[]={131,133,134,135};assert(outerClockReads<4);return ticks[outerClockReads++];}
static int expectedGunX,expectedGunY;
static NSMutableString *events;
@interface AstroSpecialPhaseView : AstroView
@end
@implementation AstroSpecialPhaseView
- (uint32_t)currentGameTick {if(outerClockTest)return outerClock();return observing?latestTick:simulationTick;}
- (uint32_t)specialClockTick {
    if(outerClockTest)return outerClock();
    if(!specialLoopRunning||fixedWorldClock)return latestTick;
    if(clockMode==6){static const uint32_t reads[]={100,100,100,131};assert(clockReads<4);latestTick=reads[clockReads++];}
    else latestTick=100+clockReads++/1000;
    return latestTick;
}
- (void)calculateSpecialContext:(AstroSpecialContext *)context world:(BeamContext *)worldContext {
    // Match the native driver's CALC boundary: clock stays fixed inside this hook.
    fixedWorldClock=YES;[super calculateSpecialContext:context world:worldContext];fixedWorldClock=NO;
}
- (void)animateSpecialWorld {fixedWorldClock=YES;[super animateSpecialWorld];fixedWorldClock=NO;}
- (void)readSpecialKeys {}
- (void)calculateActors {
    if(observing){depth++;[events appendString:@"A"];}
    [super calculateActors];if(observing)depth--;
}
- (void)inheritParentState {if(observing)[events appendString:@"I"];[super inheritParentState];}
- (void)finishPlayerUpdateAtTick:(uint32_t)tick {
    if(observing){assert(depth>0);posttails++;[events appendString:@"T"];assert(playerCombat.kind==(specialLoopRunning?-1:1));}
    [super finishPlayerUpdateAtTick:tick];
}
- (void)prepareSpecialContext:(AstroSpecialContext *)context {
    expectedGunX=playerBounds.left+74-15;expectedGunY=playerBounds.top+12+1;
    [super prepareSpecialContext:context];
}
- (void)display {if(observing){outerFrames++;[events appendString:@"O"];}}
- (void)renderSpecialWorld {
    assert(observing&&specialLoopRunning&&depth==1);
    assert(!specialPolygons.count&&!specialFlashes.count);
    innerFrames++;[events appendString:@"W"];astro_random(&randomSeed,123);
}
- (void)presentSpecialFrame {
    assert(specialPolygons.count==2&&specialFlashes.count==5);presents++;[events appendString:@"P"];
}
- (void)updateVisualEffects {
    if(observing){animations++;[events appendString:@"L"];if(specialLoopRunning)assert(playerCombat.kind==-1);}
    [super updateVisualEffects];
}
- (void)addSpecialBeam:(const AstroBeam *)beam temporary:(int)temporary context:(BeamContext *)context {
    if(observing){assert(beam->x==expectedGunX&&beam->y==expectedGunY);beams++;[events appendString:@"B"];}
    [super addSpecialBeam:beam temporary:temporary context:context];
}
@end
@interface AstroView (SpecialPhaseCheck)
- (void)checkSpecialPhases;
@end
@implementation AstroView (SpecialPhaseCheck)
- (void)checkSpecialPhases {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    int intervals[]={2,3,0,-1,3,3,3};
    for(unsigned scenario=0;scenario<sizeof(intervals)/sizeof(intervals[0]);scenario++){
        [self resetEnemies];[enemies removeAllObjects];[mapPlacements removeAllObjects];
        world=[NSMutableArray arrayWithObject:[NSNull null]];backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));
        memset(keys,0,sizeof(keys));changingStage=NO;campaignAction=ASTRO_CAMPAIGN_NONE;
        flow.phase=ASTRO_FLOW_PLAY;menuVisible=NO;paused=gameOver=gameOverPending=NO;
        camera=0;tickedScroll=0;simulationTick=100;observedWallTick=100;worldRenderTick=scenario==0?99:scenario==5?98:100;
        ui.frameInterval=intervals[scenario];playerWeapon=40;inventory.specials=1;
        lastPlayerShot=0;respawnTick=0;invulnerableUntil=scenario==4?999:0;
        playerVisual=(AstroVisual){1,100,180,71,20,100};playerX=playerEntityX=100;playerY=playerEntityY=180;
        playerBounds=(AstroRect){100,180,171,200};previousPlayerBounds=playerBounds;
        playerCombat=(AstroCombatState){.kind=1,.hit_points=200};
        playerState=(AstroPlayer){.frame=12,.tilt=3,.state=1,.update_tick=99,.animation_tick=100};
        playerVelocity=(AstroVelocity){2,0};randomSeed=12345;
        clockReads=innerFrames=presents=outerFrames=animations=posttails=beams=depth=0;events=[NSMutableString string];
        clockMode=scenario;latestTick=100;fixedWorldClock=NO;
        keys[controlKeys[1]]=YES;observing=YES;[self calculateActors];
        assert(!special.active&&!specialLoopRunning&&playerCombat.kind==1);
        assert(depth==0&&outerFrames==0&&animations==beams&&posttails==beams+1&&innerFrames==presents);
        if(scenario==6)assert(beams==0&&clockReads==4);
        else if(ui.frameInterval==3)assert(beams==30);
        else assert(beams>=30&&beams<=31);
        NSMutableString *expected=[NSMutableString stringWithString:@"A"];
        unsigned seenFrames=0;
        for(unsigned i=0;i<beams;i++){
            [expected appendString:@"ATIB"];
            if([events hasPrefix:[expected stringByAppendingString:@"W"]]){[expected appendString:@"WP"];seenFrames++;}
            [expected appendString:@"L"];
        }
        [expected appendString:@"TI"];assert([events isEqual:expected]&&seenFrames==innerFrames);
        assert(playerState.update_tick==131&&simulationTick==131);
        if(scenario==6)assert(lastPlayerShot==162);else if(ui.frameInterval==3)assert(lastPlayerShot==192);
        unsigned previous=outerFrames;[self renderTick];assert(animations==beams+1);
        if(ui.frameInterval<=0||scenario>=5)assert(outerFrames==previous+1);
        observing=NO;
        printf("PASS synchronous host interval%d: %u nested CALCs, cached gun, inner posttails/LM and outer continuation before parent pass\n",ui.frameInterval,beams);
    }
    simulationTick=130;worldRenderTick=128;ui.frameInterval=3;
    specialReturnPending=NO;outerClockReads=0;unsigned previousFrames=outerFrames;
    observing=outerClockTest=YES;[self renderTick];observing=outerClockTest=NO;
    assert(outerClockReads==4&&worldRenderTick==133&&simulationTick==134&&outerFrames==previousFrames+1);
    puts("PASS outer CALC completion uses distinct fresh render-compare/store and LM clocks");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroSpecialPhaseView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkSpecialPhases];
}}
