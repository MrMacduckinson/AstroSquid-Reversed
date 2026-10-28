// Coupled production beam world state versus independent original G5 fixtures.
#define ASTRO_WORLD_TRACE_LIBRARY
#include "world_trace_host.m"
static FILE *beamClocks;
static unsigned beamClockCount;
static const char *beamPhase;
static BOOL beamChain,beamKill;
@interface AstroBeamTraceView : AstroTraceView
- (void)traceBeamWeapon:(int)weapon cleanupFirst:(BOOL)cleanup;
@end
@implementation AstroBeamTraceView
- (uint32_t)playerClockTick {
    if(!beamPhase)return [super playerClockTick];
    uint32_t tick=1000+beamClockCount++;
    if(!strcmp(beamPhase,"fire")||!strcmp(beamPhase,"render")){
        id head=world.firstObject;BOOL player=head==[NSNull null];AstroEnemy *e=player?nil:head;
        fprintf(beamClocks,"Q\t%s\t%u\t%u\t%08x\t%u\t%d\t%u\t%u\t%u\t%u\n",beamPhase,
            beamClockCount-1,tick,randomSeed,entityID(head),player?playerCombat.kind:e->kind,
            player?playerState.update_tick:e->state.update_tick,player?playerState.animation_tick:e->state.animation_tick,
            player?lastPlayerShot:e->state.action_tick,(unsigned)renderClock);
    }
    return tick;
}
- (void)prependEnemy:(AstroEnemy *)e {
    if(entityIDs&&![entityIDs objectForKey:e])[entityIDs setObject:@(++nextEntityID) forKey:e];
    [super prependEnemy:e];
}
- (void)drawSceneSprite:(const AstroSceneSprite *)scene {[self createSceneSprite:scene];}
- (void)traceBeamWeapon:(int)weapon cleanupFirst:(BOOL)cleanup {
    [timer invalidate];timer=nil;[audio stop];audio=[[AstroTraceAudio alloc] initWithAssets:assetPath error:NULL];
    entityIDs=[NSMapTable strongToStrongObjectsMapTable];nextEntityID=1;playerTraceID=1;
    enemies=[NSMutableArray array];world=[NSMutableArray array];visualEffects=[NSMutableArray array];
    simulationTick=0;camera=0;tickedScroll=0;renderClock=0;randomSeed=0x12345678;
    score=0;actorVisits=0;inventory=(AstroInventory){weapon,0,2,0};campaign=(AstroCampaign){0};ui.frameInterval=1;
    beamClockCount=0;beamPhase="setup";traceTick=0;tracePhase="setup";
    [self createPlayerAtX:30 y:190];playerCombat=(AstroCombatState){.kind=1,.hit_points=100};
    NSDictionary *a=game[@"attributes"][@"73"];int sprite=[a[@"sprite"] intValue];
    AstroEnemy *target=[self entityForPlacement:@{@"attribute":@73,@"tag":@0,@"x":@(weapon==40?300:180),@"y":@190,
        @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height)}];
    target->hitPoints=beamKill?1:100;[self prependEnemy:target];
    if(beamChain||beamKill){
        AstroEnemy *second=[self entityForPlacement:@{@"attribute":@73,@"tag":@0,@"x":@225,@"y":@200,
            @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height)}];
        second->hitPoints=beamKill?1:100;[self prependEnemy:second];
    }
    [self dumpWorldTrace:@"setup"];
    beamPhase="fire";tracePhase=beamPhase;[self fireWeapon:weapon x:104 y:202 heading:0 source:1];[self dumpWorldTrace:@"fire"];
    if(cleanup){beamPhase="cleanup";tracePhase=beamPhase;[self cleanupWorld];[self dumpWorldTrace:@"cleanup"];}
    beamPhase="render";tracePhase=beamPhase;simulationRender=YES;
    AstroSceneSink sink={.context=(__bridge void *)self,.sprite=sceneSprite};[self renderBeams:&sink];
    simulationRender=NO;[self dumpWorldTrace:@"render"];
    uint32_t savedSeed=randomSeed;unsigned savedReads=beamClockCount;
    uint64_t savedBirth=renderClock;NSUInteger savedEffects=visualEffects.count;
    [self renderBeams:&sink]; // AppKit redraw must replay without allocating or advancing RNG/clocks.
    assert(randomSeed==savedSeed&&beamClockCount==savedReads&&renderClock==savedBirth&&visualEffects.count==savedEffects);
    if(!cleanup){beamPhase="cleanup";tracePhase=beamPhase;[self cleanupWorld];[self dumpWorldTrace:@"cleanup"];}
    beamPhase="after";tracePhase=beamPhase;AstroShot shot={.type=1,.x=50,.y=90};[self spawnShot:&shot source:1];
    [self dumpWorldTrace:@"after"];beamPhase=NULL;tracePhase=NULL;
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==5||argc==6);beamChain=argc==6&&!strcmp(argv[5],"chain");beamKill=argc==6&&!strcmp(argv[5],"kill");assert(argc==5||beamChain||beamKill);beamClocks=fopen(argv[4],"w");assert(beamClocks);
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroBeamTraceView *view=[[AstroBeamTraceView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view traceBeamWeapon:atoi(argv[2]) cleanupFirst:atoi(argv[3])];fclose(beamClocks);
}}
