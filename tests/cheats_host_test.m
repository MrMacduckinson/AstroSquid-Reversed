#define main astrosquid_application_main
#ifdef ASTRO_TIGER_TEST
#include "../src/tiger/preview.m"
#else
#include "../src/preview.m"
#endif
#undef main
@interface CheatView:AstroView
- (void)verifyCheat;
@end
@implementation CheatView
- (void)type:(NSString *)text repeat:(BOOL)repeat flags:(NSUInteger)flags {
    for(NSUInteger n=0;n<text.length;n++) {
        NSString *ch=[text substringWithRange:NSMakeRange(n,1)];
        NSEvent *e=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:flags timestamp:0 windowNumber:0 context:nil characters:ch charactersIgnoringModifiers:ch isARepeat:repeat keyCode:18];
        [self keyDown:e];
    }
}
- (void)verifyCheat {
    editingKey=-1;flow.phase=ASTRO_FLOW_PLAY;playerCombat.kind=1;
    inventory=(AstroInventory){10,0,1,9};playerWeapon=10;
    [self type:@"4" repeat:NO flags:0];assert(playerWeapon==10);
    [self type:@"weapons" repeat:YES flags:0];assert(!cheats.weapons);
    [self type:@"weapons" repeat:NO flags:NSEventModifierFlagCommand];assert(!cheats.weapons);
    menuVisible=YES;[self type:@"weapons" repeat:NO flags:0];assert(!cheats.weapons);menuVisible=NO;
    paused=YES;[self type:@"weapons" repeat:NO flags:0];assert(!cheats.weapons);paused=NO;
    playerCombat.kind=-1;[self type:@"weapons" repeat:NO flags:0];assert(!cheats.weapons);playerCombat.kind=1;
    [self type:@"wea" repeat:NO flags:0];menuVisible=YES;[self type:@"p" repeat:NO flags:0];menuVisible=NO;
    [self type:@"ons" repeat:NO flags:0];assert(!cheats.weapons);
    [self type:@"WEAPONS" repeat:NO flags:0];assert(cheats.weapons);
    const int expected[]={13,33,43,53};
    for(int n=0;n<4;n++){
        NSUInteger queued=queuedKeyEvents.count;memset(keys,0,sizeof(keys));hudRedraws=0;
        [self type:[NSString stringWithFormat:@"%d",n+1] repeat:NO flags:0];
        assert(playerWeapon==expected[n]&&inventory.upgrade==3&&inventory.specials==4&&inventory.lives==9);
        assert(hudRedraws==2&&!keys[18]&&queuedKeyEvents.count==queued);
    }
    changingStage=YES;[self type:@"1" repeat:NO flags:0];assert(playerWeapon==53);changingStage=NO;
    specialLoopRunning=YES;[self type:@"1" repeat:NO flags:0];assert(playerWeapon==53);specialLoopRunning=NO;
    menuVisible=YES;[self type:@"1" repeat:NO flags:0];assert(playerWeapon==53);
    puts("PASS actual keyDown: guards, activation, four selections, HUD and consumed key isolation");
}
@end
int main(void){@autoreleasepool{
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CheatView *view=[[CheatView alloc]initWithFrame:NSMakeRect(0,0,640,480)];[view verifyCheat];
}}
