#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
@interface NoticeView:AstroView
- (void)checkNotice;
@end
@implementation NoticeView
- (unsigned)litPixels {
    NSRect r=[self convertRectToBacking:self.bounds];unsigned w=r.size.width,h=r.size.height;
    unsigned char *pixels=malloc(w*h*4);assert(pixels);glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
    unsigned lit=0;for(unsigned n=0;n<w*h;n++)if(pixels[n*4]||pixels[n*4+1]||pixels[n*4+2])lit++;
    free(pixels);return lit;
}
- (void)checkNotice {
    [timer invalidate];timer=nil;[[self openGLContext]makeCurrentContext];
    GLuint frame,tex;glGenFramebuffersEXT(1,&frame);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,frame);
    glGenTextures(1,&tex);glBindTexture(GL_TEXTURE_2D,tex);NSRect backing=[self convertRectToBacking:self.bounds];glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,backing.size.width,backing.size.height,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,tex,0);
    assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);
    [self texture:50];menuVisible=paused=gameOver=NO;flow.phase=ASTRO_FLOW_PLAY;
    cheats.weapons=1;cheatNoticeUntil=NSProcessInfo.processInfo.systemUptime+3;
    glLineWidth(3);glViewport(7,9,320,240);glMatrixMode(GL_MODELVIEW);glLoadIdentity();glTranslated(11,12,0);
    glClearColor(0,0,0,0);glClear(GL_COLOR_BUFFER_BIT);[self drawCheatNotice];
    assert([self litPixels]>500);
    GLfloat lineWidth;glGetFloatv(GL_LINE_WIDTH,&lineWidth);assert(lineWidth==3);
    double before=[ui textWidth:@"WEAPONS ENABLED " size:16],after=[ui textWidth:@" SELECT 1-4" size:16];
    double dashX=320-(before+16+after)/2+before,scale=backing.size.width/640;
    unsigned char dash[128*8*4];unsigned width=16*scale;assert(width<=128);
    glReadPixels((GLint)(dashX*scale),(GLint)((480-94)*scale)-4,width,8,GL_RGBA,GL_UNSIGNED_BYTE,dash);
    unsigned yellow=0;for(unsigned n=0;n<width*8;n++)if(dash[n*4]>200&&dash[n*4+1]>200&&dash[n*4+2]<150)yellow++;
    assert(yellow>=width-2);GLint viewport[4],mode;GLdouble matrix[16];
    glGetIntegerv(GL_VIEWPORT,viewport);glGetIntegerv(GL_MATRIX_MODE,&mode);glGetDoublev(GL_MODELVIEW_MATRIX,matrix);
    assert(viewport[0]==7&&viewport[1]==9&&viewport[2]==320&&viewport[3]==240&&mode==GL_MODELVIEW&&matrix[12]==11&&matrix[13]==12);
    cheatNoticeUntil=0;glClear(GL_COLOR_BUFFER_BIT);[self drawCheatNotice];assert(![self litPixels]);
    cheatNoticeUntil=NSProcessInfo.processInfo.systemUptime+3;menuVisible=YES;[self drawCheatNotice];assert(![self litPixels]);
    assert(glGetError()==GL_NO_ERROR);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&frame);glDeleteTextures(1,&tex);
    puts("PASS real font notice pixels, expiry, menu exclusion and GL viewport/matrix restoration");
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    NoticeView *v=[[NoticeView alloc]initWithFrame:NSMakeRect(0,0,640,480)assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v checkNotice];
}}
