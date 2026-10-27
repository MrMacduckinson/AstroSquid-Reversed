// Source-backed _DODELAY10003760: Delay(60), starting after card presentation.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting;
static uint32_t now;
static unsigned cardReads,gameReads,polls,displayRequests;
@interface DelayAudioProbe : AstroAudio
@end
@implementation DelayAudioProbe
- (void)stopMusic {}
- (BOOL)playMusic:(int)track {return YES;}
@end
@interface CardDelayView : AstroView
@end
@implementation CardDelayView
- (void)display {}
- (void)copyKeyMap:(unsigned char *)bytes {memset(bytes,0,16);for(unsigned i=0;i<128;i++)if(keys[i])bytes[i>>3]|=1u<<(i&7);}
- (void)setNeedsDisplay:(BOOL)value {if(injecting&&value)displayRequests++;[super setNeedsDisplay:value];}
- (uint32_t)cardDelayClockTick {if(injecting){cardReads++;return now;}return [super cardDelayClockTick];}
- (uint32_t)playerClockTick {return injecting?900+gameReads++:[super playerClockTick];}
- (void)advanceFlowWithKey:(BOOL)key {if(injecting)polls++;[super advanceFlowWithKey:key];}
@end
@implementation AstroView (CardDelayCheck)
- (void)checkCardDelay {
    [timer invalidate];timer=nil;[audio stop];audio=[DelayAudioProbe new];
    injecting=YES;menuVisible=paused=gameOver=gameOverPending=NO;initialReadyCard=YES;
    observedWallTick=77;worldRenderTick=88;lastSpawnTick=66;simulationTick=55;
    memset(keys,0,sizeof(keys));keys[0]=YES;astro_flow_ready(&flow,1,1);cardClockStarted=NO;
    now=100;[self tickWallClock];assert(!polls&&!cardReads&&!gameReads&&flow.phase==ASTRO_FLOW_READY);
    assert(displayRequests==1);
    [self recordCardPresentation];assert(cardReads==1&&cardDelayStartTick==100);
    now=120;[self recordCardPresentation];assert(cardReads==1&&cardDelayStartTick==100);
    now=159;[self tickWallClock];assert(!polls&&!gameReads&&flow.phase==ASTRO_FLOW_READY);
    assert(displayRequests==1);
    assert(observedWallTick==77&&worldRenderTick==88&&lastSpawnTick==66&&simulationTick==55);
    now=160;[self tickWallClock];assert(polls==1&&gameReads==3&&flow.phase==ASTRO_FLOW_PLAY&&!cardClockStarted);
    assert(displayRequests==1);
    assert(lastSpawnTick==900&&observedWallTick==901&&worldRenderTick==902);
    // Each ending page starts a new delay, including across the 32-bit wrap.
    gameReads=polls=0;flow=(AstroFlow){.phase=ASTRO_FLOW_ENDING};cardClockStarted=NO;
    now=UINT32_MAX-20;[self recordCardPresentation];
    now=38;[self tickWallClock];assert(!polls&&flow.ending_page==0);
    now=39;[self tickWallClock];assert(polls==1&&flow.ending_page==1&&!cardClockStarted&&!gameReads);
    now=100;[self tickWallClock];assert(polls==1&&!cardClockStarted);
    [self recordCardPresentation];keys[0]=NO;now=160;[self tickWallClock];
    assert(polls==2&&flow.ending_page==1&&cardClockStarted);
    unsigned stableRequests=displayRequests;
    [self tickWallClock];assert(displayRequests==stableRequests&&flow.ending_page==1);
    keys[0]=YES;[self tickWallClock];assert(polls==4&&flow.ending_page==2&&!cardClockStarted&&!gameReads);
    assert(displayRequests==stableRequests+1);
    // ENDOFLEVEL cards have no _DODELAY: same-tick input after presentation is accepted.
    polls=0;changingStage=NO;flow=(AstroFlow){.phase=ASTRO_FLOW_END_CARD,.next_stage=2,.next_half=1};
    now=300;[self recordCardPresentation];[self tickWallClock];
    assert(polls==1&&flow.phase==ASTRO_FLOW_READY&&!cardClockStarted&&!gameReads);
    memset(keys,0,sizeof(keys));initialReadyCard=YES;now=400;[self recordCardPresentation];
    [self testModifier:57 flags:NSEventModifierFlagCapsLock];assert(keys[57]);
    now=459;[self tickWallClock];assert(flow.phase==ASTRO_FLOW_READY);
    now=460;[self tickWallClock];assert(flow.phase==ASTRO_FLOW_PLAY);
    [self testModifier:57 flags:0];assert(!keys[57]);
    astro_flow_ready(&flow,1,1);cardClockStarted=NO;now=500;[self recordCardPresentation];
    [self testModifier:63 flags:NSEventModifierFlagFunction];assert(keys[63]);
    now=560;[self tickWallClock];assert(flow.phase==ASTRO_FLOW_PLAY);
    [self testModifier:63 flags:0];assert(!keys[63]);
    injecting=NO;
    puts("PASS actual card delay: starts after presentation, strict59/60, held/current keys, repeated draw, shared game clocks untouched, page reset/wrap, no-delay end card");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[CardDelayView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkCardDelay];
}}
