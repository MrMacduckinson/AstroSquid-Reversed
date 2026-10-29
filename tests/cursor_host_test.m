// Intel only: count and forward real AppKit calls; never leave an owned hide outstanding.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <objc/runtime.h>
static IMP originalHide,originalUnhide;static unsigned hides,unhides;
static NSModalResponse answer;
static NSModalResponse modalAnswer(NSAlert *alert,SEL selector){assert(hides==unhides&&alert.buttons.count==2);return answer;}
static void hideCursor(id object,SEL selector){hides++;((void(*)(id,SEL))originalHide)(object,selector);}
static void unhideCursor(id object,SEL selector){unhides++;((void(*)(id,SEL))originalUnhide)(object,selector);}
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 AstroView *view=[[AstroView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);
 Method hide=class_getClassMethod([NSCursor class],@selector(hide)),unhide=class_getClassMethod([NSCursor class],@selector(unhide));
 originalHide=method_setImplementation(hide,(IMP)hideCursor);originalUnhide=method_setImplementation(unhide,(IMP)unhideCursor);
 @try {
  [view setGameCursorHidden:NO];assert(!hides&&!unhides);
  [view setGameCursorHidden:YES];[view setGameCursorHidden:YES];assert(hides==1&&!unhides);
  [view setGameCursorHidden:NO];[view setGameCursorHidden:NO];assert(hides==1&&unhides==1);
  [view setGameCursorHidden:YES];assert(hides==2&&unhides==1);
  AstroDelegate *delegate=[AstroDelegate new];delegate.view=view;
  [delegate applicationWillTerminate:nil];assert(hides==2&&unhides==2);
  [delegate applicationWillTerminate:nil];assert(hides==2&&unhides==2);
  Method modal=class_getInstanceMethod([NSAlert class],@selector(runModal));IMP previousModal=method_setImplementation(modal,(IMP)modalAnswer);
  @try {
   [view setGameCursorHidden:YES];answer=NSAlertSecondButtonReturn;
   assert([view continueRuntimeAlert:@"Stop" details:@"cursor boundary"]&&hides==3&&unhides==3);
   [view setGameCursorHidden:YES];answer=NSAlertFirstButtonReturn;
   assert(![view continueRuntimeAlert:@"Stop" details:@"cursor boundary"]&&hides==4&&unhides==4);
  } @finally {method_setImplementation(modal,previousModal);}
  puts("PASS modal entry restores cursor, Continue does not rehide, Stop returns with cursor restored");
  puts("PASS actual AppKit hide/unhide forwarding: duplicate calls balanced, termination delegate releases owned hide exactly once");
 } @finally {[view setGameCursorHidden:NO];method_setImplementation(hide,originalHide);method_setImplementation(unhide,originalUnhide);}
}}
