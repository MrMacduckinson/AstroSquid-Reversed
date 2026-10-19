// Actual drawRect ordering; GL rasterization and HUD dirty-count equivalence are separate.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing,drawInnerSpecial;
static NSMutableString *events;
@interface AstroObservedHUD : AstroHUDRenderer
@end
@implementation AstroObservedHUD
- (void)drawState:(const AstroHUDState *)state texture:(GLuint (^)(NSInteger))texture framebufferWidth:(GLsizei)width height:(GLsizei)height {
    [events appendString:@"H"];
}
@end
@interface AstroHUDOrderView : AstroView
@end
@implementation AstroHUDOrderView
- (uint32_t)playerClockTick {return observing?200:[super playerClockTick];}
- (void)display {if(observing)[self drawRect:self.bounds];else [super display];}
- (void)sprite:(NSInteger)identifier x:(double)x y:(double)y width:(double)width height:(double)height {
    if(observing){if(identifier==60)[events appendString:@"W"];return;}
    [super sprite:identifier x:x y:y width:width height:height];
}
- (void)presentFrame {if(observing)[events appendString:@"P"];else [super presentFrame];}
- (void)stepEnemies {assert(observing);simulationTick++;}
- (void)stepWorldWithoutFlow {
    assert(observing);simulationTick++;
    if(drawInnerSpecial){[self renderSpecialWorld];[self presentSpecialFrame];}
}
- (void)handleVisualEffects {assert(observing);[events appendString:@"L"];}
@end
@interface AstroView (HUDOrderCheck)
- (void)checkHUDOrder;
@end
@implementation AstroView (HUDOrderCheck)
- (void)checkHUDOrder {
    [timer invalidate];timer=nil;[audio stop];hud=[[AstroObservedHUD alloc] initWithGame:game ui:ui];
    menuVisible=paused=gameOver=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;campaign.level=4;automatic=NO;
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));
    liveBeams=[NSMutableArray array];visualEffects=[NSMutableArray array];
    specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    playerHitVisual.active=0;engineGlow=departureTrail=NO;playerVisualDeleted=YES;
    AstroEnemy *e=[AstroEnemy new];e->kind=20;e->renderLayer=4;e->renderBirth=1;e->visual=(AstroVisual){60,10,20,16,17,1000};
    enemies=[NSMutableArray arrayWithObject:e];world=[NSMutableArray arrayWithObject:e];
    observing=YES;ui.frameInterval=1;
    for(int nested=0;nested<2;nested++){
        worldRenderTick=100;observedWallTick=200;events=[NSMutableString string];
        [self advanceWorldForWait:nested];
        assert([events isEqual:nested?@"WHPL":@"HWPL"]&&!nestedWorldRender);
    }
    events=[NSMutableString string];[self renderSpecialWorld];
    assert([events isEqual:@"HW"]&&!nestedWorldRender);[self presentSpecialFrame];assert([events isEqual:@"HWP"]);
    events=[NSMutableString string];drawInnerSpecial=YES;worldRenderTick=100;observedWallTick=200;
    [self advanceWorldForWait:YES];assert([events isEqual:@"HWPWHPL"]&&!nestedWorldRender);drawInnerSpecial=NO;
    observing=NO;
    puts("PASS actual host drawRect HUD/world/swap/LM: ordinary HWPL, WAIT/blink WHPL, nested special HW then deferred P");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroHUDOrderView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkHUDOrder];
}}
