// Actual CALC/DOBULLET clock boundary; source-backed, run only on Intel.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
static uint32_t values[2];
static unsigned count,used;
@interface AstroBulletClockView : AstroView
@end
@implementation AstroBulletClockView
- (uint32_t)playerClockTick {if(observing){assert(used<count);return values[used++];}return [super playerClockTick];}
- (void)display {}
@end
@interface AstroView (BulletClockCheck)
- (void)checkBulletClocks;
@end
@implementation AstroView (BulletClockCheck)
- (void)checkBulletClocks {
    [timer invalidate];timer=nil;[audio stop];observing=YES;camera=0;simulationTick=999;
    const struct {int state;uint32_t old,comparison,store;unsigned reads;} cases[]={
        {1,100,100,0,1},{1,100,101,130,2},{1,UINT32_MAX,0,4,2},
        {1,0,0x80000000,0,1},{1,200,199,0,1},{0,100,101,130,0},{2,100,101,130,0},{-1,100,101,130,0}};
    for(unsigned i=0;i<8;i++){
        AstroEnemy *bullet=[AstroEnemy new];bullet->kind=2;bullet->visual=(AstroVisual){1,20,30,10,10,1000};
        bullet->definition=@{@"animated":@1};bullet->state=(AstroScriptState){.state=cases[i].state,.update_tick=cases[i].old,.velocity={2,3}};
        world=[NSMutableArray arrayWithObject:bullet];enemies=[NSMutableArray arrayWithObject:bullet];
        values[0]=cases[i].comparison;values[1]=cases[i].store;count=cases[i].reads;used=0;
        [self stepActor:bullet];assert(used==count);
        assert(bullet->state.update_tick==(count==2?cases[i].store:cases[i].old));
        assert(bullet->visual.x==22&&bullet->visual.y==33&&bullet->state.x==22&&bullet->state.y==33);
        assert(bullet->bounds.left==22&&bullet->bounds.top==33&&bullet->state.remove==0);
    }
    observing=NO;puts("PASS8 source-backed actual host bullet clocks: fresh compare/store, equality, wrap/signednegative, inactive states no reads, CALC movement independent of gate");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroView *view=[[AstroBulletClockView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkBulletClocks];
}}
