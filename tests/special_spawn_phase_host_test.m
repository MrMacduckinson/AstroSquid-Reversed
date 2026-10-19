// Actual instant-special entry/factory RNG interleaving; not a native event capture.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing,startClock;
static uint32_t before[96],after[96];
static unsigned expectedCount,reads,creates,finishes;
static void expectedSeeds(int weapon){
    uint32_t seed=12345;expectedCount=0;
    if(weapon==10)for(unsigned i=0;i<90;i++){
        astro_random(&seed,10);astro_random(&seed,10);before[expectedCount]=seed;
        astro_random(&seed,360);astro_random(&seed,4);after[expectedCount++]=seed;
    }else{
        before[0]=after[0]=seed;expectedCount=1;
        for(unsigned i=0;i<6;i++){astro_random(&seed,60);astro_random(&seed,50);before[expectedCount]=after[expectedCount]=seed;expectedCount++;}
        for(unsigned i=0;i<34;i++){
            astro_random(&seed,20);astro_random(&seed,50);before[expectedCount]=seed;
            astro_random(&seed,360);astro_random(&seed,20);astro_random(&seed,3);astro_random(&seed,60);astro_random(&seed,8);
            after[expectedCount++]=seed;
        }
    }
}
@interface AstroSpecialPhaseFactoryView : AstroView
@end
@implementation AstroSpecialPhaseFactoryView
- (uint32_t)playerClockTick {
    if(!observing)return [super playerClockTick];
    if(startClock){startClock=NO;return 900;}
    assert(reads<expectedCount*4&&randomSeed==before[reads/4]);return 1000+reads++;
}
- (void)display {}
- (AstroEnemy *)createSpecial:(const AstroSpecialSpawn *)spawn {
    assert(reads%4==0);unsigned index=reads/4;assert(randomSeed==before[index]);
    AstroEnemy *e=[super createSpecial:spawn];creates++;
    assert(e->state.frame==1&&e->state.velocity.x==0&&e->state.velocity.y==0&&e->layer==0);
    assert(e->hitPoints==[e->definition[@"hit_points"] intValue]&&e->visual.width==spriteInfo[e->baseSprite].width);
    return e;
}
- (void)finishSpecial:(const AstroSpecialSpawn *)spawn object:(AstroEnemy *)e {
    unsigned index=reads/4-1;assert(randomSeed==after[index]);
    assert(e->state.action_tick==1002+index*4);
    [super finishSpecial:spawn object:e];finishes++;
    assert(e->state.update_tick==1000+index*4&&e->state.animation_tick==1001+index*4);
    assert(e->state.action_tick==1002+index*4+(uint32_t)spawn->action_offset&&e->state.frame==spawn->frame);
    assert(e->state.velocity.x==spawn->velocity.x&&e->state.velocity.y==spawn->velocity.y);
    if(spawn->scale!=1)assert(e->bounds.right==(int16_t)astro_ppc_i32(spriteInfo[e->baseSprite].width*spawn->scale+e->bounds.left));
}
@end
@interface AstroView (SpecialSpawnCheck)
- (void)checkSpecialSpawns;
@end
@implementation AstroView (SpecialSpawnCheck)
- (void)checkSpecialSpawns {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=0;ui.frameInterval=3;observing=YES;
    for(int weapon=10;weapon<=30;weapon+=20){
        expectedSeeds(weapon);randomSeed=12345;reads=creates=finishes=0;startClock=YES;
        enemies=[NSMutableArray array];world=[NSMutableArray array];renderClock=0;
        special=(AstroSpecial){0};specialLoopRunning=specialReturnPending=NO;simulationTick=100;
        playerBounds=(AstroRect){20,30,91,50};playerCombat.kind=1;playerWeapon=weapon;inventory.specials=2;
        assert(![self startSpecial]);
        assert(reads==expectedCount*4&&enemies.count==expectedCount&&randomSeed==after[expectedCount-1]);
        assert(creates==(weapon==10?90u:35u)&&finishes==creates&&inventory.specials==1&&lastPlayerShot==962);
        for(unsigned i=0;i<world.count;i++)assert(((AstroEnemy *)world[i])->renderBirth==expectedCount-i);
    }
    observing=NO;puts("PASS actual host burst90/plasma41 constructors: source RNG points for all524 clock reads, original initial fields then mutation, scaled bounds, final RNG and birth order");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroView *view=[[AstroSpecialPhaseFactoryView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkSpecialSpawns];
}}
