// Actual mouseDown/UI hit routing and state at first terminal draw; no persistent scores.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned mouse_case,displays;
static NSPoint mousePoint;
static BOOL observing;
static const short points[][2]={{381,292},{445,356},{380,292},{446,292},{381,291},{381,357},{400,320}};
@interface MouseAudio:AstroAudio
@end
@implementation MouseAudio
- (BOOL)playCue:(NSString *)name {return [self playCue:name position:NAN];}
- (BOOL)playCue:(NSString *)name position:(double)pan {assert([name isEqual:@"Click"]);uint64_t bits;memcpy(&bits,&pan,8);if(observing)printf("%u,S,%016llx\n",mouse_case,bits);return YES;}
- (void)stop {}
@end
@interface MouseView:AstroView
- (void)checkMouse;
- (void)recordMouseState;
@end
@implementation MouseView
- (NSPoint)menuPoint:(NSEvent *)event {return mousePoint;}
- (void)recordMouseState {printf("%u,Z,%d,%d,%d\n",mouse_case,!ui.gameOverClosing,gameEndRequested,ui.editingHighscore>0);}
- (void)display {if(observing&&!displays++)[self recordMouseState];}
- (void)saveScores {}
- (void)checkMouse {
    [timer invalidate];timer=nil;[audio stop];audio=[MouseAudio new];splashVisible=NO;editingKey=-1;
    for(unsigned focus=0;focus<2;focus++)for(unsigned p=0;p<sizeof(points)/sizeof(points[0]);p++,mouse_case++){
        [ui show:@"GameOver"];[ui animateTicks:60];
        NSArray *objects=[ui valueForKey:@"objects"];[ui setValue:[objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@",@"GameOverOK"]] forKey:@"objects"];
        assert([ui clickPosition:@"GameOverOK"]==381./640&&isnan([ui clickPosition:@"missing"]));ui.editingHighscore=focus;ui.editingName=@"TEST";
        gameOver=menuVisible=YES;gameEndRequested=gameEndHighscores=NO;menuMouseLatched=NO;deferPresent=NO;score=focus?100:0;astro_scores_clear(highscores);strcpy(scoreEditor.name,"TEST");
        mousePoint=NSMakePoint(points[p][0],points[p][1]);displays=0;observing=YES;[self mouseDown:nil];observing=NO;
        if(!displays)[self recordMouseState];else assert(displays==2&&gameEndRequested&&!menuVisible&&!gameOver&&!deferPresent);
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    MouseView *view=[[MouseView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkMouse];
}}
