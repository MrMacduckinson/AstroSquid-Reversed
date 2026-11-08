#import <Cocoa/Cocoa.h>
#include "../src/star_renderer.h"
#include <assert.h>
static double scale;
static void point(void *c,double x,double y,double gray){
 glDisable(GL_TEXTURE_2D);glPointSize(scale);glColor3d(gray,gray,gray);glBegin(GL_POINTS);glVertex2d(x,y);glEnd();
}
static void trail(void *c,double x,double y,double end,double gray){
 glDisable(GL_TEXTURE_2D);glShadeModel(GL_SMOOTH);glLineWidth(scale);glBegin(GL_LINES);
 glColor3d(gray,gray,gray);glVertex2d(x,y);glColor3d(0,0,0);glVertex2d(end,y);glEnd();
}
int main(void){@autoreleasepool{
 [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 NSOpenGLPixelFormatAttribute attrs[]={NSOpenGLPFAAccelerated,NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};
 NSOpenGLPixelFormat *format=[[NSOpenGLPixelFormat alloc]initWithAttributes:attrs];
 NSOpenGLContext *context=[[NSOpenGLContext alloc]initWithFormat:format shareContext:nil];assert(context);[context makeCurrentContext];
 GLuint fb,texture;glGenFramebuffersEXT(1,&fb);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fb);
 glGenTextures(1,&texture);glBindTexture(GL_TEXTURE_2D,texture);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,1280,960,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
 glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,texture,0);
 assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
 glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);
 glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
 glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);glClearColor(0,0,0,0);
 AstroStar stars[3000];uint32_t seed=123;astro_stars_init(stars,1,&seed);
 AstroSceneSink original={.point=point,.star_trail=trail};size_t size=1280*960*4;
 unsigned char *before=malloc(size),*after=malloc(size);assert(before&&after);
 for(unsigned retina=1;retina<=2;retina++)for(unsigned kind=0;kind<4;kind++){
  scale=retina;glViewport(0,0,640*retina,480*retina);
  int menu=kind==0,stage=kind==3?4:1;double speed=kind==2?201:1;
  glClear(GL_COLOR_BUFFER_BIT);astro_stars_draw(stars,menu,stage,speed,&original);glReadPixels(0,0,1280,960,GL_RGBA,GL_UNSIGNED_BYTE,before);
  glClear(GL_COLOR_BUFFER_BIT);astro_stars_draw_gl(stars,menu,stage,speed,scale);glReadPixels(0,0,1280,960,GL_RGBA,GL_UNSIGNED_BYTE,after);
  assert(!memcmp(before,after,size));assert(glGetError()==GL_NO_ERROR);
 }
 free(before);free(after);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&fb);glDeleteTextures(1,&texture);
 puts("PASS exact old/batched star pixels: menu, gameplay, trails and skipped stage at 1x/2x");
}}
