// Authorized Intel runtime: actual reminder renderer and atlas through an offscreen FBO.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static unsigned swaps;
@interface ReminderDrawView:AstroView
@end
@implementation ReminderDrawView
- (void)display {}
- (NSRect)convertRectToBacking:(NSRect)rect {return rect;} // fixed 1x test framebuffer
- (void)presentFrame {swaps++;glFlush();}
@end
@implementation AstroView(ReminderDrawCheck)
- (void)checkReminderDrawing:(NSString *)output {
    [timer invalidate];timer=nil;[audio stop];ui.smooth=NO;
    [[self openGLContext]makeCurrentContext];
    GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);
    glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);
    assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);
    glMatrixMode(GL_MODELVIEW);glLoadIdentity();glDisable(GL_BLEND);glClearColor(1,0,1,1);
    [self drawRegistrationReminder];assert(swaps==1&&glGetError()==GL_NO_ERROR);
    NSMutableData *pixels=[NSMutableData dataWithLength:640*480*4];glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,pixels.mutableBytes);assert(glGetError()==GL_NO_ERROR);
    NSBitmapImageRep *atlas=(NSBitmapImageRep *)[NSBitmapImageRep imageRepWithContentsOfFile:[assetPath stringByAppendingPathComponent:@"atlases/70.png"]];
    assert(atlas&&atlas.pixelsWide==512&&atlas.pixelsHigh==512&&atlas.samplesPerPixel==4);
    unsigned char *actual=pixels.mutableBytes;unsigned mismatches=0;
    for(unsigned y=0;y<480;y++)for(unsigned x=0;x<640;x++){
        unsigned sx=(2*x+1)*512/1280,sy=(2*y+1)*384/960;
        const unsigned char *expected=atlas.bitmapData+sy*atlas.bytesPerRow+sx*4;
        unsigned char *got=actual+((479-y)*640+x)*4;
        if(memcmp(got,expected,4)){if(mismatches<8)fprintf(stderr,"pixel %u,%u actual %u,%u,%u,%u expected %u,%u,%u,%u\n",x,y,got[0],got[1],got[2],got[3],expected[0],expected[1],expected[2],expected[3]);mismatches++;}
    }
    NSBitmapImageRep *image=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:NULL pixelsWide:640 pixelsHigh:480 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:NSAlphaNonpremultipliedBitmapFormat bytesPerRow:2560 bitsPerPixel:32];
    for(unsigned y=0;y<480;y++)memcpy(image.bitmapData+y*2560,actual+(479-y)*2560,2560);
    assert([[image representationUsingType:NSBitmapImageFileTypePNG properties:@{}]writeToFile:output atomically:YES]);
    fprintf(stderr,"mismatches=%u\n",mismatches);assert(!mismatches);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);
    puts("PASS actual reminder draw: 307200 RGBA pixels equal scaled source atlas, full640x480 coverage, one presentation, no GL errors (nearest filtering)");
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[ReminderDrawView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);
    [view checkReminderDrawing:[NSString stringWithUTF8String:argv[2]]];
}}
