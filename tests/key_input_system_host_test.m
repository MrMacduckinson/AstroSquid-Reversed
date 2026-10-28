/* Real Cocoa availability/GetKeys/clock path, no keyboard injection or privacy changes. */
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static unsigned samples,polls,frames,music;static BOOL inputObserved;
@interface SystemInputAudio:AstroAudio
@end
@implementation SystemInputAudio
- (BOOL)playCue:(NSString *)name position:(double)p {return YES;}
- (void)serviceMusic {music++;}
- (void)stop {}
@end
@interface SystemInputView:AstroView
- (int)checkSystemInput;
@end
@implementation SystemInputView
- (void)copyKeyMap:(unsigned char *)map {
    [super copyKeyMap:map];samples++;for(unsigned i=0;i<16;i++)if(map[i])inputObserved=YES;
}
- (void)pollKeyCaptureEvents {polls++;[super pollKeyCaptureEvents];}
- (void)display {[self drawRect:self.bounds];}
- (void)presentFrame {frames++;glFlush();}
- (int)checkSystemInput {
    [timer invalidate];timer=nil;engineDebug=NO;[audio stop];audio=[SystemInputAudio new];selftestPath=campaignTestPath=nil;
    assert(!keyCaptureTestMap);menuVisible=YES;splashVisible=paused=gameOver=NO;ui.frameInterval=1;
    unsigned char map[16];inputObserved=NO;[self copyKeyMap:map];
    if(inputObserved){puts("INCONCLUSIVE: keyboard is not clear; no input values recorded");return 77;}
    [[self openGLContext]makeCurrentContext];GLuint fbo,color;glGenFramebuffersEXT(1,&fbo);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fbo);glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    spriteMapsPreloaded=YES;[self reloadMainMenu];[ui show:@"Keys Menu"];[ui animateTicks:120];assert(!ui.transitioning&&starsInitialized);
    // A private application event must remain queued, like EventAvail(0).
    NSEvent *marker=[NSEvent otherEventWithType:NSEventTypeApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil subtype:0 data1:0x57414954 data2:0];
    [NSApp postEvent:marker atStart:NO];
    samples=polls=frames=music=0;inputObserved=NO;int previous=controlKeys[0];uint32_t start=[self currentGameTick];double wall=NSProcessInfo.processInfo.systemUptime;
    [self performMenuAction:@"SetKeyFire"];
    uint32_t elapsed=[self currentGameTick]-start;double seconds=NSProcessInfo.processInfo.systemUptime-wall;
    NSEvent *pending=[NSApp nextEventMatchingMask:NSEventMaskApplicationDefined untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
    assert(pending&&pending.data1==0x57414954&&samples==polls&&editingKey==-1&&menuMouseLatched&&glGetError()==GL_NO_ERROR);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&fbo);glDeleteTextures(1,&color);[self releaseGraphics];
    if(inputObserved){puts("INCONCLUSIVE: live input changed during timeout test; no input values recorded");return 77;}
    assert(elapsed>600&&frames>0&&music==frames&&controlKeys[0]==previous);
    printf("PASS real GetKeys/Cocoa/clock timeout: ticks=%u seconds=%.3f frames=%u polls=%u queued_event_preserved=1 binding_preserved=1 ax_trusted=%d\n",elapsed,seconds,frames,polls,AXIsProcessTrusted());return 0;
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);alarm(25);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    SystemInputView *view=[[SystemInputView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);return [view checkSystemInput];
}}
