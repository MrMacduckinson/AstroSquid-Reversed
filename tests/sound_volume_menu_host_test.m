#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned sample,reads;
static BOOL observing,musicMode;
static NSString *buttonName;
@interface VolumeAudio:AstroAudio
@end
@implementation VolumeAudio
- (void)setSoundVolume:(float)v {[super setSoundVolume:v];if(observing)printf("V,%u,%d\n",sample,(int)(255*(double)v));}
- (BOOL)playCue:(NSString *)name {assert([name isEqual:@"Click"]);if(observing)printf("S,%u,Click\n",sample);return YES;}
- (BOOL)playCue:(NSString *)name position:(double)position {if(observing){assert(musicMode&&[name isEqual:@"Click"]);uint64_t b;memcpy(&b,&position,8);printf("P,%u,%016llx\n",sample,b);}return YES;}
- (void)setMusicVolume:(float)v {[super setMusicVolume:v];if(observing){assert(musicMode);printf("V,%u,1,%d\nV,%u,2,%d\n",sample,(int)(v*128),sample,(int)(v*128));}}
- (void)stop {}
@end
@interface VolumeView:AstroView
- (void)checkVolume;
@end
@implementation VolumeView
- (uint32_t)currentGameTick {if(!observing)return 100;uint32_t n=100+reads++;printf("T,%u,%u\n",sample,n);return n;}
- (void)display {
    if(!observing)return;assert(!deferPresent);AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:buttonName]mutableBytes];uint32_t d=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:buttonName]unsignedIntValue];printf("D,%u,%d,%u",sample,s->sprite,d);if(musicMode)printf(",%d",(int)lround(ui.musicVolume*10));putchar('\n');[self presentFrame];
}
- (void)presentFrame {if(observing)printf("W,%u\n",sample);}
- (void)checkVolume {
    [timer invalidate];timer=nil;[audio stop];audio=[VolumeAudio new];splashVisible=NO;deferPresent=NO;
    [ui show:@"Settings Menu"];[ui animateTicks:120];[ui setValue:@0 forKey:@"cameraX"];[ui setValue:@0 forKey:@"cameraY"];
    for(sample=0;sample<11;sample++){
        AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:buttonName]mutableBytes];assert(s);*s=(AstroUIMotion){381,222,65,65,0,900};ui.soundVolume=ui.musicVolume=sample/10.;audio.soundVolume=ui.soundVolume/2;audio.musicVolume=ui.musicVolume;reads=0;
        observing=YES;[self performMenuAction:buttonName];observing=NO;
        uint32_t d=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:buttonName]unsignedIntValue];printf("Z,%u,%d,%d,%u,%u\n",sample,(int)lround((musicMode?ui.musicVolume:ui.soundVolume)*10),s->sprite,d,reads);assert(reads==2&&![[ui valueForKey:@"pressed"]length]);
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2||argc==3);musicMode=argc==3;assert(!musicMode||!strcmp(argv[2],"music"));buttonName=musicMode?@"SetMVolume":@"SetSVolume";[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];VolumeView *v=[[VolumeView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v checkVolume];
}}
