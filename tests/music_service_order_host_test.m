// Original SERVICEMUSIC boundaries, including actual offscreen pause rendering.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
#import <objc/runtime.h>
static NSMutableString *events;static BOOL observing,finishBlink;
static BOOL animatingTicks;
@interface OrderedMenuUI:AstroUIRenderer
@end
@implementation OrderedMenuUI
- (void)animateMenuObjects {if(!animatingTicks)[events appendString:@"A"];[super animateMenuObjects];}
- (void)animateTicks:(unsigned)ticks {
    [events appendString:@"A"];animatingTicks=YES;
    @try {[super animateTicks:ticks];} @finally {animatingTicks=NO;}
}
@end
@interface ServiceAudio:AstroAudio
@end
@implementation ServiceAudio
- (void)serviceMusic {[events appendString:@"S"];}
@end
@interface ServiceView:AstroView
@end
@implementation ServiceView
- (uint32_t)playerClockTick {if(observing){[events appendString:@"T"];return 100;}return [super playerClockTick];}
- (uint32_t)currentGameTick {if(observing){[events appendString:@"C"];return 100;}return [super currentGameTick];}
- (uint32_t)cardDelayClockTick {return 100;}
- (void)pollMapSpawns {[events appendString:@"M"];if(finishBlink)invulnerableUntil=0;}
- (void)readGameKeys {[events appendString:@"K"];}
- (void)readKeyMap {[events appendString:@"K"];}
- (BOOL)menuMouseButtonPressed {return NO;}
- (void)completeGameLoopIfRequested {[events appendString:@"Q"];}
- (void)pollNestedWorld {[events appendString:@"W"];}
- (void)pollRespawnWait {[events appendString:@"R"];}
- (void)makeNewSprites {[events appendString:@"N"];}
- (void)advanceFlowWithKey:(BOOL)key {[events appendString:@"F"];}
- (void)display {if(observing){[events appendString:@"D"];[self drawRect:self.bounds];}}
- (void)presentFrame {if(observing)[events appendString:@"P"];else [super presentFrame];}
@end
static void expect(NSString *value){if(![events isEqual:value]){fprintf(stderr,"expected %s got %s\n",value.UTF8String,events.UTF8String);abort();}[events setString:@""];}
@implementation AstroView(ServiceOrderCheck)
- (void)checkServiceOrder {
    [timer invalidate];timer=nil;campaignTestPath=@"music-service-order";
    [[self openGLContext]makeCurrentContext];GLuint fb,color;
    glGenFramebuffersEXT(1,&fb);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fb);glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);
    assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    [self drawRect:self.bounds];[audio stop];audio=[ServiceAudio new];
    object_setClass(ui,[OrderedMenuUI class]);observing=YES;
    splashVisible=menuVisible=paused=gameOver=NO;flow.phase=ASTRO_FLOW_PLAY;
    observedWallTick=100;[self pollGame];expect(@"TSMKQ");
    gameEndRequested=YES;[self pollGame];expect(@"SMKQ");gameEndRequested=NO;
    [self pollRespawnWaitFrame];expect(@"WSR");
    respawnBlinkTick=respawnStartTick=100;invulnerableUntil=1;[self pollRespawnBlink];expect(@"TNSKT");invulnerableUntil=0;
    invulnerableUntil=1;finishBlink=YES;[self pollGame];expect(@"WMSKQ");finishBlink=NO;
    menuVisible=YES;ui.frameInterval=1;splashVisible=YES;[self pollMenu];expect(@"SK");splashVisible=NO;
    [ui show:@"Main"];visualRateTick=100;observedWallTick=99;[self pollMenu];expect(@"CCDTTAPSK");
    observedWallTick=100;[self pollMenu];expect(@"C");
    [ui show:@"Pause"];paused=YES;observedWallTick=99;[self pollMenu];expect(@"CCCCCDSAPCK");
    [self display];expect(@"DP"); // A redraw outside the original poll does not service music.
    [ui show:@"GameOver"];ui.editingHighscore=1;observedWallTick=99;[self pollMenu];expect(@"CCCKCDCCAPSC");
    menuVisible=paused=NO;flow.phase=ASTRO_FLOW_READY;cardClockStarted=NO;[self pollFlowCard];expect(@"");
    cardClockStarted=YES;cardDelayStartTick=41;[self pollFlowCard];expect(@"");
    cardDelayStartTick=40;[self pollFlowCard];expect(@"KSF");
    flow.phase=ASTRO_FLOW_END_CARD;[self pollFlowCard];expect(@"KSF");
    flow.phase=ASTRO_FLOW_ENDING;[self pollFlowCard];expect(@"KSF");
    observing=NO;glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&fb);glDeleteTextures(1,&color);[self releaseGraphics];
    puts("PASS actual host music-service order: outer/no-update/quit, wait, blink, splash, menu gate, pause before swap, GameOver after swap, redraw exclusion and card delay/key order");
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    events=[NSMutableString string];ServiceView *view=[[ServiceView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkServiceOrder];
}}
