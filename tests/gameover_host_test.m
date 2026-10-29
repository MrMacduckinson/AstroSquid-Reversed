// Real host GameOver sequencing with deterministic OS clock/Delay and no drawing.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static uint32_t controlledTick=100;
static NSMutableString *events;
static unsigned delays,worldFrames,panelFrames,flushes,clockReads;
static BOOL observing;
@interface AstroGameOverView : AstroView
@end
@implementation AstroGameOverView
- (uint32_t)currentGameTick {if(observing)clockReads++;return controlledTick;}
- (void)delayGameTicks:(uint32_t)ticks {
    static const unsigned expected[]={0,1,1,2,3,3,4,4,5,6};
    assert(delays<10&&ticks==expected[delays++]);controlledTick+=ticks;[events appendString:@"D"];
}
- (void)cleanupWorld {if(observing)[events appendString:@"C"];[super cleanupWorld];}
- (void)calculateActors {if(observing)[events appendString:@"A"];[super calculateActors];}
- (void)updateVisualEffects {if(observing)[events appendString:@"L"];[super updateVisualEffects];}
- (void)flushGameEvents {flushes++;[super flushGameEvents];}
- (void)display {
    if(!observing)return;
    assert(ui.editingHighscore==0);
    if(menuVisible){panelFrames++;[events appendString:@"P"];}else{worldFrames++;[events appendString:@"R"];}
}
@end
@interface AstroView (GameOverCheck)
- (void)checkGameOverSequence;
@end
@implementation AstroView (GameOverCheck)
- (void)checkGameOverSequence {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    selftestPath=@"controlled-gameover";campaignTestPath=selftestPath;
    world=[NSMutableArray array];enemies=[NSMutableArray array];visualEffects=[NSMutableArray array];
    specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));
    special=(AstroSpecial){0};specialLoopRunning=NO;changingStage=NO;camera=0;tickedScroll=1;
    randomSeed=42;score=12345;astro_scores_clear(highscores);flow.phase=ASTRO_FLOW_PLAY;
    scoreKeyEvents=[NSMutableData dataWithBytes:"stale" length:5];
    events=[NSMutableString string];observing=YES;[self beginGameOver];observing=NO;assert(!scoreKeyEvents.length&&flushes==1);
    NSMutableString *expected=[NSMutableString string];for(int i=0;i<10;i++)[expected appendString:@"CALRD"];
    for(int i=0;i<60;i++)[expected appendString:@"P"];
    assert([events isEqual:expected]);assert(delays==10&&worldFrames==10&&panelFrames==60);
    assert(controlledTick==129&&simulationTick==129&&camera==10&&randomSeed==42);
    assert(gameOver&&menuVisible&&!gameOverPending&&!ui.transitioning&&ui.editingHighscore==1&&ui.editingCaretVisible);
    puts("PASS actual GameOver cleanup/calc/animate/render/Delay order,29clockticks,60panelredraws and field enabled last");
    unsigned qualifyingReads=clockReads;
    AstroScoreEditor preserved;memset(&scoreEditor,0x3c,sizeof(scoreEditor));strcpy(scoreEditor.name,"retained");scoreEditor.cursor=7;scoreEditor.submitted=1;preserved=scoreEditor;
    AstroScoreCaret previousCaret;[[ui valueForKey:@"caret"]getValue:&previousCaret];
    NSString *previousName=ui.editingName;NSInteger previousCursor=ui.editingCursor;
    score=0;delays=worldFrames=panelFrames=clockReads=0;camera=0;controlledTick=100;[events setString:@""];
    observing=YES;[self beginGameOver];observing=NO;
    assert(!ui.editingHighscore&&!memcmp(&preserved,&scoreEditor,sizeof(preserved)));
    AstroScoreCaret afterCaret;[[ui valueForKey:@"caret"]getValue:&afterCaret];
    assert(previousCaret.deadline==afterCaret.deadline&&previousCaret.visible==afterCaret.visible);
    assert([previousName isEqual:ui.editingName]&&previousCursor==ui.editingCursor);
    assert(clockReads+1==qualifyingReads&&delays==10&&worldFrames==10&&panelFrames==60&&flushes==2);
    puts("PASS nonqualifying GameOver preserves editor/caret and skips exactly one field clock read");
    // Death cleanup must remove the player before queueing the next-loop transition.
    gameOver=NO;gameOverPending=NO;selftestPath=nil;inventory.lives=0;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=0,.remove=-1};
    playerVisual=(AstroVisual){1,100,180,71,20,129};playerY=180;
    playerBounds=(AstroRect){100,180,171,200};playerVelocity=(AstroVelocity){0};
    uint64_t before=renderClock;
    [world addObject:[NSNull null]];[self cleanupWorld];
    uint64_t first=UINT64_MAX;
    for(NSData *data in visualEffects){const LiveEffect *effect=data.bytes;if(effect->birth<first)first=effect->birth;}
    for(AstroEnemy *e in enemies)if(e->renderBirth<first)first=e->renderBirth;
    assert(first==before+1);
    assert(gameOver&&gameOverPending&&![world containsObject:[NSNull null]]&&delays==10);
    puts("PASS actual player death queues GameOver after removal without recursive world processing");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *v=[[AstroGameOverView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(v);[v checkGameOverSequence];
}}
