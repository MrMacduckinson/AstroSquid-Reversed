// Actual production LM host replay. Runtime only on remote Intel reference Mac.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static uint32_t clockValues[16];static unsigned clockCount,clockIndex,keyIndex,keyCalls;
static BOOL replaying,expectedDebug;
static double fromWord(unsigned long long u){uint64_t b=u;double d;memcpy(&d,&b,8);return d;}
static uint64_t raw(double d){uint64_t b;memcpy(&b,&d,8);return b;}
static void equalVisual(AstroVisual a,AstroVisual b){assert(a.sprite==b.sprite&&a.next_tick==b.next_tick);assert(raw(a.x)==raw(b.x)&&raw(a.y)==raw(b.y)&&raw(a.width)==raw(b.width)&&raw(a.height)==raw(b.height));}
@interface AstroVisualClockView : AstroView
@end
@implementation AstroVisualClockView
- (uint32_t)playerClockTick {if(!replaying)return [super playerClockTick];assert(clockIndex<clockCount);return clockValues[clockIndex++];}
- (void)readVisualKeys {assert(replaying&&clockIndex==keyIndex);keyCalls++;visualDebug=expectedDebug;}
- (void)display {}
@end
@interface AstroView (VisualClockCheck)
- (void)checkVisualClock:(const char *)path;
@end
@implementation AstroView (VisualClockCheck)
- (void)checkVisualClock:(const char *)path {
    [timer invalidate];timer=nil;[audio stop];audio.soundVolume=audio.musicVolume=0;
    selftestPath=@"visual-clock";campaignTestPath=selftestPath;
    FILE *f=fopen(path,"r");assert(f);char line[512];unsigned cases=0,totalClocks=0;
    memset(spriteInfo,0,sizeof spriteInfo);
    spriteInfo[1]=(AstroSpriteInfo){10,20,2,7};spriteInfo[2]=(AstroSpriteInfo){24,12,0,3};
    spriteInfo[3]=(AstroSpriteInfo){10,20,-1,7};spriteInfo[4]=(AstroSpriteInfo){10,20,0,7};spriteInfo[5]=(AstroSpriteInfo){10,20,2,7};
    while(fgets(line,sizeof line,f)) {
        int scenario;unsigned diagnostic;assert(sscanf(line,"CASE,%d,%u",&scenario,&diagnostic)==2&&scenario==(int)cases);
        AstroVisual initial[5],expected[5];int deleted[5]={0};
        for(int i=0;i<5;i++){int n,id;unsigned deadline;unsigned long long x,y,w,h;assert(fgets(line,sizeof line,f));assert(sscanf(line,"I,%d,%d,%u,%llx,%llx,%llx,%llx",&n,&id,&deadline,&x,&y,&w,&h)==7&&n==i);initial[i]=(AstroVisual){id,fromWord(x),fromWord(y),fromWord(w),fromWord(h),deadline};}
        clockCount=clockIndex=keyCalls=0;keyIndex=0;unsigned nativeClocks=0;int wantFrames=0,wantDebug=0,wantHead=0;unsigned wantRateTick=0;unsigned long long wantRate=0;
        while(fgets(line,sizeof line,f)){
            if(line[0]=='T'){unsigned n,address,t;assert(sscanf(line,"T,%u,%x,%u",&n,&address,&t)==3&&n==clockCount&&clockCount<16);clockValues[clockCount++]=t;}
            else if(line[0]=='K')keyIndex=clockCount;
            else if(line[0]=='B'){unsigned bit,debug;assert(sscanf(line,"B,%u,%u",&bit,&debug)==2&&bit==125);expectedDebug=debug;}
            else if(line[0]=='O'){int n,id,next,previous;unsigned deadline;unsigned long long x,y,w,h;int gone;assert(sscanf(line,"O,%d,%d,%d,%u,%llx,%llx,%llx,%llx,%d,%d",&n,&gone,&id,&deadline,&x,&y,&w,&h,&next,&previous)==10&&n>=0&&n<5);deleted[n]=gone;expected[n]=(AstroVisual){id,fromWord(x),fromWord(y),fromWord(w),fromWord(h),deadline};}
            else if(line[0]=='G')assert(sscanf(line,"G,%d,%d,%u,%d,%llx",&wantHead,&wantFrames,&wantRateTick,&wantDebug,&wantRate)==5);
            else if(!strncmp(line,"END,",4)){assert(sscanf(line,"END,%u",&nativeClocks)==1);break;}
            else assert(line[0]=='D');
        }
        assert(nativeClocks==clockCount);
        enemies=[NSMutableArray array];world=[NSMutableArray array];visualEffects=[NSMutableArray array];
        AstroEnemy *first=[AstroEnemy new],*second=[AstroEnemy new];first->active=second->active=scenario!=5;
        first->kind=second->kind=2;first->state.remove=second->state.remove=0;
        NSMutableData *effect=[NSMutableData dataWithLength:sizeof(LiveEffect)];LiveEffect *live=effect.mutableBytes;
        // Rotate owner types on odd cases so positive effect changes must interleave
        // with enemy/hit/player changes by native creation order, not array category.
        int kinds[5]={0,0,1,2,3};if(scenario&1){int alternate[]={1,0,3,0,2};memcpy(kinds,alternate,sizeof kinds);}
        AstroVisual *actual[5];AstroEnemy *owners[5]={0};unsigned enemyNumber=0;
        playerHitVisual.active=NO;playerVisualDeleted=NO;
        for(int i=0;i<5;i++){
            if(kinds[i]==0){AstroEnemy *e=enemyNumber++?second:first;e->visual=initial[i];e->renderBirth=i+1;actual[i]=&e->visual;owners[i]=e;if(scenario!=5){[enemies addObject:e];[world addObject:e];}}
            else if(kinds[i]==1){live->visual=initial[i];live->birth=i+1;live->layer=7;actual[i]=&live->visual;if(scenario!=5)[visualEffects addObject:effect];}
            else if(kinds[i]==2){playerHitVisual.visual=initial[i];playerHitVisual.active=scenario!=5;playerHitBirth=i+1;actual[i]=&playerHitVisual.visual;}
            else {playerVisual=initial[i];playerRenderBirth=i+1;actual[i]=&playerVisual;if(scenario!=5)[world addObject:[NSNull null]];}
        }
        visualFrames=-7;visualRate=1.25;visualRateTick=diagnostic;visualDebug=NO;
        replaying=YES;[self handleVisualEffects];replaying=NO;
        assert(clockIndex==clockCount&&keyCalls==1&&visualFrames==wantFrames&&visualRateTick==wantRateTick&&visualDebug==wantDebug&&raw(visualRate)==wantRate);
        for(int i=0;i<5;i++){
            equalVisual(*actual[i],expected[i]);
            if(kinds[i]==0){assert(owners[i]->visualDeleted==deleted[i]&&owners[i]->state.remove==0);if(scenario!=5)assert([world containsObject:owners[i]]&&[enemies containsObject:owners[i]]);}
            else if(kinds[i]==1)assert(([visualEffects containsObject:effect]?0:1)==(scenario==5?1:deleted[i]));
            else if(kinds[i]==2)assert(playerHitVisual.active==(scenario!=5&&!deleted[i]));
            else assert(playerVisualDeleted==deleted[i]);
        }
        assert((scenario==5)==(wantHead==-1));totalClocks+=clockCount;cases++;
    }
    assert(feof(f)&&cases==6&&totalClocks==25);fclose(f);
    // Production presentation increments the signed16 diagnostic frame counter.
    [[self openGLContext] makeCurrentContext];visualFrames=INT16_MAX;[self presentFrame];assert(visualFrames==INT16_MIN);[self presentFrame];assert(visualFrames==INT16_MIN+1);
    puts("PASS actual production LM host:6 native scripts/25 clockreads, mixed birth ordering, IEEE geometry/deadlines, signed diagnostic gates, GetKeys/debug ordering, LMkill without entity removal, signed frame wrap");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"smooth":@YES,@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroVisualClockView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkVisualClock:argv[2]];
}}
