#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSMutableArray *calls;
@interface TriggerAudio:AstroAudio
@end
@implementation TriggerAudio
- (void)stopMusic {[calls addObject:@"stop"];}
- (BOOL)playMusic:(int)number {assert(number==3);[calls addObject:@"play3"];return YES;}
@end
@implementation AstroView(TriggerMusicCheck)
- (void)checkTriggerMusic {
 [timer invalidate];timer=nil;audio=[TriggerAudio new];simulationTick=0;changingStage=NO;
 for(int tag=-1;tag<=1;tag++)for(int setting=0;setting<=10;setting++){
  [calls removeAllObjects];ui.musicVolume=setting/10.0;campaign=(AstroCampaign){1,1,0,0};
  AstroEnemy *trigger=[AstroEnemy new];trigger->placement=@{@"attribute":@399,@"tag":@(tag)};trigger->kind=39;trigger->subtype=9;trigger->state=(AstroScriptState){0};
  [self stepActor:trigger];NSArray *expected=tag==-1?@[]:setting?@[@"stop",@"play3"]:@[@"stop"];
  assert([calls isEqual:expected]&&trigger->state.remove==(tag!=-1));
 }
 puts("PASS33 actual host trigger399 cases match native stop/play3 gate for tags and music0..10");
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];calls=[NSMutableArray array];AstroView *view=[[AstroView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkTriggerMusic];return 0;
}}
