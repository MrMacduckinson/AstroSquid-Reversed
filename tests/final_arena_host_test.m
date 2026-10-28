// Native tag-2 tail invariants, plus actual cleanup/map/spawn integration.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSMutableString *events;static BOOL observing,realMap;static unsigned clocks;
@interface ArenaAudio:AstroAudio
@end
@implementation ArenaAudio
- (void)stopMusic {[events appendString:@"S"];}
- (BOOL)playMusic:(int)track {assert(track==2);[events appendString:@"P"];return YES;}
@end
@interface ArenaView:AstroView
@end
@implementation ArenaView
- (uint32_t)playerClockTick {return observing?100+clocks++:[super playerClockTick];}
- (BOOL)appendDebugMessage:(NSString *)message {if(observing){assert([message isEqual:@"0"]);[events appendString:@"D"];}return YES;}
- (void)loadLevelMap {
    if(observing){assert(!mapPlacements.count&&camera==0&&campaign.level==8&&campaign.half==2);[events appendString:@"L"];}
    if(realMap)[super loadLevelMap];
}
@end
@implementation AstroView(ArenaCheck)
- (AstroEnemy *)prepareArena:(double)cameraValue {
    camera=cameraValue;campaign=(AstroCampaign){8,2,1,0};finalArena=NO;campaignAction=ASTRO_CAMPAIGN_NONE;
    selectedLevel=[levels indexOfObject:@"Data 8B"];starsInitialized=YES;
    world=[NSMutableArray arrayWithObject:[NSNull null]];enemies=[NSMutableArray array];mapPlacements=[NSMutableArray arrayWithObject:@{}];
    visualEffects=[NSMutableArray array];renderClock=77;playerRenderBirth=42;
    playerVisual=(AstroVisual){1,100,90,30,20,321};playerEntityX=103;playerEntityY=93;
    playerState=(AstroPlayer){{3,-2},12,2,3,101,102};playerVelocity=(AstroVelocity){3,-2};
    playerCombat=(AstroCombatState){.kind=1,.hit_points=73};inventory=(AstroInventory){50,3,7,4};playerWeapon=53;
    playerBounds=(AstroRect){100,90,130,110};previousPlayerBounds=(AstroRect){99,89,129,109};
    playerHitVisual=(AstroPlayerHitVisual){0};engineGlow=departureTrail=NO;
    AstroEnemy *enemy=[AstroEnemy new];enemy->placement=@{@"tag":@0};enemy->visual=(AstroVisual){1,200,80,40,30,543};
    enemy->state=(AstroScriptState){.x=203,.y=83,.update_tick=11,.animation_tick=12,.action_tick=13,.velocity={4,5}};
    enemy->bounds=(AstroRect){200,80,240,110};enemy->renderLayer=5;enemy->renderBirth=43;enemy->hitPoints=71;
    [world addObject:enemy];[enemies addObject:enemy];return enemy;
}
- (void)checkFinalArena {
    [timer invalidate];timer=nil;[audio stop];audio=[ArenaAudio new];observing=YES;
    double cameras[]={0,1234.25,-42.5};
    for(int c=0;c<3;c++)for(int music=0;music<3;music++){
        realMap=NO;clocks=0;[events setString:@""];AstroEnemy *enemy=[self prepareArena:cameras[c]];
        enemy->renderLayer=c+1;
        playerHitVisual.active=YES;playerHitVisual.visual.x=500;playerHitLayer=c+1;
        engineGlow=departureTrail=YES;engineGlowRect.x=600;trailRect.x=700;
        campaign.complete=1;campaignAction=ASTRO_CAMPAIGN_COMPLETE;
        ui.musicVolume=music/2.0;AstroScriptState expected=enemy->state;expected.x-=camera;
        AstroPlayer oldPlayer=playerState;AstroCombatState oldCombat=playerCombat;AstroInventory oldInventory=inventory;
        AstroRect bounds=playerBounds,previous=previousPlayerBounds;id oldWorld=world,oldEnemies=enemies;
        LiveEffect keep={{2,300,10,5,6,222},8,44},remove={{2,400,10,5,6,333},2,45};
        NSMutableData *effect=[NSMutableData dataWithBytes:&keep length:sizeof(keep)];[visualEffects addObject:effect];
        [visualEffects addObject:[NSMutableData dataWithBytes:&remove length:sizeof(remove)]];
        [self enterFinalArena];
        assert([events isEqual:music?@"SPDL":@"SDL"]&&clocks==0&&world==oldWorld&&enemies==oldEnemies);
        assert(world.count==2&&world.lastObject==enemy&&playerRenderBirth==42&&renderClock==77);
        assert(playerVisual.x==100-cameras[c]&&playerEntityX==103-cameras[c]&&enemy->visual.x==200-cameras[c]);
        assert(!memcmp(&enemy->state,&expected,sizeof(expected))&&!memcmp(&playerState,&oldPlayer,sizeof(oldPlayer)));
        assert(!memcmp(&playerCombat,&oldCombat,sizeof(oldCombat))&&!memcmp(&inventory,&oldInventory,sizeof(oldInventory)));
        assert(!memcmp(&playerBounds,&bounds,sizeof(bounds))&&!memcmp(&previousPlayerBounds,&previous,sizeof(previous)));
        assert(playerWeapon==53&&playerVelocity.x==3&&playerVelocity.y==-2&&enemy->hitPoints==71);
        assert(enemy->visualDeleted==(c==1)&&playerHitVisual.active!=(c==1)&&playerHitVisual.visual.x==500-cameras[c]);
        assert(engineGlowRect.x==600-cameras[c]&&trailRect.x==700-cameras[c]);
        assert(visualEffects.count==1&&visualEffects.firstObject==effect&&((LiveEffect *)effect.mutableBytes)->visual.x==300-cameras[c]);
        assert(finalArena&&campaign.level==8&&campaign.half==2&&!campaign.arena&&!campaign.complete&&campaignAction==ASTRO_CAMPAIGN_NONE&&[levels[selectedLevel]isEqual:@"Data 9B"]);
    }
    // Actual death cleanup loads/spawns before returning, without recreating the player.
    [events setString:@""];AstroEnemy *survivor=[self prepareArena:1234.25];ui.musicVolume=1;realMap=YES;clocks=0;
    AstroEnemy *boss=[AstroEnemy new];boss->kind=2;boss->placement=@{@"tag":@-2};boss->definition=@{};
    boss->visual=(AstroVisual){1,500,100,20,20,300};boss->bounds=(AstroRect){500,100,520,120};boss->state.remove=-1;
    [world addObject:boss];[enemies addObject:boss];randomSeed=123;
    uint32_t expectedSeed=123;astro_random(&expectedSeed,20);astro_random(&expectedSeed,20);
    AstroStar expectedStars[3000];memcpy(expectedStars,stars,sizeof(expectedStars));astro_stars_init(expectedStars,0,&expectedSeed);
    [self cleanupWorld];
    assert([events isEqual:@"SPDL"]&&![world containsObject:boss]&&[world containsObject:survivor]);
    assert([world containsObject:[NSNull null]]&&world.count==20&&enemies.count==19&&mapPlacements.count==229);
    assert(playerRenderBirth==42&&renderClock==95&&clocks==72&&playerCombat.hit_points==73&&playerWeapon==53);
    assert(randomSeed==expectedSeed&&!memcmp(stars,expectedStars,sizeof(expectedStars)));
    assert(campaign.level==8&&campaign.half==2&&campaignAction==ASTRO_CAMPAIGN_NONE&&finalArena);
    assert(playerVisual.x==100-1234.25&&survivor->visual.x==200-1234.25);
    campaign.complete=1;[self beginStageTransition];
    assert(campaign.level==8&&campaign.half==2&&pendingCampaign.level==9&&pendingCampaign.half==1&&pendingCampaign.complete);
    transition.phase=ASTRO_TRANSITION_CARD;astro_flow_stage_end(&flow,8,2,9,1,1);
    assert(astro_flow_picture(&flow)==68);[self advanceFlowWithKey:YES];
    assert(flow.phase==ASTRO_FLOW_ENDING&&campaign.level==9&&campaign.half==1&&campaign.complete&&!world.count);
    observing=NO;puts("PASS9 native final-arena tail cases and actual tag-2 cleanup: preserved player/actor bytes, cached bounds, effects, music/load order,18 new map actors,72 constructor clocks and exact RNG/stars");
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    events=[NSMutableString string];ArenaView *view=[[ArenaView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkFinalArena];
}}
