#import "../src/ui_renderer.h"
#include <assert.h>
#include "../src/weapons.h"
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
    uint32_t seed=12345,expected=seed;
    NSDictionary *data=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSString stringWithUTF8String:argv[1]] stringByAppendingPathComponent:@"ui/ui.json"]] options:0 error:NULL];
    for(NSDictionary *object in data[@"scenes"][@"Data B2"]){NSInteger sprite=[object[@"sprite"] integerValue];if(sprite==900||sprite==901)astro_random(&expected,60);}
    [ui reloadMenuWithRandom:&seed];assert(seed==expected);
    assert(fabs([[ui valueForKey:@"cameraX"] doubleValue]-(-590.63886067661))<1e-10);
    assert(fabs([[ui valueForKey:@"cameraY"] doubleValue]-(-338.9153762681465))<1e-10);
    assert([ui.registeredName isEqual:@""]);ui.registeredName=@"MACSPB";
    assert([[ui mouseDownX:369 y:175] isEqual:@"Play"]);assert(![ui mouseUpX:0 y:0]);
    assert([ui.anchor isEqual:@"Play Menu"]);assert(ui.transitioning);
    [ui animateTicks:120];assert(!ui.transitioning);
    assert([[ui mouseDownX:394 y:268] isEqual:@"New Game"]);[ui mouseUpX:0 y:0];
    [ui mouseDownX:394 y:268];assert(![ui mouseUpX:0 y:0]);
    assert([ui textWidth:@" " size:16]==3);
    assert((int)[ui textWidth:@" 12345" size:18]==59);
    assert([[ui briefingForStage:1 list:400] hasPrefix:@"Just another dull"]);
    assert([[ui briefingForStage:8 list:402] hasPrefix:@"That last bit"]);
    assert([[ui briefingForStage:9 list:402] isEqual:@""]);
    [ui show:@"Pause"];assert(ui.transitioning&&ui.panelOffset==-380);
    assert(![ui mouseDownX:365 y:250]);[ui animateTicks:29];assert(ui.transitioning);
    [ui animateTicks:1];assert(!ui.transitioning&&ui.panelOffset==0);
    NSData *firstPause=[[[ui valueForKey:@"orbStates"] objectForKey:@"Pause"] copy];
    assert([[ui mouseDownX:365 y:250] isEqual:@"PauseContinue"]);[ui mouseUpX:0 y:0];
    [ui beginPauseExit];[ui animateTicks:29];assert(ui.transitioning);
    [ui animateTicks:1];assert(!ui.transitioning&&fabs(ui.panelOffset+380)<1e-10);
    [ui show:@"Pause"];[ui animateTicks:30];assert(!ui.transitioning);
    assert(!memcmp(firstPause.bytes,[[[ui valueForKey:@"orbStates"] objectForKey:@"Pause"] bytes],32));
    [ui show:@"GameOver"];[ui animateTicks:59];assert(ui.transitioning);
    [ui animateTicks:1];assert(!ui.transitioning&&ui.panelOffset==0);
    puts("PASS original menu pointer navigation, mouse-down activation and original panel frame counts, font spacing and campaign text");
}}
