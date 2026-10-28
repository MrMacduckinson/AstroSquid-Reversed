// Original RESOLVESPRITECOLLISION passes the actual actor, independently of g_player.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned hitCount;
static BOOL sceneryHit;
static AstroRect hitBounds;
@interface AstroActorCollisionView : AstroView
@end
@implementation AstroActorCollisionView
- (void)display {}
- (void)showPlayerHit:(BOOL)scenery bounds:(AstroRect)bounds {hitCount++;sceneryHit=scenery;hitBounds=bounds;}
@end
@interface AstroView (ActorCollisionCheck)
- (void)checkActorCollisions;
@end
@implementation AstroView (ActorCollisionCheck)
- (void)checkActorCollisions {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=100};playerVelocity=(AstroVelocity){7,8};
    playerBounds=(AstroRect){500,200,571,220};
    AstroEnemy *actor=[AstroEnemy new],*other=[AstroEnemy new];
    actor->kind=1;actor->hitPoints=100;actor->bounds=(AstroRect){20,20,40,40};
    other->kind=2;other->layer=2;other->hitPoints=10;other->bounds=(AstroRect){25,20,45,40};
    world=[NSMutableArray arrayWithArray:@[other,actor,[NSNull null]]];
    hudRedraws=0;hitCount=0;[self checkCollisionsFor:other];assert(hudRedraws==2);
    assert(actor->hitPoints==90&&other->state.remove==-1&&other->hitPoints==-80);
    assert(playerCombat.hit_points==100&&playerVelocity.x==7&&playerVelocity.y==8);
    assert(hitCount==1&&!sceneryHit&&hitBounds.left==20);
    // A removed attacker and an invulnerable actor must not receive another hit.
    hudRedraws=0;[self checkCollisionsFor:other];assert(actor->hitPoints==90&&hitCount==1&&hudRedraws==0);
    other->state.remove=0;actor->kind=-1;[self checkCollisionsFor:other];assert(actor->hitPoints==90&&hitCount==1&&hudRedraws==0);
    actor->kind=1;actor->hitPoints=100;actor->state.velocity=(AstroVelocity){0,0};
    other->kind=20;other->hitPoints=50;other->state.remove=0;other->state.velocity=(AstroVelocity){0,0};
    world=[NSMutableArray arrayWithArray:@[actor,other,[NSNull null]]];hudRedraws=0;[self checkCollisionsFor:actor];assert(hudRedraws==2);
    assert(actor->hitPoints==90&&other->hitPoints==40&&actor->state.velocity.x==-1&&other->state.velocity.x==1);
    assert(playerCombat.hit_points==100&&playerVelocity.x==7&&hitCount==2&&sceneryHit&&hitBounds.left==20);
    actor->hitPoints=100;other->kind=40;other->hitPoints=30;other->state.remove=0;other->placement=@{@"attribute":@401};
    hudRedraws=0;[self checkCollisionsFor:actor];assert(hudRedraws==2);assert(actor->hitPoints==130&&playerCombat.hit_points==100&&other->state.remove==1);
    hudRedraws=0;[self checkCollisionsFor:actor];assert(hudRedraws==2);assert(actor->hitPoints==130);
    other->state.remove=0;other->placement=@{@"attribute":@409};inventory.lives=2;
    [self checkCollisionsFor:actor];assert(inventory.lives==3&&playerCombat.hit_points==100);
    NSArray *objects=@[actor,[NSNull null]];NSMutableData *data=[self targetsForObjects:objects];
    BeamContext context={.view=self,.objects=objects,.targets=data.mutableBytes};
    AstroBeam beam={.damage=10,.target=0};actor->hitPoints=100;
    hudRedraws=0;[self applyBeam:&beam context:&context];assert(hudRedraws==2);
    assert(actor->hitPoints==80&&playerCombat.hit_points==100&&hitCount==3&&!sceneryHit);
    actor->kind=-1;hudRedraws=0;[self applyBeam:&beam context:&context];assert(actor->hitPoints==80&&hitCount==3&&hudRedraws==0);
    actor->kind=1;actor->hitPoints=10;[self applyBeam:&beam context:&context];
    assert(actor->hitPoints==0&&actor->state.remove==-1&&context.targets[0].remove==-1&&playerCombat.remove==0);
    // Killing an enemy invalidates HUD even when the kill score is zero.
    actor->kind=5;actor->hitPoints=100;actor->state.remove=0;actor->definition=@{@"kill_score":@0};
    hudRedraws=0;[self applyBeam:&beam context:&context];assert(actor->hitPoints==90&&hudRedraws==0);
    actor->hitPoints=10;[self applyBeam:&beam context:&context];assert(actor->hitPoints==0&&hudRedraws==2);
    hudRedraws=0;[self finishPlayerStart];assert(hudRedraws==2);
    hudRedraws=0;[self beginRespawnBlink];assert(hudRedraws==2);invulnerableUntil=0;
    hudRedraws=0;campaign=(AstroCampaign){1,1,0,0};[self beginStageTransition];assert(hudRedraws==2);
    puts("PASS source-backed actual host non-primary player projectile/scenery/pickup routing, shared inventory/hit overlay, removal and immunity");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroActorCollisionView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkActorCollisions];
}}
