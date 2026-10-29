// Actual card UI methods; glyph drawing is observed as MacRoman/IEEE commands.
#import "../src/ui_renderer.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
static unsigned card_case,texts;
static double textColor[4];
void glColor4d(GLdouble r,GLdouble g,GLdouble b,GLdouble a){textColor[0]=r;textColor[1]=g;textColor[2]=b;textColor[3]=a;}
static uint64_t word(double x){uint64_t u;memcpy(&u,&x,8);return u;}
@interface CardTextUI:AstroUIRenderer
@end
@implementation CardTextUI
- (void)drawPicture:(NSInteger)n x:(double)x y:(double)y width:(double)w height:(double)h texture:(AstroUITextureLoader)texture {}
- (void)drawText:(NSString *)text x:(double)x baseline:(double)y size:(double)size texture:(AstroUITextureLoader)texture {
    NSData *data=[text dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];assert(data);
    printf("%u,%u,",card_case,texts++);const unsigned char *p=data.bytes;for(NSUInteger i=0;i<data.length;i++)printf("%02x",p[i]);
    printf(",%016llx,%016llx,%016llx",word(x),word(y),word(size));
    for(unsigned i=0;i<4;i++)printf(",%016llx",word(textColor[i]));putchar('\n');
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2||argc==3);BOOL endcards=argc==3;assert(!endcards||!strcmp(argv[2],"endcards"));[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSOpenGLPixelFormatAttribute attributes[]={NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};
    NSOpenGLPixelFormat *format=[[NSOpenGLPixelFormat alloc]initWithAttributes:attributes];
    NSOpenGLContext *context=[[NSOpenGLContext alloc]initWithFormat:format shareContext:nil];assert(context);[context makeCurrentContext];
    CardTextUI *ui=[[CardTextUI alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:NULL];assert(ui);
    for(card_case=0;card_case<(endcards?8:19);card_case++){
        texts=0;
        if(endcards)[ui drawBriefingForStage:card_case+1 list:402 texture:^GLuint(NSInteger n){return 0;}];
        else if(card_case==18)[ui drawSplashWithTexture:^GLuint(NSInteger n){return 0;}];
        else if(card_case<16)[ui drawBriefingForStage:card_case/2+1 list:card_case%2?401:400 texture:^GLuint(NSInteger n){return 0;}];
        else for(int page=0;page<4;page++)[ui drawEndingPage:page texture:^GLuint(NSInteger n){return 0;}];
    }
}}
