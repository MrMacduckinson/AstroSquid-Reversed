// Authorized Intel only: actual drawRect, two retained FBOs and window swaps.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static unsigned hudDraws;
static BOOL swapping;
@interface RetentionHUD:AstroHUDRenderer
@end
@implementation RetentionHUD
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)width height:(GLsizei)height {
    hudDraws++;
    glDisable(GL_TEXTURE_2D);glDisable(GL_BLEND);glViewport(0,0,width,height);
    glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
    glColor4d(1,0,0,1);glBegin(GL_QUADS);
    glVertex2d(0,0);glVertex2d(640,0);glVertex2d(640,70);glVertex2d(0,70);
    glVertex2d(0,450);glVertex2d(640,450);glVertex2d(640,480);glVertex2d(0,480);glEnd();
    glViewport(0,height*30/480,width,height*380/480);
    glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,379,0,-1,1);glMatrixMode(GL_MODELVIEW);
}
@end
@interface RetentionView:AstroView
- (void)checkRetention;
@end
@implementation RetentionView
- (void)presentFrame {if(swapping)[[self openGLContext] flushBuffer];}
- (void)checkRetention {
    [timer invalidate];timer=nil;[audio stop];spriteMapsPreloaded=YES;
    menuVisible=paused=gameOver=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;campaign.level=1;
    hud=[[RetentionHUD alloc]initWithGame:game ui:ui];
    world=[NSMutableArray array];enemies=[NSMutableArray array];visualEffects=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));
    specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    playerHitVisual.active=0;engineGlow=departureTrail=NO;playerVisualDeleted=YES;
    NSWindow *window=[[NSWindow alloc]initWithContentRect:NSMakeRect(40,40,640,480) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    window.contentView=self;[window orderFrontRegardless];
    [self lockFocus];[[self openGLContext] update];[self unlockFocus];[[self openGLContext] makeCurrentContext];
    assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    NSRect backing=[self convertRectToBacking:self.bounds];GLsizei fw=backing.size.width,fh=backing.size.height;
    GLuint buffers[2],colors[2];glGenFramebuffersEXT(2,buffers);glGenTextures(2,colors);
    for(int i=0;i<2;i++){
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,buffers[i]);glBindTexture(GL_TEXTURE_2D,colors[i]);
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,fw,fh,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,colors[i],0);
        assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
        glClearColor(0,1,0,1);glClear(GL_COLOR_BUFFER_BIT);
    }
    hudRedraws=2;hudDraws=0;
    for(int frame=0;frame<8;frame++){
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,buffers[frame%2]);[self drawRect:self.bounds];
        unsigned char top[4],bottom[4],middle[4];
        glReadPixels(10*fw/640,470*fh/480,1,1,GL_RGBA,GL_UNSIGNED_BYTE,top);
        glReadPixels(10*fw/640,10*fh/480,1,1,GL_RGBA,GL_UNSIGNED_BYTE,bottom);
        glReadPixels(10*fw/640,200*fh/480,1,1,GL_RGBA,GL_UNSIGNED_BYTE,middle);
        assert(top[0]==255&&!top[1]&&!top[2]&&bottom[0]==255&&!bottom[1]&&!bottom[2]);
        assert(!middle[0]&&!middle[1]&&!middle[2]&&hudDraws==(unsigned)(frame?2:1));
        assert(hudRedraws==(frame?0:1)&&glGetError()==GL_NO_ERROR);
    }
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(2,buffers);glDeleteTextures(2,colors);

    GLint interval=0;[[self openGLContext] setValues:&interval forParameter:NSOpenGLCPSwapInterval];
    backing=[self convertRectToBacking:self.bounds];fw=backing.size.width;fh=backing.size.height;
    swapping=YES;hudRedraws=2;hudDraws=0;
    for(int frame=0;frame<8;frame++){
        [self drawRect:self.bounds];glReadBuffer(GL_FRONT);unsigned char pixel[4];
        glReadPixels(10*fw/640,470*fh/480,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel);glReadBuffer(GL_BACK);
        assert(pixel[0]==255&&!pixel[1]&&!pixel[2]&&hudDraws==(unsigned)(frame?2:1));
        assert(hudRedraws==(frame?0:1)&&glGetError()==GL_NO_ERROR);
    }
    swapping=NO;[window orderOut:nil];window.contentView=nil;
    puts("PASS HUD exactly twice, retained across8 alternating FBO frames and8 actual window swaps; world clears by original black quad");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);alarm(30);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    RetentionView *view=[[RetentionView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkRetention];
}}
