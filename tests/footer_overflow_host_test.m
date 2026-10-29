#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <objc/runtime.h>
static unsigned footerLength,footerPattern,footerChoice,drawn,alerts,cases,polls;static BOOL recording,inModal;
@interface FooterOverflowView:AstroView
- (void)prepareFooter;
- (void)checkModalFreeze;
- (void)footerLength:(unsigned)length pattern:(unsigned)pattern choice:(unsigned)choice bytes:(const unsigned char *)name;
- (void)finishFooter;
@end
static FooterOverflowView *footerView;
static void hexData(NSData *data){assert(data);const unsigned char *p=data.bytes;for(NSUInteger i=0;i<data.length;i++)printf("%02x",p[i]);}
static NSModalResponse controlledModal(NSAlert *alert,SEL selector){
    assert(recording&&!inModal);inModal=YES;assert(alert.buttons.count==2&&[alert.buttons[0].title isEqual:@"Stop"]&&[alert.buttons[1].title isEqual:@"Continue"]);
    NSArray *lines=[alert.informativeText componentsSeparatedByString:@"\n"];assert(lines.count==2);alerts++;
    printf("A,%u,%u,%u,",footerLength,footerPattern,footerChoice);hexData([alert.messageText dataUsingEncoding:NSMacOSRomanStringEncoding]);putchar(',');hexData([lines[0] dataUsingEncoding:NSMacOSRomanStringEncoding]);putchar(',');hexData([lines[1] dataUsingEncoding:NSMacOSRomanStringEncoding]);putchar('\n');
    [footerView checkModalFreeze];inModal=NO;return footerChoice==0?NSModalResponseAbort:footerChoice==1?NSAlertFirstButtonReturn:NSAlertSecondButtonReturn;
}
@interface FooterOverflowUI:AstroUIRenderer @end
@implementation FooterOverflowUI
- (void)drawText:(NSString *)text x:(double)x baseline:(double)y size:(double)size texture:(AstroUITextureLoader)texture {
    if(recording&&size==10&&!drawn){printf("D,%u,%u,%u,",footerLength,footerPattern,footerChoice);hexData([text dataUsingEncoding:NSMacOSRomanStringEncoding]);putchar('\n');drawn++;}
}
@end
@implementation FooterOverflowView {
    GLuint footerFbo,footerTexture;
}
- (void)copyKeyMap:(unsigned char *)map {memset(map,0,16);}
- (void)pollMenu {polls++;}
- (void)prepareFooter {
    [timer invalidate];timer=nil;[audio stop];menuVisible=YES;splashVisible=paused=gameOver=gameEndRequested=NO;spriteMapsPreloaded=YES;
    [[self openGLContext]makeCurrentContext];glGenFramebuffersEXT(1,&footerFbo);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,footerFbo);glGenTextures(1,&footerTexture);glBindTexture(GL_TEXTURE_2D,footerTexture);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,footerTexture,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    object_setClass(ui,[FooterOverflowUI class]);NSArray *objects=[ui valueForKey:@"objects"];NSDictionary *anchor=nil;for(NSDictionary *o in objects)if([o[@"name"]isEqual:@"Main Menu"])anchor=o;assert(anchor);[ui setValue:@[anchor] forKey:@"objects"];
}
- (void)checkModalFreeze {
    assert(stringOverflowActive&&!graphicsReleased);unsigned before=polls;
    [self tick:nil];[self tickWallClock];[self drawRect:NSZeroRect];assert(polls==before&&!drawn);
}
- (void)terminateApplication {assert(terminationAllowed);printf("E,%u,%u,%u\n",footerLength,footerPattern,footerChoice);@throw [NSException exceptionWithName:@"FooterStopped" reason:nil userInfo:nil];}
- (void)footerLength:(unsigned)n pattern:(unsigned)p choice:(unsigned)answer bytes:(const unsigned char *)name {
    footerLength=n;footerPattern=p;footerChoice=answer;drawn=alerts=0;terminationAllowed=NO;assert(!stringOverflowActive);if(!ui.registered)ui.registered=YES;NSData *incoming=[NSData dataWithBytes:name length:n];if(![[ui.registeredName dataUsingEncoding:NSMacOSRomanStringEncoding]isEqual:incoming])ui.registeredName=[[NSString alloc]initWithData:incoming encoding:NSMacOSRomanStringEncoding];assert(ui.registeredName);recording=YES;
    @try {[ui drawSprites:^(NSInteger n,double x,double y,double w,double h){} texture:^GLuint(NSInteger n){return 0;}];assert(drawn==1);}
    @catch(NSException *exception){if(![exception.name isEqual:@"FooterStopped"])@throw;assert(n>240&&answer==1&&!drawn);}
    recording=NO;assert(!stringOverflowActive&&!inModal&&alerts==(n>240));NSData *unchanged=[ui.registeredName dataUsingEncoding:NSMacOSRomanStringEncoding];assert(unchanged.length==n&&(!n||!memcmp(unchanged.bytes,name,n)));cases++;
}
- (void)finishFooter {glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteTextures(1,&footerTexture);glDeleteFramebuffersEXT(1,&footerFbo);[self releaseGraphics];}
@end
static void footer_case(unsigned n,unsigned p,unsigned choice,const unsigned char *name){[footerView footerLength:n pattern:p choice:choice bytes:name];}
#include "footer_overflow_cases.h"
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    Method modal=class_getInstanceMethod([NSAlert class],@selector(runModal));IMP original=method_setImplementation(modal,(IMP)controlledModal);
    footerView=[[FooterOverflowView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(footerView);[footerView prepareFooter];run_footer_overflow_cases();[footerView finishFooter];method_setImplementation(modal,original);
    fprintf(stderr,"PASS %u actual Root footer renders/dialogs/Stop/Continue; timers and redraw blocked during modal; original name unchanged\n",cases);
}}
