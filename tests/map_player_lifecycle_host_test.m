// Source-backed shipped attr11 creation/CALC/cull/cleanup; runtime only on Intel.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting,sequence;
static uint32_t now;
static unsigned reads;
@interface AstroMapPlayerView : AstroView
@end
@implementation AstroMapPlayerView
- (uint32_t)playerClockTick {if(injecting){uint32_t tick=sequence?1000+reads:now;reads++;return tick;}return [super playerClockTick];}
- (void)display {}
@end
@interface AstroView (MapPlayerCheck)
- (void)checkMapPlayers;
@end
@implementation AstroView (MapPlayerCheck)
- (void)checkMapPlayers {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    memset(keys,0,sizeof(keys));injecting=YES;
    selectedLevel=0;camera=0;simulationTick=100;sequence=YES;reads=0;[self resetEnemies];
    assert(reads==4*enemies.count+4);uint32_t first=1000+reads-4;
    assert(playerState.update_tick==first&&playerState.animation_tick==first+1&&lastPlayerShot==first+2);
    assert(playerVisual.next_tick==first+3+(uint32_t)spriteInfo[1].delay);
    assert(playerState.frame==12&&playerState.tilt==1&&playerState.state==1);
    for(AstroEnemy *e in enemies){assert(e->state.action_tick<first&&e->renderBirth<playerRenderBirth);}
    assert(world[0]==[NSNull null]&&playerNextActor==world[1]);
    [world removeObjectIdenticalTo:[NSNull null]];reads=0;camera=12.75;
    [self createPlayerAtX:camera+30 y:190];
    assert(reads==4&&playerState.update_tick==1000&&playerState.animation_tick==1001&&lastPlayerShot==1002);
    assert(playerVisual.next_tick==1003+(uint32_t)spriteInfo[1].delay&&playerVisual.x==42);
    assert(playerState.frame==12&&playerState.tilt==1&&playerState.state==1);
    AstroPlayer animation=playerState;
    astro_player_animate(&animation,1011,1012,0);
    assert(animation.frame==12&&animation.tilt==1&&animation.animation_tick==1001);
    astro_player_animate(&animation,1012,1013,0);
    assert(animation.frame==13&&animation.tilt==2&&animation.animation_tick==1013);
    astro_player_animate(&animation,1024,1025,0);
    assert(animation.frame==14&&animation.tilt==3&&animation.animation_tick==1025);
    assert(playerBounds.left==42&&playerBounds.right==113&&playerBounds.top==190&&playerBounds.bottom==210);
    assert(previousPlayerBounds.left==0&&previousPlayerBounds.top==0&&previousPlayerBounds.right==0&&previousPlayerBounds.bottom==0);
    assert(world[0]==[NSNull null]&&playerNextActor==world[1]);sequence=NO;
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
