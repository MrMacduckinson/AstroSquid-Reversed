#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL held;
static unsigned actions;
@interface ReturnMouseView:AstroView
- (void)checkReturnMouse;
@end
@implementation ReturnMouseView
- (void)display {}
- (void)flushGameEvents {}
- (void)setGameCursorHidden:(BOOL)hidden {}
- (BOOL)menuMouseButtonPressed {return held;}
- (NSPoint)currentMenuMousePoint {return NSMakePoint(-10000,-10000);}
- (void)performMenuAction:(NSString *)name {if([name isEqual:@"New Game"])actions++;}
- (void)checkReturnMouse {
    [timer invalidate];timer=nil;[audio stop];audio=nil;
    for(unsigned record=0;record<2;record++){
        gameLoopActive=YES;gameEndRequested=YES;gameEndHighscores=record;
        quitRequested=NO;respawnTick=invulnerableUntil=0;changingStage=NO;
        flow.phase=ASTRO_FLOW_PLAY;menuVisible=paused=gameOver=NO;
        pauseLoopRunning=specialLoopRunning=NO;actorTraversalDepth=0;
        menuMouseLatched=NO;held=YES;actions=0;
        [self completeGameLoopIfRequested];
        assert(!gameLoopActive&&!gameEndRequested&&menuVisible);
        [self handleMenuAction:@"New Game" atPoint:NSMakePoint(-10000,-10000)];
        assert(actions==0);
        held=NO;[self pollMenuMouse];
        assert(!menuMouseLatched);
        held=YES;[self handleMenuAction:@"New Game" atPoint:NSMakePoint(-10000,-10000)];
        assert(actions==1);
    }
    puts("PASS both game returns suppress held click until release and accept a new press");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    ReturnMouseView *view=[[ReturnMouseView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkReturnMouse];
}}
