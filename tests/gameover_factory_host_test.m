// Actual Data B1 transition geometry through the root mouse handler; no score writes.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSPoint point;
static unsigned factoryCase,reads;
static uint64_t word(double x){uint64_t b;memcpy(&b,&x,8);return b;}
@interface FactoryView:AstroView
- (void)checkFactory;
@end
@implementation FactoryView
- (NSPoint)menuPoint:(NSEvent *)event {return point;}
- (void)display {}
- (void)saveScores {}
- (void)checkFactory {
    [timer invalidate];timer=nil;[audio stop];splashVisible=NO;editingKey=-1;
    for(unsigned c=0;c<2;c++){
        factoryCase=c;reads=0;uint32_t tick=c?UINT32_MAX-10:1000;
        ui.readTick=^uint32_t{printf("T,%u,%u,%u\n",factoryCase,reads++,tick);return tick;};
        (void)ui.readTick();[ui show:@"GameOver"];[ui animateTicks:60];[ui prepareScoreField];
        [ui beginScoreClock:ui.readTick()];assert(reads==5);
        NSDictionary *states=[ui valueForKey:@"orbStates"],*deadlines=[ui valueForKey:@"hoverDeadlines"];
        unsigned index=0;for(NSDictionary *object in [ui valueForKey:@"objects"]){
            NSString *name=object[@"name"];AstroUIMotion *state=[states[name] mutableBytes];
            printf("N,%u,%u,",c,index++);NSData *label=[name dataUsingEncoding:NSMacOSRomanStringEncoding];
            const unsigned char *bytes=label.bytes;for(NSUInteger i=0;i<label.length;i++)printf("%02x",bytes[i]);
            printf(",%d,%d,%u,%d,%016llx,%016llx,%016llx,%016llx\n",[object[@"kind"] intValue],state->sprite,[deadlines[name] unsignedIntValue],state->counter,word(state->x),word(state->y),word(state->width),word(state->height));
        }assert(index==3);
        NSRect r=ui.scoreField;AstroScoreCaret caret;[[ui valueForKey:@"caret"] getValue:&caret];assert(caret.deadline==tick+20u);
        printf("F,%u,%016llx,%016llx,%016llx,%016llx,%u\n",c,word(r.origin.x),word(r.origin.y),word(r.size.width),word(r.size.height),caret.deadline);
        assert(r.origin.y<184&&(int)r.origin.y==183);
        gameOver=menuVisible=YES;menuMouseLatched=YES;ui.editingHighscore=1;
        for(int y=250;y<=280;y++){
            astro_score_editor_begin(&scoreEditor);scoreEditor.cursor=77;[self refreshScoreEditor];
            point=NSMakePoint(225,y);[self mouseDown:nil];
            printf("M,%u,%d,%d,%d,%d,%d,%d,%d\n",c,y,scoreEditor.cursor!=77,scoreEditor.cursor,(int)r.origin.x,(int)r.origin.y,(int)r.origin.x+(int)r.size.width,(int)r.origin.y+(int)r.size.height);
            assert((scoreEditor.cursor!=77)==(y>=253&&y<275));
        }
        ui.readTick=nil;[ui beginGameOverExit];
        assert([ui scoreFieldContainsX:225 y:183]&&![ui scoreFieldContainsX:225 y:205]);
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    FactoryView *view=[[FactoryView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkFactory];
}}
