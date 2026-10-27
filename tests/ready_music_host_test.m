// GETREADY1004e004 STOPTRACK then conditional PLAYTRACK at accepted key.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSMutableString *events;
@interface ReadyAudioProbe : AstroAudio
@end
@implementation ReadyAudioProbe
- (void)stopMusic {[events appendString:@"S"];}
- (BOOL)playMusic:(int)track {assert(track==2);[events appendString:@"P"];return YES;}
@end
@interface ReadyMusicView : AstroView
@end
@implementation ReadyMusicView
- (void)display {}
- (void)pollMapSpawns {}
@end
@implementation AstroView (ReadyMusicCheck)
- (void)checkReadyMusic {
    [timer invalidate];timer=nil;[audio stop];audio=[ReadyAudioProbe new];
    events=[NSMutableString string];initialReadyCard=NO;
    astro_flow_ready(&flow,1,1);ui.musicVolume=1;flow.ticks=58;
    [self advanceFlowWithKey:YES];assert(flow.phase==ASTRO_FLOW_READY&&events.length==0);
    [self advanceFlowWithKey:YES];assert(flow.phase==ASTRO_FLOW_PLAY&&[events isEqual:@"SP"]);
    [self advanceFlowWithKey:YES];assert([events isEqual:@"SP"]);
    astro_flow_ready(&flow,1,2);ui.musicVolume=0;flow.ticks=59;[events setString:@""];
    [self advanceFlowWithKey:YES];assert(flow.phase==ASTRO_FLOW_PLAY&&[events isEqual:@"S"]);
    astro_flow_ready(&flow,2,1);ui.musicVolume=.1;flow.ticks=60;[events setString:@""];
    [self advanceFlowWithKey:NO];assert(flow.phase==ASTRO_FLOW_READY&&events.length==0);
    [self advanceFlowWithKey:YES];assert(flow.phase==ASTRO_FLOW_PLAY&&[events isEqual:@"SP"]);
    puts("PASS actual ready music: no calls before accepted key, STOP before PLAY, muted STOP only, no repeated PLAY calls");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[ReadyMusicView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkReadyMusic];
}}
