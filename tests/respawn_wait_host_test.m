// WAITLOOP60 timeout boundary in the actual host outer poll; source-backed, Intel only.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing,checkEntryInventory;
static uint32_t script[8];
static unsigned supplied,used,steps,renders;
static void supply(const uint32_t *ticks,unsigned count){memcpy(script,ticks,count*sizeof(*ticks));supplied=count;used=0;}
@interface AstroRespawnWaitView : AstroView
@end
@implementation AstroRespawnWaitView
- (uint32_t)playerClockTick {if(observing){assert(used<supplied);if(checkEntryInventory)assert(inventory.upgrade==3&&playerWeapon==43);return script[used++];}return [super playerClockTick];}
- (void)display {}
- (void)stepEnemies {assert(!"ordinary flow dispatcher during WAIT");}
- (void)stepWorldWithoutFlow {assert(observing);steps++;simulationTick++;}
- (void)renderTick {renders++;}
- (void)addDeathEffects:(AstroEnemy *)enemy {if(!observing)[super addDeathEffects:enemy];}
- (void)makeNewSprites {if(!observing){[super makeNewSprites];return;}assert(!"map spawning during respawn wait");}
@end
@interface AstroView (RespawnWaitCheck)
- (void)checkRespawnWait;
@end
@implementation AstroView (RespawnWaitCheck)
- (void)checkRespawnWait {
    [timer invalidate];timer=nil;[audio stop];observing=YES;
    world=[NSMutableArray array];enemies=[NSMutableArray array];flow.phase=ASTRO_FLOW_PLAY;
    menuVisible=paused=gameOver=changingStage=NO;invulnerableUntil=0;
    observedWallTick=140;simulationTick=5;camera=10.25;lastSpawnTick=73;
    inventory=(AstroInventory){40,3,2,2};playerWeapon=43;
    const uint32_t entry[]={100};supply(entry,1);[self beginRespawnWait];
    assert(used==1&&respawnTick&&respawnWaitStartTick==100);
    const uint32_t closed[]={140,160};supply(closed,2);[self pollGame];
    assert(used==2&&!steps&&respawnTick&&world.count==0&&lastSpawnTick==73);
    const uint32_t open[]={140,161,170,171,172,173,180,182};supply(open,8);checkEntryInventory=YES;[self pollGame];checkEntryInventory=NO;
    assert(used==8&&!steps&&!respawnTick&&invulnerableUntil&&playerCombat.kind==-1);
    assert(playerState.update_tick==170&&playerState.animation_tick==171&&lastPlayerShot==172);
    assert(playerVisual.next_tick==173+(uint32_t)spriteInfo[1].delay&&playerVisual.x==40);
    assert(respawnStartTick==180&&respawnBlinkTick==182&&world.count==1);
    assert(inventory.weapon==40&&inventory.upgrade==0&&inventory.specials==2&&inventory.lives==2&&playerWeapon==40&&lastSpawnTick==73);
    respawnTick=1;respawnWaitStartTick=0;
    const uint32_t negative[]={0x80000000};supply(negative,1);[self pollRespawnWait];assert(used==1&&respawnTick);
    world=[NSMutableArray array];respawnWaitStartTick=UINT32_MAX-10;invulnerableUntil=0;
    const uint32_t wrap[]={50,51,52,53,54,55,56};supply(wrap,7);[self pollRespawnWait];
    assert(used==7&&!respawnTick&&playerState.update_tick==51&&respawnStartTick==55&&respawnBlinkTick==56);
    world=[NSMutableArray arrayWithObject:[NSNull null]];respawnTick=invulnerableUntil=0;respawnPending=NO;inventory.lives=2;observedWallTick=199;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=0,.remove=-1};supplied=used=0;
    [self cleanupWorld];assert(used==0&&respawnPending&&!respawnTick&&inventory.lives==2&&world.count==0);
    const uint32_t branch[]={200,201,202,202,203,262};supply(branch,6);[self pollGame];
    assert(used==6&&!respawnPending&&respawnTick&&inventory.lives==1&&respawnWaitStartTick==202);
    assert(observedWallTick==203&&steps==1&&renders==1&&world.count==0&&lastSpawnTick==73);
    const uint32_t finish[]={203,263,270,271,272,273,280,282};supply(finish,8);[self pollGame];
    assert(used==8&&!respawnTick&&steps==1&&renders==1&&inventory.lives==1&&respawnStartTick==280);
    observing=NO;
    puts("PASS source-backed actual host respawn wait: fresh entry, closedCPU equality60/strict61, constructor after timeout, no mapfactory, wrap/signednegative and outer checkpoint preservation");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroRespawnWaitView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkRespawnWait];
}}
