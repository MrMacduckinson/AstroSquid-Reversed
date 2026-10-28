#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned sample,reads;
static BOOL observing;
@interface VolumeAudio:AstroAudio
@end
@implementation VolumeAudio
- (void)setSoundVolume:(float)v {[super setSoundVolume:v];if(observing)printf("V,%u,%d\n",sample,(int)(255*(double)v));}
- (BOOL)playCue:(NSString *)name {assert([name isEqual:@"Click"]);if(observing)printf("S,%u,Click\n",sample);return YES;}
- (BOOL)playCue:(NSString *)name position:(double)position {assert(!observing);return YES;}
- (void)stop {}
@end
@interface VolumeView:AstroView
- (void)checkVolume;
@end
@implementation VolumeView
- (uint32_t)currentGameTick {if(!observing)return 100;uint32_t n=100+reads++;printf("T,%u,%u\n",sample,n);return n;}
- (void)display {
    if(!observing)return;assert(!deferPresent);AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"SetSVolume"]mutableBytes];uint32_t d=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"SetSVolume"]unsignedIntValue];printf("D,%u,%d,%u\n",sample,s->sprite,d);[self presentFrame];
}
- (void)presentFrame {if(observing)printf("W,%u\n",sample);}
- (void)checkVolume {
    [timer invalidate];timer=nil;[audio stop];audio=[VolumeAudio new];splashVisible=NO;deferPresent=NO;
    [ui show:@"Settings Menu"];[ui animateTicks:120];
    for(sample=0;sample<11;sample++){
        AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"SetSVolume"]mutableBytes];assert(s);*s=(AstroUIMotion){381,222,65,65,0,900};ui.soundVolume=sample/10.;audio.soundVolume=ui.soundVolume/2;reads=0;
        observing=YES;[self performMenuAction:@"SetSVolume"];observing=NO;
        uint32_t d=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"SetSVolume"]unsignedIntValue];printf("Z,%u,%d,%d,%u,%u\n",sample,(int)lround(ui.soundVolume*10),s->sprite,d,reads);assert(reads==2&&![[ui valueForKey:@"pressed"]length]);
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];VolumeView *v=[[VolumeView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v checkVolume];
}}
