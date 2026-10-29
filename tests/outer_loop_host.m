// Actual beginGameLoop/pollGame/renderTick gates; semantic services observed.
// GPU HUD commands and terminal tail are outside this fixture.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include "outer_loop_cases.h"
static unsigned scenario,reads,initialHUD;
static BOOL observing,repeated;
static void loopEvent(char name,uint32_t value,uint32_t cpu,uint32_t render){
    printf("%u,%c,%u,%u,%u,%u\n",scenario,name,reads,value,cpu,render);
}
@interface LoopView:AstroView
- (void)loopEvent:(char)name value:(uint32_t)value;
- (void)checkLoop;
- (void)observeHUD;
@end
static __weak LoopView *loopView;
@interface LoopAudio:AstroAudio
@end
@implementation LoopAudio
- (void)serviceMusic {if(observing)[loopView loopEvent:'S' value:0];}
@end
@interface LoopHUD:AstroHUDRenderer
@end
@implementation LoopHUD
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)width height:(GLsizei)height {[loopView observeHUD];}
@end
@implementation LoopView
- (void)observeHUD {[self loopEvent:'V' value:(uint16_t)hudRedraws];}
- (void)loopEvent:(char)name value:(uint32_t)value {loopEvent(name,value,observedWallTick,worldRenderTick);}
- (uint32_t)playerClockTick {
    if(!observing)return [super playerClockTick];
    assert(repeated||reads<loop_cases[scenario].count);
    uint32_t value=repeated?(scenario>=8?0xfffffff0u:1000u)+reads++*(scenario%4):loop_cases[scenario].clocks[reads++];[self loopEvent:'C' value:value];return value;
}
- (void)cleanupWorld {if(observing){[self loopEvent:'U' value:0];if(loop_cases[scenario].world_clock)[self playerClockTick];}else [super cleanupWorld];}
- (void)calculateActors {if(observing){[self loopEvent:'A' value:0];if(loop_cases[scenario].world_clock)[self playerClockTick];}else [super calculateActors];}
- (void)display {if(observing){[self drawHUD:YES];[self loopEvent:'R' value:0];[self loopEvent:'W' value:0];}}
- (void)handleVisualEffects {if(observing)[self loopEvent:'H' value:0];else [super handleVisualEffects];}
- (void)makeNewSprites {if(observing){[self loopEvent:'F' value:0];if(loop_cases[scenario].factory_clock)[self playerClockTick];}else [super makeNewSprites];}
- (void)copyKeyMap:(unsigned char *)bytes {memset(bytes,0,16);if(observing)[self loopEvent:'K' value:0];}
- (void)handleMiscKeys {if(observing)[self loopEvent:'M' value:0];else [super handleMiscKeys];}
- (void)checkLoop {
    [timer invalidate];timer=nil;[audio stop];audio=[[LoopAudio alloc]initWithAssets:assetPath error:NULL];assert(audio);loopView=self;hud=[[LoopHUD alloc]initWithGame:game ui:ui];
    for(scenario=0;scenario<sizeof(loop_cases)/sizeof(loop_cases[0]);scenario++){
        reads=0;hudRedraws=initialHUD;observedWallTick=worldRenderTick=lastSpawnTick=simulationTick=0;
        menuVisible=paused=gameOver=changingStage=respawnPending=gameEndRequested=gameLoopActive=NO;
        flow.phase=ASTRO_FLOW_PLAY;respawnTick=invulnerableUntil=0;automatic=NO;
        campaignAction=ASTRO_CAMPAIGN_NONE;ui.frameInterval=loop_cases[scenario].interval;
        observing=YES;[self beginGameLoop];for(unsigned i=0;i<(repeated?64u:1u);i++)[self pollGame];assert(repeated||reads==loop_cases[scenario].count);[self loopEvent:'Z' value:(uint16_t)hudRedraws];observing=NO;
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc>=2&&argc<=4);repeated=argc==4;assert(!repeated||!strcmp(argv[3],"repeat"));initialHUD=argc>=3?(unsigned)strtoul(argv[2],NULL,10):0;assert(initialHUD<=2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    LoopView *view=[[LoopView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkLoop];
}}
