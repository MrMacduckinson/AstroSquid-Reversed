// Required active gap: rapid release/repress without a released hover-frame poll.
#define main astrosquid_application_main
#include "../../src/preview.m"
#undef main
static NSPoint point;
@interface ReleaseAudio:AstroAudio
@end
@implementation ReleaseAudio
- (BOOL)playCue:(NSString *)name position:(double)position {return YES;}
- (void)stop {}
@end
@interface ReleaseView:AstroView
- (void)checkRelease;
@end
@implementation ReleaseView
- (NSPoint)menuPoint:(NSEvent *)event {return point;}
- (void)display {}
- (void)saveScores {}
- (void)checkRelease {
    [timer invalidate];timer=nil;[audio stop];audio=[ReleaseAudio new];
    splashVisible=NO;editingKey=-1;score=0;menuVisible=gameOver=YES;gameEndRequested=NO;
    [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=0;
    point=NSMakePoint(-1,100);[self mouseDown:nil];assert(!gameEndRequested);
    point=NSMakePoint(400,320);[self mouseDragged:nil];assert(!gameEndRequested);
    [self mouseUp:nil];[self mouseDown:nil];
    printf("rapid_repress,end_requested=%d\n",gameEndRequested);fflush(stdout);
    // Original mouse_latch_native.csv case0 step6 keeps active1/end0.
    assert(!gameEndRequested);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    ReleaseView *view=[[ReleaseView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkRelease];
}}
