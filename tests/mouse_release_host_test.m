// Actual root latch: raw release does not reset it; an eligible released poll does.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSPoint point;
static BOOL held;
static unsigned clicks;
@interface ReleaseAudio:AstroAudio
@end
@implementation ReleaseAudio
- (BOOL)playCue:(NSString *)name position:(double)position {clicks++;return YES;}
- (void)stop {}
- (void)serviceMusic {}
@end
@interface ReleaseView:AstroView
- (void)checkRelease;
@end
@implementation ReleaseView
- (NSPoint)menuPoint:(NSEvent *)event {return point;}
- (void)display {}
- (void)presentFrame {}
- (uint32_t)currentGameTick {return 1000;}
- (void)copyKeyMap:(unsigned char *)bytes {memset(bytes,0,16);}
- (BOOL)menuMouseButtonPressed {return held;}
- (void)saveScores {}
- (void)checkRelease {
    [timer invalidate];timer=nil;[audio stop];audio=[ReleaseAudio new];
    splashVisible=NO;editingKey=-1;score=0;menuVisible=gameOver=YES;gameEndRequested=NO;
    [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=0;
    held=YES;point=NSMakePoint(-1,100);[self mouseDown:nil];assert(!gameEndRequested);
    point=NSMakePoint(400,320);[self mouseDragged:nil];assert(!gameEndRequested);
    held=NO;[self mouseUp:nil];held=YES;[self mouseDown:nil];
    assert(!gameEndRequested&&menuMouseLatched&&!clicks);
    held=NO;[self mouseUp:nil];observedWallTick=1000;[self pollMenu];
    assert(menuMouseLatched&&!gameEndRequested); // Closed gate cannot release the latch.
    held=YES;[self mouseDown:nil];assert(!gameEndRequested&&!clicks);
    held=NO;[self mouseUp:nil];observedWallTick=999;[self pollMenu];
    assert(!menuMouseLatched&&!gameEndRequested);
    held=YES;[self mouseDown:nil];assert(gameEndRequested&&!gameOver&&!menuVisible&&clicks==1);
    [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=1;
    menuVisible=gameOver=YES;gameEndRequested=NO;menuMouseLatched=YES;
    astro_score_editor_begin(&scoreEditor);scoreEditor.cursor=77;[self refreshScoreEditor];
    point=NSMakePoint(225,260);[self mouseDown:nil];
    assert(scoreEditor.cursor==0&&ui.editingCursor==0&&menuMouseLatched&&!gameEndRequested&&clicks==1);
    puts("PASS actual root mouse latch: rapid repress/closed gate suppressed, eligible released poll rearms, latched field selection retained");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    ReleaseView *view=[[ReleaseView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkRelease];
}}
