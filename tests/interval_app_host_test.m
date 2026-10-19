// Run the existing complete application self-test at a nondefault frame interval.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==4);int interval=atoi(argv[3]);assert(interval==2||interval==3);
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,480)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    AstroView *view=[[AstroView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);
    ((AstroUIRenderer *)[view valueForKey:@"ui"]).frameInterval=(int16_t)interval;
    window.contentView=view;[window makeKeyAndOrderFront:nil];
    [view beginSelfTest:[NSString stringWithUTF8String:argv[2]]];[NSApp run];
}}
