#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>
static unsigned char startup[16];static BOOL terminated;
@interface FullscreenView:AstroView
@end
@implementation FullscreenView
- (void)copyKeyMap:(unsigned char *)bytes {memcpy(bytes,startup,16);}
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
- (void)stopProbeTimer {[timer invalidate];timer=nil;[audio stop];}
- (void)checkRequest:(BOOL)value {assert(fullscreenRequested==value);}
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
 [[view openGLContext] makeCurrentContext];unsigned char *rgb=malloc(640*480*3);assert(rgb);glReadBuffer(GL_FRONT);glReadPixels(0,0,640,480,GL_RGB,GL_UNSIGNED_BYTE,rgb);unsigned lit=0;for(unsigned i=0;i<640*480;i++)if(rgb[i*3]||rgb[i*3+1]||rgb[i*3+2])lit++;free(rgb);assert(glGetError()==GL_NO_ERROR&&lit>1000);
 if(!strcmp(argv[2],"--exit-child")){puts("direct_exit_requested_after_actual_fullscreen_render");exit(0);}
 assert([delegate applicationShouldTerminate:NSApp]==NSTerminateCancel);[view closeDown];assert(terminated&&!view.inFullScreenMode&&[delegate applicationShouldTerminate:NSApp]==NSTerminateNow);
 startup[58>>3]=1u<<(58&7);FullscreenView *option=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(option);[option stopProbeTimer];[option checkRequest:NO];assert(![option startFullscreen]);
 memset(startup,0,16);startup[61>>3]=1u<<(61&7);FullscreenView *right=[[FullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(right);[right stopProbeTimer];[right checkRequest:YES];
 UnavailableFullscreenView *unavailable=[[UnavailableFullscreenView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(unavailable);[unavailable stopProbeTimer];assert(![unavailable startFullscreen]&&!unavailable.inFullScreenMode);
 [window close];printf("PASS actual fullscreen game rendering lit%u, default/leftOption/rightOption, delegate quit after view move, closeDown restoration\n",lit);return 0;
}}
