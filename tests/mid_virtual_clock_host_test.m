// The campaign driver's synthetic clock must advance inside synchronous MIDLEVEL.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static uint32_t clockTick=100;
@interface MidClockAudio:AstroAudio
@end
@implementation MidClockAudio
- (void)serviceMusic {}
- (void)stopMusic {}
- (BOOL)playMusic:(int)track {assert(track==1);return YES;}
@end
@interface MidClockView:AstroView
@end
@implementation MidClockView
- (uint32_t)currentGameTick {assert(clockTick<100000);return clockTick++;}
- (void)display {}
@end
@implementation AstroView(MidClockCheck)
- (void)checkMidClock {
    [timer invalidate];timer=nil;[audio stop];audio=[MidClockAudio new];
    campaignTestPath=@"controlled-clock";simulationTick=700;observedWallTick=worldRenderTick=699;
    campaign=(AstroCampaign){1,2,0,0};selectedLevel=[levels indexOfObject:@"Data 1A"];
    menuVisible=paused=gameOver=NO;flow.phase=ASTRO_FLOW_PLAY;automatic=YES;
    world=[NSMutableArray array];enemies=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];worldTop=0;worldBottom=380;camera=0;
    [self createPlayerAtX:30 y:190];[self finishPlayerStart];
    campaignAction=ASTRO_CAMPAIGN_LOAD;[self pollGame];
    assert(clockTick>100&&!transitionLoopRunning&&!changingStage&&readyLoadPending);
    assert(flow.phase==ASTRO_FLOW_READY&&campaign.half==2&&!world.count&&!backgrounds.count);
    assert([self playerClockTick]==simulationTick);
    puts("PASS synchronous MIDLEVEL advances campaign clock, reaches next briefing, clears scene and restores synthetic clock mode");
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[MidClockView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkMidClock];
}}
