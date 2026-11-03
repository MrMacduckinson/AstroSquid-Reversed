#define main astrosquid_application_main
#ifdef ASTRO_TIGER
#include "../src/tiger/preview.m"
#else
#include "../src/preview.m"
#endif
#undef main
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>
static BOOL rejectExitDraw,requireFirstFullscreen,firstLoadingSeen;
static NSDictionary *originalMode;
static unsigned char startup[16];static BOOL terminated;
@interface FullscreenView:AstroView
@end
@implementation FullscreenView
- (void)copyKeyMap:(unsigned char *)bytes {memcpy(bytes,startup,16);}
- (GLuint)texture:(NSInteger)identifier {
 if(requireFirstFullscreen&&identifier==40&&!spriteMapsPreloaded){assert(self.isGameFullscreen);assert([originalMode isEqual:(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID())]);firstLoadingSeen=YES;}
 return [super texture:identifier];
}
- (uint32_t)screenshotSeconds {return 123;}
- (void)drawRect:(NSRect)rect {assert(!rejectExitDraw);[super drawRect:rect];}
- (void)saveSettings {}
- (void)saveScores {}
- (void)terminateApplication {terminated=YES;}
@end
@implementation AstroView(FullscreenCheck)
- (void)checkGraphicsReleased {assert(!audio&&graphicsReleased&&!textures.count&&NSOpenGLContext.currentContext==nil);}
- (NSArray *)textureNames {return textures.allValues;}
- (void)stopProbeTimer {[timer invalidate];timer=nil;[audio stop];}
- (void)checkRequest:(BOOL)value {assert(fullscreenRequested==value);}
- (void)checkFontFrame {
    NSRect backing=[self convertRectToBacking:self.bounds];int w=backing.size.width,h=backing.size.height;
    unsigned char *first=malloc((size_t)w*h*4),*second=malloc((size_t)w*h*4);assert(first&&second);
    [[self openGLContext]makeCurrentContext];
    glBindTexture(GL_TEXTURE_2D,[self texture:50]);unsigned char *atlas=malloc(512*512*4);assert(atlas);
    glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,atlas);
    unsigned half=0;for(unsigned y=0;y<512;y++)for(unsigned x=0;x<512;x++){
        const unsigned char *p=atlas+(y*512+x)*4;if(p[3]==127)half++;
        if(y%32==31&&p[0]<=5&&p[1]<=5&&p[2]<=5&&p[3]<=5)assert(!(p[0]|p[1]|p[2]|p[3]));
    }assert(half);free(atlas);
    for(int pass=0;pass<2;pass++){
        glViewport(0,0,w,h);glClear(GL_COLOR_BUFFER_BIT);glDisable(GL_DEPTH_TEST);
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);
        glMatrixMode(GL_MODELVIEW);glLoadIdentity();glColor4f(1,1,1,1);
        [ui drawText:@"AstroSquid: Original font 0123456789" x:24 baseline:160 size:16 texture:^GLuint(NSInteger n){return [self texture:n];}];
        [ui drawText:@"Game Paused" x:24 baseline:220 size:32 texture:^GLuint(NSInteger n){return [self texture:n];}];
        [ui drawText:@"Fullscreen / Window" x:24 baseline:270 size:20 texture:^GLuint(NSInteger n){return [self texture:n];}];
        glReadBuffer(GL_BACK);glPixelStorei(GL_PACK_ALIGNMENT,1);glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,pass?second:first);assert(glGetError()==GL_NO_ERROR);
    }
    assert(!memcmp(first,second,(size_t)w*h*4));
    unsigned lit=0;for(size_t i=0;i<(size_t)w*h;i++)if(first[i*4])lit++;assert(lit>1000);
    const char *path=getenv("ASTRO_FONT_CAPTURE");if(path){
        NSBitmapImageRep *rep=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:w*4 bitsPerPixel:32];
        for(int y=0;y<h;y++)memcpy(rep.bitmapData+(size_t)y*w*4,first+(size_t)(h-1-y)*w*4,w*4);
        assert([[rep representationUsingType:NSPNGFileType properties:@{}]writeToFile:[NSString stringWithUTF8String:path]atomically:YES]);
        presentationRelease(rep);
    }
    free(first);free(second);printf("PASS stable original-font framebuffer %dx%d, unchanged repeated frame\n",w,h);
}
- (void)checkFullscreenPicture:(const unsigned char *)bottomUp width:(unsigned)width height:(unsigned)height {
 char directory[]="/tmp/astrosquid-fullscreen-shot.XXXXXX";assert(mkdtemp(directory));screenshotBase=[NSString stringWithUTF8String:directory];
 unsigned char *rgba=malloc(640*480*4),*expected=NULL;size_t size=0;assert(rgba);
 for(unsigned y=0;y<480;y++)for(unsigned x=0;x<640;x++)memcpy(rgba+(y*640+x)*4,bottomUp+((size_t)(height-1-y*height/480)*width+x*width/640)*4,4);
 assert(astro_picture_fullscreen_encode(rgba,640*4,640,480,&expected,&size));free(rgba);
 glReadBuffer(GL_BACK);glPixelStorei(GL_PACK_ALIGNMENT,8);[NSOpenGLContext clearCurrentContext];assert([self saveScreenshot]);assert(NSOpenGLContext.currentContext==nil);[[self openGLContext] makeCurrentContext];
 GLint read,pack;glGetIntegerv(GL_READ_BUFFER,&read);glGetIntegerv(GL_PACK_ALIGNMENT,&pack);assert(read==GL_BACK&&pack==8);glReadBuffer(GL_FRONT);glPixelStorei(GL_PACK_ALIGNMENT,4);
 NSData *data=[NSData dataWithContentsOfFile:[screenshotBase stringByAppendingPathComponent:@"Screenshots/Screen 123.pict"]];assert(data.length==512+size);const unsigned char *bytes=data.bytes;for(unsigned i=0;i<512;i++)assert(!bytes[i]);assert(!memcmp(bytes+512,expected,size));free(expected);
 assert([NSFileManager.defaultManager removeItemAtPath:screenshotBase error:NULL]);
 puts("PASS actual fullscreen PICT RGBA/row order/native format, fileprefix and GL context/readbuffer/alignment restoration");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==2||argc==3);
 assert(NSEqualRects(presentationFrame(NSMakeSize(1920,1080)),NSMakeRect(240,0,1440,1080)));
 assert(NSEqualRects(presentationFrame(NSMakeSize(640,480)),NSMakeRect(0,0,640,480)));setvbuf(stdout,NULL,_IONBF,0);
 if(argc==2){
  for(unsigned phase=0;phase<2;phase++){
  NSDictionary *before=[(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID()) copy];pid_t pid=fork();assert(pid>=0);if(!pid){execl(argv[0],argv[0],argv[1],phase?"--exit-child":"--child",NULL);_exit(2);}
  int status=0;BOOL done=NO;for(unsigned i=0;i<300;i++){if(waitpid(pid,&status,WNOHANG)==pid){done=YES;break;}usleep(100000);}
  if(!done){kill(pid,SIGKILL);waitpid(pid,&status,0);}
  BOOL same=[before isEqual:(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID())];
  printf("parent phase%u done%d exit%d native_restore%d\n",phase,done,WIFEXITED(status)?WEXITSTATUS(status):-1,same);if(!done||!WIFEXITED(status)||WEXITSTATUS(status)||!same)return 3;
  }return 0;
 }
 originalMode=[(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID()) copy];
 alarm(25);atexit(restoreFullscreen);[AstroApplication sharedApplication];ProcessSerialNumber psn={0,kCurrentProcess};TransformProcessType(&psn,kProcessTransformToForegroundApplication);
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 NSString *assets=[NSString stringWithUTF8String:argv[1]];
 FullscreenView *view=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(view);[(AstroApplication *)NSApp setGameView:view];[view stopProbeTimer];[view checkRequest:YES];
 AstroDelegate *delegate=[AstroDelegate new];delegate.view=view;
 NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,480) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];window.releasedWhenClosed=NO;window.contentView=view;delegate.window=window;requireFirstFullscreen=YES;[delegate presentGameWindow];
 for(unsigned i=0;i<20&&!firstLoadingSeen;i++)[[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.05]];
 assert(firstLoadingSeen&&view.isGameFullscreen&&[originalMode isEqual:(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID())]&&![window isVisible]);requireFirstFullscreen=NO;[view display];
 [[view openGLContext] makeCurrentContext];GLfloat clear[4];glGetFloatv(GL_COLOR_CLEAR_VALUE,clear);assert(!clear[0]&&!clear[1]&&!clear[2]&&!clear[3]);NSRect backing=[view convertRectToBacking:view.bounds];unsigned width=backing.size.width,height=backing.size.height;assert(abs((int)(width*3)-(int)(height*4))<=4);unsigned char *rgb=malloc(width*height*4);assert(rgb);glReadBuffer(GL_FRONT);glReadPixels(0,0,width,height,GL_RGBA,GL_UNSIGNED_BYTE,rgb);unsigned lit=0;for(unsigned i=0;i<width*height;i++)if(rgb[i*4]||rgb[i*4+1]||rgb[i*4+2])lit++;assert(glGetError()==GL_NO_ERROR&&lit>1000);[view checkFullscreenPicture:rgb width:width height:height];free(rgb);
 if(!strcmp(argv[2],"--exit-child")){puts("direct_exit_requested_after_actual_fullscreen_render");rejectExitDraw=YES;exit(0);}
 [view checkFontFrame];
 NSEvent *toggle=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:NSCommandKeyMask|NSControlKeyMask timestamp:0 windowNumber:fullscreenWindow.windowNumber context:nil characters:@"f" charactersIgnoringModifiers:@"f" isARepeat:NO keyCode:3];
 assert(presentationShortcut(toggle));[NSApp sendEvent:toggle];assert(!view.isGameFullscreen&&window.contentView==view&&[window isVisible]&&NSEqualSizes(view.bounds.size,NSMakeSize(640,480)));
 [NSApp sendEvent:toggle];assert(view.isGameFullscreen&&fullscreenWindow.firstResponder==view);
 NSArray *names=[view textureNames];assert(names.count);NSOpenGLContext *oldContext=view.openGLContext;
 assert([delegate applicationShouldTerminate:NSApp]==NSTerminateCancel);[view closeDown];[view checkGraphicsReleased];[view drawRect:view.bounds];[view checkGraphicsReleased];
 [oldContext makeCurrentContext];for(NSNumber *name in names)assert(!glIsTexture(name.unsignedIntValue));[NSOpenGLContext clearCurrentContext];assert(terminated&&!view.isGameFullscreen&&[delegate applicationShouldTerminate:NSApp]==NSTerminateNow);
 startup[58>>3]=1u<<(58&7);FullscreenView *option=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(option);[option stopProbeTimer];[option checkRequest:NO];delegate.view=option;window.contentView=option;[delegate presentGameWindow];assert([window isVisible]&&!option.isGameFullscreen);[option releaseGraphics];[window orderOut:nil];
 memset(startup,0,16);startup[61>>3]=1u<<(61&7);FullscreenView *right=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(right);[right stopProbeTimer];[right checkRequest:YES];
 assert(!enterFullscreen(right));[right releaseGraphics];
 [window close];printf("PASS actual fullscreen game rendering lit%u, native-mode/default/leftOption/rightOption/toggle/firstResponder/no-window fallback, delegate quit after view move, closeDown restoration\n",lit);return 0;
}}
