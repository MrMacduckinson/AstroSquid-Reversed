// Actual production cleanup/death/map path; compare with the original native composite.
#define ASTRO_WORLD_TRACE_LIBRARY
#include "world_trace_host.m"
static unsigned compositeClocks;static BOOL advancing,outerFrame;
@interface CompositeArenaAudio:AstroTraceAudio
@end
@implementation CompositeArenaAudio
- (void)stopMusic {puts("A\tstop");}
- (BOOL)playMusic:(int)track {assert(track==2);puts("A\tplay2");return YES;}
@end
@interface CompositeArenaView:AstroTraceView
@end
@implementation CompositeArenaView
- (uint32_t)playerClockTick {unsigned index=compositeClocks++;return 100+(advancing&&tracePhase&&strcmp(tracePhase,"before")?index:0);}
- (void)renderTick {if(!outerFrame)[super renderTick];}
@end
@implementation AstroView(CompositeArena)
- (void)runCompositeArena:(const char *)phaseOutput {
    [timer invalidate];timer=nil;[audio stop];audio=[[CompositeArenaAudio alloc]initWithAssets:assetPath error:NULL];assert(audio);
    entityIDs=[NSMapTable strongToStrongObjectsMapTable];nextEntityID=1;playerTraceID=1;
    world=[NSMutableArray array];enemies=[NSMutableArray array];visualEffects=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];starsInitialized=YES;renderClock=0;simulationTick=100;
    campaign=(AstroCampaign){8,2,0,0};inventory=(AstroInventory){0};selectedLevel=[levels indexOfObject:@"Data 8B"];
    randomSeed=123;camera=0;tickedScroll=0;[self createPlayerAtX:1400 y:180];playerCombat=(AstroCombatState){.kind=1,.hit_points=73};playerState.frame=1;
    for(int i=0;i<2;i++){
        NSDictionary *a=game[@"attributes"][@"73"];int sprite=[a[@"sprite"] intValue];
        AstroEnemy *e=[self entityForPlacement:@{@"attribute":@73,@"x":@(1500+i*100),@"y":@(i?100:180),
            @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height),@"tag":@(i?0:-2)}];
        e->active=YES;if(!i)e->state.remove=-1;else e->hitPoints=71;[self prependEnemy:e];
    }
    camera=1234.25;ui.musicVolume=1;traceTick=100;tracePhase="before";[self dumpWorldTrace:@"before"];
    outerFrame=phaseOutput&&(!strcmp(phaseOutput,"outer")||!strcmp(phaseOutput,"outer64")||!strcmp(phaseOutput,"outer-map256"));
    if(outerFrame){
        campaign.arena=1;observedWallTick=100;compositeClocks=0;tracePhase="outer";[self advanceWorldForWait:NO];[self dumpWorldTrace:@"outer"];
        assert(compositeClocks==211&&camera==1&&randomSeed==0xf8ce7428&&nextEntityID==33&&renderClock==52);
        fprintf(stderr,"HOST outerbody camera%.17g clocks%u RNG%08x entities%u images%llu\n",camera,compositeClocks,randomSeed,nextEntityID,(unsigned long long)renderClock);if(strcmp(phaseOutput,"outer"))for(unsigned step=1;step<(!strcmp(phaseOutput,"outer-map256")?256u:64u);step++){
            char label[32];snprintf(label,sizeof label,"follow%u",step);tracePhase=label;
            [self cleanupWorld];[self calculateActors];[self handleVisualEffects];
            if(!strcmp(phaseOutput,"outer-map256"))[self makeNewSprites];
            [self dumpWorldTrace:[NSString stringWithUTF8String:label]];
        }
        return;
    }
    compositeClocks=0;tracePhase="cleanup";[self cleanupWorld];[self dumpWorldTrace:@"cleanup"];
    fprintf(stderr,"HOST finalarena composite clocks%u RNG%08x entities%u images%llu backgrounds%lu\n",compositeClocks,randomSeed,nextEntityID,(unsigned long long)renderClock,(unsigned long)backgrounds.count);
    if(phaseOutput){
        [world removeAllObjects];[enemies removeAllObjects];[self calculateActors];
        assert(worldTop==0&&signbit(worldTop)&&worldBottom==380);FILE *out=fopen(phaseOutput,"wb");assert(out);
        unsigned char bytes[32];for(unsigned i=0;i<3000;i++){be64(bytes,stars[i].brightness);be64(bytes+8,stars[i].x);be64(bytes+16,stars[i].y);be64(bytes+24,stars[i].speed);assert(fwrite(bytes,1,32,out)==32);}
        const AstroParallax *p=parallaxData.bytes;for(unsigned i=0;i<backgrounds.count;i++){be64(bytes,p[i].x);be64(bytes+8,p[i].y);be32(bytes+16,p[i].depth);assert(fwrite(bytes,1,20,out)==20);}
        assert(!fclose(out));fprintf(stderr,"HOST first CALC star phase RNG%08x\n",randomSeed);
    }
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc>=2&&argc<=4);advancing=argc>=3;if(advancing)assert(!strcmp(argv[2],"advancing"));[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    CompositeArenaView *view=[[CompositeArenaView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view runCompositeArena:argc==4?argv[3]:NULL];
}}
