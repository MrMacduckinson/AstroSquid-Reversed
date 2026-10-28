/* Authorized Intel iMac only: real Cocoa fullscreen with independent mode recovery. */
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
static int number(NSDictionary *mode,CFStringRef key){return [mode[(__bridge NSString *)key] intValue];}
static void report(const char *label){NSDictionary *m=(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID());printf("%s,%dx%d,bpp%d,hz%d\n",label,number(m,kCGDisplayWidth),number(m,kCGDisplayHeight),number(m,kCGDisplayBitsPerPixel),number(m,kCGDisplayRefreshRate));}
int main(int argc,const char **argv){@autoreleasepool{
 setvbuf(stdout,NULL,_IONBF,0);BOOL child=argc==2&&!strcmp(argv[1],"--child");
 if(argc>2||(argc==2&&!child&&strcmp(argv[1],"--run")))return 2;
 NSDictionary *selected=nil;for(NSDictionary *mode in (__bridge NSArray *)CGDisplayAvailableModes(CGMainDisplayID())){
  if(number(mode,kCGDisplayWidth)==640&&number(mode,kCGDisplayHeight)==480&&number(mode,kCGDisplayBitsPerPixel)==32){printf("available,640x480,bpp32,hz%d\n",number(mode,kCGDisplayRefreshRate));if(!selected)selected=mode;}
 }
 if(!selected){puts("UNAVAILABLE640x480bpp32");return 4;}if(argc==1)return 0;
 if(!child){
  NSDictionary *before=[(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID()) copy];report("before");
  pid_t pid=fork();if(pid<0)return 3;if(!pid){execl(argv[0],argv[0],"--child",NULL);_exit(2);}
  int status=0;BOOL done=NO;for(unsigned i=0;i<150;i++){pid_t p=waitpid(pid,&status,WNOHANG);if(p==pid){done=YES;break;}if(p<0&&errno!=EINTR)break;usleep(100000);}
  if(!done){kill(pid,SIGKILL);if(waitpid(pid,&status,0)!=pid)return 3;}
  BOOL same=[before isEqual:(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID())];
  if(!same)printf("recovery_error%d\n",CGDisplaySwitchToMode(CGMainDisplayID(),(__bridge CFDictionaryRef)before));
  BOOL restored=[before isEqual:(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID())];report("after");
  printf("done%d,childexit%d,native_restore%d,final_restore%d\n",done,WIFEXITED(status)?WEXITSTATUS(status):-1,same,restored);
  return done&&WIFEXITED(status)&&!WEXITSTATUS(status)&&same&&restored?0:3;
 }
 alarm(12);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
 NSOpenGLPixelFormatAttribute attrs[]={NSOpenGLPFADoubleBuffer,NSOpenGLPFAAccelerated,NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};
 NSOpenGLPixelFormat *format=[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];if(!format)return 4;
 NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,480) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];window.releasedWhenClosed=NO;
 NSOpenGLView *view=[[NSOpenGLView alloc] initWithFrame:NSMakeRect(0,0,640,480) pixelFormat:format];window.contentView=view;[window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
 int result=3;@try {
  BOOL entered=[view enterFullScreenMode:NSScreen.mainScreen withOptions:@{NSFullScreenModeAllScreens:@NO,NSFullScreenModeSetting:selected}];report("active");
  if(entered){[view displayIfNeeded];[view lockFocus];[[view openGLContext] update];[[view openGLContext] makeCurrentContext];glViewport(0,0,640,480);glClearColor(1,0,0,1);glClear(GL_COLOR_BUFFER_BIT);glFinish();unsigned char back[4]={0};glReadBuffer(GL_BACK);glReadPixels(320,240,1,1,GL_RGBA,GL_UNSIGNED_BYTE,back);printf("owned_back_rgb%u,%u,%u,error%u\n",back[0],back[1],back[2],glGetError());[[view openGLContext] flushBuffer];glFinish();unsigned char p[4]={0};glReadBuffer(GL_FRONT);glReadPixels(320,240,1,1,GL_RGBA,GL_UNSIGNED_BYTE,p);BOOL rendered=glGetError()==GL_NO_ERROR&&p[0]==255&&!p[1]&&!p[2];NSDictionary *m=(__bridge NSDictionary *)CGDisplayCurrentMode(CGMainDisplayID());BOOL modeOK=number(m,kCGDisplayWidth)==640&&number(m,kCGDisplayHeight)==480;printf("entered%d,in_fullscreen%d,owned_rgb%u,%u,%u,mode_match%d,rendered%d\n",entered,view.inFullScreenMode,p[0],p[1],p[2],modeOK,rendered);result=modeOK&&rendered?0:3;[view unlockFocus];}
 }@catch(NSException *e){printf("exception,%s\n",e.name.UTF8String);}@finally{if(view.inFullScreenMode)[view exitFullScreenModeWithOptions:nil];[NSOpenGLContext clearCurrentContext];[[view openGLContext] clearDrawable];[window close];}
 return result;
}}
