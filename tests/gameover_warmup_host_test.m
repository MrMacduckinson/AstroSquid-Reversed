// Same callback boundary as ppc_gameover_warmup_oracle; no game/GL on primary host.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
@interface WarmView:AstroView
@end
@implementation WarmView
- (uint32_t)currentGameTick {if(observing){puts("T");return 100;}return [super currentGameTick];}
- (uint32_t)playerClockTick {return [self currentGameTick];}
- (void)cleanupWorld {if(observing)puts("cleanup");else [super cleanupWorld];}
- (void)calculateActors {if(observing)puts("calc");else [super calculateActors];}
- (void)handleVisualEffects {if(observing)puts("visual");else [super handleVisualEffects];}
- (void)display {if(observing){puts("render");if(hudRedraws){puts("hud");hudRedraws--;}puts("swap");}}
- (void)delayGameTicks:(uint32_t)ticks {assert(observing);printf("D%u\n",ticks);}
- (void)setGameCursorHidden:(BOOL)hidden {if(observing){assert(!hidden);puts("cursor");@throw [NSException exceptionWithName:@"WarmDone" reason:nil userInfo:nil];}[super setGameCursorHidden:hidden];}
@end
@implementation AstroView(WarmCheck)
- (void)checkWarm {
 [timer invalidate];timer=nil;[audio stop];hudRedraws=2;observing=YES;
 @try {[self beginGameOver];assert(0);}@catch(NSException *e){assert([e.name isEqual:@"WarmDone"]);}
 observing=NO;
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 AstroView *view=[[WarmView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkWarm];
}}
