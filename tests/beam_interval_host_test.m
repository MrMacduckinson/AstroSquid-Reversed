// Actual app beam caller must preserve the native signed interval domain.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
@interface AstroView (BeamIntervalCheck)
- (void)checkBeamIntervals;
@end
@implementation AstroView (BeamIntervalCheck)
- (void)checkBeamIntervals {
    [timer invalidate];timer=nil;[audio stop];
    world=[NSMutableArray array];enemies=[NSMutableArray array];camera=0;simulationTick=100;
    const int intervals[]={-32768,-3,-2,-1,0,1,2,3,32767};
    for(unsigned i=0;i<sizeof(intervals)/sizeof(*intervals);i++)for(int weapon=40;weapon<=43;weapon++) {
        ui.frameInterval=intervals[i];[liveBeams removeAllObjects];
        [self fireWeapon:weapon x:100 y:180 heading:0 source:1];
        assert(liveBeams.count==(weapon>=42?2:1));
        for(NSData *data in liveBeams) {
            const LiveBeam *live=data.bytes;
            assert(live->beam.damage==(int)((weapon==40?1.5:weapon==41?3:4.5)*intervals[i]));
        }
    }
    puts("PASS actual host36 signed interval laser requests, including zero/negative damage");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkBeamIntervals];
}}
