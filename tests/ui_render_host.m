// Standalone offscreen GL check for original UI texture/font and scene geometry.
#import "../src/ui_renderer.h"
#import "../src/hud_renderer.h"
#import <OpenGL/glext.h>
#include <assert.h>
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);
    NSString *assets=[NSString stringWithUTF8String:argv[1]],*output=[NSString stringWithUTF8String:argv[2]];
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSOpenGLPixelFormatAttribute attributes[]={NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};
    NSOpenGLPixelFormat *format=[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    NSOpenGLContext *context=[[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];assert(context);[context makeCurrentContext];
    GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);
    glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);
    assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    glViewport(0,0,640,480);glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
    NSDictionary *game=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[assets stringByAppendingPathComponent:@"game.json"]] options:0 error:NULL];
    NSMutableDictionary *textures=[NSMutableDictionary dictionary];
    AstroUITextureLoader load=^GLuint(NSInteger identifier){
        if(textures[@(identifier)])return [textures[@(identifier)] unsignedIntValue];
        NSBitmapImageRep *source=(id)[NSBitmapImageRep imageRepWithContentsOfFile:[assets stringByAppendingPathComponent:[NSString stringWithFormat:@"atlases/%ld.png",(long)identifier]]];assert(source);
        NSInteger w=source.pixelsWide,h=source.pixelsHigh;
        NSBitmapImageRep *rgba=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:w*4 bitsPerPixel:32];
        NSGraphicsContext *old=NSGraphicsContext.currentContext;NSGraphicsContext.currentContext=[NSGraphicsContext graphicsContextWithBitmapImageRep:rgba];[source drawInRect:NSMakeRect(0,0,w,h)];NSGraphicsContext.currentContext=old;
        GLuint texture;glGenTextures(1,&texture);glBindTexture(GL_TEXTURE_2D,texture);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,(GLsizei)w,(GLsizei)h,0,GL_RGBA,GL_UNSIGNED_BYTE,rgba.bitmapData);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);textures[@(identifier)]=@(texture);return texture;
    };
    AstroUISpriteDrawer sprite=^(NSInteger identifier,double x,double y,double w,double h){
        NSDictionary *s=game[@"sprites"][[NSString stringWithFormat:@"%ld",(long)identifier]];if(!s)return;
        NSInteger atlas=[s[@"texture"] integerValue];NSDictionary *a=game[@"textures"][[NSString stringWithFormat:@"%ld",(long)atlas]];
        double aw=[a[@"width"] doubleValue],ah=[a[@"height"] doubleValue],u=[s[@"x"] doubleValue]/aw,v=[s[@"y"] doubleValue]/ah,du=[s[@"width"] doubleValue]/aw,dv=[s[@"height"] doubleValue]/ah;
        glEnable(GL_TEXTURE_2D);glEnable(GL_BLEND);glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);glBindTexture(GL_TEXTURE_2D,load(atlas));
        glBegin(GL_QUADS);glTexCoord2d(u,v);glVertex2d(x,y);glTexCoord2d(u+du,v);glVertex2d(x+w,y);glTexCoord2d(u+du,v+dv);glVertex2d(x+w,y+h);glTexCoord2d(u,v+dv);glVertex2d(x,y+h);glEnd();
    };
    AstroUIRenderer *ui=[[AstroUIRenderer alloc] initWithAssets:assets error:NULL];assert(ui);ui.unlockedLevel=16;
    ui.highscores=@[@{@"name":@"MACSPB",@"score":@12345}];ui.editingHighscore=1;ui.editingName=@"MACSPB";ui.editingCursor=6;
    AstroHUDRenderer *hud=[[AstroHUDRenderer alloc] initWithGame:game ui:ui];
    [[NSFileManager defaultManager] createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:NULL];
    for(NSString *anchor in @[@"Main Menu",@"Play Menu",@"Settings Menu",@"Continue Menu",@"Keys Menu",@"Highscores Menu",@"Pause",@"GameOver",@"Credits",@"HUD"]){
        [ui show:anchor];[ui animateTicks:120];glClearColor(0,0,0,1);glClear(GL_COLOR_BUFFER_BIT);
        if([anchor isEqual:@"HUD"]){AstroHUDState state={1,150,30,2,3,4,12345};[hud drawState:&state texture:load framebufferWidth:640 height:480];GLint viewport[4];glGetIntegerv(GL_VIEWPORT,viewport);assert(viewport[1]==30&&viewport[3]==380);}
        else [ui drawSprites:sprite texture:load];glFinish();assert(glGetError()==GL_NO_ERROR);
        NSMutableData *raw=[NSMutableData dataWithLength:640*480*4];glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,raw.mutableBytes);
        NSBitmapImageRep *png=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:640 pixelsHigh:480 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:640*4 bitsPerPixel:32];
        unsigned char *bytes=raw.mutableBytes;NSUInteger bright=0;
        for(int y=0;y<480;y++)for(int x=0;x<640;x++){unsigned char *pixel=bytes+((479-y)*640+x)*4,*dest=png.bitmapData+(y*640+x)*4;memcpy(dest,pixel,4);if(pixel[0]>32||pixel[1]>32||pixel[2]>32)bright++;}
        assert(bright>100);NSString *file=[output stringByAppendingPathComponent:[anchor stringByAppendingString:@".png"]];
        assert([[png representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:file atomically:YES]);
        printf("PASS %s rendered %lu visible pixels\n",anchor.UTF8String,(unsigned long)bright);
    }
}}
