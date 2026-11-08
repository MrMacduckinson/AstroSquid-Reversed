// Offscreen production HUD/world paths must cover every pixel at fractional backing scales.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSSize backingSize;
@interface ClipView:AstroView
- (void)prepare;
@end
@implementation ClipView
- (void)prepare {spriteMapsPreloaded=YES;flow.phase=ASTRO_FLOW_PLAY;campaign.level=1;deferPresent=YES;hudRedraws=2;hud=[[AstroHUDRenderer alloc]initWithGame:@{} ui:nil];}
- (NSRect)convertRectToBacking:(NSRect)rect {return NSMakeRect(0,0,backingSize.width,backingSize.height);}
- (void)drawSpecialOverlays {
 glDisable(GL_TEXTURE_2D);glColor4d(1,1,1,1);glLineWidth(6*scenePixelScale);
 glBegin(GL_LINES);glVertex2d(100,0);glVertex2d(200,0);glVertex2d(100,379);glVertex2d(200,379);
 glVertex2d(100,190);glVertex2d(200,190);glEnd();
}
@end
int main(void){@autoreleasepool{
 [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 NSOpenGLPixelFormatAttribute attrs[]={NSOpenGLPFAAccelerated,NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};
 NSOpenGLPixelFormat *format=[[NSOpenGLPixelFormat alloc]initWithAttributes:attrs];
 NSOpenGLContext *context=[[NSOpenGLContext alloc]initWithFormat:format shareContext:nil];assert(context);[context makeCurrentContext];
 ClipView *view=[[ClipView alloc]initWithFrame:NSMakeRect(0,0,640,480)];[view setOpenGLContext:context];[view prepare];
 GLuint fb,texture;glGenFramebuffersEXT(1,&fb);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fb);glGenTextures(1,&texture);glBindTexture(GL_TEXTURE_2D,texture);
 const NSSize sizes[]={{640,480},{1280,960},{2618,1964},{1366,1024}};unsigned totalMissing=0;
 for(unsigned run=0;run<4;run++) {
 backingSize=sizes[run];int w=backingSize.width,h=backingSize.height;[view prepare];
 glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,w,h,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,texture,0);
 assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);
 glClearColor(1,0,1,1);glClear(GL_COLOR_BUFFER_BIT);[view drawRect:view.bounds];
 unsigned char *pixels=malloc(w*h*4);assert(pixels);glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
 unsigned missing=0;for(int n=0;n<w*h;n++)if(pixels[n*4]>200&&pixels[n*4+1]<20&&pixels[n*4+2]>200)missing++;
 printf("WORLD_COVERAGE %dx%d untouched=%u\n",w,h,missing);totalMissing+=missing;free(pixels);
 glBindTexture(GL_TEXTURE_2D,texture);
 }
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&fb);glDeleteTextures(1,&texture);
 return totalMissing?1:0;
}}
