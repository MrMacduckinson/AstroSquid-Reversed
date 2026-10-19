// Actual production AstroView renderer in a controlled offscreen fixture.
// Runtime only on remote Intel; never primaryMac. No persistent preferences.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>

// Pin the controlled reference resolution on Retina displays; renderer is inherited.
@interface AstroReferenceView : AstroView
@end
@implementation AstroReferenceView
- (NSRect)convertRectToBacking:(NSRect)rect {return rect;}
@end

static BOOL referenceHUDEdge;
static BOOL referenceWrongHUDOrder;
@interface AstroView (RenderReference)
- (void)renderReferenceTrial:(int)trial smooth:(BOOL)smooth output:(NSString *)output;
- (void)stopReferenceRuntime;
@end
@implementation AstroView (RenderReference)
- (void)stopReferenceRuntime {
    [timer invalidate];timer=nil;audio.soundVolume=0;audio.musicVolume=0;[audio setPaused:YES];
    selftestPath=@"controlled-render-reference";campaignTestPath=selftestPath;
}
- (void)renderReferenceTrial:(int)trial smooth:(BOOL)smooth output:(NSString *)output {
    menuVisible=NO;splashVisible=NO;paused=NO;gameOver=NO;
    flow=(AstroFlow){.phase=ASTRO_FLOW_PLAY};changingStage=NO;
    simulationTick=100;simulationRender=NO;invulnerableUntil=0;
    campaign=(AstroCampaign){.level=trial%3==0?1:trial%3==1?4:7};
    double cy=trial<3?0:-13.5;camera=trial<3?0:37.25;tickedScroll=0;
    ui.smooth=smooth;
    for(NSNumber *key in textures){GLuint texture=[textures[key] unsignedIntValue];glDeleteTextures(1,&texture);}
    [textures removeAllObjects];
    memset(stars,0,sizeof(stars));
    for(int i=0;i<1000;i++)stars[i]=(AstroStar){i%100+1,(i*37)%640+.25,(i*29)%380+.5,0};
    backgrounds=@[@{@"sprite":@44,@"width":@350,@"height":@300}];
    AstroParallax background={40.25,30.5+cy,0};parallaxData=[NSMutableData dataWithBytes:&background length:sizeof(background)];
    enemies=[NSMutableArray array];world=[NSMutableArray array];
    visualEffects=[NSMutableArray array];liveBeams=[NSMutableArray array];presentedBeams=nil;
    specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    playerHitVisual=(AstroPlayerHitVisual){0};
    int ids[]={240,200,47},kinds[]={5,20,2};
    double xywh[][4]={{210.25,170.5,144,52},{250.5,170.25,117,114},{260.5,180.25,30,34}};
    if(referenceHUDEdge){xywh[2][0]=50;xywh[2][1]=374;}
    uint64_t births[]={3,4,6};
    for(int i=0;i<3;i++){
        AstroEnemy *e=[AstroEnemy new];e->active=YES;e->kind=kinds[i];e->renderLayer=kinds[i]==5?5:kinds[i]==20?4:6;e->renderBirth=births[i];
        e->visual=(AstroVisual){ids[i],xywh[i][0],xywh[i][1]+cy,xywh[i][2],xywh[i][3],100};
        [enemies addObject:e];[world addObject:e];
    }
    playerVisual=(AstroVisual){1,230.25,180.5+cy,142,40,100};
    playerX=playerVisual.x-camera;playerY=playerVisual.y;playerRenderBirth=5;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=100};[world addObject:[NSNull null]];
    departureTrail=YES;trailRect=(AstroTransitionRect){120.5,180.25+cy,88,120};
    engineGlow=YES;engineGlowBirth=9;departureGlow=(AstroTransitionRect){195.25,160.5+cy,82,82};
    LiveEffect shield={{71,220.25,155.5+cy,100,100,100},7,7};
    LiveEffect boom={{83,280.5,155.25+cy,80,90,100},7,8};
    [visualEffects addObject:[NSData dataWithBytes:&shield length:sizeof(shield)]];
    [visualEffects addObject:[NSData dataWithBytes:&boom length:sizeof(boom)]];
    glDisable(GL_DITHER);[self drawRect:self.bounds];
    if(referenceWrongHUDOrder){AstroHUDState overlay={0};[hud drawState:&overlay texture:^GLuint(NSInteger n){return [self texture:n];} framebufferWidth:640 height:480];}
    glFinish();assert(glGetError()==GL_NO_ERROR);
    NSMutableData *rgba=[NSMutableData dataWithLength:640*380*4];
    glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);glPixelStorei(GL_PACK_ALIGNMENT,1);
    glReadPixels(0,30,640,380,GL_RGBA,GL_UNSIGNED_BYTE,rgba.mutableBytes);assert(glGetError()==GL_NO_ERROR);
    NSString *file=[output stringByAppendingPathComponent:[NSString stringWithFormat:@"port-%d-%d.rgba",smooth?1:0,trial]];
    assert([rgba writeToFile:file atomically:YES]);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc>=3&&argc<=5);referenceHUDEdge=argc>=4;referenceWrongHUDOrder=argc==5;[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSDictionary *muted=@{@"AstroSquidSettings":@{@"smooth":@YES,@"sound":@0,@"music":@0}};
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:muted forName:NSArgumentDomain];
    AstroView *view=[[AstroReferenceView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);
    [view stopReferenceRuntime];[[view openGLContext] makeCurrentContext];[view prepareOpenGL];
    NSRect backing=[view convertRectToBacking:view.bounds];assert(backing.size.width==640&&backing.size.height==480);
    GLuint fbo,color;glGenFramebuffersEXT(1,&fbo);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fbo);
    glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);
    assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
    glDrawBuffer(GL_COLOR_ATTACHMENT0_EXT);glReadBuffer(GL_COLOR_ATTACHMENT0_EXT);assert(glGetError()==GL_NO_ERROR);
    printf("Production AstroView GL renderer %s\n",glGetString(GL_RENDERER));
    NSString *output=[NSString stringWithUTF8String:argv[2]];[[NSFileManager defaultManager] createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:NULL];
    for(int smooth=0;smooth<2;smooth++)for(int trial=0;trial<6;trial++)[view renderReferenceTrial:trial smooth:smooth output:output];
    puts("PASS:12 actual production AstroView controlled framebuffer crops written");return 0;
}}
