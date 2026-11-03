// Offscreen production callbacks: preserve original 640x480 primitive thickness at 2x.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned columnPixels(unsigned char *rgba,int x){unsigned count=0;for(int y=0;y<960;y++)if(rgba[(y*1280+x)*4]>20)count++;return count;}
int main(void){@autoreleasepool{
    alarm(10);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSOpenGLPixelFormatAttribute attrs[]={NSOpenGLPFAAccelerated,NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};
    NSOpenGLPixelFormat *format=[[NSOpenGLPixelFormat alloc]initWithAttributes:attrs];assert(format);
    NSOpenGLContext *context=[[NSOpenGLContext alloc]initWithFormat:format shareContext:nil];assert(context);[context makeCurrentContext];
    GLuint fb,texture;glGenFramebuffersEXT(1,&fb);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fb);
    glGenTextures(1,&texture);glBindTexture(GL_TEXTURE_2D,texture);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,1280,960,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,texture,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    AstroView *view=[[AstroView alloc]initWithFrame:NSZeroRect];[context makeCurrentContext];
    unsigned char *pixels=malloc(1280*960*4);assert(pixels);BOOL pass=YES;
    for(unsigned scale=1;scale<=2;scale++){
        glViewport(0,0,640*scale,480*scale);[view setValue:@(scale) forKey:@"scenePixelScale"];
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();glClearColor(0,0,0,0);
        for(unsigned primitive=0;primitive<3;primitive++){
            glClear(GL_COLOR_BUFFER_BIT);
            if(primitive==0)scenePoint((__bridge void *)view,100,100,1);
            else if(primitive==1)sceneLine((__bridge void *)view,100,100,120,100,(AstroLineStyle){1,1,1,1,3});
            else sceneTrail((__bridge void *)view,100,100,120,1);
            glReadPixels(0,0,1280,960,GL_RGBA,GL_UNSIGNED_BYTE,pixels);assert(glGetError()==GL_NO_ERROR);
            unsigned count=columnPixels(pixels,110*scale),expected=(primitive==1?3:1)*scale;
            if(!primitive){count=0;for(int x=100*scale-scale;x<=(int)(100*scale+scale);x++)count=MAX(count,columnPixels(pixels,x));}
            printf("scale%u primitive%u thickness%u expected%u\n",scale,primitive,count,expected);if(count!=expected)pass=NO;
        }
    }
    free(pixels);glDeleteFramebuffersEXT(1,&fb);glDeleteTextures(1,&texture);[NSOpenGLContext clearCurrentContext];
    puts(pass?"PASS original logical point/laser/trail thickness at1x and2x":"FAIL backing scale changes primitive thickness");return pass?0:1;
}}
