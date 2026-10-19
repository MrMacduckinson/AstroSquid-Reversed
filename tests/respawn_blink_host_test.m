// NEWPLAYERSTART source clock boundaries, with world/factory observers on Intel.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing,verifyNested;
static uint32_t clocks[8];
static unsigned count,used,factories,calculations,renders;
static void supply(const uint32_t *values,unsigned n){memcpy(clocks,values,n*sizeof(*values));count=n;used=0;}
@interface AstroBlinkView : AstroView
@end
@implementation AstroBlinkView
- (uint32_t)playerClockTick {if(observing){assert(used<count);return clocks[used++];}return [super playerClockTick];}
- (void)display {}
- (void)makeNewSprites {if(!observing){[super makeNewSprites];return;}factories++;(void)[self playerClockTick];}
- (void)calculateActors {assert(observing&&playerVisual.width==spriteInfo[playerVisual.sprite].width);calculations++;}
- (void)stepEnemies {assert(!verifyNested);[super stepEnemies];}
- (void)renderTick {if(verifyNested){renders++;return;}[super renderTick];}
@end
@interface AstroView (BlinkCheck)
- (void)checkBlink;
@end
@implementation AstroView (BlinkCheck)
- (void)checkBlink {
    [timer invalidate];timer=nil;[audio stop];observing=YES;
    world=[NSMutableArray array];enemies=[NSMutableArray array];campaignAction=ASTRO_CAMPAIGN_NONE;changingStage=NO;respawnTick=0;
    playerCombat.kind=-1;playerVisual=(AstroVisual){1,30,190,71,20,100};lastSpawnTick=73;
    const uint32_t entry[]={100,102};supply(entry,2);[self beginRespawnBlink];
    assert(used==2&&respawnStartTick==100&&respawnBlinkTick==102&&respawnBlinkWidth==0&&invulnerableUntil);
    const uint32_t equalFive[]={107,120,150};supply(equalFive,3);[self pollRespawnBlink];
    assert(used==3&&respawnBlinkTick==102&&respawnBlinkWidth==0&&invulnerableUntil&&factories==1);
    const uint32_t turnOn[]={108,112,120,150};supply(turnOn,4);[self pollRespawnBlink];
    assert(used==4&&respawnBlinkTick==112&&respawnBlinkWidth==71&&invulnerableUntil);
    [self stepEnemies];assert(calculations==1&&playerVisual.width==71);
    const uint32_t turnOff[]={118,125,130,160};supply(turnOff,4);[self pollRespawnBlink];
    assert(used==4&&respawnBlinkWidth==0&&playerVisual.width==71);
    [self stepEnemies];assert(calculations==2&&playerVisual.width==0);
    const uint32_t equal180[]={130,180,280};supply(equal180,3);[self pollRespawnBlink];
    assert(used==3&&invulnerableUntil&&playerCombat.kind==-1);
    const uint32_t end181[]={130,181,281};supply(end181,3);[self pollRespawnBlink];
    assert(used==3&&!invulnerableUntil&&playerCombat.kind==1&&playerVisual.width==71&&lastSpawnTick==73);
    respawnStartTick=UINT32_MAX-100;respawnBlinkTick=UINT32_MAX-5;respawnBlinkWidth=0;invulnerableUntil=1;playerCombat.kind=-1;
    const uint32_t wrap[]={0,1,2,80};supply(wrap,4);[self pollRespawnBlink];
    assert(used==4&&!invulnerableUntil&&respawnBlinkTick==1&&playerCombat.kind==1);
    respawnStartTick=respawnBlinkTick=0;respawnBlinkWidth=0;invulnerableUntil=1;playerCombat.kind=-1;
    const uint32_t negative[]={0x80000000,1,0x80000000};supply(negative,3);[self pollRespawnBlink];
    assert(used==3&&invulnerableUntil&&respawnBlinkWidth==0&&playerCombat.kind==-1);
    menuVisible=paused=gameOver=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;
    respawnTick=0;respawnPending=NO;observedWallTick=299;respawnStartTick=124;respawnBlinkTick=298;
    campaignAction=ASTRO_CAMPAIGN_LOAD;verifyNested=YES;
    unsigned previousCalculations=calculations;
    const uint32_t nested[]={300,301,302,303,304};supply(nested,5);[self pollGame];
    assert(used==5&&calculations==previousCalculations+1&&renders==1&&invulnerableUntil&&playerVisual.width==0);
    assert(campaignAction==ASTRO_CAMPAIGN_LOAD&&!changingStage);
    const uint32_t resume[]={301,302,303,305,306,307,308};supply(resume,7);[self pollGame];
    assert(used==7&&calculations==previousCalculations+1&&renders==1&&!invulnerableUntil&&playerVisual.width==71);
    assert(lastSpawnTick==308&&observedWallTick==301&&playerCombat.kind==1);
    // A recently updated outer checkpoint remains unchanged on return.
    invulnerableUntil=1;playerCombat.kind=-1;respawnStartTick=100;respawnBlinkTick=275;lastSpawnTick=270;
    const uint32_t closedReturn[]={280,281,281,282};supply(closedReturn,4);[self pollMapSpawns];
    assert(used==4&&!invulnerableUntil&&lastSpawnTick==270);
    verifyNested=NO;
    observing=NO;
    puts("PASS source-backed actual host respawn: two entry clocks, strict5/fresh store, CPU width restoration, unconditional factory before strict180 exit, wrap/signed gates and unchanged outer checkpoint");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroBlinkView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkBlink];
}}
