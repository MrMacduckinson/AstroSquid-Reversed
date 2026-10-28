// Actual drawRect panel projection; runtime only on the authorized Intel Mac.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static BOOL observing;
static unsigned scale=1,frames;
@interface PanelProjectionUI:AstroUIRenderer
@end
@implementation PanelProjectionUI
- (void)drawSprites:(AstroUISpriteDrawer)draw texture:(AstroUITextureLoader)texture {
    GLint viewport[4];GLdouble projection[16],modelview[16];
    glGetIntegerv(GL_VIEWPORT,viewport);glGetDoublev(GL_PROJECTION_MATRIX,projection);glGetDoublev(GL_MODELVIEW_MATRIX,modelview);
    if(!frames)fprintf(stderr,"panel viewport%d/%d/%d/%d projectionY%.17g modelviewY%.17g\n",viewport[0],viewport[1],viewport[2],viewport[3],projection[5],modelview[13]);
    assert(viewport[0]==0&&viewport[1]==30*(int)scale&&viewport[2]==640*(int)scale&&viewport[3]==380*(int)scale);
    for(unsigned i=0;i<16;i++){
        double expected=i==0?2./640:i==5?-2./379:i==10?-1:i==12?-1:i==13?1:i==15?1:0;
        assert(fabs(projection[i]-expected)<1e-8);
        expected=i==0||i==5||i==10||i==15?1:i==13?-70:0;
        assert(modelview[i]==expected);
    }
    GLenum error=glGetError();if(error)fprintf(stderr,"panel GLerror%x\n",error);assert(error==GL_NO_ERROR);frames++;
}
@end
@interface PanelProjectionView:AstroView
@end
@implementation PanelProjectionView
- (void)display {
    if(!observing){[super display];return;}[self drawRect:self.bounds];
    GLdouble modelview[16];glGetDoublev(GL_MODELVIEW_MATRIX,modelview);assert(modelview[13]==0);
}
- (void)sprite:(NSInteger)n x:(double)x y:(double)y width:(double)w height:(double)h {if(!observing)[super sprite:n x:x y:y width:w height:h];}
- (void)presentFrame {if(!observing)[super presentFrame];}
- (NSRect)convertRectToBacking:(NSRect)rect {if(observing)return NSMakeRect(0,0,640*scale,480*scale);return [super convertRectToBacking:rect];}
@end
@interface AstroView (PanelProjectionCheck)
- (void)checkPanelProjection;
@end
@implementation AstroView (PanelProjectionCheck)
- (void)checkPanelProjection {
    [timer invalidate];timer=nil;[audio stop];spriteMapsPreloaded=YES;menuVisible=YES;flow.phase=ASTRO_FLOW_PLAY;campaign.level=4;
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));
    enemies=[NSMutableArray array];world=[NSMutableArray array];visualEffects=[NSMutableArray array];
    specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];playerVisualDeleted=YES;playerHitVisual.active=NO;engineGlow=departureTrail=NO;
    ui=[[PanelProjectionUI alloc]initWithAssets:assetPath error:NULL];assert(ui);[[self openGLContext]makeCurrentContext];while(glGetError()!=GL_NO_ERROR){}
    GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);
    glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,1280,960,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);
    assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);observing=YES;
    for(scale=1;scale<=2;scale++)for(NSString *panel in @[@"Pause",@"GameOver"]){
        [ui show:panel];frames=0;[self drawPanelTransition];assert(frames==([panel isEqual:@"Pause"]?30u:60u));
        unsigned transitionFrames=frames;[self display];[self display];assert(frames==transitionFrames+2);
        printf("PASS actual %s %ux projection, %u transition and2steady frames\n",panel.UTF8String,scale,transitionFrames);
    }
    observing=NO;glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[PanelProjectionView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkPanelProjection];
}}
