// Intel-only AppKit probe: hidden window; ordinary key uses a direct positive control.
// This checks menu interception, not foreground OS keyboard delivery.
// clang -fobjc-arc tools/cocoa_command_dispatch_probe.m -framework Cocoa -o /tmp/astrosquid-dispatch-probe
#import <Cocoa/Cocoa.h>
#include <assert.h>
static unsigned keys,actions;
@interface ProbeView:NSView
@end
@implementation ProbeView
- (BOOL)acceptsFirstResponder{return YES;}
- (void)keyDown:(NSEvent *)event{keys++;}
@end
@interface ProbeTarget:NSObject
- (void)quitProbe:(id)sender;
@end
@implementation ProbeTarget
- (void)quitProbe:(id)sender{actions++;}
@end
int main(void){@autoreleasepool{
 [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 NSWindow *window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,64,64) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
 ProbeView *view=[ProbeView new];window.contentView=view;[window makeFirstResponder:view];
 ProbeTarget *target=[ProbeTarget new];NSMenu *menu=[NSMenu new],*submenu=[NSMenu new];NSMenuItem *root=[NSMenuItem new];root.submenu=submenu;[menu addItem:root];
 NSMenuItem *quit=[submenu addItemWithTitle:@"Quit probe" action:@selector(quitProbe:) keyEquivalent:@"q"];quit.target=target;NSApp.mainMenu=menu;
 for(unsigned repeat=0;repeat<2;repeat++)for(unsigned cmd=0;cmd<2;cmd++){
  keys=actions=0;
  NSEvent *e=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:cmd?NSEventModifierFlagCommand:0 timestamp:0 windowNumber:window.windowNumber context:nil characters:@"q" charactersIgnoringModifiers:@"q" isARepeat:repeat keyCode:12];
  if(cmd)[NSApp sendEvent:e];else [view keyDown:e];assert(keys==!cmd&&actions==cmd);printf("repeat=%u,command=%u,keyDown=%u,menuAction=%u\n",repeat,cmd,keys,actions);
 }
 puts("PASS matched Command-Q executes menu action without keyDown; direct keyDown positive control passes");[window orderOut:nil];
}}
