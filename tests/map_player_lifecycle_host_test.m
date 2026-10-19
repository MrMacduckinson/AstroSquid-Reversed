// Source-backed shipped attr11 creation/CALC/cull/cleanup; runtime only on Intel.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting;
static uint32_t now;
static unsigned reads;
@interface AstroMapPlayerView : AstroView
@end
@implementation AstroMapPlayerView
- (uint32_t)playerClockTick {if(injecting){reads++;return now;}return [super playerClockTick];}
- (void)display {}
@end
@interface AstroView (MapPlayerCheck)
- (void)checkMapPlayers;
@end
@implementation AstroView (MapPlayerCheck)
- (void)checkMapPlayers {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    memset(keys,0,sizeof(keys));injecting=YES;
    unsigned checked=0,halves=0;
    for(NSUInteger index=0;index<levels.count;index++){
        selectedLevel=index;camera=0;simulationTick=now=100;[self resetEnemies];
        unsigned wanted=0;for(NSDictionary *p in game[@"levels"][levels[index]][@"entities"])if([p[@"attribute"] intValue]==11)wanted++;
        NSMutableArray *players=[NSMutableArray array];
        for(AstroEnemy *e in enemies)if([e->placement[@"attribute"] intValue]==11)[players addObject:e];
        assert(players.count==wanted);if(wanted)halves++;
        for(AstroEnemy *e in players){
            assert(e->kind==1&&e->state.update_tick==100&&e->state.animation_tick==100);
            world=[NSMutableArray arrayWithArray:@[e,[NSNull null]]];enemies=[NSMutableArray arrayWithObject:e];
            playerCombat=(AstroCombatState){.kind=1,.hit_points=100};inventory.lives=2;score=1234;
            double originalX=e->visual.x;uint64_t beforeRNG=randomSeed;
            playerHitVisual.active=YES;engineGlow=YES;playerVisual=(AstroVisual){1,500,200,71,20,100};
            now=101;tickedScroll=10;reads=0;[self stepActor:e];
            assert(reads==4&&e->state.update_tick==101&&e->state.animation_tick==95&&e->state.remove==1);
            assert(e->visual.x==originalX&&e->kind==1&&playerCombat.kind==1&&playerCombat.hit_points==100);
            assert(playerHitVisual.visual.x==e->bounds.left-5&&playerHitVisual.visual.y==e->bounds.top-5);
            AstroTransitionRect glow=astro_transition_engine_glow(500,200,20,e->state.frame);
            assert(engineGlowRect.x==glow.x&&engineGlowRect.y==glow.y&&engineGlowRect.width==glow.width);
            [self cleanupWorld];assert(enemies.count==0&&world.count==1&&world[0]==[NSNull null]);
            assert(inventory.lives==2&&score==1234&&randomSeed==beforeRNG&&!gameOverPending&&!respawnTick);
            checked++;
        }
    }
    injecting=NO;assert(checked==17&&halves==14);
    puts("PASS source-backed actual host all17 map player nodes/14 halves: constructor clocks, cull still updates, four reads, shared hit/glow, no camera compensation, plain cleanup without primary death");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroMapPlayerView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkMapPlayers];
}}
