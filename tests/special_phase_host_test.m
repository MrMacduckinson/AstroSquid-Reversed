// Actual production nested-special orchestration; only GL/audio boundaries observed.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing;
static unsigned innerFrames,presents,outerFrames,animations,beams;
static int expectedGunX,expectedGunY;
static NSMutableString *events;
@interface AstroSpecialPhaseView : AstroView
@end
@implementation AstroSpecialPhaseView
- (void)inheritParentState {if(observing)[events appendString:@"I"];[super inheritParentState];}
- (void)display {if(observing){outerFrames++;[events appendString:@"O"];}}
- (void)renderSpecialWorld {
    assert(observing&&worldRenderTick==simulationTick);
    assert(!specialPolygons.count&&!specialFlashes.count);
    innerFrames++;[events appendString:@"W"];
    // A real world renderer can consume RNG before the special visual tail.
    astro_random(&randomSeed,123);
}
- (void)presentSpecialFrame {
    assert(specialPolygons.count==2&&specialFlashes.count==5);
    presents++;[events appendString:@"P"];
}
- (void)updateVisualEffects {
    if(observing){animations++;[events appendString:@"L"];if(suspendedSpecialTail)assert(playerCombat.kind==-1);}
    [super updateVisualEffects];
}
- (void)addSpecialBeam:(const AstroBeam *)beam temporary:(int)temporary context:(BeamContext *)context {
    if(observing){assert(beam->x==expectedGunX&&beam->y==expectedGunY);beams++;[events appendString:@"B"];}
    [super addSpecialBeam:beam temporary:temporary context:context];
}
@end
@interface AstroView (SpecialPhaseCheck)
- (void)checkSpecialPhases;
@end
@implementation AstroView (SpecialPhaseCheck)
- (void)checkSpecialPhases {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    selftestPath=@"special-phase-check";campaignTestPath=selftestPath;
    int intervals[]={2,3,0,-1,3};
    for(unsigned scenario=0;scenario<sizeof(intervals)/sizeof(intervals[0]);scenario++){
        [self resetEnemies];[enemies removeAllObjects];[mapPlacements removeAllObjects];
        world=[NSMutableArray arrayWithObject:[NSNull null]];
        backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));
        memset(keys,0,sizeof(keys));changingStage=NO;campaignAction=ASTRO_CAMPAIGN_NONE;
        flow.phase=ASTRO_FLOW_PLAY;menuVisible=NO;paused=gameOver=gameOverPending=NO;
        camera=0;tickedScroll=0;simulationTick=100;worldRenderTick=scenario==0?99:100;
        ui.frameInterval=intervals[scenario];playerWeapon=40;inventory.specials=1;
        lastPlayerShot=0;respawnTick=0;invulnerableUntil=scenario==4?999:0;
        playerVisual=(AstroVisual){1,100,180,71,20,100};
        playerX=playerEntityX=100;playerY=playerEntityY=180;
        playerBounds=(AstroRect){100,180,171,200};previousPlayerBounds=playerBounds;
        playerCombat=(AstroCombatState){.kind=1,.hit_points=200};
        playerState=(AstroPlayer){.frame=12,.tilt=3,.state=1,.update_tick=100,.animation_tick=100};
        playerVelocity=(AstroVelocity){2,0};randomSeed=12345;
        innerFrames=presents=outerFrames=animations=beams=0;events=[NSMutableString string];
        keys[58]=YES;observing=YES;[self calculateActors];[self renderTick];
        assert(special.active&&suspendedSpecialTail&&!events.length);
        for(unsigned step=0;step<31;step++){
            expectedGunX=playerBounds.left+74-15;expectedGunY=playerBounds.top+12+1;
            uint32_t now=simulationTick+1;BOOL due=(int32_t)(now-worldRenderTick)>=ui.frameInterval;
            NSMutableString *expected=[NSMutableString stringWithString:@"IB"];
            if(due)[expected appendString:@"WP"];[expected appendString:@"L"];
            if(step==30){[expected appendString:@"I"];if(ui.frameInterval<=0)[expected appendString:@"O"];[expected appendString:@"L"];}
            [events setString:@""];[self stepEnemies];[self renderTick];
            assert([events isEqual:expected]);
            if(step==0)assert(playerBounds.left!=100);
        }
        observing=NO;
        assert(!special.active&&!suspendedSpecialTail&&playerCombat.kind==1);
        assert(beams==31&&animations==32&&innerFrames==presents);
        assert(outerFrames==(ui.frameInterval<=0?1u:0u));
        printf("PASS actual host special interval%d: pre-CALC gun, shared render deadline, inner/outer LM and terminal resume\n",ui.frameInterval);
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroSpecialPhaseView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkSpecialPhases];
}}
