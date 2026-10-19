// Actual menu poll clock boundary; native fixture retains fuller OS/body order.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static BOOL injecting;
static uint32_t clockValues[2];
static unsigned clockCount,clockUsed,bodies,draws;
static uint32_t bodyDeadline;
static NSMutableString *events;
@interface AstroMenuGateView : AstroView
@end
@implementation AstroMenuGateView
- (uint32_t)currentGameTick {
    if(!injecting)return [super currentGameTick];
    assert(clockUsed<clockCount);[events appendString:clockUsed?@"T":@"C"];return clockValues[clockUsed++];
}
- (void)stepMenu {
    bodies++;bodyDeadline=observedWallTick;[events appendString:@"B"];[super stepMenu];
}
- (void)display {if(injecting){draws++;[events appendString:@"D"];}}
@end
@interface AstroView (MenuGateCheck)
- (void)checkMenuGates:(const char *)path;
@end
@implementation AstroView (MenuGateCheck)
- (void)checkMenuGates:(const char *)path {
    [timer invalidate];timer=nil;[audio stop];splashVisible=NO;
    FILE *file=fopen(path,"r");assert(file);char trace[4096];int mode,id,interval;unsigned before,comparison,store,reads,after,checked=0;
    while(fscanf(file,"%d,%d,%d,%u,%u,%u,%u,%u,%4095s",&mode,&id,&interval,&before,&comparison,&store,&reads,&after,trace)==9){
        (void)id;if(mode==3)continue;assert(mode>=0&&mode<3);
        [ui show:mode==0?@"Play Menu":mode==1?@"Pause":@"GameOver"];
        [ui animateTicks:60];ui.frameInterval=interval;
        observedWallTick=before;clockValues[0]=comparison;clockValues[1]=store;clockCount=reads;
        clockUsed=bodies=draws=0;bodyDeadline=0;events=[NSMutableString string];injecting=YES;
        [self pollMenu];injecting=NO;
        assert(clockUsed==reads&&observedWallTick==after);
        assert(bodies==(reads==2)&&draws==bodies);
        if(reads==2){assert(bodyDeadline==(mode==0?after:before));assert([events isEqualToString:mode==0?@"CTBD":@"CBDT"]);}
        else assert([events isEqualToString:@"C"]);
        checked++;
    }
    assert(feof(file)&&checked==30);fclose(file);puts("PASS30 original Main/Pause/GameOver interval gates, independent clocks, store/body order and actual gated drawing");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroMenuGateView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkMenuGates:argv[2]];
}}
