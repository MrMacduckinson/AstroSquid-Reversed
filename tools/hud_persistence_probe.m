// Diagnostic only: actual host HUD pixels before/after an omitted HUD draw.
// Run on Intel iMac, never on the primary Mac. Produces counts, no screenshots.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include <OpenGL/glext.h>
static BOOL paintHUD=YES;
@interface AstroProbeHUD : AstroHUDRenderer
@end
@implementation AstroProbeHUD
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)width height:(GLsizei)height {
    if(paintHUD)[super drawState:state texture:texture framebufferWidth:width height:height];
}
@end
@interface AstroView (HUDPersistenceProbe)
- (int)probeHUDPersistence;
@end
@implementation AstroView (HUDPersistenceProbe)
- (int)probeHUDPersistence {
    [timer invalidate];timer=nil;[audio stop];[[self openGLContext] makeCurrentContext];
    while(glGetError()!=GL_NO_ERROR){}
    GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);
    glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);
    if(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)!=GL_FRAMEBUFFER_COMPLETE_EXT){puts("UNAVAILABLE framebuffer");return 3;}
    glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);
    hud=[[AstroProbeHUD alloc] initWithGame:game ui:ui];
    menuVisible=paused=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;campaign.level=4;
    enemies=[NSMutableArray array];world=[NSMutableArray array];backgrounds=@[];parallaxData=[NSMutableData data];
    liveBeams=[NSMutableArray array];presentedBeams=@[];visualEffects=[NSMutableArray array];
    specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    playerHitVisual.active=0;engineGlow=departureTrail=NO;memset(stars,0,sizeof(stars));
    deferPresent=YES;simulationRender=YES;
    unsigned counts[2]={0};unsigned char *pixels=malloc(640*70*4);assert(pixels);
    for(int frame=0;frame<2;frame++){
        paintHUD=frame==0;[self drawRect:self.bounds];glFinish();
        glReadPixels(0,410,640,70,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
        GLenum error=glGetError();if(error){printf("UNAVAILABLE GL error %u\n",error);free(pixels);return 3;}
        for(unsigned i=0;i<640*70;i++)if(pixels[i*4]>10||pixels[i*4+1]>10||pixels[i*4+2]>10)counts[frame]++;
    }
    free(pixels);glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);
    if(!counts[0]){puts("UNAVAILABLE initial HUD pixels");return 3;}
    printf("MEASURED actual host HUD bright pixels: first=%u omitted_next=%u retained=%s\n",counts[0],counts[1],counts[0]==counts[1]?"yes":"no");
    return 0;
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroView *view=[[AstroView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,480) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    window.contentView=view;[[view openGLContext] update];return [view probeHUDPersistence];
}}
