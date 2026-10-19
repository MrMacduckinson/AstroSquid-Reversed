// Original signed16 FPS is loaded once, independently of smooth filtering.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
@interface AstroView (FPSPreferenceCheck)
- (void)checkFPS:(int16_t)fps interval:(int16_t)interval;
@end
@implementation AstroView (FPSPreferenceCheck)
- (void)checkFPS:(int16_t)fps interval:(int16_t)interval {
    [timer invalidate];timer=nil;[audio stop];
    assert(preferenceFPS==fps&&ui.frameInterval==interval);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    const int16_t cases[][2]={{60,1},{20,3},{0,-1},{-1,-60},{61,0},{-32768,0},{32767,0}};
    for(unsigned i=0;i<sizeof(cases)/sizeof(*cases);i++){
        [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"fps":@(cases[i][0]),@"sound":@0,@"music":@0,@"smooth":@(i%2)}} forName:NSArgumentDomain];
        AstroView *view=[[AstroView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkFPS:cases[i][0] interval:cases[i][1]];
    }
    puts("PASS7 actual startup signed16 FPS settings, unvalidated zero/negative/high domain and independent smooth");
}}
