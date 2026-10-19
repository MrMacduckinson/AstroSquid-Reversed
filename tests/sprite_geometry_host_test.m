// Capture actual production vertex arguments; this is not a GPU raster comparison.
static int capturing;
static unsigned vertices;
static double xy[8];
#define glVertex2d observeVertex
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#undef glVertex2d
void observeVertex(GLdouble x,GLdouble y){if(capturing){assert(vertices<4);xy[vertices*2]=x;xy[vertices*2+1]=y;vertices++;}}
@interface AstroGeometryView : AstroView
@end
@implementation AstroGeometryView
- (GLuint)texture:(NSInteger)identifier {return capturing?1:[super texture:identifier];}
- (void)display {}
@end
@interface AstroView (GeometryCheck)
- (void)checkGeometry;
@end
@implementation AstroView (GeometryCheck)
- (void)checkGeometry {
    [timer invalidate];timer=nil;[audio stop];capturing=1;
    const double sizes[][2]={{71,20},{0,20},{71,0},{0,0},{-7,-9}};
    for(unsigned i=0;i<5;i++){
        double w=sizes[i][0],h=sizes[i][1];vertices=0;
        [self sprite:1 x:10 y:20 width:w height:h];assert(vertices==4);
        assert(xy[0]==10&&xy[1]==20&&xy[2]==10+w&&xy[3]==20);
        assert(xy[4]==10+w&&xy[5]==20+h&&xy[6]==10&&xy[7]==20+h);
    }
    capturing=0;puts("PASS actual host sprite vertex arguments preserve positive, zero blink, zero height and negative dimensions");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    AstroView *view=[[AstroGeometryView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkGeometry];
}}
