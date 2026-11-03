#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <objc/runtime.h>
#include <unistd.h>
static IMP originalLaunch,originalTerminate;
static BOOL invoked;
static void forbiddenSave(id self,SEL selector){fputs("FAIL menu quit saved settings\n",stderr);_exit(91);}
static void didLaunch(AstroDelegate *self,SEL selector,NSNotification *note){
    ((void (*)(id,SEL,id))originalLaunch)(self,selector,note);
    [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer *timer){
        assert(self.view.isGameFullscreen&&![self.view canTerminateApplication]);
        NSMenu *menu=[NSApp.mainMenu itemAtIndex:0].submenu;
        NSMenuItem *item=[menu itemAtIndex:0];
        assert(item.target==self&&item.action==@selector(quitFromMenu:));
        invoked=YES;[menu performActionForItemAtIndex:0];
    }];
}
static void willTerminate(AstroDelegate *self,SEL selector,NSNotification *note){
    assert(invoked&&[self.view canTerminateApplication]);
    ((void (*)(id,SEL,id))originalTerminate)(self,selector,note);
    assert(!self.view.isGameFullscreen);
    puts("PASS real production menu target, termination delegate and fullscreen exit; saveSettings never called");fflush(stdout);
}
int main(int argc,const char **argv){@autoreleasepool{
    alarm(20);
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    method_setImplementation(class_getInstanceMethod([AstroView class],@selector(saveSettings)),(IMP)forbiddenSave);
    originalLaunch=method_setImplementation(class_getInstanceMethod([AstroDelegate class],@selector(applicationDidFinishLaunching:)),(IMP)didLaunch);
    originalTerminate=method_setImplementation(class_getInstanceMethod([AstroDelegate class],@selector(applicationWillTerminate:)),(IMP)willTerminate);
    return astrosquid_application_main(argc,argv);
}}
