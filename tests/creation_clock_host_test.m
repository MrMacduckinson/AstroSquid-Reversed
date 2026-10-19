// Source-backed NEWSPRITE/LMNEWSPRITE clock protocol; run only on Intel iMac.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting;
static uint32_t script[16];
static unsigned used,count;
@interface AstroCreationClockView : AstroView
@end
@implementation AstroCreationClockView
- (uint32_t)playerClockTick {
    if(!injecting)return [super playerClockTick];
    assert(used<count);return script[used++];
}
- (void)display {}
@end
@interface AstroView (CreationClockCheck)
- (void)checkCreationClocks;
@end
@implementation AstroView (CreationClockCheck)
- (void)checkCreationClocks {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    NSDictionary *placement=@{@"attribute":@201,@"x":@30.5,@"y":@40.5,@"width":@90,@"height":@80};
    const uint32_t direct[]={100,103,107,UINT32_MAX};
    memcpy(script,direct,sizeof(direct));count=4;used=0;injecting=YES;simulationTick=19;
    AstroEnemy *e=[self entityForPlacement:placement];
    assert(used==4&&e->state.update_tick==100&&e->state.animation_tick==103&&e->state.action_tick==107);
    assert(e->visual.next_tick==UINT32_MAX+(uint32_t)spriteInfo[e->baseSprite].delay);
    const uint32_t batch[]={201,202,203,204,301,302,303,304};
    memcpy(script,batch,sizeof(batch));count=8;used=0;camera=0;
    NSDictionary *second=@{@"attribute":@201,@"x":@31.5,@"y":@41.5,@"width":@90,@"height":@80};
    NSDictionary *edge=@{@"attribute":@201,@"x":@740,@"y":@0};
    NSDictionary *nan=@{@"attribute":@201,@"x":@(NAN),@"y":@0};
    enemies=[NSMutableArray array];world=[NSMutableArray array];
    mapPlacements=[NSMutableArray arrayWithArray:@[placement,second,edge,nan]];
    [self makeNewSprites];
    assert(used==8&&enemies.count==2&&mapPlacements.count==2);
    AstroEnemy *a=enemies[1],*b=enemies[0];
    assert(a->placement==placement&&b->placement==second&&a->renderBirth<b->renderBirth);
    assert(a->state.update_tick==201&&a->state.animation_tick==202&&a->state.action_tick==203);
    assert(b->state.update_tick==301&&b->state.animation_tick==302&&b->state.action_tick==303);
    assert(a->visual.next_tick==204+(uint32_t)spriteInfo[a->baseSprite].delay);
    assert(b->visual.next_tick==304+(uint32_t)spriteInfo[b->baseSprite].delay);
    assert(a->state.x==30&&a->state.y==40&&b->state.x==31&&b->state.y==41);
    const uint32_t bulletClocks[]={401,402,403,404};
    memcpy(script,bulletClocks,sizeof(bulletClocks));count=4;used=0;
    AstroShot shot={.type=1,.x=100,.y=180,.heading=90};
    [self spawnShot:&shot source:1];AstroEnemy *bullet=enemies[0];
    assert(used==4&&bullet->kind==2&&bullet->layer==3);
    assert(bullet->state.update_tick==401&&bullet->state.animation_tick==402&&bullet->state.action_tick==403);
    assert(bullet->visual.next_tick==404+(uint32_t)spriteInfo[bullet->baseSprite].delay);
    const int offsets[]={-30,0,29};
    for(unsigned i=0;i<3;i++) {
        const uint32_t clocks[]={501,502,i==0?10:UINT32_MAX-5,504};
        memcpy(script,clocks,sizeof(clocks));count=4;used=0;
        AstroSpecialSpawn spawn={.kind=4,.subtype=2,.x=100,.y=180,.frame=2,.scale=1,.action_offset=offsets[i]};
        [self spawnSpecial:&spawn];AstroEnemy *particle=enemies[0];
        assert(used==4&&particle->kind==4&&particle->state.frame==2);
        assert(particle->state.update_tick==501&&particle->state.animation_tick==502);
        assert(particle->state.action_tick==clocks[2]+(uint32_t)offsets[i]);
        assert(particle->visual.next_tick==504+(uint32_t)spriteInfo[particle->baseSprite].delay);
    }
    for(int type=ASTRO_EFFECT_DEBRIS;type<=ASTRO_EFFECT_PICKUP;type++) {
        const uint32_t clocks[]={601,602,UINT32_MAX-3,604};
        memcpy(script,clocks,sizeof(clocks));count=4;used=0;
        AstroDeathEffect effect={.type=type,.kind=type==ASTRO_EFFECT_DEBRIS?4:40,
            .attribute=type==ASTRO_EFFECT_DEBRIS?42:401,.x=100,.y=180,.frame=1,
            .width=20,.height=20,.action_tick=simulationTick+9};
        [self emitDeathEffect:&effect];AstroEnemy *created=enemies[0];
        assert(used==4&&created->state.update_tick==601&&created->state.animation_tick==602);
        assert(created->state.action_tick==clocks[2]+(type==ASTRO_EFFECT_DEBRIS?9u:0u));
        assert(created->visual.next_tick==604+(uint32_t)spriteInfo[created->baseSprite].delay);
    }
    for(int delta=-5;delta<=4;delta++) {
        script[0]=UINT32_MAX-2;count=1;used=0;
        AstroDeathEffect effect={.type=ASTRO_EFFECT_EXPLOSION,.sprite=1,.x=100,.y=180,
            .width=71,.height=20,.animation_tick=simulationTick+(uint32_t)spriteInfo[1].delay+(uint32_t)delta};
        [self emitDeathEffect:&effect];const LiveEffect *created=[visualEffects.lastObject bytes];
        assert(used==1&&created->visual.next_tick==script[0]+(uint32_t)spriteInfo[1].delay+(uint32_t)delta);
    }
    injecting=NO;
    puts("PASS source-backed creation: four clocks, map/bullet/special timestamps, signed offsets/wrap, death debris/pickup clocks, ten explosion offsets, map order/edge/NaN");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroCreationClockView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkCreationClocks];
}}
