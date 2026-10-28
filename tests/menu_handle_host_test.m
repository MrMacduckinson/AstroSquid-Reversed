// Actual root handler, UI list and shared diagnostics; no persistent writes.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned sample,reads;
static BOOL observing,checkingOrder,overlayOrder;
static unsigned orderStep;
static const uint32_t starts[]={100,101,160,UINT32_MAX-1,0x7fffffff,0x80000000};
@interface MenuHandleView:AstroView
- (void)checkHandle;
@end
@implementation MenuHandleView
- (uint32_t)playerClockTick {if(!observing)return 1000;uint32_t n=starts[sample]+reads++;printf("T,%u,%u\n",sample,n);return n;}
- (void)copyKeyMap:(unsigned char *)p {memset(p,0,16);if(sample&1)p[15]=4;if(observing)printf("K,%u,%u\n",sample,sample&1);}
- (void)handleMenuSprites {if(checkingOrder){assert(!overlayOrder&&orderStep==0);orderStep=1;}[super handleMenuSprites];}
- (void)pollMenuMouse {if(checkingOrder){assert(orderStep==(overlayOrder?0:1));orderStep=2;}else [super pollMenuMouse];}
- (void)display {if(checkingOrder){assert(orderStep==2);orderStep=3;}}
- (void)presentFrame {if(checkingOrder){assert(orderStep==3);orderStep=4;}}
- (void)checkHandle {
    [timer invalidate];timer=nil;[audio stop];
    for(sample=0;sample<6;sample++){
        ui.readTick=nil;[ui reloadMenuWithRandom:&randomSeed];
        NSArray *objects=[ui valueForKey:@"objects"];assert(objects.count>=6);
        NSDictionary *states=[ui valueForKey:@"orbStates"];NSMutableDictionary *deadlines=[ui valueForKey:@"hoverDeadlines"];
        const int16_t ids[]={0,1,900,901,902,902};
        for(unsigned i=0;i<6;i++){
            NSString *name=objects[i][@"name"];AstroUIMotion *s=[states[name]mutableBytes];*s=(AstroUIMotion){381+i*.125,222-i*.25,65+i*.125,65-i*.125,0,ids[i]};deadlines[name]=@(i==5?starts[sample]-1:starts[sample]);
        }
        __weak MenuHandleView *weakSelf=self;ui.readTick=^{return [weakSelf playerClockTick];};
        reads=0;visualFrames=-7;visualRateTick=sample==3?UINT32_MAX-59:100;visualRate=3.5;
        observing=YES;[self handleMenuSprites];observing=NO;
        for(unsigned i=0;i<6;i++){
            NSString *name=objects[i][@"name"];AstroUIMotion *s=[states[name]mutableBytes];printf("N,%u,%u,%d,%u",sample,i,s->sprite,[deadlines[name]unsignedIntValue]);
            double values[]={s->x,s->y,s->width,s->height};for(unsigned a=0;a<4;a++){uint64_t b;memcpy(&b,&values[a],8);printf(",%016llx",b);}putchar('\n');
        }
        uint64_t bits;memcpy(&bits,&visualRate,8);printf("F,%u,%d,%d,%u,%016llx,%u\n",sample,visualDebug,visualFrames,visualRateTick,bits,reads);
    }
    checkingOrder=YES;splashVisible=NO;deferPresent=NO;
    for(unsigned overlay=0;overlay<2;overlay++){
        overlayOrder=overlay;orderStep=0;[ui show:overlay?@"GameOver":@"Main Menu"];[ui animateTicks:60];[self stepMenu];assert(orderStep==4);
    }
    fputs("PASS root normal handler before mouse/draw; GameOver excludes handler\n",stderr);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    MenuHandleView *view=[[MenuHandleView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkHandle];
}}
