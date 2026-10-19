// Actual host outer clock boundary, checked against GAMELOOP source protocol.
// Runtime only on remote Intel. World/render/factory callbacks are observers;
// this does not establish terminal-tail, input, or music-fade equivalence.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting,constantClock,factoryConsumesClock;
static uint32_t values[16],constantValue,factoryCheckpoint,cpuAtStep,simulationAtStep;
static unsigned supplied,used,steps,renders,factories;
static NSMutableString *events;
@interface AstroGameClockView : AstroView
@end
@implementation AstroGameClockView
- (uint32_t)currentGameTick {
    if(!injecting)return [super currentGameTick];
    if(constantClock)return constantValue;
    assert(used<supplied);[events appendString:@"C"];return values[used++];
}
- (uint32_t)playerClockTick {
    return injecting?[self currentGameTick]:[super playerClockTick];
}
- (void)display {}
- (void)stepEnemies {
    if(!injecting){[super stepEnemies];return;}
    [events appendString:@"E"];steps++;cpuAtStep=observedWallTick;simulationAtStep=simulationTick;
    simulationTick++;
}
- (void)renderTick {
    if(!injecting){[super renderTick];return;}
    [events appendString:@"R"];renders++;
}
- (void)makeNewSprites {
    if(!injecting){[super makeNewSprites];return;}
    [events appendString:@"F"];factories++;factoryCheckpoint=lastSpawnTick;
    if(factoryConsumesClock)(void)[self playerClockTick];
}
@end
@interface AstroView (GameClockCheck)
- (void)checkGameLoopClock;
- (void)resetClockCase:(const uint32_t *)script count:(unsigned)count;
@end
@implementation AstroView (GameClockCheck)
- (void)resetClockCase:(const uint32_t *)script count:(unsigned)count {
    assert(count<=16);if(count)memcpy(values,script,count*sizeof(*script));supplied=count;used=steps=renders=factories=0;
    factoryCheckpoint=cpuAtStep=simulationAtStep=0;events=[NSMutableString string];constantClock=NO;factoryConsumesClock=NO;
    menuVisible=paused=gameOver=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;respawnTick=invulnerableUntil=0;
    observedWallTick=worldRenderTick=lastSpawnTick=100;simulationTick=100;automatic=NO;campaign.arena=0;campaignAction=ASTRO_CAMPAIGN_NONE;
}
- (void)checkGameLoopClock {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;splashVisible=NO;injecting=YES;
    unsigned checked=0;
    {const uint32_t c[]={100,101,102};[self resetClockCase:c count:3];[self beginGameLoop];
        assert(used==3&&lastSpawnTick==100&&observedWallTick==101&&worldRenderTick==102);assert([events isEqual:@"CCC"]);checked++;}
    {const uint32_t c[]={100,121,123,125};[self resetClockCase:c count:4];factoryConsumesClock=YES;[self pollGame];
        assert(used==4&&!steps&&!renders&&factories==1&&lastSpawnTick==125&&factoryCheckpoint==100&&observedWallTick==100);
        assert([events isEqual:@"CCFCC"]);checked++;}
    {const uint32_t c[]={101,105,120};[self resetClockCase:c count:3];[self pollGame];
        assert(used==3&&steps==1&&renders==1&&!factories&&cpuAtStep==105&&simulationAtStep==104&&observedWallTick==105&&lastSpawnTick==100);
        assert([events isEqual:@"CCERC"]);checked++;}
    {const uint32_t c[]={101,102,121,122,150};[self resetClockCase:c count:5];factoryConsumesClock=YES;[self pollGame];
        assert(used==5&&steps==1&&renders==1&&factories==1&&factoryCheckpoint==100&&lastSpawnTick==150);
        assert([events isEqual:@"CCERCFCC"]);checked++;}
    {const struct {uint32_t old,comparison,store;BOOL open;} cases[]={
        {100,120,999,NO},{100,121,150,YES},{UINT32_MAX-10,10,20,YES},{0,0x80000000,0,NO},{200,199,0,NO}};
        for(unsigned i=0;i<sizeof(cases)/sizeof(cases[0]);i++){
            const uint32_t c[]={cases[i].comparison,cases[i].store};[self resetClockCase:c count:cases[i].open?2:1];lastSpawnTick=cases[i].old;ui.frameInterval=i&1?-1:3;
            [self pollMapSpawns];assert(used==(cases[i].open?2u:1u)&&factories==(unsigned)cases[i].open&&lastSpawnTick==(cases[i].open?cases[i].store:cases[i].old));
            assert([events isEqual:cases[i].open?@"CFC":@"C"]);
        }checked++;}
    {for(int guard=0;guard<6;guard++){
            [self resetClockCase:NULL count:0];lastSpawnTick=77;
            if(guard==0)menuVisible=YES;else if(guard==1)paused=YES;else if(guard==2)gameOver=YES;
            else if(guard==3)flow.phase=ASTRO_FLOW_READY;else if(guard==4){changingStage=YES;transition.phase=ASTRO_TRANSITION_WAIT;}
            else {changingStage=YES;transition.phase=ASTRO_TRANSITION_TRAIL;}
            [self pollMapSpawns];assert(!used&&!factories&&lastSpawnTick==77);
        }checked++;}
    {const uint32_t c[]={131,140};[self resetClockCase:c count:2];changingStage=YES;transition.phase=ASTRO_TRANSITION_WAIT;
        [self pollMapSpawns];assert(!used&&!factories&&lastSpawnTick==100);
        changingStage=NO;[self pollMapSpawns];assert(used==2&&factories==1&&factoryCheckpoint==100&&lastSpawnTick==140&&[events isEqual:@"CFC"]);checked++;}
    {const uint32_t c[]={100,100,100,100,100};[self resetClockCase:c count:5];invulnerableUntil=1;respawnStartTick=respawnBlinkTick=100;lastSpawnTick=73;
        [self pollMapSpawns];[self pollMapSpawns];assert(used==4&&factories==2&&lastSpawnTick==73&&[events isEqual:@"CFCCFC"]);
        respawnTick=1;respawnWaitStartTick=100;[self pollMapSpawns];assert(used==5&&factories==2&&lastSpawnTick==73);checked++;}
    {[self resetClockCase:NULL count:0];lastSpawnTick=0xaabbccdd;constantClock=YES;constantValue=777;
        [self resetEnemies];assert(lastSpawnTick==0xaabbccdd);constantClock=NO;checked++;}
    {const uint32_t c[]={130,140};[self resetClockCase:c count:2];
        flow.phase=ASTRO_FLOW_READY;flow.ticks=59;initialReadyCard=NO;
        [self advanceFlowWithKey:YES];
        assert(flow.phase==ASTRO_FLOW_PLAY&&used==2&&factories==1&&lastSpawnTick==140);
        assert(observedWallTick==100&&worldRenderTick==100&&!steps&&!renders&&[events isEqual:@"CFC"]);checked++;}
    injecting=NO;assert(checked==10);
    puts("PASS10 actual host source-backed outer clocks: entry3, closedCPUspawn, freshCPU/factorystores, signedspawn, blockedresume, blink exception, reset preservation and READY return tail");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroGameClockView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkGameLoopClock];
}}
