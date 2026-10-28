#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include <assert.h>
static BOOL recording;static unsigned profile,reads;
static uint64_t bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
@interface SetupView:AstroView
- (void)checkSetup;
@end
@implementation SetupView
- (uint32_t)currentGameTick {if(!recording)return 1000;uint32_t t=1000+reads++;assert(reads<1000);printf("T,%u,%u,%u,%016llx,%016llx\n",profile,t,randomSeed,bits(ui.cameraX),bits(ui.cameraY));return t;}
- (void)checkSetup {
    [timer invalidate];timer=nil;[audio stop];selftestPath=campaignTestPath=nil;
    ui.registered=NO;ui.unlockedLevel=16;
    const uint32_t seeds[]={0,0x12345678,UINT32_MAX};
    for(profile=0;profile<9;profile++){
        ui.frameInterval=profile%3+1;randomSeed=seeds[profile/3];reads=0;
        [ui setValue:@(profile/3==1?-1234.25:profile/3==2?33.25:0) forKey:@"cameraX"];[ui setValue:@(profile/3==1?19.5:profile/3==2?-44.5:0) forKey:@"cameraY"];
        printf("P,%u,%u,%u\n",profile,profile%3+1,randomSeed);recording=YES;[self reloadMainMenu];recording=NO;
        unsigned i=0;for(NSDictionary *object in [ui valueForKey:@"objects"]){
            NSString *name=object[@"name"];AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:name]mutableBytes];
            uint32_t deadline=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:name]unsignedIntValue];
            printf("N,%u,%u,%d,%d,%u,%016llx,%016llx,%016llx,%016llx\n",profile,i++,s->sprite,s->counter,deadline,bits(s->x),bits(s->y),bits(s->width),bits(s->height));
        }assert(i==52&&starsInitialized);
        for(i=0;i<3000;i++)printf("S,%u,%u,%016llx,%016llx,%016llx,%016llx\n",profile,i,bits(stars[i].brightness),bits(stars[i].x),bits(stars[i].y),bits(stars[i].speed));
        printf("Z,%u,%u,%u,%016llx,%016llx,%016llx,%016llx\n",profile,reads,randomSeed,bits(ui.cameraX),bits(ui.cameraY),bits(menuScroll.x),bits(menuScroll.y));
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    SetupView *view=[[SetupView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkSetup];
}}
