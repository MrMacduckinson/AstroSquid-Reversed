// Actual finishGameOver and drawRect terminal commands, no persistent score writes.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static unsigned exit_case,records;
static BOOL observing,closing;
static AstroUIRenderer *observedUI;
static AstroView *observedView;
static void event(char code){if(!observing)return;records++;printf("%u,%c,%d,%d,%d,%d\n",exit_case,code,!closing,observedUI.editingHighscore>0,[[observedUI valueForKey:@"pressed"] isEqual:@"GameOverOK"]?901:900,[[observedView valueForKey:@"gameEndRequested"] boolValue]);}
@interface AstroUIRenderer (ExitProbe)
- (void)beginGameOverExit;
- (void)finishGameOverExit;
@end
@interface ExitUI:AstroUIRenderer
@end
@implementation ExitUI
- (void)beginGameOverExit {[super beginGameOverExit];closing=YES;assert([[self valueForKey:@"gameOverClosing"] boolValue]);event('C');}
- (void)drawSprites:(AstroUISpriteDrawer)draw texture:(AstroUITextureLoader)texture {event('O');}
- (void)finishGameOverExit {
    [super finishGameOverExit];for(NSDictionary *object in [self valueForKey:@"objects"])assert((![@[@"GameOverOK",@"GameOverFade"]containsObject:object[@"name"]]));event('B');event('F');
}
@end
@interface ExitHUD:AstroHUDRenderer
@end
@implementation ExitHUD
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)w height:(GLsizei)h {event('H');}
@end
@interface ExitView:AstroView
- (void)checkExit;
@end
@implementation ExitView
- (void)display {if(observing){event('R');[self drawRect:self.bounds];}}
- (void)presentFrame {event('W');}
- (void)saveScores {event('I');}
- (void)sprite:(NSInteger)n x:(double)x y:(double)y width:(double)w height:(double)h {if(!observing)[super sprite:n x:x y:y width:w height:h];}
- (void)checkExit {
    [timer invalidate];timer=nil;[audio stop];spriteMapsPreloaded=YES;flow.phase=ASTRO_FLOW_PLAY;campaign.level=4;
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));enemies=[NSMutableArray array];world=[NSMutableArray array];visualEffects=[NSMutableArray array];specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];playerVisualDeleted=YES;playerHitVisual.active=NO;engineGlow=departureTrail=NO;
    ui=[[ExitUI alloc]initWithAssets:assetPath error:NULL];hud=[[ExitHUD alloc]initWithGame:game ui:ui];observedUI=ui;observedView=self;
    [[self openGLContext]makeCurrentContext];GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);while(glGetError()!=GL_NO_ERROR){}
    for(exit_case=0;exit_case<2;exit_case++){
        [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=exit_case;ui.editingName=@"TEST";
        score=exit_case?100:0;strcpy(scoreEditor.name,"TEST");astro_scores_clear(highscores);menuVisible=gameOver=YES;gameEndRequested=gameEndHighscores=NO;deferPresent=exit_case;closing=NO;records=0;
        observing=YES;[self finishGameOver];event('Z');observing=NO;
        assert(gameEndRequested&&!menuVisible&&!gameOver&&gameEndHighscores==(BOOL)exit_case&&deferPresent==(BOOL)exit_case);
        assert(glGetError()==GL_NO_ERROR);
        if(exit_case)assert(highscores[0].score==100&&!strcmp(highscores[0].name,"TEST"));
    }
    glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    ExitView *view=[[ExitView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkExit];
}}
