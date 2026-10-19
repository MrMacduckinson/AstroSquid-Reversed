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
        assert(source.bitsPerSample==8&&source.samplesPerPixel==4&&!source.isPlanar&&(source.bitmapFormat&NSAlphaNonpremultipliedBitmapFormat));
        glPixelStorei(GL_UNPACK_ALIGNMENT,1);glPixelStorei(GL_UNPACK_ROW_LENGTH,(GLint)(source.bytesPerRow/4));
        GLuint texture;glGenTextures(1,&texture);glBindTexture(GL_TEXTURE_2D,texture);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,(GLsizei)w,(GLsizei)h,0,GL_RGBA,GL_UNSIGNED_BYTE,source.bitmapData);glPixelStorei(GL_UNPACK_ROW_LENGTH,0);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);textures[@(identifier)]=@(texture);return texture;
    };
    AstroUISpriteDrawer sprite=^(NSInteger identifier,double x,double y,double w,double h){
        NSDictionary *s=game[@"sprites"][[NSString stringWithFormat:@"%ld",(long)identifier]];if(!s)return;
        NSInteger atlas=[s[@"texture"] integerValue];NSDictionary *a=game[@"textures"][[NSString stringWithFormat:@"%ld",(long)atlas]];
        double aw=[a[@"width"] doubleValue],ah=[a[@"height"] doubleValue],u=[s[@"x"] doubleValue]/aw,v=[s[@"y"] doubleValue]/ah,du=[s[@"width"] doubleValue]/aw,dv=[s[@"height"] doubleValue]/ah;
        glEnable(GL_TEXTURE_2D);glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);glBindTexture(GL_TEXTURE_2D,load(atlas));
        glBegin(GL_QUADS);glTexCoord2d(u,v);glVertex2d(x,y);glTexCoord2d(u+du,v);glVertex2d(x+w,y);glTexCoord2d(u+du,v+dv);glVertex2d(x+w,y+h);glTexCoord2d(u,v+dv);glVertex2d(x,y+h);glEnd();
    };
    AstroUIRenderer *ui=[[AstroUIRenderer alloc] initWithAssets:assets error:NULL];assert(ui);ui.unlockedLevel=16;ui.registeredName=@"MACSPB";
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
    glViewport(0,0,640,480);glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
    [ui show:@"GameOver"];[ui animateTicks:120];ui.editingName=@"";ui.editingCursor=0;
    glClear(GL_COLOR_BUFFER_BIT);[ui drawSprites:sprite texture:load];
    NSMutableData *empty=[NSMutableData dataWithLength:640*480*4],*longName=[NSMutableData dataWithLength:640*480*4];
    glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,empty.mutableBytes);
    ui.editingName=[@"" stringByPaddingToLength:255 withString:@"W" startingAtIndex:0];ui.editingCursor=255;
    glClear(GL_COLOR_BUFFER_BIT);[ui drawSprites:sprite texture:load];glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,longName.mutableBytes);
    assert(!glIsEnabled(GL_SCISSOR_TEST)&&glGetError()==GL_NO_ERROR);unsigned changes=0;
    const unsigned char *before=empty.bytes,*after=longName.bytes;
    for(int y=0;y<480;y++)for(int x=0;x<640;x++){
        size_t offset=(y*640+x)*4;int differs=memcmp(before+offset,after+offset,4)!=0;
        if(x<225||x>=423||y<203||y>=225)assert(!differs);else changes+=differs;
    }
    assert(changes>100);puts("PASS long score name scrolls inside field and restores GL scissor state");
    glViewport(0,0,1,1);glDisable(GL_SCISSOR_TEST);glClearColor(0,0,0,0);glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,1,0,1,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
    NSDictionary *atlas=game[@"textures"][@"2"];double u=193.0/[atlas[@"width"] doubleValue],v=46.5/[atlas[@"height"] doubleValue];
    glEnable(GL_TEXTURE_2D);glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);glColor4d(1,1,1,1);glBindTexture(GL_TEXTURE_2D,load(2));
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glBegin(GL_QUADS);glTexCoord2d(u,v);glVertex2d(0,0);glTexCoord2d(u,v);glVertex2d(1,0);
    glTexCoord2d(u,v);glVertex2d(1,1);glTexCoord2d(u,v);glVertex2d(0,1);glEnd();
    unsigned char witness[4];glReadPixels(0,0,1,1,GL_RGBA,GL_UNSIGNED_BYTE,witness);
    assert(witness[0]>=63&&witness[0]<=65&&witness[1]==witness[0]&&witness[2]==witness[0]);
    puts("PASS original straight-RGBA linear-edge witness (64, not premultiplied128)");
    /* Font PICT301 RGB already contains coverage; original LMDRAWTEXT uses ONE. */
    glViewport(0,0,640,480);glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
    glClearColor(0,0,0,1);glClear(GL_COLOR_BUFFER_BIT);glColor4d(1,1,1,1);
    GLuint font=load(50);glBindTexture(GL_TEXTURE_2D,font);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    [ui drawText:@"Game Paused" x:220 baseline:220 size:32 texture:load];
    GLint sourceFactor;glGetIntegerv(GL_BLEND_SRC,&sourceFactor);assert(sourceFactor==GL_SRC_ALPHA);
    NSMutableData *fontPixels=[NSMutableData dataWithLength:640*480*4];glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,fontPixels.mutableBytes);
    unsigned half=0;const unsigned char *fp=fontPixels.bytes;
    for(unsigned i=0;i<640*480;i++)if(fp[4*i]==127&&fp[4*i+1]==127&&fp[4*i+2]==127)half++;
    assert(half>0);printf("PASS font original ONE blend, %u actual half-coverage pixels retain127\n",half);

}}
