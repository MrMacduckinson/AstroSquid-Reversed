// Coupled root menu frames. Original GPU/audio calls are observers; real stars/UI state retained.
#define astro_stars_draw transition_stars_draw
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#undef astro_stars_draw
#import <OpenGL/glext.h>
extern void astro_stars_draw(const AstroStar *,int,int,double,const AstroSceneSink *);
static unsigned profile,route,reads,frame,actualClockCalls;static BOOL recording;
static BOOL dispatchMode,routesMode,returnsMode,startupMode,startupInput,heldButton;static NSPoint heldPoint;
static NSString *const routeButtons[]={@"Play",@"Continue",@"Back7",@"Back2",@"Highscores",@"Back4",@"Settings",@"SetKeys",@"Back6",@"Back",@"Register",@"Back3"};
static NSString *const returnButtons[]={@"Yeah",@"Back5"};
static FILE *star_dump;static AstroUIRenderer *observedUI;static AstroView *observedView;
static uint64_t word(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static void snapshot(unsigned f){unsigned i=0;for(NSDictionary *object in [observedUI valueForKey:@"objects"]){NSString *name=object[@"name"];AstroUIMotion *s=[[[observedUI valueForKey:@"orbStates"]objectForKey:name]mutableBytes];uint32_t deadline=[[[observedUI valueForKey:@"hoverDeadlines"]objectForKey:name]unsignedIntValue];printf("N,%u,%u,%u,%u,%d,%d,%u",profile,route,f,i++,s->sprite,s->counter,deadline);double v[]={s->x,s->y,s->width,s->height};for(unsigned a=0;a<4;a++)printf(",%016llx",word(v[a]));putchar('\n');}assert(i==52);}
void transition_stars_draw(const AstroStar *stars,int menu,int stage,double sx,const AstroSceneSink *sink){
 if(recording&&menu){uint64_t words[3000*4];for(unsigned i=0;i<3000;i++){double v[]={stars[i].brightness,stars[i].x,stars[i].y,stars[i].speed};for(unsigned a=0;a<4;a++)words[i*4+a]=CFSwapInt64HostToBig(word(v[a]));}assert(fwrite(words,8,3000*4,star_dump)==3000*4);
  printf("S,%u,%u,%u,%u,%016llx,%016llx",profile,route,frame,[[observedView valueForKey:@"randomSeed"]unsignedIntValue],word(observedUI.cameraX),word(observedUI.cameraY));double v[]={stars[0].brightness,stars[0].x,stars[0].y,stars[0].speed};for(unsigned a=0;a<4;a++)printf(",%016llx",word(v[a]));putchar('\n');}
 astro_stars_draw(stars,menu,stage,sx,sink);
}
@interface TransitionUI:AstroUIRenderer
@end
@implementation TransitionUI
- (void)drawSprites:(AstroUISpriteDrawer)draw texture:(AstroUITextureLoader)texture {if(recording){snapshot(frame);printf("D,%u,%u,%u\nO,%u,%u,%u\n",profile,route,frame,profile,route,frame);}}
@end
@interface TransitionAudio:AstroAudio
@end
@implementation TransitionAudio
- (BOOL)playCue:(NSString *)name position:(double)p {if(recording){assert(dispatchMode&&[name isEqual:@"Click"]);printf("P,%u,%u,%016llx,%d\n",profile,route,word(p),[[observedView valueForKey:@"menuMouseLatched"]boolValue]);}return YES;}
- (void)serviceMusic {if(recording)printf("U,%u,%u,%u\n",profile,route,frame);}
- (void)stop {}
@end
@interface TransitionView:AstroView
- (void)checkTransitions;
@end
@implementation TransitionView
- (uint32_t)currentGameTick {actualClockCalls++;if(!recording)return 1000;assert(reads<10000);uint32_t t=1000+reads++;printf("T,%u,%u,%u",profile,route,t);if(dispatchMode)printf(",%d",menuMouseLatched);putchar('\n');return t;}
- (void)copyKeyMap:(unsigned char *)map {memset(map,0,16);if(startupInput&&profile<3)map[4]=0x10;if(recording)printf("K,%u,%u,%u\n",profile,route,frame);}
- (NSPoint)currentMenuMousePoint {return profile>=6?heldPoint:NSMakePoint(-30000,-30000);}
- (BOOL)menuMouseButtonPressed {return heldButton;}
- (void)saveSettings {if(recording){assert(dispatchMode&&route==(routesMode?9u:1u)&&[ui.anchor isEqual:@"Settings Menu"]);AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"Back"]mutableBytes];uint32_t deadline=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"Back"]unsignedIntValue];printf("I,%u,%u,%d,%u,%016llx,%016llx\n",profile,route,s->sprite,deadline,word(ui.cameraX),word(ui.cameraY));}}
- (void)display {if(recording){[self drawRect:self.bounds];assert(!menuFrameActive);if(frame==0||!ui.transitioning){unsigned clocks=actualClockCalls;uint32_t seed=randomSeed;recording=NO;[self drawRect:self.bounds];recording=YES;assert(actualClockCalls==clocks&&randomSeed==seed);}}}
- (void)presentFrame {if(recording){visualFrames=(int16_t)((uint16_t)visualFrames+1u);printf("W,%u,%u,%u\n",profile,route,frame++);assert(frame<1000);}}
- (void)checkTransitions {
 [timer invalidate];timer=nil;[audio stop];audio=[TransitionAudio new];selftestPath=campaignTestPath=nil;splashVisible=NO;menuVisible=YES;gameEndRequested=YES;gameOver=paused=NO;editingKey=-1;spriteMapsPreloaded=YES;deferPresent=NO;observedView=self;
 [[self openGLContext]makeCurrentContext];GLuint fbo,color;glGenFramebuffersEXT(1,&fbo);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fbo);glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,640,480,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)==GL_FRAMEBUFFER_COMPLETE_EXT);
 for(profile=0;profile<(dispatchMode?9u:3u);profile++){
  recording=NO;ui=[[TransitionUI alloc]initWithAssets:assetPath error:NULL];assert(ui);observedUI=ui;if(routesMode){ui.registered=NO;ui.unlockedLevel=16;}ui.frameInterval=profile%3+1;[ui setValue:@(-599.5) forKey:@"cameraX"];[ui setValue:@(-344) forKey:@"cameraY"];
  for(NSDictionary *object in [ui valueForKey:@"objects"])[[ui valueForKey:@"hoverDeadlines"]setObject:@1000 forKey:object[@"name"]];
  __weak TransitionView *weakSelf=self;ui.readTick=^{return [weakSelf currentGameTick];};randomSeed=0x12345678;menuScroll=(AstroVelocity){2,-1};visualFrames=0;visualRateTick=1000;visualDebug=NO;reads=0;menuMouseLatched=NO;assert(!navigationButton);
  for(unsigned i=1;i<=3000;i++)stars[i-1]=(AstroStar){80,(i*17)%640,(i*29)%480,i%5+1};
  if(startupMode){[ui setValue:@0 forKey:@"cameraX"];[ui setValue:@0 forKey:@"cameraY"];[ui show:@"Main Menu"];while(ui.transitioning)[ui advanceMenuCamera];splashVisible=YES;}
  recording=YES;
  for(route=0;route<(startupMode?1u:routesMode?12u:2u);route++){
   frame=0;NSString *button=returnsMode?returnButtons[route]:routesMode?routeButtons[route]:route?@"Back":@"Settings";
   if(returnsMode){recording=NO;[ui show:route?@"Reg Thanks":@"CreditsMenu"];while(ui.transitioning)[ui advanceMenuCamera];recording=YES;}
   if(startupMode){heldButton=profile>=3;heldPoint=NSMakePoint(369,175);startupInput=YES;[self pollMenu];startupInput=NO;assert(!splashVisible);for(unsigned poll=0;ui.transitioning;poll++){assert(poll<10000);[self pollMenu];}}
   else if(dispatchMode){
    heldButton=profile>=3;assert(!menuMouseLatched);AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:button]mutableBytes];NSPoint p=NSMakePoint((int)(ui.cameraX+s->x+s->width/2),(int)(ui.cameraY+s->y+s->height/2));heldPoint=p;[self handleMenuMouseAtPoint:p];assert(navigationButton);
    for(unsigned poll=0;navigationButton;poll++){assert(poll<10000);[self pollMenu];}
   }else{
    [ui setButton:button pressed:YES];[ui show:route?@"Main Menu":@"Settings Menu"];observedWallTick=[self currentGameTick];for(unsigned poll=0;ui.transitioning;poll++){assert(poll<10000);[self pollMenu];}[ui setButton:button pressed:NO];
   }
   snapshot(999);printf("Z,%u,%u,%u,%u,%016llx,%016llx",profile,route,frame,reads,word(ui.cameraX),word(ui.cameraY));if(dispatchMode){assert(menuMouseLatched==(startupMode?(profile>=3):YES));printf(",%d",menuMouseLatched);}putchar('\n');
   if(dispatchMode&&route<(routesMode?11u:1u)){if(heldButton){unsigned before=frame;printf("H,%u,%u\n",profile,route);[self pollMenu];printf("F,%u,%u,%d\n",profile,route,menuMouseLatched);assert(frame==before+1&&menuMouseLatched);heldButton=NO;}unsigned before=frame;printf("B,%u,%u\n",profile,route);[self pollMenu];printf("E,%u,%u,%d\n",profile,route,menuMouseLatched);assert(frame==before+1&&!menuMouseLatched);}

  }recording=NO;
 }
 if(startupMode){
  splashVisible=YES;[self mouseUp:[self testMouse:NSLeftMouseUp x:0 y:0]];assert(splashVisible);
  [self keyDown:[self testEvent:NSKeyDown code:255]];assert(splashVisible);
  [self keyDown:[self testEvent:NSKeyDown code:36]];assert(!splashVisible&&ui.transitioning&&menuMouseLatched&&keys[36]);[ui animateTicks:120];[self keyUp:[self testEvent:NSKeyUp code:36]];
  splashVisible=YES;[self mouseDown:[self testMouse:NSLeftMouseDown x:0 y:0]];assert(!splashVisible&&ui.transitioning&&menuMouseLatched);[ui animateTicks:120];
  splashVisible=YES;[self testModifier:58 flags:0];assert(splashVisible);[self testModifier:58 flags:NSEventModifierFlagOption|NX_DEVICELALTKEYMASK];assert(!splashVisible&&ui.transitioning&&menuMouseLatched);[self testModifier:58 flags:0];
  fputs("PASS startup direct key/modifier/mousedown paths; release and unsupported key do not accept\n",stderr);
 }
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,0);glDeleteFramebuffersEXT(1,&fbo);glDeleteTextures(1,&color);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==3||argc==4);dispatchMode=argc==4;routesMode=dispatchMode&&!strcmp(argv[3],"routes");returnsMode=dispatchMode&&!strcmp(argv[3],"returns");startupMode=dispatchMode&&!strcmp(argv[3],"startup");assert(!dispatchMode||routesMode||returnsMode||startupMode||!strcmp(argv[3],"dispatch"));star_dump=fopen(argv[2],"wb");assert(star_dump);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];TransitionView *v=[[TransitionView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v checkTransitions];assert(!fclose(star_dump));
}}
