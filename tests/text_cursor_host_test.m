#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include <assert.h>
#include "text_cursor_cases.h"
static NSPoint mouseLocation;
@interface CursorMouseView:AstroView
@end
@implementation CursorMouseView
- (void)copyKeyMap:(unsigned char *)bytes {memset(bytes,0,16);}
- (NSPoint)menuPoint:(NSEvent *)event {return mouseLocation;}
- (void)display {}
@end
@implementation AstroView(CursorMouseCheck)
- (void)checkMouseCursor {
    [timer invalidate];timer=nil;[audio stop];menuVisible=gameOver=YES;splashVisible=NO;editingKey=-1;
    [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=1;
    for(unsigned n=0;n<sizeof(text_cursor_names)/sizeof(text_cursor_names[0]);n++){
        memset(&scoreEditor,0,sizeof(scoreEditor));strcpy(scoreEditor.name,text_cursor_names[n]);
        for(unsigned ix=0;ix<sizeof(text_cursor_mouse_x)/sizeof(text_cursor_mouse_x[0]);ix++)for(unsigned iy=0;iy<sizeof(text_cursor_mouse_y)/sizeof(text_cursor_mouse_y[0]);iy++){
            scoreEditor.cursor=77;[self refreshScoreEditor];mouseLocation=NSMakePoint(223+text_cursor_mouse_x[ix],text_cursor_mouse_y[iy]);
            [self mouseDown:nil];printf("M,%u,%d,%d,%d,%d\n",n,text_cursor_mouse_x[ix],text_cursor_mouse_y[iy],scoreEditor.cursor!=77,scoreEditor.cursor);
        }
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroUIRenderer *ui=[[AstroUIRenderer alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:NULL];assert(ui);
    for(unsigned n=0;n<sizeof(text_cursor_names)/sizeof(text_cursor_names[0]);n++){
        NSString *name=[[NSString alloc]initWithBytes:text_cursor_names[n] length:strlen(text_cursor_names[n]) encoding:NSMacOSRomanStringEncoding];assert(name);
        ui.editingName=name;ui.editingCursor=name.length;
        for(unsigned s=0;s<sizeof(text_cursor_sizes)/sizeof(text_cursor_sizes[0]);s++)for(NSUInteger prefix=0;prefix<=name.length;prefix++)
            printf("W,%u,%lu,%d,%.17g\n",n,(unsigned long)prefix,text_cursor_sizes[s],[ui textWidth:[name substringToIndex:prefix] size:text_cursor_sizes[s]]);
        for(int x=-4;x<=260;x++)printf("C,%u,%d,%ld\n",n,x,(long)[ui scoreCursorAtX:223+x]);
    }
    CursorMouseView *view=[[CursorMouseView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkMouseCursor];
}}
