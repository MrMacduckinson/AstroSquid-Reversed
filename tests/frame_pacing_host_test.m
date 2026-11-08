#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL measuring;static unsigned updates,draws,worldUpdates;static double began,pollInterval,firstNotice,maxEventAge;
@interface PacingView:AstroView
- (void)startMeasure;
- (void)finishMeasure;
- (void)checkReadyCard;
- (void)checkQueuedCheat;
- (void)stopTimer;
@end
@implementation PacingView
- (BOOL)initializeAudio {return YES;}
- (void)setGameCursorHidden:(BOOL)hidden {}
- (void)drawRect:(NSRect)rect {if(measuring)draws++;[super drawRect:rect];}
- (void)keyDown:(NSEvent *)event {
 if(measuring)maxEventAge=fmax(maxEventAge,NSProcessInfo.processInfo.systemUptime-event.timestamp);
 [super keyDown:event];
}
- (void)presentFrame {
 [super presentFrame];
 if(measuring&&cheats.weapons&&!firstNotice)firstNotice=NSProcessInfo.processInfo.systemUptime;
}
- (void)calculateActors {if(measuring)worldUpdates++;[super calculateActors];}
- (void)tick:(NSTimer *)t {if(measuring)updates++;[super tick:t];}
- (void)stopTimer {pollInterval=timer.timeInterval;[timer invalidate];timer=nil;}
- (void)startMeasure {
 [self acceptSplash];[ui show:@"Play Menu"];[self performMenuAction:@"New Game"];
 [self tickWallClock];assert(cardClockStarted);
 assert(self.wantsLayer);
 began=NSProcessInfo.processInfo.systemUptime;
 timer=[NSTimer scheduledTimerWithTimeInterval:pollInterval target:self selector:@selector(tick:) userInfo:nil repeats:YES];
 [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
 [self performSelector:@selector(checkReadyCard) withObject:nil afterDelay:.25];
}
- (void)checkReadyCard {
 printf("READY elapsed=%.3f presented=%d\n",NSProcessInfo.processInfo.systemUptime-began,cardClockStarted);fflush(stdout);
 assert(cardClockStarted);
 flow.ticks=59;[self advanceFlowWithKey:YES];
 began=NSProcessInfo.processInfo.systemUptime;measuring=YES;
 const unsigned codes[]={13,14,123,0,35,124,31,45,1};
 for(unsigned n=0;n<sizeof(codes)/sizeof(codes[0]);n++) {
  NSEvent *e=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:began windowNumber:self.window.windowNumber context:nil characters:@"x" charactersIgnoringModifiers:@"x" isARepeat:NO keyCode:codes[n]];
  [NSApp postEvent:e atStart:NO];
 }
 [self performSelector:@selector(checkQueuedCheat) withObject:nil afterDelay:.25];
 [self performSelector:@selector(finishMeasure) withObject:nil afterDelay:3];
}
- (void)checkQueuedCheat {
 printf("QUEUED_CHEAT elapsed=%.3f enabled=%d matched=%u\n",NSProcessInfo.processInfo.systemUptime-began,cheats.weapons,cheats.matched);fflush(stdout);
 assert(cheats.weapons&&cheatNoticeUntil>NSProcessInfo.processInfo.systemUptime);
 printf("INPUT maxEventAge=%.3f firstNotice=%.3f\n",maxEventAge,firstNotice-began);fflush(stdout);
 assert(firstNotice>began&&firstNotice-began<.25&&maxEventAge<.25);
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
 [AstroApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
 NSWindow *w=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,640,480)styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
 PacingView *v=[[PacingView alloc]initWithFrame:NSMakeRect(0,0,640,480)assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v stopTimer];w.contentView=v;((AstroApplication *)NSApp).gameView=v;[v startFullscreen];
 [v performSelector:@selector(startMeasure) withObject:nil afterDelay:.2];[NSApp run];
}}
