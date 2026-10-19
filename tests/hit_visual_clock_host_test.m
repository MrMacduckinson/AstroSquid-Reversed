// Source-backed LMNEWSPRITE / LMCHANGESPRITEID clock boundary after player hits.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
static uint32_t clockValue;
static unsigned reads,allowed;
@interface AstroHitClockView : AstroView
@end
@implementation AstroHitClockView
- (uint32_t)playerClockTick {if(observing){assert(reads<allowed);reads++;return clockValue;}return [super playerClockTick];}
- (void)display {}
@end
@interface AstroView (HitClockCheck)
- (void)checkHitClocks;
@end
@implementation AstroView (HitClockCheck)
- (void)checkHitClocks {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=0;observing=YES;simulationTick=9;
    playerHitVisual=(AstroPlayerHitVisual){0};renderClock=40;clockValue=1000;reads=0;allowed=1;
    [self showPlayerHit:NO bounds:(AstroRect){100,120,171,140}];
    assert(reads==1&&playerHitVisual.visual.sprite==71&&playerHitVisual.visual.next_tick==1000+(uint32_t)spriteInfo[71].delay);
    assert(playerHitBirth==41&&playerHitLayer==7&&playerHitVisual.visual.width==81&&playerHitVisual.visual.height==30);
    clockValue=1100;reads=0;[self showPlayerHit:NO bounds:(AstroRect){200,220,240,260}];
    assert(reads==1&&playerHitVisual.visual.sprite==72&&playerHitVisual.visual.next_tick==1100+(uint32_t)spriteInfo[72].delay);
    assert(playerHitBirth==41&&playerHitLayer==7);
    clockValue=1200;reads=0;[self showPlayerHit:YES bounds:(AstroRect){200,220,240,260}];
    assert(reads==1&&playerHitVisual.visual.next_tick==1200+(uint32_t)spriteInfo[72].delay&&playerHitBirth==41&&playerHitLayer==7);
    assert(playerHitVisual.visual.x==195&&playerHitVisual.visual.y==215&&playerHitVisual.visual.width==50&&playerHitVisual.visual.height==50);
    playerHitVisual.active=0;clockValue=UINT32_MAX;reads=0;[self showPlayerHit:YES bounds:(AstroRect){200,220,240,260}];
    assert(reads==1&&playerHitBirth==42&&playerHitLayer==8&&playerHitVisual.visual.next_tick==UINT32_MAX+(uint32_t)spriteInfo[71].delay);
    for(int scenario=0;scenario<3;scenario++){
        playerCombat=(AstroCombatState){.kind=1,.hit_points=scenario==0?5:100};
        AstroCombatState bullet={.kind=2,.layer=scenario==2?0:2,.hit_points=10,.remove=scenario==1?1:0};
        reads=allowed=0;[self hitPlayerWithCombat:&bullet];assert(reads==0&&playerHitBirth==42);
    }
    observing=NO;puts("PASS source-backed actual host hit effects: one fresh clock for create/repeat/scenery, wrapped deadline, birth/layer retained and no clock on lethal/removed/wrong-layer hit");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroView *view=[[AstroHitClockView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkHitClocks];
}}
