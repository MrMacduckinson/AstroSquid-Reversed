// Replay the original Main schedules through Root; OS time/events and drawing are observers.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned profile,reads,frames,queued,clockStep,mixedConsumed;
static BOOL recording,mixedMode,finished;
static void record(char kind,unsigned value){printf("%u,%c,%u,%u,%u,%u\n",profile,kind,value,reads,frames,queued);}
static uint32_t traceTick(void){if(!recording)return 1000;uint32_t value=1000+reads++*clockStep;if(reads>=80)finished=YES;record('T',value);return value;}
@interface MainQueueApplication:AstroApplication @end
@implementation MainQueueApplication
- (NSEvent *)nextEventMatchingMask:(NSEventMask)mask untilDate:(NSDate *)date inMode:(NSRunLoopMode)mode dequeue:(BOOL)dequeue {
 if(!recording)return [super nextEventMatchingMask:mask untilDate:date inMode:mode dequeue:dequeue];
 assert(dequeue&&[mode isEqual:NSDefaultRunLoopMode]&&(mask==NSEventMaskKeyDown||mask==NSEventMaskAny));
 BOOL field=mask==NSEventMaskKeyDown;unsigned ch;BOOL repeat=NO;
 if(mixedMode){
  unsigned i;for(i=0;i<3;i++)if(!(mixedConsumed&(1u<<i))&&(!field||i))break;
  if(i==3)return nil;mixedConsumed|=1u<<i;queued++;ch=i?('A'+i-1):'M';record(field?'F':'P',ch);
  if(!i)return [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:0];
 }else {assert(queued<128);repeat=queued%2;ch='A'+queued++%26;record(field?'F':'P',ch);}
 NSString *text=[NSString stringWithFormat:@"%c",ch];
 return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:text charactersIgnoringModifiers:text isARepeat:repeat keyCode:0];
}
- (void)sendEvent:(NSEvent *)event {if(recording){assert(mixedMode&&event.type==NSEventTypeLeftMouseUp);return;}[super sendEvent:event];}
@end
@interface MainQueueAudio:AstroAudio @end
@implementation MainQueueAudio
- (void)serviceMusic {}
- (void)stop {}
@end
@interface MainQueueView:AstroView
- (void)checkSchedules;
@end
@implementation MainQueueView
- (uint32_t)currentGameTick {return traceTick();}
- (uint32_t)cardDelayClockTick {return traceTick();}
- (void)copyKeyMap:(unsigned char *)map {memset(map,0,16);}
- (BOOL)menuMouseButtonPressed {return NO;}
- (NSPoint)currentMenuMousePoint {return NSMakePoint(-30000,-30000);}
- (void)stepMenu {assert(recording);frames++;record('W',0);}
- (void)checkSchedules {
 [timer invalidate];timer=nil;[audio stop];audio=[MainQueueAudio new];
 menuVisible=YES;splashVisible=paused=gameOver=gameLoopActive=NO;editingKey=-1;
 [ui show:@"Register Menu"];while(ui.transitioning)[ui advanceMenuCamera];
 const uint32_t serviceTicks[]={1000,940,0};const short intervals[]={1,2,3,1000};
 const uint32_t idleDeadlines[]={1000,1200,0x7fffffffu,0x80000000u};
 for(unsigned idle=0;idle<(mixedMode?4u:1u);idle++)for(unsigned seed=0;seed<3;seed++)for(unsigned focus=0;focus<3;focus++)for(unsigned interval=0;interval<4;interval++)for(clockStep=0;clockStep<3;clockStep++){
  [queuedKeyEvents removeAllObjects];memset(keys,0,sizeof(keys));[ui resetRegistrationFields];
  AstroScoreEditor *fields=[ui registrationFields];fields[1].submitted=0;ui.activeRegistrationField=(NSInteger)focus-1;
  ui.frameInterval=intervals[interval];observedWallTick=mixedMode?999:1000;lastMainEventTick=serviceTicks[seed];mainMenuFrames=mainMenuRate=0;mainIdleTimerTick=idleDeadlines[idle];
  reads=frames=queued=mixedConsumed=0;finished=NO;recording=YES;
  do {[self pollMainMenu];}while(!finished);
  recording=NO;assert(reads>=80&&reads<86&&!queuedKeyEvents.count);
  printf("%u,Z,%u,%u,%u,%u,%u,%u,%u,",profile,reads,frames,queued,observedWallTick,lastMainEventTick,mainMenuFrames,mainMenuRate);
  if(focus)for(const unsigned char *p=(const unsigned char *)fields[focus-1].name;*p;p++)printf("%02x",*p);putchar('\n');if(mixedMode)printf("%u,I,%u\n",profile,mainIdleTimerTick);profile++;
 }
 [self releaseGraphics];fprintf(stderr,"PASS %u actual Root Main queue schedules (%s), deterministic OS inputs and drawing observers\n",profile,mixedMode?"idle":"generated");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==2||argc==3);mixedMode=argc==3;assert(!mixedMode||!strcmp(argv[2],"idle"));
 [MainQueueApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 MainQueueView *view=[[MainQueueView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkSchedules];
}}
