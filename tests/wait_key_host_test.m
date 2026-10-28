#define astro_stars_move wait_stars_move
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#undef astro_stars_move
static unsigned scenario,reads,polls,frames;static uint32_t base;static BOOL recording,binding,dispatchMode;
static AstroView *observedView;
static uint64_t wait_bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static NSString *bindingName;static NSArray *oldLabels;
void wait_stars_move(AstroStar *stars,double cx,double cy,double left,double top,double right,double bottom,double sx,double sy,double ix,double iy,int interval,uint32_t *seed,AstroParallax *layers,size_t count,int menu){assert(ix==0&&iy==0&&menu);if(recording)printf("M,%u,%u\n",scenario,frames);}
@interface AstroUIRenderer (KeyCaptureGeometry)
- (NSDictionary *)object:(NSString *)name;
- (NSRect)bounds:(NSDictionary *)object;
@end
@interface WaitUI:AstroUIRenderer
@end
@implementation WaitUI
- (void)animateMenuObjects {if(recording)printf("A,%u,%u\n",scenario,frames);}
@end
@interface WaitAudio:AstroAudio
@end
@implementation WaitAudio
- (BOOL)playCue:(NSString *)name position:(double)p {if(recording&&dispatchMode)printf("P,%u,%016llx,%d\n",scenario,wait_bits(p),[[observedView valueForKey:@"menuMouseLatched"]boolValue]);return YES;}
- (void)serviceMusic {if(recording)printf("U,%u,%u\n",scenario,frames);}
- (void)stop {}
@end
@interface WaitView:AstroView
- (void)checkWait;
@end
@implementation WaitView
- (uint32_t)currentGameTick {if(!recording)return 1000;assert(reads<2000);uint32_t t=base+reads++;printf("T,%u,%u",scenario,t);if(dispatchMode){AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:bindingName]mutableBytes];printf(",%d,%d",s->sprite,menuMouseLatched);}putchar('\n');return t;}
- (void)copyKeyMap:(unsigned char *)p {
    memset(p,0,16);unsigned n=polls++,inputCase=dispatchMode?(scenario%3==0?128:scenario%3==1?130:131):scenario;
    if(inputCase<128)p[inputCase>>3]|=1u<<(inputCase&7);
    else if(inputCase==128)p[0]=0x81;
    else if(inputCase==129){p[0]=1;p[15]=0x80;}
    else if(inputCase==130&&n>=4)p[7]=4;
    if(recording){printf("K,%u,%u,",scenario,n);for(unsigned i=0;i<16;i++)printf("%02x",p[i]);putchar('\n');}
}
- (void)pollKeyCaptureEvents {
    unsigned before=reads;[self tick:nil];[self tickWallClock];assert(reads==before);
    if(binding){AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:bindingName]mutableBytes];assert(s->sprite==901&&!menuMouseLatched&&[ui.keyLabels isEqual:oldLabels]);}
    if(recording)printf("E,%u,%u\n",scenario,polls);
}
- (void)display {assert(!menuFrameActive);if(recording){printf("S,%u,%u\nD,%u,%u\nO,%u,%u",scenario,frames,scenario,frames,scenario,frames);if(dispatchMode){AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:bindingName]mutableBytes];printf(",%d,%d",s->sprite,menuMouseLatched);for(unsigned i=0;i<6;i++)printf(",%d",controlKeys[i]);}putchar('\n');}}
- (void)presentFrame {if(recording)printf("W,%u,%u\n",scenario,frames++);}
- (void)handleMenuSprites {abort();}
- (void)pollMenuMouse {abort();}
- (void)checkWait {
    [timer invalidate];timer=nil;[audio stop];audio=[WaitAudio new];selftestPath=campaignTestPath=nil;
    observedView=self;ui=[[WaitUI alloc]initWithAssets:assetPath error:NULL];assert(ui);menuVisible=YES;splashVisible=paused=gameOver=NO;
    NSArray *names=@[@"SetKeyFire",@"SetKeySpecial",@"SetKeyUp",@"SetKeyDown",@"SetKeyLeft",@"SetKeyRight"];
    for(scenario=0;scenario<(dispatchMode?18u:134u);scenario++){
        reads=polls=frames=0;base=scenario==133?UINT32_MAX-300:1000;unsigned interval=scenario<131?1:scenario-130;
        if(dispatchMode){ui=[[WaitUI alloc]initWithAssets:assetPath error:NULL];assert(ui);__weak WaitView *weakSelf=self;ui.readTick=^{return [weakSelf currentGameTick];};bindingName=names[scenario/3];oldLabels=nil;binding=NO;const int raw[]={55,58,126,125,123,124};memcpy(controlKeys,raw,sizeof(raw));[self refreshKeyLabels];oldLabels=[ui.keyLabels copy];binding=YES;interval=(scenario/3)%3+1;base=scenario/3==5?UINT32_MAX-300:1000;[ui setValue:@0 forKey:@"cameraX"];[ui setValue:@0 forKey:@"cameraY"];menuMouseLatched=NO;editingKey=-1;}
        ui.frameInterval=interval;observedWallTick=base;if(!dispatchMode)editingKey=0;recording=YES;
        if(dispatchMode){printf("C,%u,%u,%u\n",scenario,interval,base);[self performMenuAction:bindingName];AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:bindingName]mutableBytes];printf("Z,%u,%u,%u,%u,%u,%d,%d",scenario,reads,polls,frames,observedWallTick,s->sprite,menuMouseLatched);for(unsigned i=0;i<6;i++)printf(",%d",controlKeys[i]);putchar('\n');recording=NO;continue;}
        printf("P,%u,%u,%u\n",scenario,interval,base);int code=[self waitForMenuKey];
        printf("Z,%u,%d,%d,%u,%u,%u,%u\n",scenario,code<0?-1:code^7,code,reads,polls,frames,observedWallTick);recording=NO;editingKey=-1;
    }
    if(dispatchMode){binding=NO;fputs("PASS18 original DOMOUSE key binding transactions\n",stderr);return;}
    scenario=128;binding=YES;ui.frameInterval=1;
    for(unsigned slot=0;slot<6;slot++){
        int saved[6];memcpy(saved,controlKeys,sizeof(saved));oldLabels=[ui.keyLabels copy];bindingName=names[slot];menuMouseLatched=NO;observedWallTick=1000;
        [self performMenuAction:bindingName];assert(controlKeys[slot]==0&&editingKey==-1&&menuMouseLatched);
        for(unsigned j=0;j<6;j++)if(j!=slot)assert(controlKeys[j]==saved[j]);
        AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:bindingName]mutableBytes];assert(s->sprite==900&&[ui.keyLabels[slot] isEqual:[ui nameForKeyCode:0]]);
    }
    binding=NO;[ui show:@"Keys Menu"];[ui animateTicks:120];bindingName=@"SetKeyFire";controlKeys[0]=55;[self refreshKeyLabels];oldLabels=[ui.keyLabels copy];binding=YES;menuMouseLatched=NO;
    NSRect r=[ui bounds:[ui object:bindingName]];[self handleMenuMouseAtPoint:NSMakePoint(NSMidX(r),NSMidY(r))];assert(controlKeys[0]==0&&menuMouseLatched&&editingKey==-1);
    [self keyDown:[self testEvent:NSKeyDown code:7]];[self keyDown:[self testEvent:NSKeyDown code:0]];assert(controlKeys[0]==0);
    binding=NO;fputs("PASS134 original WAITFORKEY traces, six binding actions and actual hit dispatch, pressed/reset/labels/latch/reentry guards\n",stderr);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2||argc==3);dispatchMode=argc==3;assert(!dispatchMode||!strcmp(argv[2],"dispatch"));[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    WaitView *view=[[WaitView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkWait];
}}
