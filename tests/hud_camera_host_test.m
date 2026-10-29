// Intel only. Actual HUD boundary and CALC; drawing is observed through a nil renderer.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
@interface AstroView (HUDCameraCheck)
- (void)checkHUDCamera;
@end
@implementation AstroView (HUDCameraCheck)
- (void)checkHUDCamera {
    [timer invalidate];timer=nil;[audio stop];hud=nil;
    world=[NSMutableArray array];enemies=[NSMutableArray array];backgrounds=@[];
    visualEffects=[NSMutableArray array];parallaxData=[NSMutableData data];
    specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    for(int i=0;i<4;i++){
        camera=i&1?-1234.25:1234.75;worldLeft=camera;worldRight=camera+640;
        worldTop=70;worldBottom=450;tickedScroll=.375;hudRedraws=1;
        double before=camera,left=worldLeft,right=worldRight;
        [self drawHUD:NO];assert(camera==before&&hudRedraws==1);
        [self drawHUD:YES];assert(camera==-(double)astro_ppc_i32(-before)&&!hudRedraws);
        assert(worldLeft==left&&worldRight==right&&worldTop==70&&worldBottom==450);
        double truncated=camera;[self drawHUD:YES];assert(camera==truncated);
        [self calculateActors];assert(camera==astro_camera_advance(truncated,.375));
        assert(worldLeft==camera&&worldRight==camera+640&&worldTop==0&&signbit(worldTop)&&worldBottom==380);
    }
    puts("PASS HUD truncates render camera only; cached viewport survives until actual CALC; repaint and zero-count HUD preserve state");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkHUDCamera];
}}
