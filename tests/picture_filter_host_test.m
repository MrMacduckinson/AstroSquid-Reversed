#import "../src/ui_renderer.h"
#import <OpenGL/glext.h>
#include <assert.h>
static void checkFilter(GLint expected){GLint min,mag;glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,&min);glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,&mag);assert(min==expected&&mag==expected&&glGetError()==GL_NO_ERROR);}
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 NSOpenGLPixelFormatAttribute attributes[]={NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};NSOpenGLPixelFormat *format=[[NSOpenGLPixelFormat alloc]initWithAttributes:attributes];
 NSOpenGLContext *context=[[NSOpenGLContext alloc]initWithFormat:format shareContext:nil];assert(context);[context makeCurrentContext];
 GLuint framebuffer,color,picture;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);
 glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
 glGenTextures(1,&picture);glBindTexture(GL_TEXTURE_2D,picture);unsigned char white[]={255,255,255,255};glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,1,1,0,GL_RGBA,GL_UNSIGNED_BYTE,white);
 glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
 glViewport(0,0,640,480);glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
 NSError *error=nil;AstroUIRenderer *ui=[[AstroUIRenderer alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:&error];assert(ui);ui.smooth=YES;
 __block unsigned calls=0;AstroUITextureLoader cached=^GLuint(NSInteger id){assert(id==40);calls++;return picture;};
 [ui drawPicture:40 x:0 y:0 width:100 height:50 texture:cached];checkFilter(GL_LINEAR);
 [ui drawPicture:40 x:0 y:0 width:0 height:0 texture:cached];checkFilter(GL_NEAREST);
 [ui drawPicture:40 x:13 y:17 width:100 height:50 texture:cached];checkFilter(GL_NEAREST);
 [ui drawPicture:40 x:0 y:0 width:0 height:50 texture:cached];checkFilter(GL_NEAREST);
 [ui drawPicture:40 x:0 y:0 width:0 height:0 texture:cached];checkFilter(GL_NEAREST);assert(calls==5&&glIsTexture(picture));
 ui.smooth=NO;glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
 [ui drawPicture:40 x:0 y:0 width:100 height:50 texture:cached];checkFilter(GL_LINEAR);assert(calls==6);
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&picture);glDeleteTextures(1,&color);[NSOpenGLContext clearCurrentContext];
 puts("PASS actual UI picture path preserves native NEAREST after natural draw, scaled/one-zero draws retain prior filter regardless of smooth flag, cached texture remains alive");return 0;
}}
