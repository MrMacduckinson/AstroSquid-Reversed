// Replay original PAUSE clock/frame/input boundaries in the actual Intel host.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include <unistd.h>
typedef struct {char event[24];int value;unsigned reads,polls,frames,cpu;int paused,any;} PauseRow;
static PauseRow rows[128];
static unsigned rowCount,rowUsed,reads,polls,frames,transitions,scenario,outerReads,factories;
static BOOL observing,inTransition;
static unsigned mode,gameReads;
static const uint32_t waitClocks[]={161,170,171,172,173,180,182};
static void boundary(const char *name,int value,uint32_t cpu,BOOL paused){
    assert(rowUsed<rowCount);PauseRow *r=&rows[rowUsed++];
    assert(!strcmp(r->event,name)&&r->value==value);
    assert(r->reads==reads&&r->polls==polls&&r->frames==frames&&r->cpu==cpu&&r->paused==paused);
}
@interface PauseView : AstroView
@end
@implementation PauseView
- (uint32_t)currentGameTick {
    if(!observing)return [super currentGameTick];
    assert(rowUsed<rowCount&&!strcmp(rows[rowUsed].event,"clock"));
    uint32_t value=(uint32_t)rows[rowUsed].value;reads++;
    boundary("clock",(int32_t)value,observedWallTick,paused);return value;
}
- (uint32_t)playerClockTick {
    if(!observing)return [super playerClockTick];
    if(mode==1){assert(gameReads<7);return waitClocks[gameReads++];}
    if(mode==2){assert(gameReads<2);return gameReads++?281:105;}
    assert(mode==3&&gameReads++==0);return 100;
}
- (void)display {
    if(observing&&!inTransition){frames++;boundary("world",0,observedWallTick,paused);}
}
- (void)drawPanelTransition {
    if(observing)transitions++;
    inTransition=YES;@try {[super drawPanelTransition];} @finally {inTransition=NO;}
}
- (void)copyKeyMap:(unsigned char *)bytes {
    if(!observing){[super copyKeyMap:bytes];return;}
    memset(bytes,0,16);
    if(!pauseLoopRunning){outerReads++;bytes[6]=0x20;return;}
    polls++;boundary("keys",0,observedWallTick,paused);
    if(polls>scenario/3){
        if(scenario==6){bytes[6]=0x80;bytes[1]=0x10;}
        else if(scenario/3==0)bytes[6]=0x20;
        else bytes[0]=1;
    }
}
- (void)pumpPauseEvents {
    boundary("mouse",0,observedWallTick,paused);
    if(polls){unsigned any=0;for(unsigned i=0;i<128;i++)any+=keys[i];assert(any==(unsigned)rows[rowUsed-1].any);}
    unsigned before=rowUsed;[self tickWallClock];[self tick:nil];assert(rowUsed==before);
}
- (void)makeNewSprites {if(observing)factories++;else [super makeNewSprites];}
- (void)pollMapSpawns {if(observing)factories++;else [super pollMapSpawns];}
@end
@implementation AstroView (PauseCheck)
- (void)preparePauseCase:(unsigned)number path:(const char *)path {
    observing=NO;[timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    selftestPath=campaignTestPath=nil;
    FILE *f=fopen(path,"r");assert(f);char line[512];assert(fgets(line,sizeof(line),f));rowCount=0;
    while(fgets(line,sizeof(line),f)){
        unsigned id,quit,hudDirty;PauseRow r;
        assert(sscanf(line,"%u,%23[^,],%d,%u,%u,%u,%u,%d,%d,%u,%u",&id,r.event,&r.value,
            &r.reads,&r.polls,&r.frames,&r.cpu,&r.paused,&r.any,&quit,&hudDirty)==11);
        if(id!=number)continue;
        if(!strcmp(r.event,"clock")||!strcmp(r.event,"world")||!strcmp(r.event,"keys")||!strcmp(r.event,"mouse")){
            assert(rowCount<128);rows[rowCount++]=r;
        }
    }
    assert(!ferror(f));fclose(f);assert(rowCount);
    reads=polls=frames=transitions=rowUsed=outerReads=factories=gameReads=0;mode=0;scenario=number%8;
    menuVisible=paused=splashVisible=changingStage=pauseLoopRunning=gameOverPending=NO;gameOver=scenario==7;
    flow.phase=ASTRO_FLOW_PLAY;editingKey=-1;respawnTick=invulnerableUntil=0;
    observedWallTick=number<8?100:UINT32_MAX-3;ui.frameInterval=scenario%3+1;
    simulationTick=42;worldRenderTick=77;lastSpawnTick=66;randomSeed=0x12345678;world=[NSMutableArray array];enemies=[NSMutableArray array];
    memset(keys,0,sizeof(keys));keys[53]=YES;observing=YES;
}
- (void)assertPauseComplete {
    assert(rowUsed==rowCount&&frames==scenario/3+1&&polls==frames);
    assert(transitions==(scenario==7?1:2)&&!paused&&!menuVisible&&!pauseLoopRunning);
    assert(simulationTick==42&&randomSeed==0x12345678&&worldRenderTick==77&&lastSpawnTick==66);
}
- (void)checkPause:(const char *)path {
    for(unsigned c=0;c<16;c++){
        [self preparePauseCase:c path:path];[self handleMiscKeys];[self assertPauseComplete];
        assert(!outerReads&&!gameReads&&!factories);
    }
    puts("PASS16 native pause frame/clock/key/mouse projections, held/delayed keys, intervals/wrap, deferred exit and timer reentry guard");
    // Actual callers must continue after PAUSE without repeating a world/factory step.
    [self preparePauseCase:0 path:path];mode=1;respawnTick=1;respawnWaitStartTick=100;
    inventory=(AstroInventory){40,3,2,2};playerWeapon=43;[self pollRespawnWait];
    assert(rowUsed==rowCount&&outerReads==1&&gameReads==7&&!respawnTick&&invulnerableUntil);
    assert(!factories&&world.count==1&&playerState.update_tick==170&&respawnStartTick==180&&respawnBlinkTick==182);
    assert(inventory.upgrade==0&&playerWeapon==40&&!paused&&!pauseLoopRunning);
    [self preparePauseCase:0 path:path];mode=2;invulnerableUntil=1;respawnStartTick=respawnBlinkTick=100;
    playerCombat.kind=-1;[self pollRespawnBlink];
    assert(rowUsed==rowCount&&outerReads==1&&gameReads==2&&factories==1&&!invulnerableUntil&&playerCombat.kind==1);
    [self preparePauseCase:0 path:path];mode=3;[self pollGame];[self assertPauseComplete];
    assert(gameReads==1&&outerReads==1&&factories==1);
    [self preparePauseCase:0 path:path];[self readSpecialKeys];assert(outerReads==1&&!rowUsed&&!transitions&&!paused);
    puts("PASS actual WAIT/blink/outer-loop continuations; special key poll does not enter PAUSE");
    observing=NO;
}

@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);alarm(30);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[PauseView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkPause:argv[2]];
}}
