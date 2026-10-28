// Actual GameOver UI field commands in common 640x480 menu coordinates.
#import "../src/ui_renderer.h"
#include <assert.h>
#include <stdint.h>
#include "text_cursor_cases.h"
static unsigned field_case,command_index,primitive,vertices;
static GLenum polygonMode=GL_FILL;
static BOOL recording;
static double rgba[4],xy[8];
static uint64_t word(double x){uint64_t u;memcpy(&u,&x,8);return u;}
static void colors(void){for(unsigned i=0;i<4;i++)printf(",%016llx",word(rgba[i]));putchar('\n');}
void glColor4d(GLdouble r,GLdouble g,GLdouble b,GLdouble a){rgba[0]=r;rgba[1]=g;rgba[2]=b;rgba[3]=a;}
void glPolygonMode(GLenum face,GLenum mode){assert(face==GL_FRONT_AND_BACK);polygonMode=mode;}
void glBegin(GLenum mode){primitive=mode;vertices=0;}
void glVertex2d(GLdouble x,GLdouble y){assert(vertices<4);xy[2*vertices]=x;xy[2*vertices+1]=y;vertices++;}
void glEnd(void){
    if(!recording)return;assert(vertices==4&&(primitive==GL_QUADS||primitive==GL_LINE_LOOP));
    assert(xy[0]==xy[6]&&xy[1]==xy[3]&&xy[2]==xy[4]&&xy[5]==xy[7]);
    printf("%u,%u,B,%u,%016llx,%016llx,%016llx,%016llx",field_case,command_index++,primitive==GL_LINE_LOOP||polygonMode==GL_LINE,word(xy[0]),word(xy[1]),word(xy[4]),word(xy[5]));colors();
}
void glScissor(GLint x,GLint y,GLsizei w,GLsizei h){if(recording)printf("%u,%u,S,%d,%d,%d,%d\n",field_case,command_index++,x,y,w,h);}
void glEnable(GLenum cap){if(recording&&cap==GL_SCISSOR_TEST)printf("%u,%u,E,1\n",field_case,command_index++);}
void glDisable(GLenum cap){if(recording&&cap==GL_SCISSOR_TEST)printf("%u,%u,E,0\n",field_case,command_index++);}
@interface FieldDrawUI:AstroUIRenderer
@end
@implementation FieldDrawUI
- (void)drawText:(NSString *)text x:(double)x baseline:(double)y size:(double)size texture:(AstroUITextureLoader)texture {
    if(!recording||(![text isEqual:@"Name:"]&&![text isEqual:self.editingName]))return;
    NSData *data=[text dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];assert(data);
    printf("%u,%u,T,",field_case,command_index++);const unsigned char *p=data.bytes;for(NSUInteger i=0;i<data.length;i++)printf("%02x",p[i]);
    printf(",%016llx,%016llx,%016llx",word(x),word(y),word(size));colors();
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSOpenGLPixelFormatAttribute attributes[]={NSOpenGLPFAColorSize,24,NSOpenGLPFAAlphaSize,8,0};
    NSOpenGLContext *context=[[NSOpenGLContext alloc]initWithFormat:[[NSOpenGLPixelFormat alloc]initWithAttributes:attributes] shareContext:nil];assert(context);[context makeCurrentContext];
    FieldDrawUI *ui=[[FieldDrawUI alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:NULL];assert(ui);
    [ui show:@"GameOver"];[ui animateTicks:120];[ui setValue:@[] forKey:@"objects"];ui.editingHighscore=1;ui.readTick=^uint32_t{return 100;};
    for(unsigned n=0;n<sizeof(text_cursor_names)/sizeof(text_cursor_names[0]);n++){
        NSString *name=[[NSString alloc]initWithBytes:text_cursor_names[n] length:strlen(text_cursor_names[n]) encoding:NSMacOSRomanStringEncoding];assert(name);
        int cursors[]={-1,0,(int)name.length/2,(int)name.length,(int)name.length+5};ui.editingName=name;
        for(unsigned c=0;c<5;c++)for(unsigned visible=0;visible<2;visible++){
            ui.editingCursor=cursors[c];[ui beginScoreClock:visible?100:0];recording=NO;
            if(!visible)[ui drawSprites:^(NSInteger n,double x,double y,double w,double h){} texture:^GLuint(NSInteger n){return 0;}];
            command_index=0;recording=YES;[ui drawSprites:^(NSInteger n,double x,double y,double w,double h){} texture:^GLuint(NSInteger n){return 0;}];recording=NO;field_case++;
        }
    }
    command_index=0;ui.editingHighscore=0;recording=YES;[ui drawSprites:^(NSInteger n,double x,double y,double w,double h){} texture:^GLuint(NSInteger n){return 0;}];recording=NO;assert(!command_index);printf("%u,0,N\n",field_case);
}}
