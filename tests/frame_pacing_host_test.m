#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL measuring;static unsigned updates,draws,worldUpdates;static double began,pollInterval;
@interface PacingView:AstroView
- (void)startMeasure;
- (void)finishMeasure;
- (void)stopTimer;
@end
@implementation PacingView
- (BOOL)initializeAudio {return YES;}
- (void)setGameCursorHidden:(BOOL)hidden {}
- (void)drawRect:(NSRect)rect {if(measuring)draws++;[super drawRect:rect];}
- (void)calculateActors {if(measuring)worldUpdates++;[super calculateActors];}
- (void)tick:(NSTimer *)t {if(measuring)updates++;[super tick:t];}
- (void)stopTimer {pollInterval=timer.timeInterval;[timer invalidate];timer=nil;}
- (void)startMeasure {
 [self acceptSplash];[ui show:@"Play Menu"];[self performMenuAction:@"New Game"];[self display];
 flow.ticks=59;[self advanceFlowWithKey:YES];
 assert(self.wantsLayer);
 began=NSProcessInfo.processInfo.systemUptime;measuring=YES;
 timer=[NSTimer scheduledTimerWithTimeInterval:pollInterval target:self selector:@selector(tick:) userInfo:nil repeats:YES];
 [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
 [self performSelector:@selector(finishMeasure) withObject:nil afterDelay:3];
}
- (void)finishMeasure {
 [self stopTimer];double seconds=NSProcessInfo.processInfo.systemUptime-began;
 printf("PACING elapsed=%.3f polls=%u worlds=%u draws=%u worldRate=%.2f\n",seconds,updates,worldUpdates,draws,worldUpdates/seconds);
 assert(worldUpdates/seconds>=50&&draws<=worldUpdates+4);fflush(stdout);
 restoreFullscreen();exit(0);
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);alarm(20);atexit(restoreFullscreen);
 [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
 NSWindow *w=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,640,480)styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
 PacingView *v=[[PacingView alloc]initWithFrame:NSMakeRect(0,0,640,480)assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v stopTimer];w.contentView=v;[v startFullscreen];
 [v performSelector:@selector(startMeasure) withObject:nil afterDelay:.2];[NSApp run];
}}
