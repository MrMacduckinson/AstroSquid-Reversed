// Source-backed RNG/constructor interleaving through actual host effect factories.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
static uint32_t expectedSeeds[3];
static unsigned clockReads,created,finished;
@interface AstroDeathPhaseView : AstroView
@end
@implementation AstroDeathPhaseView
- (uint32_t)playerClockTick {
    if(!observing)return [super playerClockTick];
    unsigned phase=clockReads==0?0:clockReads<5?1:2;
    assert(clockReads<9&&randomSeed==expectedSeeds[phase]);return 1000+clockReads++;
}
- (void)display {}
- (void *)emitDeathEffect:(const AstroDeathEffect *)effect {
    if(observing){assert(created<3&&randomSeed==expectedSeeds[created]);created++;}
    return [super emitDeathEffect:effect];
}
- (void)finishDeathEffect:(const AstroDeathEffect *)effect object:(void *)object baseTick:(uint32_t)tick {
    if(observing){
        if(effect->type==ASTRO_EFFECT_EXPLOSION){LiveEffect *v=[(__bridge NSMutableData *)object mutableBytes];
            assert(v->visual.width==spriteInfo[effect->sprite].width&&v->visual.next_tick==1000+(uint32_t)spriteInfo[effect->sprite].delay);}
        if(effect->type==ASTRO_EFFECT_DEBRIS){AstroEnemy *e=(__bridge AstroEnemy *)object;
            assert(e->state.frame==1&&e->state.velocity.x==0&&e->state.velocity.y==0);
            assert(e->bounds.right-e->bounds.left==spriteInfo[e->baseSprite].width);
            assert(e->state.update_tick==1001&&e->state.animation_tick==1002&&e->state.action_tick==1003);}
    }
    [super finishDeathEffect:effect object:object baseTick:tick];
    if(observing){finished++;if(effect->type==ASTRO_EFFECT_DEBRIS){AstroEnemy *e=(__bridge AstroEnemy *)object;
        assert(e->state.update_tick==1001&&e->state.animation_tick==1002);
        assert(e->state.action_tick==1003+effect->action_tick-tick);
        assert(e->bounds.right==(int16_t)astro_ppc_i32(spriteInfo[e->baseSprite].width*effect->scale+e->bounds.left));
        assert(e->visual.width==effect->width);}}
}
@end
@interface AstroView (DeathPhaseCheck)
- (void)checkDeathPhases;
@end
@implementation AstroView (DeathPhaseCheck)
- (void)checkDeathPhases {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=0;
    enemies=[NSMutableArray array];world=[NSMutableArray array];visualEffects=[NSMutableArray array];
    simulationTick=100;randomSeed=12345;
    uint32_t expected=randomSeed;
    const int bounds[]={10,10,10,10,10,10,10,360,40,3,10,8};
    for(unsigned i=0;i<12;i++){astro_random(&expected,bounds[i]);if(i==3)expectedSeeds[0]=expected;if(i==6)expectedSeeds[1]=expected;if(i==11)expectedSeeds[2]=expected;}
    int debrisSprite=[game[@"attributes"][@"42"][@"sprite"] intValue];
    AstroDeathSource source={.kind=2,.tag=1,.left=20,.render_x=20,.top=30,.right=30,.bottom=40,.width=10,.height=10,.original_height=10,
        .explosion_sprite=83,.explosion_width=spriteInfo[83].width,.explosion_height=spriteInfo[83].height,.explosion_delay=spriteInfo[83].delay,
        .debris_attribute=42,.debris_sprite=debrisSprite,.debris_width=spriteInfo[debrisSprite].width,.debris_height=spriteInfo[debrisSprite].height,.debris_count=1};
    observing=YES;DeathContext context={self,100};
    assert(astro_death_effects_phased(&source,100,&randomSeed,createDeathEffect,finishDeathEffect,&context));
    assert(created==3&&finished==3&&clockReads==9&&randomSeed==expected&&enemies.count==2&&visualEffects.count==1);
    AstroEnemy *pickup=enemies[0],*debris=enemies[1];assert(pickup->kind==40&&debris->kind==4);
    assert(pickup->state.update_tick==1005&&pickup->state.animation_tick==1006&&pickup->state.action_tick==1007);
    const LiveEffect *image=[visualEffects[0] bytes];assert(image->birth<debris->renderBirth&&debris->renderBirth<pickup->renderBirth);
    observing=NO;puts("PASS actual host death phases: constructor clocks at source RNG seeds, unscaled creation then SCALESPRITE bounds, retained fresh timers, birth order and exact final RNG");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroView *view=[[AstroDeathPhaseView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkDeathPhases];
}}
