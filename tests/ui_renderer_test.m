#import "../src/ui_renderer.h"
#include <assert.h>
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);NSError *error=nil;
    AstroUIRenderer *ui=[[AstroUIRenderer alloc] initWithAssets:[NSString stringWithUTF8String:argv[1]] error:&error];
    ui.editingName=@"MACSPB";ui.editingCursor=6;
    assert([ui scoreCursorAtX:225]==0);
    assert([ui scoreCursorAtX:225+[ui textWidth:@"MAC" size:20]]==3);
    assert([ui scoreCursorAtX:999]==6);
    assert([[ui nameForKeyCode:0] isEqual:@"A"]&&[[ui nameForKeyCode:7] isEqual:@"X"]);
    assert([[ui nameForKeyCode:49] isEqual:@"Space"]&&[[ui nameForKeyCode:58] isEqual:@"Option"]);
    assert([[ui nameForKeyCode:126] isEqual:@"Up"]);
    assert(ui&&!error);assert([ui.anchor isEqual:@"Main Menu"]);
    assert([ui.registeredName isEqual:@""]);ui.registeredName=@"MACSPB";
    [ui mouseDownX:369 y:175];assert([[ui mouseUpX:369 y:175] isEqual:@"Play"]);
    assert([ui.anchor isEqual:@"Play Menu"]);assert(ui.transitioning);
    [ui animateTicks:120];assert(!ui.transitioning);
    [ui mouseDownX:394 y:268];assert([[ui mouseUpX:394 y:268] isEqual:@"New Game"]);
    [ui mouseDownX:394 y:268];assert(![ui mouseUpX:0 y:0]);
    assert([ui textWidth:@" " size:16]==3.2);
    assert((int)[ui textWidth:@" 12345" size:18]==59);
    assert([[ui briefingForStage:1 list:400] hasPrefix:@"Just another dull"]);
    assert([[ui briefingForStage:8 list:402] hasPrefix:@"That last bit"]);
    assert([[ui briefingForStage:9 list:402] isEqual:@""]);
    [ui show:@"Pause"];[ui mouseDownX:365 y:250];assert([[ui mouseUpX:365 y:250] isEqual:@"PauseContinue"]);
    puts("PASS original menu pointer navigation, click cancellation, font spacing and campaign text");
}}
