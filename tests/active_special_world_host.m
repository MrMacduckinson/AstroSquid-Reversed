// Complete host CALC -> DOPLAYER -> nested special, with an injected OS clock.
#define ASTRO_WORLD_TRACE_LIBRARY
#include "world_trace_host.m"
static BOOL activeClock,activeTail,activeStorm;
static unsigned activeReads,activeFrames,activeLM;
static uint32_t activeNow;
static FILE *clockTrace;
@interface AstroActiveTraceView : AstroTraceView
@end
@implementation AstroActiveTraceView
- (uint32_t)currentGameTick {
    if(!activeClock)return [super currentGameTick];
    activeNow=100+activeReads/4096;
    if(clockTrace)fprintf(clockTrace,"%u,%u\n",activeReads,activeNow);
    activeReads++;traceTick=activeNow;return activeNow;
}
- (void)dumpWorldTrace:(NSString *)phase {
    tracePhase=phase.UTF8String;
    printf("Q\t%u\t%s\t%u\t%u\t%u\t%u\t%u\t%u\n",simulationTick,phase.UTF8String,activeReads,observedWallTick,worldRenderTick,(unsigned)actorVisits,(unsigned)(uint16_t)visualFrames,visualRateTick);
    [super dumpWorldTrace:phase];
}
- (uint32_t)specialClockTick {return [self currentGameTick];}
- (void)readSpecialKeys {} // Same held special bit supplied by the native GetKeys provider.
- (void)renderSpecialWorld {
    simulationTick=worldRenderTick;activeFrames++;
    if(activeStorm){simulationRender=YES;AstroSceneSink sink={.context=(__bridge void *)self,.sprite=sceneSprite};[self renderBeams:&sink];simulationRender=NO;}
    [self dumpWorldTrace:@"render"];
}
- (void)presentSpecialFrame {visualFrames=(int16_t)((uint16_t)visualFrames+1u);[self dumpWorldTrace:@"swap"];}
- (void)drawSceneSprite:(const AstroSceneSprite *)sprite {[self createSceneSprite:sprite];}
- (void)prependEnemy:(AstroEnemy *)e {
    if(entityIDs&&![entityIDs objectForKey:e])[entityIDs setObject:@(++nextEntityID) forKey:e];
    [super prependEnemy:e];
}
- (void)updateVisualEffects {[super updateVisualEffects];if(activeClock)activeLM++;}
@end
@interface AstroView (ActiveWorldTrace)
- (void)traceActiveWorld;
@end
@implementation AstroView (ActiveWorldTrace)
- (void)traceActiveWorld {
    [timer invalidate];timer=nil;[audio stop];audio=[[AstroTraceAudio alloc] initWithAssets:assetPath error:NULL];
    entityIDs=[NSMapTable strongToStrongObjectsMapTable];nextEntityID=1;
    selftestPath=campaignTestPath=nil;simulationTick=100;observedWallTick=worldRenderTick=100;
    camera=-0.0;tickedScroll=0;randomSeed=0x12345678;renderClock=1;
    world=[NSMutableArray arrayWithObject:[NSNull null]];enemies=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof stars);
    visualEffects=[NSMutableArray array];presentedBeams=@[];
    playerVisual=(AstroVisual){1,100,180,71,20,100};playerRenderBirth=1;
    playerEntityX=playerX=100;playerEntityY=playerY=180;playerVelocity=(AstroVelocity){0};
    playerBounds=(AstroRect){100,180,171,200};previousPlayerBounds=(AstroRect){0};
    playerCombat=(AstroCombatState){.kind=1,.hit_points=200};
    playerState=(AstroPlayer){.frame=12,.tilt=3,.state=1,.update_tick=99,.animation_tick=100};
    lastPlayerShot=0;playerWeapon=50;inventory=(AstroInventory){50,0,1,0};campaign=(AstroCampaign){0};score=0;
    visualRateTick=0;visualFrames=0;visualRate=0;
    special=(AstroSpecial){0};specialLoopRunning=specialReturnPending=NO;engineGlow=departureTrail=NO;
    changingStage=NO;respawnTick=invulnerableUntil=0;campaignAction=ASTRO_CAMPAIGN_NONE;flow.phase=ASTRO_FLOW_PLAY;menuVisible=paused=gameOver=gameOverPending=NO;
    ui.frameInterval=1;memset(keys,0,sizeof keys);int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);keys[58]=YES;
    if(activeStorm){
        renderClock=0;nextEntityID=0;playerTraceID=2;
        NSDictionary *a=game[@"attributes"][@"204"];int sprite=[a[@"sprite"] intValue];
        AstroEnemy *target=[self entityForPlacement:@{@"attribute":@204,@"x":@300,@"y":@180,@"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height)}];
        target->active=YES;target->hitPoints=30000;[enemies addObject:target];[world addObject:target];playerRenderBirth=++renderClock;nextEntityID=2;
    }
    if(activeTail){
        renderClock=0;nextEntityID=0;playerTraceID=2;
        NSDictionary *a=game[@"attributes"][@"41"];int sprite=[a[@"sprite"] intValue];
        AstroEnemy *tail=[self entityForPlacement:@{@"attribute":@41,@"x":@500,@"y":@300,@"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height)}];
        tail->active=YES;[enemies addObject:tail];[world addObject:tail];playerRenderBirth=++renderClock;nextEntityID=2;
    }
    [self dumpWorldTrace:@"initial"];activeClock=YES;tracePhase="calc";[self calculateActors];tracePhase=NULL;activeClock=NO;
    simulationTick=activeNow;[self dumpWorldTrace:@"return"];
    assert(!special.active&&!specialLoopRunning&&inventory.specials==0&&(activeStorm?world.count>=2:world.count==(activeTail?2:1)));
    if(activeStorm)assert(renderClock==2420&&nextEntityID==374);
    fprintf(stderr,"HOST coupled active-special reads%u frames%u LM%u return%u update%u action%u RNG%08x\n",activeReads,activeFrames,activeLM,activeNow,playerState.update_tick,lastPlayerShot,randomSeed);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3||argc==4);activeTail=argc==4&&!strcmp(argv[3],"tail");activeStorm=argc==4&&!strcmp(argv[3],"storm");assert(argc==3||activeTail||activeStorm);clockTrace=fopen(argv[2],"w");assert(clockTrace);
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroActiveTraceView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view traceActiveWorld];fclose(clockTrace);
}}
