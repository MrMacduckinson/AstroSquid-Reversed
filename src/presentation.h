// Shared ARC/MRC implementation; uses APIs available on Intel Tiger.
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <OpenGL/gl.h>
#include <math.h>
@interface NSOpenGLView (AstroBackingSurface)
- (void)setWantsBestResolutionOpenGLSurface:(BOOL)value;
@end
static NSView *fullscreenView;
static NSWindow *fullscreenWindow,*windowedWindow;
static NSRect windowedViewFrame;
static SystemUIMode previousUIMode;
static SystemUIOptions previousUIOptions;
static id presentationRetain(id value){
#if !__has_feature(objc_arc)
    [value retain];
#endif
    return value;
}
static void presentationRelease(id value){
#if !__has_feature(objc_arc)
    [value release];
#endif
}
static NSRect presentationFrame(NSSize size){
    double scale=fmin(size.width/640.0,size.height/480.0);
    NSSize game=NSMakeSize(floor(640*scale),floor(480*scale));
    return NSMakeRect(floor((size.width-game.width)/2),floor((size.height-game.height)/2),game.width,game.height);
}
@interface AstroFullscreenWindow:NSWindow @end
@implementation AstroFullscreenWindow
- (BOOL)canBecomeKeyWindow{return YES;}
- (BOOL)canBecomeMainWindow{return YES;}
@end
@interface AstroLetterboxView:NSView @end
@implementation AstroLetterboxView
- (void)drawRect:(NSRect)rect{[[NSColor blackColor]set];NSRectFill(rect);}
@end
static void leaveFullscreen(BOOL showWindow){
    if(!fullscreenView)return;
    NSView *view=fullscreenView;
    [view removeFromSuperview];[windowedWindow setContentView:view];[view setFrame:windowedViewFrame];
    [fullscreenWindow orderOut:nil];[fullscreenWindow setDelegate:nil];
    SetSystemUIMode(previousUIMode,previousUIOptions);
    if(showWindow){[windowedWindow makeKeyAndOrderFront:nil];[windowedWindow makeFirstResponder:view];}
    if([view isKindOfClass:[NSOpenGLView class]])[[(NSOpenGLView *)view openGLContext]update];
    presentationRelease(fullscreenWindow);fullscreenWindow=nil;
    presentationRelease(windowedWindow);windowedWindow=nil;
    presentationRelease(fullscreenView);fullscreenView=nil;
    if(showWindow)[view setNeedsDisplay:YES];
}
static void restoreFullscreen(void){@autoreleasepool{leaveFullscreen(NO);}}
static BOOL enterFullscreen(NSView *view){
    if(fullscreenView)return fullscreenView==view;
    NSWindow *window=[view window];NSScreen *screen=[window screen]?:[NSScreen mainScreen];
    if(!window||!screen)return NO;
    NSRect frame=[screen frame];
    NSWindow *full=[[AstroFullscreenWindow alloc]initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if(!full)return NO;
    [full setTitle:[window title]];[full setAcceptsMouseMovedEvents:YES];
    fullscreenWindow=full;windowedWindow=presentationRetain(window);fullscreenView=presentationRetain(view);windowedViewFrame=[view frame];
    GetSystemUIMode(&previousUIMode,&previousUIOptions);
    NSView *blank=[[NSView alloc]initWithFrame:[view frame]];[window setContentView:blank];presentationRelease(blank);
    AstroLetterboxView *back=[[AstroLetterboxView alloc]initWithFrame:NSMakeRect(0,0,frame.size.width,frame.size.height)];
    [full setContentView:back];presentationRelease(back);[full setDelegate:[window delegate]];
    [view setFrame:presentationFrame(frame.size)];[back addSubview:view];[window orderOut:nil];
    SetSystemUIMode(kUIModeAllHidden,kUIOptionAutoShowMenuBar);
    [full makeKeyAndOrderFront:nil];[full makeFirstResponder:view];
    if([view isKindOfClass:[NSOpenGLView class]])[[(NSOpenGLView *)view openGLContext]update];
    [view setNeedsDisplay:YES];return YES;
}
static BOOL presentationShortcut(NSEvent *event){
    NSUInteger flags=[event modifierFlags];
    return [event type]==NSKeyDown&&[event keyCode]==3&&(flags&NSCommandKeyMask)&&(flags&NSControlKeyMask);
}
