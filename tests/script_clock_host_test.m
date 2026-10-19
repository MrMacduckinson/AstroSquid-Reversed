// Actual CALC→DOSCRIPTED integration with scripted independent clock values.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
static uint32_t values[8];
static unsigned used,count;
@interface AstroScriptClockView : AstroView
@end
@implementation AstroScriptClockView
- (uint32_t)playerClockTick {if(observing){assert(used<count);return values[used++];}return [super playerClockTick];}
- (void)display {}
@end
@interface AstroView (ScriptClockCheck)
- (void)checkScriptClock;
@end
@implementation AstroView (ScriptClockCheck)
- (void)checkScriptClock {
    [timer invalidate];timer=nil;[audio stop];observing=YES;camera=0;simulationTick=999;
    AstroInstruction op={.delay=7,.opcode=ASTRO_STOP};
    for(int open=0;open<2;open++){
        AstroEnemy *e=[AstroEnemy new];e->kind=5;e->baseSprite=60;e->visual=(AstroVisual){60,10,20,16,17,1000};
        e->definition=@{@"animated":@1};e->program=[NSData dataWithBytes:&op length:sizeof(op)];
        e->state=(AstroScriptState){.frame=1,.tilt=1,.state=1,.update_tick=100,.action_tick=100,.animation_tick=100,.velocity={2,3}};
        enemies=[NSMutableArray arrayWithObject:e];world=[NSMutableArray arrayWithObject:e];
        const uint32_t ticks[]={100,open?101:100,105,110,120,140,150};memcpy(values,ticks,sizeof(ticks));count=open?7:2;used=0;
        [self stepActor:e];assert(used==count&&e->state.x==12&&e->state.y==23);
        if(open){assert(e->state.update_tick==105&&e->state.action_tick==127&&e->state.animation_tick==150&&e->state.line==1);
            assert(e->state.velocity.x==0&&e->state.velocity.y==0&&e->state.frame==2&&e->state.tilt==2);}
        else assert(e->state.update_tick==100&&e->state.action_tick==100&&e->state.animation_tick==100&&e->state.line==0);
    }
    observing=NO;puts("PASS actual host CALC/script clock integration: visual clock then independent update/action/animation clocks, closed update stops script only");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroView *view=[[AstroScriptClockView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkScriptClock];
}}
