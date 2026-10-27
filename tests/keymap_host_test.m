// GETKEYMAP1004cb28 source-backed snapshot decoding and actual host call sites.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting;
static unsigned char map[16];
static unsigned snapshots;
static NSMutableString *events;
@interface KeyMapView : AstroView
@end
@implementation KeyMapView
- (void)display {}
- (void)copyKeyMap:(unsigned char *)bytes {if(!injecting){[super copyKeyMap:bytes];return;}snapshots++;[events appendString:@"K"];memcpy(bytes,map,16);}
- (uint32_t)playerClockTick {if(injecting){[events appendString:@"T"];return 100;}return [super playerClockTick];}
- (void)pollMapSpawns {if(injecting)[events appendString:@"M"];else [super pollMapSpawns];}
- (void)makeNewSprites {if(injecting)[events appendString:@"M"];else [super makeNewSprites];}
@end
@implementation AstroView (KeyMapCheck)
- (void)checkKeyMap {
    [timer invalidate];timer=nil;[audio stop];events=[NSMutableString string];injecting=YES;
    selftestPath=campaignTestPath=nil;
    for(unsigned bit=0;bit<128;bit++){
        memset(map,0,16);map[bit>>3]=1u<<(bit&7);memset(keys,1,sizeof(keys));
        unsigned before=snapshots;[self readKeyMap];assert(snapshots==before+1);
        for(unsigned i=0;i<128;i++)assert(keys[i]==(i==bit));
    }
    memset(map,0,16);[self readKeyMap];for(unsigned i=0;i<128;i++)assert(!keys[i]);
    map[15]=0x80;[self readSpecialKeys];assert(keys[127]); // Non-control keys refresh too.
    observedWallTick=100;respawnTick=invulnerableUntil=0;respawnPending=NO;flow.phase=ASTRO_FLOW_PLAY;
    [events setString:@""];[self pollGame];assert([events isEqual:@"TMK"]);
    respawnTick=1;respawnWaitStartTick=100;[events setString:@""];
    [self pollRespawnWait];assert([events isEqual:@"KT"]&&respawnTick);
    respawnTick=0;invulnerableUntil=1;respawnStartTick=respawnBlinkTick=100;
    [events setString:@""];[self pollRespawnBlink];assert([events isEqual:@"TMKT"]);
    selftestPath=@"controlled";unsigned before=snapshots;keys[0]=YES;[self readKeyMap];assert(snapshots==before&&keys[0]);
    selftestPath=nil;campaignTestPath=@"controlled";[self readKeyMap];assert(snapshots==before&&keys[0]);
    injecting=NO;
    puts("PASS128 keymap bit positions and full stale-key replacement; ordinary/special/WAIT/blink snapshot ordering; controlled input preserved");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[KeyMapView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkKeyMap];
}}
