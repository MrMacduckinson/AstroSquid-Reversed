#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static NSString *captured;static unsigned calls;static double rgba[4];
@interface FPSUI:AstroUIRenderer
@end
@implementation FPSUI
- (void)drawText:(NSString *)text x:(double)x baseline:(double)y size:(double)size texture:(AstroUITextureLoader)texture {
 assert(x==6&&y==22&&size==12);captured=[text copy];calls++;glGetDoublev(GL_CURRENT_COLOR,rgba);
 [super drawText:text x:x baseline:y size:size texture:texture];
}
@end
@implementation AstroView(FPSDisplayCheck)
- (void)checkFPSDisplay:(NSString *)assets {
 [timer invalidate];timer=nil;[audio stop];campaignTestPath=@"fps-display-test";
 [[self openGLContext] makeCurrentContext];GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);
 glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
 glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
 double xs[]={-21,-20,-19.9,-1.9,-.9,0,.9,639,639.9,640,640.9,641},ys[]={-21,-20,-19.9,-1.9,-.9,0,.9,379.9,380,479,479.9,480,480.9},sizes[]={0,.9,1,1.9,20},offsets[]={0,-.75,.75};unsigned count=0,visible=0;
 for(unsigned cx=0;cx<3;cx++)for(unsigned cy=0;cy<3;cy++)for(unsigned x=0;x<12;x++)for(unsigned y=0;y<13;y++)for(unsigned w=0;w<5;w++)for(unsigned h=0;h<5;h++){
  double px=xs[x]+offsets[cx],py=ys[y]+offsets[cy];int left=(int)px,top=(int)py,right=left+(int)sizes[w],bottom=top+(int)sizes[h];
  BOOL expected=right>left&&bottom>top&&right>0&&bottom>0&&left<640&&top<480;
  visualSprites=0;assert([self countSpriteX:px y:py width:sizes[w] height:sizes[h]]==expected);assert(visualSprites==expected);count++;visible+=expected;
 }
 assert(count==35100&&visible==3283);
 visualSprites=0;[self sprite:1 x:10 y:10 width:20 height:20];assert(visualSprites==1);
 [self sprite:1 x:640 y:10 width:20 height:20];assert(visualSprites==1);
 AstroSceneSprite beam={0};beam.sprite=116;beam.alpha=.5;beam.rect[0]=10;beam.rect[1]=10;beam.rect[2]=20;beam.rect[3]=20;
 [self drawSceneSprite:&beam];assert(visualSprites==2);assert(glGetError()==GL_NO_ERROR);
 beam.persistent=1;[self drawSceneSprite:&beam];assert(visualSprites==2);
 AstroHUDState state={1,100,1,0,0,3,123};AstroHUDCommand commands[32];size_t n=astro_hud_commands(&state,commands,32);int expected=0;
 for(size_t i=0;i<n;i++)if(commands[i].kind==ASTRO_HUD_SPRITE)expected++;
 visualSprites=0;[hud drawState:&state texture:^GLuint(NSInteger id){return [self texture:id];} framebufferWidth:640 height:480];assert(visualSprites==expected&&expected>0);assert(glGetError()==GL_NO_ERROR);
 visualDebug=NO;splashVisible=NO;menuVisible=YES;visualSprites=999;[self drawRect:self.bounds];int menuCount=visualSprites;assert(menuCount>0&&menuCount<999);
 visualSprites=999;[self drawRect:self.bounds];assert(visualSprites==menuCount);
 menuVisible=NO;flow.phase=ASTRO_FLOW_PLAY;campaign.level=4;backgrounds=@[];parallaxData=[NSData data];[enemies removeAllObjects];[world removeAllObjects];[visualEffects removeAllObjects];playerHitVisual.active=NO;engineGlow=departureTrail=NO;
 visualSprites=999;[self drawRect:self.bounds];assert(visualSprites==0);
 AstroVisual flash={115,10,10,20,20,0};specialFlashes=[NSMutableArray arrayWithObject:[NSData dataWithBytes:&flash length:sizeof flash]];
 visualSprites=2;[self presentSpecialFrame];assert(visualSprites==3);assert(glGetError()==GL_NO_ERROR);
 NSError *error=nil;ui=[[FPSUI alloc] initWithAssets:assets error:&error];assert(ui);
 const int rates[]={0,60,-7,32767};const int counts[]={0,1,-1,INT32_MAX};NSArray *texts=@[@" 0 fps  0 sprites drawn",@" 60 fps  1 sprites drawn",@"-7 fps -1 sprites drawn",@" 32767 fps  2147483647 sprites drawn"];
 visualDebug=YES;
 for(unsigned i=0;i<4;i++){
  visualRate=rates[i];visualSprites=counts[i];visualFrames=32767;glMatrixMode(GL_MODELVIEW);glLoadIdentity();glTranslated(13,17,0);
  [self presentFrame];assert(glGetError()==GL_NO_ERROR);assert([captured isEqual:texts[i]]&&calls==i+1&&visualFrames==INT16_MIN);assert(rgba[0]==1&&rgba[1]==1&&rgba[2]==1);
  double matrix[16];glGetDoublev(GL_MODELVIEW_MATRIX,matrix);for(int j=0;j<16;j++)assert(matrix[j]==(j%5==0?1:0));
 }
 visualDebug=NO;[self presentFrame];assert(calls==4&&visualFrames==INT16_MIN+1);assert(glGetError()==GL_NO_ERROR);
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);
 puts("PASS native visibility35100/3283, linked/temporary sprites, HUD sprite commands, menu/game resets and deferred special count, exact reachable native FPS strings, debug gate, signed16 wrap and final modelview identity");
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 NSString *assets=[NSString stringWithUTF8String:argv[1]];AstroView *view=[[AstroView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(view);NSWindow *window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,640,480) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];window.releasedWhenClosed=NO;window.contentView=view;[window makeKeyAndOrderFront:nil];[view prepareOpenGL];[view checkFPSDisplay:assets];[window close];return 0;
}}
