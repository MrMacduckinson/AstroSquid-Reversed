// Actual production cleanup/death/map path; compare with the original native composite.
#define ASTRO_WORLD_TRACE_LIBRARY
#include "world_trace_host.m"
static unsigned compositeClocks;
@interface CompositeArenaAudio:AstroTraceAudio
@end
@implementation CompositeArenaAudio
- (void)stopMusic {puts("A\tstop");}
- (BOOL)playMusic:(int)track {assert(track==2);puts("A\tplay2");return YES;}
@end
@interface CompositeArenaView:AstroTraceView
@end
@implementation CompositeArenaView
- (uint32_t)playerClockTick {compositeClocks++;return 100;}
@end
@implementation AstroView(CompositeArena)
- (void)runCompositeArena {
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
    compositeClocks=0;tracePhase="cleanup";[self cleanupWorld];[self dumpWorldTrace:@"cleanup"];
    fprintf(stderr,"HOST finalarena composite clocks%u RNG%08x entities%u images%llu backgrounds%lu\n",compositeClocks,randomSeed,nextEntityID,(unsigned long long)renderClock,(unsigned long)backgrounds.count);
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    CompositeArenaView *view=[[CompositeArenaView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view runCompositeArena];
}}
