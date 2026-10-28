// Replay actual G5 GETKEYMAP outputs; side-effect flags are interpreted, not executed.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned char fixtureMap[16];
static unsigned pauseEntries;
@interface NativeKeysView : AstroView
@end
@implementation NativeKeysView
- (void)display {}
- (void)enterPause {pauseEntries++;[super enterPause];}
- (void)copyKeyMap:(unsigned char *)bytes {memcpy(bytes,fixtureMap,16);}
@end
@implementation AstroView (NativeKeysCheck)
- (void)checkNativeKeys:(const char *)path {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=0;
    selftestPath=campaignTestPath=nil;int defaults[6]={55,58,126,125,123,124};memcpy(controlKeys,defaults,sizeof(defaults));
    FILE *f=fopen(path,"r");assert(f);char line[512];assert(fgets(line,sizeof(line),f));unsigned count=0,poison=0;
    while(fgets(line,sizeof(line),f)){
        unsigned id,copy,pad,shots;char hex[33];int debug,quitBefore,left,right,up,down,pause,fire,special,any,quitAfter;
        assert(sscanf(line,"%u,%32[^,],%u,%d,%d,%u,%d,%d,%d,%d,%d,%d,%d,%d,%d,%u",
            &id,hex,&copy,&debug,&quitBefore,&pad,&left,&right,&up,&down,&pause,&fire,&special,&any,&quitAfter,&shots)==16);
        assert(pad==0);
        if(copy!=16){assert(id==135&&copy==32&&any==1);poison++;continue;}
        for(unsigned i=0;i<16;i++){unsigned byte;assert(sscanf(hex+2*i,"%2x",&byte)==1);fixtureMap[i]=byte;}
        memset(keys,1,sizeof(keys));[self readKeyMap];
        assert(keys[123]==left&&keys[124]==right&&keys[126]==up&&keys[125]==down);
        assert(keys[53]==pause&&keys[55]==fire&&keys[58]==special);
        int pressed=0;for(unsigned i=0;i<128;i++)pressed+=keys[i];assert(pressed==any);
        assert(quitAfter==(quitBefore||(keys[55]&&keys[12])));
        assert(shots==(unsigned)(debug==1&&keys[67]));
        count++;
    }
    assert(!ferror(f));fclose(f);assert(count==136&&poison==1);
    puts("PASS136 original G5 keymaps: control bits/count, Escape pause flag, CmdQ latch and keypad-multiply screenshot mapping; poison extra-bit case separate");fflush(stdout);
    memset(keys,0,sizeof(keys));splashVisible=menuVisible=paused=gameOver=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;editingKey=-1;
    [self keyDown:[self testEvent:NSKeyDown code:50]];assert(!paused&&!menuVisible);
    [self keyUp:[self testEvent:NSKeyUp code:50]];
    [self keyDown:[self testEvent:NSKeyDown code:53]];assert(!paused&&!menuVisible);
    memset(fixtureMap,0,16);fixtureMap[6]=0x20;[self readGameKeys];
    assert(pauseEntries==1&&!paused&&!menuVisible);
    [self keyUp:[self testEvent:NSKeyUp code:53]];
    puts("PASS host pause binding matches original Escape; grave does not pause");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[NativeKeysView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view checkNativeKeys:argv[2]];
}}
