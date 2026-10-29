// Source-backed firing-actor identity through the production synchronous special stack.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
static unsigned reads,calculations;
static AstroEnemy *origin;
@interface AstroSpecialActorView : AstroView
@end
@implementation AstroSpecialActorView
- (uint32_t)currentGameTick {return observing?100:[super currentGameTick];}
- (uint32_t)specialClockTick {return observing?100+reads++/32:[super specialClockTick];}
- (void)display {}
- (void)renderSpecialWorld {}
- (void)presentSpecialFrame {}
- (void)readSpecialKeys {}
- (void)animateSpecialWorld {assert(origin->kind==-1&&playerCombat.kind==1);}
- (void)calculateSpecialContext:(AstroSpecialContext *)context world:(BeamContext *)worldContext {
    assert(specialSourceActor==origin&&origin->kind==-1&&playerCombat.kind==1);
    assert(context->action_tick==&origin->state.action_tick&&origin->state.action_tick==special.action_until&&lastPlayerShot==77);
    assert(context->gun_x==origin->bounds.left+74&&context->gun_y==origin->bounds.top+12);
    assert(playerBounds.left==500&&playerBounds.top==200);
    calculations++;origin->bounds.left++;
    context->targets=NULL;context->target_count=0;worldContext->objects=@[];worldContext->targets=NULL;
}
@end
@interface AstroView (SpecialActorCheck)
- (void)checkSpecialActor;
@end
@implementation AstroView (SpecialActorCheck)
- (void)checkSpecialActor {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    world=[NSMutableArray array];worldLeft=0;worldRight=640;worldTop=0;worldBottom=380;playerCombat.kind=1;playerBounds=(AstroRect){500,200,571,220};
    origin=[AstroEnemy new];ui.frameInterval=3;observing=YES;
    for(int ending=0;ending<2;ending++)for(int weapon=40;weapon<=50;weapon+=10){
        changingStage=ending;transition.allow_input=0;
        special=(AstroSpecial){0};specialReturnPending=specialLoopRunning=NO;reads=calculations=0;
        simulationTick=observedWallTick=worldRenderTick=100;lastPlayerShot=77;hudRedraws=0;inventory.specials=2;playerWeapon=weapon;
        origin->kind=1;origin->bounds=(AstroRect){20,30,91,50};origin->state.action_tick=9;
        origin->state.update_tick=99;origin->state.animation_tick=100;origin->state.frame=12;origin->state.tilt=3;origin->state.state=1;
        origin->visual=(AstroVisual){1,20,30,71,20,100};
        memset(keys,0,sizeof(keys));keys[controlKeys[1]]=YES;
        [self updateOtherPlayer:origin];
        assert(specialReturnPending&&calculations>0&&!specialLoopRunning&&!special.active&&specialSourceActor==nil);
        assert(origin->state.update_tick>=131&&origin->state.update_tick<=132);
        assert(origin->kind==1&&playerCombat.kind==1&&lastPlayerShot==77&&origin->state.action_tick==special.action_until);
        assert(origin->state.action_tick>=192&&origin->state.action_tick<=193);
        assert(hudRedraws==2&&inventory.specials==1&&playerBounds.left==500&&origin->bounds.left==20+(int)calculations);
    }
    observing=NO;origin=nil;
    puts("PASS source-backed host timed40/50 retain firing actor identity, own action clock and cached gun while primary remains independent");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroSpecialActorView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkSpecialActor];
}}
