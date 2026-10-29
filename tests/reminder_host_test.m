// Compare the actual reminder loop with the six original PPC traces.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSMutableString *events;
static unsigned testCase,polls,exitPoll,draws,returns;
static BOOL mouseExit,recording;
@interface ReminderAudio : AstroAudio
@end
@implementation ReminderAudio
- (void)stopMusic {}
- (BOOL)playMusic:(int)track {return YES;}
- (void)serviceMusic {if(recording)[events appendFormat:@"%u,music\n",testCase];}
@end
@interface ReminderView : AstroView
@end
@implementation ReminderView
- (void)display {}
- (void)drawRegistrationReminder {draws++;if(recording)[events appendFormat:@"%u,swap\n",testCase];}
- (void)delayGameTicks:(uint32_t)ticks {assert(ticks==300);if(recording)[events appendFormat:@"%u,delay,%u\n",testCase,ticks];}
- (void)readKeyMap {
    polls++;memset(keys,0,sizeof(keys));keys[12]=YES; // unrelated key must never accept
    keys[controlKeys[0]]=(!mouseExit&&polls>=exitPoll);
    if(recording)[events appendFormat:@"%u,keys\n",testCase];
}
- (BOOL)menuMouseButtonPressed {
    assert(polls<=exitPoll);if(recording)[events appendFormat:@"%u,button\n",testCase];
    return mouseExit&&polls>=exitPoll;
}
- (void)beginGameLoop {returns++;}
@end
@implementation AstroView (ReminderCheck)
- (void)checkReminder:(NSString *)reference {
    [timer invalidate];timer=nil;[audio stop];audio=[ReminderAudio new];
    controlKeys[0]=49;events=[NSMutableString string];recording=YES;
    for(testCase=0;testCase<6;testCase++){
        polls=0;exitPoll=testCase%3+1;mouseExit=testCase>=3;paused=YES;gameEndRequested=NO;
        [self showRegistrationReminder];assert(!paused&&gameEndRequested&&polls==exitPoll);
        [events appendFormat:@"%u,return,%u,%u\n",testCase,polls,polls];
    }
    NSError *error=nil;NSString *expected=[NSString stringWithContentsOfFile:reference encoding:NSUTF8StringEncoding error:&error];
    assert(expected&&!error&&[events isEqual:expected]);recording=NO;
    // Registered/unregistered boundaries through actual READY acceptance and continuation.
    for(int registered=0;registered<2;registered++)for(int stage=1;stage<=9;stage++)for(int half=1;half<=2;half++){
        ui.registered=registered;initialReadyCard=YES;paused=NO;gameEndRequested=NO;
        astro_flow_ready(&flow,stage,half);flow.ticks=59;polls=draws=returns=0;exitPoll=1;mouseExit=NO;
        [self advanceFlowWithKey:NO];assert(draws==0&&returns==0&&flow.phase==ASTRO_FLOW_READY);
        [self advanceFlowWithKey:YES];BOOL reminder=!registered&&(stage-1)*2+half>6;
        assert(draws==reminder&&gameEndRequested==reminder&&returns==1&&flow.phase==ASTRO_FLOW_PLAY);
    }
    puts("PASS reminder: six native event traces; unrelated key ignored; mouse sampled even with fire; 36 registration/stage gates and ready continuation");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[ReminderView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkReminder:[NSString stringWithUTF8String:argv[2]]];
}}
