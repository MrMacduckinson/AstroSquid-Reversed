#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static NSMutableArray *events;static BOOL observing;static unsigned initialClocks;
@interface StartupMapsView:AstroView
@end
@implementation StartupMapsView
- (uint32_t)currentGameTick {initialClocks++;if(observing){[events addObject:@"fps-clock"];return 123;}return [super currentGameTick];}
- (void)reloadMainMenu {if(observing){assert(spriteMapsPreloaded&&audio.music.isPlaying);[events addObject:@"menu"]; }[super reloadMainMenu];}
- (GLuint)texture:(NSInteger)identifier {if(observing)[events addObject:@(identifier)];return [super texture:identifier];}
- (void)presentFrame {if(observing){if(!spriteMapsPreloaded)assert(!audio);[events addObject:@"swap"];}[super presentFrame];}
- (BOOL)appendDebugMessage:(NSString *)message {if(observing){if([message isEqual:@"Loading Sound..."]||[message isEqual:@"Loading Music..."])assert(spriteMapsPreloaded&&!audio);[events addObject:message];}return YES;}
@end
@implementation AstroView(StartupMapsCheck)
- (void)checkStartupMaps {
 [timer invalidate];timer=nil;[audio stop];campaignTestPath=@"startup-test";ui.soundVolume=.7;assert(!audio&&!starsInitialized&&!spriteMapsPreloaded&&!textures.count&&!initialClocks&&!visualRateTick);
 [[self openGLContext]makeCurrentContext];GLuint fb,color;glGenFramebuffersEXT(1,&fb);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fb);glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
 ui.frameInterval=1;observing=YES;[self drawRect:self.bounds];observing=NO;
 // Actual PUTCONTROLS profile0 records 135 clocks at interval1.
 NSUInteger menuNodes=[[ui valueForKey:@"objects"]count],menuClocks=135;assert(menuNodes==52&&initialClocks==menuClocks+1&&visualRateTick==123&&[events[0]isEqual:@"fps-clock"]);
 assert(events.count>111&&[events[1]isEqual:@40]&&[events[2]isEqual:@"swap"]&&[events[3]isEqual:@"Loading SpriteMaps..."]);
 for(unsigned i=0;i<107;i++)assert([events[i+4]isEqual:@(i)]);
 assert([events[111]isEqual:@"Loading Sound..."]&&[events[112]isEqual:@"Loading Music..."]&&[events[113]isEqual:@"menu"]&&[events[114+menuClocks]isEqual:@41]&&spriteMapsPreloaded&&textures.count==54&&audio.music.isPlaying&&fabs(audio.soundVolume-ui.soundVolume/2)<1e-6&&fabs(audio.musicVolume-ui.musicVolume)<1e-6);
 for(NSUInteger i=0;i<menuClocks;i++)assert([events[114+i]isEqual:@"fps-clock"]);
 NSArray *expected=@[@0,@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@12,@13,@14,@15,@16,@17,@18,@19,@20,@21,@22,@40,@41,@50,@51,@52,@53,@54,@55,@56,@57,@58,@61,@62,@63,@64,@65,@66,@67,@68,@70,@71,@72,@73,@74,@75,@76,@77,@78,@98,@99,@100];
 assert([[textures.allKeys sortedArrayUsingSelector:@selector(compare:)]isEqual:expected]);GLuint picture=[textures[@40]unsignedIntValue];glBindTexture(GL_TEXTURE_2D,picture);GLint filter;glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,&filter);assert(filter==GL_NEAREST);
 uint32_t menuSeed=randomSeed;AstroAudio *firstAudio=audio;AVAudioPlayer *firstTrack=audio.music;NSDictionary *first=[textures copy];[events removeAllObjects];observing=YES;[self drawRect:self.bounds];observing=NO;assert(initialClocks==menuClocks+1&&visualRateTick==123&&[events[0]isEqual:@41]&&![events containsObject:@"Loading SpriteMaps..."]&&[textures isEqual:first]&&audio==firstAudio&&audio.music==firstTrack&&randomSeed==menuSeed&&![events containsObject:@"menu"]&&glGetError()==GL_NO_ERROR);
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&fb);glDeleteTextures(1,&color);[self releaseGraphics];[audio stop];
 puts("PASS actual startup picture40/swap -> map calls0..106 -> picture41;sound/music/menu after maps,54 original maps cached, picture40 NEAREST retained, repeated draw does not preload/reallocate");
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"smooth":@YES,@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 events=[NSMutableArray array];StartupMapsView *view=[[StartupMapsView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkStartupMaps];return 0;
}}
