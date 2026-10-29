// Intel only: production HUD callback; replace only GL drawing with command traversal.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned clockReads,sprites;
@interface HUDClockView:AstroView
@end
@implementation HUDClockView
- (uint32_t)playerClockTick {return 100+clockReads++;}
@end
@interface HUDClockRenderer:AstroHUDRenderer
@end
@implementation HUDClockRenderer
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)width height:(GLsizei)height {
    AstroHUDCommand c[32];size_t count=astro_hud_commands(state,c,32);
    for(size_t i=0;i<count;i++)if(c[i].kind==ASTRO_HUD_SPRITE){
        unsigned before=clockReads;self.didDrawSprite(c[i].sprite,c[i].x,c[i].y,c[i].width,c[i].height);
        assert(clockReads==before||clockReads==before+1);sprites++;
    }
}
@end
@implementation AstroView(HUDClockCheck)
- (void)checkHUDClocks {
    [timer invalidate];timer=nil;[audio stop];
    HUDClockRenderer *observer=[[HUDClockRenderer alloc]initWithGame:game ui:ui];observer.didDrawSprite=hud.didDrawSprite;hud=observer;
    for(unsigned mode=0;mode<4;mode++)for(unsigned consume=0;consume<2;consume++){
        simulationRender=mode==1;panelTransitionRender=mode==2;hudClockActive=mode==3;
        clockReads=sprites=0;hudRedraws=1;uint64_t birth=renderClock;
        [self drawHUD:consume];assert(sprites==17&&clockReads==(mode?17:0));
        assert(renderClock==birth+(mode?17:0)&&hudRedraws==1-consume);
        if(consume){[self drawHUD:YES];assert(sprites==17&&clockReads==(mode?17:0));}
    }
    simulationRender=panelTransitionRender=hudClockActive=NO;
    puts("PASS actual HUD callback:17 individual clocks/births on simulation, panel transition, overlay; zero on repaint and closed HUD gate");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    HUDClockView *view=[[HUDClockView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkHUDClocks];
}}
