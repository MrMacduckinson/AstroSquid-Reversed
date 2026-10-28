#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>
static BOOL rejectExitDraw;
static unsigned char startup[16];static BOOL terminated,checkMusicShutdown;
@interface FullscreenView:AstroView
@end
@implementation FullscreenView
- (void)copyKeyMap:(unsigned char *)bytes {memcpy(bytes,startup,16);}
- (uint32_t)screenshotSeconds {return 123;}
- (void)destroyGameWorld {if(checkMusicShutdown)assert(audio.music&&audio.music.isPlaying);[super destroyGameWorld];}
- (void)drawRect:(NSRect)rect {assert(!rejectExitDraw);[super drawRect:rect];}
- (void)saveSettings {}
- (void)saveScores {}
- (void)terminateApplication {terminated=YES;}
@end
@interface UnavailableFullscreenView:FullscreenView
@end
@implementation UnavailableFullscreenView
- (BOOL)enterFullScreenMode:(NSScreen *)screen withOptions:(NSDictionary *)options {(void)screen;(void)options;return NO;}
@end
@implementation AstroView(FullscreenCheck)
- (void)checkGraphicsReleased {assert(!audio&&graphicsReleased&&!textures.count&&NSOpenGLContext.currentContext==nil);}
- (void)startShutdownMusic {assert([audio playMusic:1]);}
- (NSArray *)textureNames {return textures.allValues;}
- (void)stopProbeTimer {[timer invalidate];timer=nil;[audio stop];}
- (void)checkRequest:(BOOL)value {assert(fullscreenRequested==value);}
- (void)checkFullscreenPicture:(const unsigned char *)bottomUp {
 char directory[]="/tmp/astrosquid-fullscreen-shot.XXXXXX";assert(mkdtemp(directory));screenshotBase=[NSString stringWithUTF8String:directory];
 unsigned char *rgba=malloc(640*480*4),*expected=NULL;size_t size=0;assert(rgba);
 for(unsigned y=0;y<480;y++)memcpy(rgba+y*640*4,bottomUp+(479-y)*640*4,640*4);
 assert(astro_picture_fullscreen_encode(rgba,640*4,640,480,&expected,&size));free(rgba);
 glReadBuffer(GL_BACK);glPixelStorei(GL_PACK_ALIGNMENT,8);[NSOpenGLContext clearCurrentContext];assert([self saveScreenshot]);assert(NSOpenGLContext.currentContext==nil);[[self openGLContext] makeCurrentContext];
 GLint read,pack;glGetIntegerv(GL_READ_BUFFER,&read);glGetIntegerv(GL_PACK_ALIGNMENT,&pack);assert(read==GL_BACK&&pack==8);glReadBuffer(GL_FRONT);glPixelStorei(GL_PACK_ALIGNMENT,4);
 NSData *data=[NSData dataWithContentsOfFile:[screenshotBase stringByAppendingPathComponent:@"Screenshots/Screen 123.pict"]];assert(data.length==512+size);const unsigned char *bytes=data.bytes;for(unsigned i=0;i<512;i++)assert(!bytes[i]);assert(!memcmp(bytes+512,expected,size));free(expected);
 assert([NSFileManager.defaultManager removeItemAtPath:screenshotBase error:NULL]);
 puts("PASS actual fullscreen PICT RGBA/row order/native format, fileprefix and GL context/readbuffer/alignment restoration");
}
@end
static BOOL modeSize(int width,int height){NSDictionary *m=(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID());return [m[(__bridge NSString *)kCGDisplayWidth] intValue]==width&&[m[(__bridge NSString *)kCGDisplayHeight] intValue]==height;}
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==2||argc==3);setvbuf(stdout,NULL,_IONBF,0);
 if(argc==2){
  for(unsigned phase=0;phase<2;phase++){
  NSDictionary *before=[(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID()) copy];pid_t pid=fork();assert(pid>=0);if(!pid){execl(argv[0],argv[0],argv[1],phase?"--exit-child":"--child",NULL);_exit(2);}
  int status=0;BOOL done=NO;for(unsigned i=0;i<300;i++){if(waitpid(pid,&status,WNOHANG)==pid){done=YES;break;}usleep(100000);}
  if(!done){kill(pid,SIGKILL);waitpid(pid,&status,0);}
  BOOL same=[before isEqual:(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID())];if(!same)CGDisplaySwitchToMode(CGMainDisplayID(),(__bridge CFDictionaryRef)before);
  printf("parent phase%u done%d exit%d native_restore%d\n",phase,done,WIFEXITED(status)?WEXITSTATUS(status):-1,same);if(!done||!WIFEXITED(status)||WEXITSTATUS(status)||!same)return 3;
  }return 0;
 }
 alarm(25);atexit(restoreFullscreen);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 NSString *assets=[NSString stringWithUTF8String:argv[1]];
 FullscreenView *view=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(view);[view stopProbeTimer];[view checkRequest:YES];
 AstroDelegate *delegate=[AstroDelegate new];delegate.view=view;
 NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,480) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];window.releasedWhenClosed=NO;window.contentView=view;delegate.window=window;[window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
 assert([view startFullscreen]&&view.inFullScreenMode&&modeSize(640,480));[view display];
 [[view openGLContext] makeCurrentContext];GLfloat clear[4];glGetFloatv(GL_COLOR_CLEAR_VALUE,clear);assert(!clear[0]&&!clear[1]&&!clear[2]&&!clear[3]);unsigned char *rgb=malloc(640*480*4);assert(rgb);glReadBuffer(GL_FRONT);glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,rgb);unsigned lit=0;for(unsigned i=0;i<640*480;i++)if(rgb[i*4]||rgb[i*4+1]||rgb[i*4+2])lit++;assert(glGetError()==GL_NO_ERROR&&lit>1000);[view checkFullscreenPicture:rgb];free(rgb);
 if(!strcmp(argv[2],"--exit-child")){puts("direct_exit_requested_after_actual_fullscreen_render");rejectExitDraw=YES;exit(0);}
 NSArray *names=[view textureNames];assert(names.count);NSOpenGLContext *oldContext=view.openGLContext;
 assert([delegate applicationShouldTerminate:NSApp]==NSTerminateCancel);[view startShutdownMusic];checkMusicShutdown=YES;[view closeDown];checkMusicShutdown=NO;[view checkGraphicsReleased];[view drawRect:view.bounds];[view checkGraphicsReleased];
 [oldContext makeCurrentContext];for(NSNumber *name in names)assert(!glIsTexture(name.unsignedIntValue));[NSOpenGLContext clearCurrentContext];assert(terminated&&!view.inFullScreenMode&&[delegate applicationShouldTerminate:NSApp]==NSTerminateNow);
 startup[58>>3]=1u<<(58&7);FullscreenView *option=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(option);[option stopProbeTimer];[option checkRequest:NO];assert(![option startFullscreen]);
 memset(startup,0,16);startup[61>>3]=1u<<(61&7);FullscreenView *right=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(right);[right stopProbeTimer];[right checkRequest:YES];
 UnavailableFullscreenView *unavailable=[[UnavailableFullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(unavailable);[unavailable stopProbeTimer];assert(![unavailable startFullscreen]&&!unavailable.inFullScreenMode);
 [window close];printf("PASS actual fullscreen game rendering lit%u, default/leftOption/rightOption, delegate quit after view move, closeDown restoration\n",lit);return 0;
}}
