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
    injecting=NO;
    puts("PASS source-backed creation: four fresh clocks, deadline wrap, map batch and bullet retain timestamps, map order, strict edge and unordered NaN rejection");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroCreationClockView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkCreationClocks];
}}
