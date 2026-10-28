// Actual root mouse callbacks/poll plus UI hover state; terminal tail observed separately.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include "mouse_latch_steps.h"
static unsigned scenario,step,reads;
static BOOL held;
static NSPoint point;
@interface LatchAudio:AstroAudio
@end
@implementation LatchAudio
- (BOOL)playCue:(NSString *)name position:(double)pan {assert([name isEqual:@"Click"]);uint64_t bits;memcpy(&bits,&pan,8);printf("%u,%u,S,%016llx\n",scenario,step,bits);return YES;}
- (void)stop {}
@end
@interface LatchView:AstroView
- (void)checkLatch;
@end
@implementation LatchView
- (NSPoint)menuPoint:(NSEvent *)event {return point;}
- (NSPoint)currentMenuMousePoint {return point;}
- (BOOL)menuMouseButtonPressed {return held;}
- (void)display {}
- (void)finishGameOver {ui.gameOverClosing=YES;}
- (void)checkLatch {
    [timer invalidate];timer=nil;[audio stop];audio=[LatchAudio new];splashVisible=NO;editingKey=-1;
    for(scenario=0;scenario<2;scenario++){
        ui.readTick=nil;[ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=scenario;
        astro_score_editor_begin(&scoreEditor);scoreEditor.cursor=77;[self refreshScoreEditor];
        menuVisible=gameOver=YES;menuMouseLatched=NO;gameEndRequested=NO;reads=0;
        ui.readTick=^uint32_t{uint32_t tick=100+reads++;printf("%u,%u,T,%u\n",scenario,step,tick);return tick;};
        for(step=0;step<sizeof(mouse_latch_steps)/sizeof(mouse_latch_steps[0]);step++){
            point=NSMakePoint(mouse_latch_steps[step].x,mouse_latch_steps[step].y);held=mouse_latch_steps[step].down;
            if(!scenario&&(step==10||step==12))point.x=0;
            if(mouse_latch_steps[step].op=='H')[self pollMenuMouse];
            if(mouse_latch_steps[step].op=='D')[self mouseDown:nil];
            if(mouse_latch_steps[step].op=='U')[self mouseUp:nil];
            const AstroUIMotion *state=[[[ui valueForKey:@"orbStates"]objectForKey:@"GameOverOK"]bytes];
            unsigned deadline=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"GameOverOK"]unsignedIntValue];
            printf("%u,%u,%c,%d,%u,%d,%d,%d,%d,%d",scenario,step,mouse_latch_steps[step].op,state->sprite,deadline,menuMouseLatched,!ui.gameOverClosing,gameEndRequested,scoreEditor.cursor,ui.editingHighscore>0);
            for(unsigned axis=0;axis<4;axis++){uint64_t bits;memcpy(&bits,(const char *)state+axis*8,8);printf(",%016llx",bits);}putchar('\n');
        }
        assert(reads==5&&gameEndRequested&&ui.gameOverClosing);
        [self pollMenuMouse];
            const AstroUIMotion *state=[[[ui valueForKey:@"orbStates"]objectForKey:@"GameOverOK"]bytes];
            unsigned deadline=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"GameOverOK"]unsignedIntValue];
            printf("%u,%u,%c,%d,%u,%d,%d,%d,%d,%d",scenario,step,'H',state->sprite,deadline,menuMouseLatched,!ui.gameOverClosing,gameEndRequested,scoreEditor.cursor,ui.editingHighscore>0);
            for(unsigned axis=0;axis<4;axis++){uint64_t bits;memcpy(&bits,(const char *)state+axis*8,8);printf(",%016llx",bits);}putchar('\n');
        assert(reads==5);
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    LatchView *view=[[LatchView alloc]initWithFrame:NSMakeRect(0,0,640,480)assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkLatch];
}}
