// Campaign clocks must advance inside synchronous stage transitions.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static uint32_t clockTick=100;
static NSMutableString *cardEvents;
static BOOL cardKey;
@interface MidClockAudio:AstroAudio
@end
@implementation MidClockAudio
- (void)serviceMusic {if(cardEvents)[cardEvents appendString:@"M"];}
- (void)stopMusic {}
- (void)playCue:(NSString *)name {}
- (BOOL)playMusic:(int)track {assert(track==1);return YES;}
@end
@interface MidClockView:AstroView
@end
@implementation MidClockView
- (uint32_t)currentGameTick {assert(clockTick<100000);return clockTick++;}
- (void)display {}
- (void)copyKeyMap:(unsigned char *)bytes {memset(bytes,0,16);bytes[0]=cardKey?1:0;if(cardEvents)[cardEvents appendString:@"K"];}
- (void)advanceFlowWithKey:(BOOL)key {if(cardEvents)[cardEvents appendString:@"A"];[super advanceFlowWithKey:key];}
@end
@implementation AstroView(MidClockCheck)
- (void)checkMidClock {
    [timer invalidate];timer=nil;[audio stop];audio=[MidClockAudio new];
    campaignTestPath=@"controlled-clock";simulationTick=700;observedWallTick=worldRenderTick=699;
    campaign=(AstroCampaign){1,2,0,0};pendingCampaign=campaign;selectedLevel=[levels indexOfObject:@"Data 1A"];
    menuVisible=paused=gameOver=NO;flow.phase=ASTRO_FLOW_PLAY;automatic=YES;
    world=[NSMutableArray array];enemies=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];worldTop=0;worldBottom=380;camera=0;
    [self createPlayerAtX:30 y:190];[self finishPlayerStart];
    campaignAction=ASTRO_CAMPAIGN_LOAD;[self pollGame];
    assert(clockTick>100&&!transitionLoopRunning&&!changingStage&&readyLoadPending);
    assert(flow.phase==ASTRO_FLOW_READY&&campaign.half==2&&!world.count&&!backgrounds.count);
    assert([self playerClockTick]==simulationTick);
    // Enter END through the real outer poll, retaining the inherited clock routing.
    selectedLevel=[levels indexOfObject:@"Data 1B"];campaign=(AstroCampaign){2,1,0,0};pendingCampaign=campaign;
    readyLoadPending=NO;flow.phase=ASTRO_FLOW_PLAY;simulationTick=700;observedWallTick=worldRenderTick=699;
    worldTop=0;worldBottom=380;camera=0;[self createPlayerAtX:30 y:190];[self finishPlayerStart];
    campaignAction=ASTRO_CAMPAIGN_LOAD;[self pollGame];
    assert(!transitionLoopRunning&&changingStage&&flow.phase==ASTRO_FLOW_END_CARD);
    assert(transition.phase==ASTRO_TRANSITION_CARD&&transition.scale<.001&&engineGlow&&departureTrail);
    assert(campaign.level==1&&campaign.half==2&&pendingCampaign.level==2);
    assert([self playerClockTick]==simulationTick);
    unsigned before=clockTick;campaignTestPath=nil;cardEvents=[NSMutableString string];
    cardClockStarted=NO;[self pollFlowCard];assert(cardEvents.length==0);
    cardClockStarted=YES;[self pollFlowCard];
    assert([cardEvents isEqual:@"KMA"]&&flow.phase==ASTRO_FLOW_END_CARD&&clockTick==before);
    [cardEvents setString:@""];cardKey=YES;[self pollFlowCard];
    assert([cardEvents isEqual:@"KMA"]);cardEvents=nil;cardKey=NO;campaignTestPath=@"controlled-clock";
    assert(!changingStage&&flow.phase==ASTRO_FLOW_READY&&campaign.level==2&&campaign.half==1);
    assert(transition.scale==1&&!engineGlow&&!departureTrail&&![world containsObject:[NSNull null]]);
    assert([levels[selectedLevel] isEqual:@"Data 2A"]&&!readyLoadPending);
    // ENDOFLEVEL clears all three lists before the final dialogue, too.
    pendingCampaign=(AstroCampaign){9,1,0,1};changingStage=YES;
    flow=(AstroFlow){.phase=ASTRO_FLOW_END_CARD,.complete=1};
    transition=(AstroTransition){.phase=ASTRO_TRANSITION_CARD};engineGlow=departureTrail=YES;
    [visualEffects addObject:[NSMutableData dataWithLength:sizeof(LiveEffect)]];
    [self advanceFlowWithKey:YES];
    assert(flow.phase==ASTRO_FLOW_ENDING&&!changingStage);
    assert(!world.count&&!enemies.count&&!mapPlacements.count&&!visualEffects.count&&!backgrounds.count&&!parallaxData.length);
    assert(!engineGlow&&!departureTrail&&!playerHitVisual.active);
    puts("PASS synchronous MID and END advance inherited campaign clock; END outer poll reaches card, waits for key, loads next A before READY without primary");
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[MidClockView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkMidClock];
}}
