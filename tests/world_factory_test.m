// Actual host factories and AI caller; runtime restricted to remote Intel iMac.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static int fired,fireX,fireY,fireWeapon,redraws,alerts;
static NSUInteger operandLeft,operandRight;
@interface AstroFactoryView : AstroView
@end
@implementation AstroFactoryView
- (void)display {redraws++;}
- (BOOL)continueScoreOverflow:(NSData *)left right:(NSData *)right {alerts++;operandLeft=left.length;operandRight=right.length;return YES;}
- (void)fireWeapon:(int)weapon x:(int)x y:(int)y heading:(int)heading source:(int)kind {
    (void)heading;(void)kind;fired++;fireX=x;fireY=y;fireWeapon=weapon;
}
@end
@interface AstroView (FactoryCheck)
- (void)checkOriginalFactories;
@end
@implementation AstroView (FactoryCheck)
- (void)checkOriginalFactories {
    [timer invalidate];timer=nil;selftestPath=@"factory-check";campaignTestPath=selftestPath;
    audio.soundVolume=0;audio.musicVolume=0;[audio setPaused:YES];
    enemies=[NSMutableArray array];world=[NSMutableArray array];camera=200;simulationTick=0;
    AstroEnemy *boss=[self entityForPlacement:@{@"attribute":@151,@"x":@700,@"y":@200,@"width":@125,@"height":@186}];
    boss->active=YES;
    for(simulationTick=1;simulationTick<=3;simulationTick++)[self stepActor:boss];
    assert(fired==1&&fireWeapon==61&&fireX==752&&fireY==283);
    int types[]={44,51,48,55};
    for(int i=0;i<4;i++){
        AstroShot shot={.type=types[i],.x=300,.y=200,.heading=0};
        [self spawnShot:&shot source:5];AstroEnemy *e=enemies[0];
        assert(e->kind==5&&e->renderLayer==6&&e->layer==2);
    }
    AstroDeathEffect effect={.type=ASTRO_EFFECT_DEBRIS,.kind=20,.attribute=201,
        .x=300,.y=200,.width=24,.height=25,.frame=1};
    [self emitDeathEffect:&effect];AstroEnemy *debris=enemies[0];
    assert(debris->kind==20&&debris->renderLayer==6&&debris->layer==0);
    AstroEnemy *scenery=[self entityForPlacement:@{@"attribute":@201,@"x":@0,@"y":@0,@"width":@24,@"height":@25}];
    assert(scenery->kind==20&&scenery->renderLayer==4&&scenery->layer==2);
    astro_score_editor_begin(&scoreEditor);memset(scoreEditor.name,'A',255);scoreEditor.name[255]=0;scoreEditor.cursor=255;
    assert([self editScoreByte:'B']&&alerts==1&&operandLeft==255&&operandRight==1);
    assert(scoreEditor.cursor==256&&strlen(scoreEditor.name)==255&&!scoreEditor.alert);
    scoreEditor.cursor=128;
    assert([self editScoreByte:'B']&&alerts==2&&operandLeft==129&&operandRight==127);
    assert(scoreEditor.cursor==129&&strlen(scoreEditor.name)==255&&!scoreEditor.alert);
    assert([[self scoreOperandDescription:[NSData dataWithBytes:"ABC" length:3]] isEqual:@"\"ABC\" (length 3)"]);
    puts("PASS actual host score overflow resolves before accepting another byte, with original operand lengths");
    uint32_t stopped=simulationTick;uint32_t seed=randomSeed;
    paused=YES;menuVisible=YES;[ui show:@"Pause"];redraws=0;
    [self drawPanelTransition];assert(redraws==30&&paused&&menuVisible&&!ui.transitioning);
    [self resumePause];assert(redraws==60&&!paused&&!menuVisible);
    assert(simulationTick==stopped&&randomSeed==seed);
    puts("PASS actual host Pause entry/resume:30+30 redraws, frozen world clock/RNG");
    puts("PASS actual host scaled boss turret and creation-time projectile/debris/scenery layers vs original native fixtures");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSDictionary *muted=@{@"AstroSquidSettings":@{@"smooth":@YES,@"sound":@0,@"music":@0}};
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:muted forName:NSArgumentDomain];
    AstroView *v=[[AstroFactoryView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(v);[v checkOriginalFactories];
}}
