// Source-backed GAMELOOP10051a68 LOADLEVEL/GETREADY/NEWPLAYERSTART ordering.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL observing,checkingInventory;
static unsigned reads;
static NSMutableString *events;
@interface StageAudioProbe : AstroAudio
@end
@implementation StageAudioProbe
- (void)stopMusic {[events appendString:@"S"];}
- (BOOL)playMusic:(int)track {[events appendString:@"P"];return YES;}
@end
@interface StageReadyView : AstroView
@end
@implementation StageReadyView
- (uint32_t)playerClockTick {if(checkingInventory)assert(inventory.weapon==40&&inventory.upgrade==3&&playerWeapon==43);return observing?1000+reads++:[super playerClockTick];}
- (void)display {}
- (void)pollMapSpawns {}
- (void)loadCampaignStage:(AstroCampaign)next {if(observing)[events appendString:@"L"];[super loadCampaignStage:next];}
- (void)makeNewSprites {if(observing)[events appendString:@"M"];[super makeNewSprites];}
- (void)createPlayerAtX:(double)x y:(double)y {if(observing)[events appendString:@"C"];[super createPlayerAtX:x y:y];}
@end
@implementation AstroView (StageReadyCheck)
- (void)checkStageReady {
    [timer invalidate];timer=nil;[audio stop];audio=[StageAudioProbe new];events=[NSMutableString string];
    observing=YES;reads=0;ui.musicVolume=1;selftestPath=nil;campaignTestPath=@"controlled-stage-test";
    selectedLevel=[levels indexOfObject:@"Data 1A"];campaign=(AstroCampaign){1,1,0,0};pendingCampaign=(AstroCampaign){1,2,0,0};
    ui.unlockedLevel=1;
    changingStage=YES;transition=(AstroTransition){.phase=ASTRO_TRANSITION_DONE};
    uint64_t seed=randomSeed;
    [self stepStageTransition];
    assert(flow.phase==ASTRO_FLOW_READY&&readyLoadPending&&reads==0&&randomSeed==seed);
    assert(campaign.level==1&&campaign.half==2&&ui.unlockedLevel==2);
    assert(world.count==0&&enemies.count==0&&mapPlacements.count==0&&playerNextActor==nil&&events.length==0);
    assert([levels[selectedLevel] isEqual:@"Data 1A"]);
    inventory=(AstroInventory){40,3,2,2};playerWeapon=43;
    flow.ticks=58;[self advanceFlowWithKey:YES];assert(reads==0&&events.length==0);
    checkingInventory=YES;[self advanceFlowWithKey:YES];checkingInventory=NO;
    assert([events isEqual:@"SPLMC"]&&flow.phase==ASTRO_FLOW_PLAY&&!readyLoadPending);
    assert([levels[selectedLevel] isEqual:@"Data 1B"]&&reads==4*enemies.count+6);
    unsigned constructor=1000+reads-6;
    assert(playerState.update_tick==constructor&&playerState.animation_tick==constructor+1&&lastPlayerShot==constructor+2);
    assert(playerVisual.next_tick==constructor+3+(uint32_t)spriteInfo[1].delay);
    assert(playerState.tilt==1&&playerState.frame==12&&playerCombat.kind==1&&inventory.weapon==10&&inventory.upgrade==0);
    assert(world.firstObject==[NSNull null]&&playerNextActor==world[1]);
    for(AstroEnemy *enemy in enemies)assert(enemy->state.action_tick<constructor&&enemy->renderBirth<playerRenderBirth);
    // Next A loads before READY; its map clocks and birth order must survive the card.
    reads=0;[events setString:@""];campaign=(AstroCampaign){1,2,0,0};pendingCampaign=(AstroCampaign){2,1,0,0};
    inventory=(AstroInventory){40,3,2,2};playerWeapon=43;score=12345;checkingInventory=YES;
    changingStage=YES;flow=(AstroFlow){.phase=ASTRO_FLOW_END_CARD};transition=(AstroTransition){.phase=ASTRO_TRANSITION_CARD};
    [self advanceFlowWithKey:YES];
    assert(flow.phase==ASTRO_FLOW_READY&&[events isEqual:@"LM"]&&!readyLoadPending);
    assert(campaign.level==2&&campaign.half==1&&ui.unlockedLevel==3);
    assert(![world containsObject:[NSNull null]]&&[levels[selectedLevel] isEqual:@"Data 2A"]&&reads==4*enemies.count);
    NSMutableArray *snapshots=[NSMutableArray array];
    for(AstroEnemy *enemy in enemies)[snapshots addObject:@[[NSData dataWithBytes:&enemy->state length:sizeof(enemy->state)],
        [NSData dataWithBytes:&enemy->visual length:sizeof(enemy->visual)],@(enemy->renderBirth)]];
    unsigned before=reads;seed=randomSeed;[events setString:@""];flow.ticks=59;
    [self advanceFlowWithKey:NO];assert(reads==before&&events.length==0&&randomSeed==seed);
    [self advanceFlowWithKey:YES];checkingInventory=NO;assert([events isEqual:@"SPC"]&&reads==before+6&&randomSeed==seed&&score==12345);
    for(NSUInteger i=0;i<enemies.count;i++){
        AstroEnemy *enemy=enemies[i];NSArray *saved=snapshots[i];
        assert(!memcmp([saved[0] bytes],&enemy->state,sizeof(enemy->state)));
        assert(!memcmp([saved[1] bytes],&enemy->visual,sizeof(enemy->visual)));
        assert([saved[2] unsignedLongLongValue]==enemy->renderBirth);
    }
    // A fresh game keeps the primary BEFORE its card and adds only GAMELOOP clocks after it.
    reads=0;[events setString:@""];ui.unlockedLevel=7;readyLoadPending=YES;[self performMenuAction:@"New Game"];
    assert(initialReadyCard&&!readyLoadPending&&flow.phase==ASTRO_FLOW_READY&&reads==4*enemies.count+6);
    assert(ui.unlockedLevel==7&&campaign.level==1&&campaign.half==1);
    unsigned entryReads=reads;uint64_t birth=playerRenderBirth;uint32_t update=playerState.update_tick;
    [events setString:@""];flow.ticks=59;[self advanceFlowWithKey:YES];
    assert(reads==entryReads+3&&[events isEqual:@"SP"]&&playerRenderBirth==birth&&playerState.update_tick==update);
    ui.unlockedLevel=1;
    [self loadCampaignStage:(AstroCampaign){4,1,0,0}];
    assert(ui.unlockedLevel==1); // LOADLEVEL itself does not unlock a card.
    [self unlockStage];assert(ui.unlockedLevel==7);
    observing=NO;
    puts("PASS source-backed actual stage lifecycle: B after READY, A map before/primary after, independent six player-start clocks, retained map state, initial primary before card");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@1}} forName:NSArgumentDomain];
    AstroView *view=[[StageReadyView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkStageReady];
}}
