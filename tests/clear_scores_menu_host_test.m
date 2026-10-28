#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned sample,reads;static BOOL observing;
static void hex_name(const char *s){for(;*s;s++)printf("%02x",(unsigned char)*s);}
@interface ClearAudio:AstroAudio
@end
@implementation ClearAudio
- (BOOL)playCue:(NSString *)name position:(double)p {assert([name isEqual:@"Click"]);if(observing){uint64_t b;memcpy(&b,&p,8);printf("P,%u,%016llx\n",sample,b);}return YES;}
- (void)stop {}
@end
@interface ClearView:AstroView
- (void)checkClear;
@end
@implementation ClearView
- (uint32_t)currentGameTick {if(!observing)return 100;uint32_t t=100+reads++;printf("T,%u,%u\n",sample,t);return t;}
- (void)display {
 if(!observing)return;assert(!deferPresent);AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"Clear"]mutableBytes];uint32_t d=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"Clear"]unsignedIntValue];printf("D,%u,%d,%u,%d,",sample,s->sprite,d,highscores[0].score);hex_name(highscores[0].name);putchar('\n');[self presentFrame];
}
- (void)presentFrame {if(observing)printf("W,%u\n",sample);}
- (void)delayGameTicks:(uint32_t)ticks {if(observing){assert(ticks==3);printf("L,%u,%u\n",sample,ticks);}}
- (void)saveScores {
 if(!observing)return;assert(ui.editingHighscore==0);[self refreshScores];printf("I,%u,0\n",sample);
 for(unsigned i=0;i<10;i++){printf("R,%u,%u,%d,",sample,i+1,highscores[i].score);hex_name(highscores[i].name);putchar('\n');assert(highscores[i].score==0&&!strcmp(highscores[i].name,"Space Dust"));}
}
- (void)checkClear {
 [timer invalidate];timer=nil;[audio stop];audio=[ClearAudio new];splashVisible=NO;deferPresent=NO;
 [ui show:@"Highscores Menu"];[ui animateTicks:120];[ui setValue:@0 forKey:@"cameraX"];[ui setValue:@0 forKey:@"cameraY"];
 for(sample=0;sample<3;sample++){
  for(unsigned i=0;i<10;i++){strcpy(highscores[i].name,"TEST");highscores[i].score=sample==0?0:sample==1?1001+(int)i:-1001-(int)i;}[self refreshScores];ui.editingHighscore=0;
  AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"Clear"]mutableBytes];assert(s);*s=(AstroUIMotion){381,222,65,65,0,900};reads=0;observing=YES;[self performMenuAction:@"Clear"];observing=NO;
  uint32_t d=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"Clear"]unsignedIntValue];printf("Z,%u,0,%d,%u,%u\n",sample,s->sprite,d,reads);assert(reads==2&&![[ui valueForKey:@"pressed"]length]);
 }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0},@"AstroSquidHighscores":@[]}forName:NSArgumentDomain];ClearView *v=[[ClearView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v checkClear];
}}
