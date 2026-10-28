#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned saves;static NSString *savedAnchor;static double savedSound,savedMusic;static int savedKey;static BOOL terminated;
@interface AstroUIRenderer (SettingsTestGeometry)
- (NSDictionary *)object:(NSString *)name;
- (NSRect)bounds:(NSDictionary *)object;
@end
@interface SettingsSaveView:AstroView
@end
@implementation SettingsSaveView
- (uint32_t)currentGameTick {static uint32_t tick=100;return tick++;}
- (void)copyKeyMap:(unsigned char *)map {memset(map,0,16);}
- (void)display {}
- (void)saveSettings {saves++;savedAnchor=[ui.anchor copy];savedSound=ui.soundVolume;savedMusic=ui.musicVolume;savedKey=controlKeys[0];}
- (void)terminateApplication {terminated=YES;}
@end
@implementation AstroView(SettingsSaveCheck)
- (void)clickSettingsNavigation:(NSString *)name {
 NSDictionary *object=[ui object:name];assert(object);NSRect r=[ui bounds:object];
 NSString *hit=[ui mouseDownX:NSMidX(r) y:NSMidY(r)];assert([hit isEqual:name]);
 assert([ui mouseDownX:NSMidX(r) y:NSMidY(r)]==nil);[self performMenuAction:hit];
 for(unsigned poll=0;navigationButton;poll++){assert(poll<1000);[self pollMenu];}
 [ui mouseUpX:NSMidX(r) y:NSMidY(r)];
}
- (void)checkSettingsSaves {
 [timer invalidate];timer=nil;[audio stop];splashVisible=NO;selftestPath=campaignTestPath=nil;
 [self performMenuAction:@"SetSVolume"];[self performMenuAction:@"SetMVolume"];[self performMenuAction:@"SetSmooth"];assert(!saves);
 [self performMenuAction:@"SetKeyFire"];[self keyDown:[self testEvent:NSKeyDown code:7]];assert(controlKeys[0]==7&&!saves);
 [self performMenuAction:@"SetKeyFire"];[self testModifier:58 flags:NSEventModifierFlagOption|NX_DEVICELALTKEYMASK];[self testModifier:58 flags:0];assert(controlKeys[0]==58&&!saves);
 [ui show:@"Keys Menu"];[ui animateTicks:120];[self clickSettingsNavigation:@"Back6"];assert([ui.anchor isEqual:@"Settings Menu"]&&!saves);
 [ui animateTicks:120];[self clickSettingsNavigation:@"Back"];
 assert(saves==1&&[savedAnchor isEqual:@"Settings Menu"]&&[ui.anchor isEqual:@"Main Menu"]&&savedSound==ui.soundVolume&&savedMusic==ui.musicVolume&&savedKey==58);
 [ui animateTicks:120];[ui show:@"Highscores Menu"];[ui animateTicks:120];[self clickSettingsNavigation:@"Back2"];assert(saves==1);
 [self performMenuAction:@"SetSVolume"];assert(saves==1);[self closeDown];assert(saves==2&&terminated&&savedSound==ui.soundVolume);
 puts("PASS settings edits apply without writes; Back6/Back2 do not save; Back saves once before navigation; quit saves pending values");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 AstroView *view=[[SettingsSaveView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkSettingsSaves];
}}
