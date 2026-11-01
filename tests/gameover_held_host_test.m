// Actual queued keyDown -> pollMenu frame gate and terminal drawRect, no score writes.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <OpenGL/glext.h>
static unsigned exit_case,records,clockReads,keyPolls,alerts,tails;
static AstroScoreEditor *observedEditor;
static uint32_t *observedWall;
static BOOL observing,composite;static unsigned polls;
static BOOL *observedLatch,*observedEnd;
static AstroUIRenderer *observedUI;
static int currentSprite(void){NSData *state=[[observedUI valueForKey:@"orbStates"]objectForKey:@"GameOverOK"];return state?((const AstroUIMotion *)state.bytes)->sprite:901;}
static void compositeEvent(char kind,unsigned value){
 AstroScoreCaret caret;[[observedUI valueForKey:@"caret"]getValue:&caret];
 printf("%u,%c,%u,%u,%u,%d,%d,%d,%d,%d,%d,%u,%d,",exit_case,kind,value,clockReads,*observedWall,!observedUI.gameOverClosing,*observedEnd,*observedLatch,observedUI.editingHighscore>0,observedEditor->submitted,observedEditor->cursor,caret.deadline,caret.visible);
 for(const unsigned char *p=(const unsigned char *)observedEditor->name;*p;p++)printf("%02x",*p);putchar('\n');
 if(kind=='O'||kind=='A'||kind=='Z')for(NSDictionary *object in [observedUI valueForKey:@"objects"]){
  NSString *name=object[@"name"];AstroUIMotion *state=[[[observedUI valueForKey:@"orbStates"]objectForKey:name]mutableBytes];NSData *label=[name dataUsingEncoding:NSMacOSRomanStringEncoding];
  printf("N,%u,%c,",exit_case,kind);const unsigned char *bytes=label.bytes;for(unsigned i=0;i<label.length;i++)printf("%02x",bytes[i]);
  printf(",%d,%d,%u,%d",[object[@"kind"]intValue],state->sprite,[[[observedUI valueForKey:@"hoverDeadlines"]objectForKey:name]unsignedIntValue],state->counter);
  double v[]={state->x,state->y,state->width,state->height};for(unsigned i=0;i<4;i++){uint64_t bits;memcpy(&bits,v+i,8);printf(",%016llx",bits);}putchar('\n');
 }
}
static void eventValue(char code,unsigned value){
    if(!observing)return;if(composite){compositeEvent(code,value);return;}records++;
    printf("%u,%c,%u,%d,%d,%d,%u,",exit_case,code,value,!observedUI.gameOverClosing,currentSprite(),observedEditor->submitted,*observedWall);
    for(unsigned i=0;i<strlen(observedEditor->name);i++)printf("%02x",(unsigned char)observedEditor->name[i]);printf(",%d\n",observedEditor->cursor);
}
static void event(char code){eventValue(code,0);}
@interface AstroUIRenderer (ExitProbe)
- (void)beginGameOverExit;
- (void)finishGameOverExit;
@end
@interface ExitUI:AstroUIRenderer
@end
@implementation ExitUI
- (void)beginGameOverExit {[super beginGameOverExit];assert([[self valueForKey:@"gameOverClosing"] boolValue]);if(composite)return;event('P');
    AstroUIMotion *state=[[[self valueForKey:@"orbStates"]objectForKey:@"GameOverOK"]mutableBytes];uint32_t deadline=[[[self valueForKey:@"hoverDeadlines"]objectForKey:@"GameOverOK"]unsignedIntValue];
    printf("%u,G,%u",exit_case,deadline);double values[]={state->x,state->y,state->width,state->height};for(unsigned i=0;i<4;i++){uint64_t bits;memcpy(&bits,&values[i],8);printf(",%016llx",bits);}putchar('\n');
}
- (void)animateTicks:(unsigned)ticks {[super animateTicks:ticks];event('A');}
- (void)drawSprites:(AstroUISpriteDrawer)draw texture:(AstroUITextureLoader)texture {if(composite)[super drawSprites:draw texture:texture];event('O');}
- (void)finishGameOverExit {
    [super finishGameOverExit];for(NSDictionary *object in [self valueForKey:@"objects"])assert((![@[@"GameOverOK",@"GameOverFade"]containsObject:object[@"name"]]));if(!composite){event('B');event('F');}
}
@end
@interface ExitHUD:AstroHUDRenderer
@end
@implementation ExitHUD
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)w height:(GLsizei)h {event('H');}
@end
@interface InputAudio:AstroAudio
@end
@implementation InputAudio
- (void)serviceMusic {event('S');}
- (BOOL)playCue:(NSString *)name position:(double)pan {if(!observing||!composite)return YES;assert([name isEqualToString:@"Click"]);uint64_t bits;memcpy(&bits,&pan,8);printf("C,%u,%016llx\n",exit_case,bits);return YES;}
- (void)stop {}
@end
@interface AstroView(HeldProbe)
- (void)handleMenuMouseAtPoint:(NSPoint)p;
@end
@interface ExitView:AstroView
- (void)checkExit;
@end
@implementation ExitView
- (void)display {if(observing){event('R');[self drawRect:self.bounds];}}
- (void)presentFrame {event('W');}
- (void)saveScores {event('I');}
- (void)finishGameOver {tails++;[super finishGameOver];}
- (BOOL)continueScoreOverflow:(NSData *)left right:(NSData *)right {assert(left.length==255&&right.length==1);alerts++;return YES;}
- (uint32_t)currentGameTick {if(!observing)return 1000;uint32_t tick=1000+clockReads++;eventValue('T',tick);return tick;}
- (void)copyKeyMap:(unsigned char *)bytes {if(composite&&observing){polls++;if((polls==2||polls==4||polls==35)){NSString *text=polls==2?@"A":polls==4?@"B":@"\r";[self keyDown:[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:text charactersIgnoringModifiers:text isARepeat:NO keyCode:polls==35?36:0]];}}memset(bytes,0,16);BOOL any=YES;if(any)bytes[0]=1;eventValue('K',any);}
- (NSPoint)currentMenuMousePoint {return composite&&exit_case>=3&&polls>=16&&polls<=25?NSMakePoint(413,362):NSMakePoint(225,260);}
- (BOOL)menuMouseButtonPressed {return observing&&!(composite&&exit_case>=3&&polls>=8&&polls<=10);}
- (void)handleMenuMouseAtPoint:(NSPoint)p {[super handleMenuMouseAtPoint:p];event('D');}
- (BOOL)editScoreByte:(unsigned)ch {eventValue('E',ch);return [super editScoreByte:ch];}
- (void)sprite:(NSInteger)n x:(double)x y:(double)y width:(double)w height:(double)h {if(!observing)[super sprite:n x:x y:y width:w height:h];}
- (void)checkExit {
    [timer invalidate];timer=nil;[audio stop];audio=[InputAudio new];selftestPath=campaignTestPath=nil;spriteMapsPreloaded=YES;splashVisible=NO;flow.phase=ASTRO_FLOW_PLAY;campaign.level=4;
    backgrounds=@[];parallaxData=[NSMutableData data];memset(stars,0,sizeof(stars));enemies=[NSMutableArray array];world=[NSMutableArray array];visualEffects=[NSMutableArray array];specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];playerVisualDeleted=YES;playerHitVisual.active=NO;engineGlow=departureTrail=NO;
    ui=[[ExitUI alloc]initWithAssets:assetPath error:NULL];hud=[[ExitHUD alloc]initWithGame:game ui:ui];__weak ExitView *weakSelf=self;ui.readTick=^{return [weakSelf currentGameTick];};observedUI=ui;observedEditor=&scoreEditor;observedWall=&observedWallTick;observedLatch=&menuMouseLatched;observedEnd=&gameEndRequested;
    [[self openGLContext]makeCurrentContext];GLuint framebuffer,color;glGenFramebuffersEXT(1,&framebuffer);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,framebuffer);glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);while(glGetError()!=GL_NO_ERROR){}
    for(exit_case=0;exit_case<(composite?6u:3u);exit_case++){
        [ui show:@"GameOver"];[ui animateTicks:60];ui.editingHighscore=1;ui.frameInterval=exit_case%3+1;ui.editingName=@"TEST";if(composite){[ui prepareScoreField];[ui beginScoreClock:1000];}
        score=100;astro_score_editor_begin(&scoreEditor);[self refreshScoreEditor];astro_scores_clear(highscores);menuVisible=gameOver=YES;gameEndRequested=gameEndHighscores=NO;deferPresent=NO;records=clockReads=keyPolls=polls=0;observedWallTick=1000;
        menuMouseLatched=YES;
        if(!composite){
            for(NSDictionary *input in @[@{@"code":@0,@"text":@"A"},@{@"code":@11,@"text":@"B"},@{@"code":@36,@"text":@""}]){
                NSEvent *key=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:input[@"text"] charactersIgnoringModifiers:input[@"text"] isARepeat:NO keyCode:[input[@"code"]unsignedShortValue]];[self keyDown:key];
            }
            assert(!scoreEditor.name[0]&&!scoreEditor.submitted&&!gameEndRequested);
        }
        observing=YES;for(unsigned poll=0;poll<100&&!gameEndRequested;poll++)[self pollMenu];event('Z');observing=NO;
        assert(gameEndRequested&&!menuVisible&&!gameOver&&gameEndHighscores&&!deferPresent);
        assert(glGetError()==GL_NO_ERROR);
        assert(highscores[0].score==100&&!strcmp(highscores[0].name,"BA"));
    }
    if(composite){assert(tails==6);glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);return;}
    assert(tails==3);[ui show:@"GameOver"];[ui animateTicks:60];ui.gameOverClosing=YES;
    menuVisible=gameOver=YES;gameEndRequested=NO;[self performMenuAction:@"GameOverOK"];
    assert(tails==3&&gameEndRequested&&menuVisible);
    fputs("PASS closing OK requests end without recursively redrawing terminal tail\n",stderr);
    glDeleteFramebuffersEXT(1,&framebuffer);glDeleteTextures(1,&color);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    setvbuf(stdout,NULL,_IONBF,0);assert(argc==2||argc==3);composite=argc==3;assert(!composite||!strcmp(argv[2],"composite"));[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    ExitView *view=[[ExitView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkExit];
}}
