// Compare actual host postfire continuation with original G5 IEEE/state captures.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static double value(unsigned long long bits){double d;uint64_t b=bits;memcpy(&d,&b,8);return d;}
static void same(double actual,unsigned long long want){uint64_t bits;memcpy(&bits,&actual,8);assert(bits==(uint64_t)want);}
static BOOL gateCheck;
static uint32_t gateClock;
static unsigned fires,finishes,clockReads;
static uint32_t prefixClocks[4];
static unsigned prefixCount,prefixRead;
@interface AstroPlayerTailView : AstroView
@end
@implementation AstroPlayerTailView
- (uint32_t)playerClockTick {if(prefixCount){assert(prefixRead<prefixCount);return prefixClocks[prefixRead++];}if(gateCheck){clockReads++;return gateClock;}return [super playerClockTick];}
- (void)fireWeapon:(int)weapon x:(int)x y:(int)y heading:(int)heading source:(int)kind {
    if(gateCheck){assert(playerState.update_tick==99);fires++;gateClock=105;}
    [super fireWeapon:weapon x:x y:y heading:heading source:kind];
}
- (void)finishPlayerUpdateAtTick:(uint32_t)tick {if(gateCheck)finishes++;[super finishPlayerUpdateAtTick:tick];}
@end
@interface AstroView (PlayerTailCheck)
- (void)checkPlayerTail:(const char *)path;
- (void)checkPlayerGate;
@end
@implementation AstroView (PlayerTailCheck)
- (void)checkPlayerTail:(const char *)path {
    [timer invalidate];timer=nil;[audio stop];FILE *file=fopen(path,"r");assert(file);
    int mask,frame,variant,left,top;unsigned now,before,anim,after,wantAnim,count=0;unsigned long long b[10];
    while(fscanf(file,"%d,%d,%d,%u,%u,%u,%d,%d,%llx,%llx,%llx,%llx,%u,%u,%llx,%llx,%llx,%llx,%llx,%llx",&mask,&frame,&variant,&now,&before,&anim,&left,&top,b,b+1,b+2,b+3,&after,&wantAnim,b+4,b+5,b+6,b+7,b+8,b+9)==20){
        (void)variant;playerState.frame=frame;playerState.update_tick=before;playerState.animation_tick=anim;
        playerBounds=(AstroRect){left,top,left+20,top+20};
        playerVisual=(AstroVisual){1,value(b[0]),value(b[1]),value(b[2]),value(b[3]),0};
        playerHitVisual=(AstroPlayerHitVisual){0};playerHitVisual.active=mask&1;
        playerHitVisual.visual.x=-123.25;playerHitVisual.visual.y=456.5;
        engineGlow=(mask&2)!=0;engineGlowRect=(AstroTransitionRect){-19.25,23.5,7.75,9.5};
        [self finishPlayerUpdateAtTick:now];
        assert(playerState.update_tick==after&&playerState.animation_tick==wantAnim);
        same(playerHitVisual.visual.x,b[4]);same(playerHitVisual.visual.y,b[5]);
        same(engineGlowRect.x,b[6]);same(engineGlowRect.y,b[7]);same(engineGlowRect.width,b[8]);same(engineGlowRect.height,b[9]);count++;
    }
    assert(feof(file)&&count==48);fclose(file);puts("PASS48 original player postfire states: update clock, shield/glow presence, signed frames and animation underflow");
}
- (void)checkPlayerGate {
    world=[NSMutableArray arrayWithObject:[NSNull null]];enemies=[NSMutableArray array];
    selftestPath=nil;campaignTestPath=nil;changingStage=NO;simulationTick=100;camera=tickedScroll=0;
    playerVisual=(AstroVisual){1,100,180,71,20,100};playerX=100;playerY=180;
    playerBounds=(AstroRect){100,180,171,200};playerVelocity=(AstroVelocity){0};
    playerCombat=(AstroCombatState){.kind=1,.hit_points=200};
    playerState=(AstroPlayer){.frame=12,.tilt=3,.state=1,.update_tick=100,.animation_tick=100};
    special=(AstroSpecial){0};specialLoopRunning=NO;playerWeapon=10;inventory.specials=0;
    memset(keys,0,sizeof(keys));keys[controlKeys[0]]=YES;lastPlayerShot=0;ui.frameInterval=3;
    playerHitVisual.active=YES;playerHitVisual.visual.x=-123.25;playerHitVisual.visual.y=456.5;
    engineGlow=YES;engineGlowRect=(AstroTransitionRect){-19.25,23.5,7.75,9.5};
    gateCheck=YES;gateClock=100;fires=finishes=clockReads=0;[self stepPlayer];
    assert(fires==0&&finishes==0&&clockReads==3&&playerState.update_tick==100);
    assert(playerHitVisual.visual.x==-123.25&&engineGlowRect.x==-19.25);
    playerState.update_tick=99;clockReads=0;[self stepPlayer];gateCheck=NO;
    assert(fires==1&&finishes==1&&clockReads==6&&lastPlayerShot==107&&playerState.update_tick==105);
    assert(playerState.animation_tick==95);
    assert(playerHitVisual.visual.x==playerBounds.left-5&&playerHitVisual.visual.y==playerBounds.top-5);
    memset(keys,0,sizeof(keys));engineGlow=NO;playerHitVisual.active=NO;
    playerState.animation_tick=90;playerState.update_tick=100;
    prefixClocks[0]=100;prefixClocks[1]=100;prefixClocks[2]=101;prefixClocks[3]=109;prefixCount=4;prefixRead=0;
    [self stepPlayer];assert(prefixRead==4&&playerState.animation_tick==90&&playerState.update_tick==109);
    playerState.animation_tick=90;playerState.update_tick=107;
    prefixClocks[0]=101;prefixClocks[1]=101;prefixClocks[2]=107;prefixClocks[3]=107;prefixRead=0;
    int beforeFrame=playerState.frame;
    [self stepPlayer];assert(prefixRead==4&&playerState.animation_tick==107&&playerState.update_tick==107&&playerState.frame!=beforeFrame);
    prefixCount=0;
    puts("PASS actual host separate animation/update comparisons and distinct animation store clock");
    puts("PASS actual player closed gate suppresses fire/posttail; open gate defers update store and samples clocks after synchronous fire");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroPlayerTailView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkPlayerTail:argv[2]];[view checkPlayerGate];
}}
