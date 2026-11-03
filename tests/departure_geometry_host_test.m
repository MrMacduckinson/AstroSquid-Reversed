// ENDOFLEVEL1004eda0 keeps player and trail centers aligned after LMCHANGESPRITEID15.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static uint32_t fakeTick;
static unsigned checkedFrames;
@interface DepartureView:AstroView
@end
@implementation DepartureView
- (uint32_t)playerClockTick{return fakeTick++;}
- (void)pollNestedWorld {}
- (void)readGameKeys {}
- (void)blowTransitionEnemies {}
- (void)checkGeometry {
    double renderedX=playerX+playerVisual.width/2,renderedY=playerY+playerVisual.height/2;
    double glowX=departureGlow.x-camera+departureGlow.width/2,glowY=departureGlow.y+departureGlow.height/2;
    // Original glow's x offset is intentional; vertical centers must coincide.
    if(renderedX!=252.5||renderedY!=184||glowX!=232.5||glowY!=184||trailRect.y+trailRect.height/2!=184){
        fprintf(stderr,"FAIL player center %.2f,%.2f; original center 252.50,184.00; glow %.2f,%.2f\n",renderedX,renderedY,glowX,glowY);exit(1);
    }
    checkedFrames++;
}
- (void)renderTick {[self checkGeometry];astro_transition_render_trail(&transition);}
- (void)checkAssets:(NSString *)assets {
    NSDictionary *data=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[assets stringByAppendingPathComponent:@"game.json"]] options:0 error:NULL];assert(data);
    for(NSString *key in data[@"sprites"]){NSDictionary *s=data[@"sprites"][key];int i=key.intValue;if(i<1001)spriteInfo[i]=(AstroSpriteInfo){[s[@"width"]intValue],[s[@"height"]intValue],0,0};}
    assert(spriteInfo[12].width==65&&spriteInfo[12].height==28&&spriteInfo[15].width==78&&spriteInfo[15].height==20);
    for(unsigned route=0;route<2;route++){
        fakeTick=0;playerVisual=(AstroVisual){12,320,170,65,28,0};playerX=220;playerY=170;camera=100;
        playerBounds=(AstroRect){320,170,385,198};worldLeft=32.5;worldRight=672.5;worldTop=-6;worldBottom=374;
        transition=(AstroTransition){.phase=ASTRO_TRANSITION_CRUISE,.scale=1};simulationTick=0;
        if(route==0){[self stepStageTransition];[self checkGeometry];}
        else [self runEndlevelTransition];
    }
    printf("PASS both departure paths: %u render frames retain original player/glow/trail centers after sprite12->15\n",checkedFrames);
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);alarm(10);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    DepartureView *view=[[DepartureView alloc]initWithFrame:NSZeroRect];[view checkAssets:[NSString stringWithUTF8String:argv[1]]];
}}
