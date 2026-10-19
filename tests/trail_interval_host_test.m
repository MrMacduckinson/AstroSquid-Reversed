// Actual END trail: CPU/world frozen; shared render gate owns stars and counter.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting;
static uint32_t clocks[2];static unsigned used,count,draws,actors,animations;
static double drawScale;
@interface AstroTrailView : AstroView
@end
@implementation AstroTrailView
- (uint32_t)playerClockTick {if(!injecting)return [super playerClockTick];assert(used<count);return clocks[used++];}
- (void)stepActor:(id)object {(void)object;actors++;}
- (void)updateVisualEffects {animations++;}
- (void)display {if(injecting){draws++;drawScale=transition.scale;assert(flow.phase==ASTRO_FLOW_PLAY);}}
@end
@interface AstroView (TrailIntervalCheck)
- (void)checkTrailIntervals;
@end
@implementation AstroView (TrailIntervalCheck)
- (void)checkTrailIntervals {
    [timer invalidate];timer=nil;[audio stop];
    menuVisible=NO;changingStage=YES;flow=(AstroFlow){.phase=ASTRO_FLOW_PLAY};campaign=(AstroCampaign){1,2,0,0};pendingCampaign=(AstroCampaign){2,1,0,0};
    campaignAction=0;camera=80;tickedScroll=0;simulationTick=100;worldRenderTick=100;ui.frameInterval=3;
    world=[NSMutableArray arrayWithObject:[NSNull null]];enemies=[NSMutableArray array];backgrounds=@[];parallaxData=[NSMutableData data];
    transition=(AstroTransition){.mode=ASTRO_TRANSITION_END,.phase=ASTRO_TRANSITION_TRAIL,.scroll_x=220,.scale=.006};
    randomSeed=123;astro_stars_init(stars,0,&randomSeed);
    AstroStar expected[3000];memcpy(expected,stars,sizeof expected);uint32_t seed=randomSeed;
    draws=actors=animations=0;injecting=YES;
    for(int frame=0;frame<2;frame++){
        double before=transition.scale;tickedScroll=0;[self stepEnemies];assert(transition.scale==before&&camera==80&&actors==0&&animations==0&&tickedScroll==220);
        assert(!memcmp(stars,expected,sizeof expected)&&randomSeed==seed);
        clocks[0]=worldRenderTick+1;count=1;used=0;[self renderTick];assert(used==1&&draws==(unsigned)frame&&transition.scale==before);
        assert(!memcmp(stars,expected,sizeof expected)&&randomSeed==seed);
        clocks[0]=worldRenderTick+3;clocks[1]=worldRenderTick+9;count=2;used=0;
        astro_stars_move(expected,-camera,0,camera,0,camera+640,380,220,0,0,0,3,&seed,NULL,0,0);
        [self renderTick];assert(used==2&&draws==(unsigned)frame+1&&actors==0&&animations==0&&camera==80&&tickedScroll==220);
        assert(drawScale==before-.005&&!memcmp(stars,expected,sizeof expected)&&randomSeed==seed);
        assert(flow.phase==(frame?ASTRO_FLOW_END_CARD:ASTRO_FLOW_PLAY));
    }
    injecting=NO;assert(transition.phase==ASTRO_TRANSITION_CARD);
    puts("PASS actual trail closed/open fresh clocks, CPU/world freeze, retained SX, complete stars/RNG, final draw before card");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroTrailView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkTrailIntervals];
}}
