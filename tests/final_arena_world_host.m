// Actual production cleanup/death/map path; compare with the original native composite.
#define ASTRO_WORLD_TRACE_LIBRARY
#include "world_trace_host.m"
static const char *retainedStarPath;
static unsigned compositeClocks;static BOOL advancing,outerFrame,loopMode,resumeMode,midMode,midFull;static unsigned loopStep;static char resumeLabel[32];
static __weak AstroView *midView;
@interface AstroView(MidCapture)
- (void)captureMidFrame;
@end
@interface CompositeArenaAudio:AstroTraceAudio
@end
@implementation CompositeArenaAudio
- (void)serviceMusic {if(midMode)[midView captureMidFrame];else [super serviceMusic];}
- (void)stopMusic {puts("A\tstop");}
- (BOOL)playMusic:(int)track {if(midMode){assert(track==1);puts("A\tplay1");}else {assert(track==2);puts("A\tplay2");}return YES;}
@end
@interface CompositeArenaView:AstroTraceView
@end
@implementation CompositeArenaView
- (void)display {if(loopMode||midMode){if(hudRedraws)hudRedraws--;}else [super display];}
- (void)copyKeyMap:(unsigned char *)bytes {
    if(midMode){memset(bytes,0,16);return;}
    if(!loopMode){[super copyKeyMap:bytes];return;}
    memset(bytes,0,16);unsigned input=(loopStep/8)%16;int codes[5]={126,125,123,124,55};
    for(unsigned i=0;i<5;i++)if(i==4?loopStep%7==0:(input&(1u<<i)))bytes[codes[i]>>3]|=1u<<(codes[i]&7);
}
- (void)createPlayerAtX:(double)x y:(double)y {if(resumeMode&&loopStep)playerTraceID=++nextEntityID;[super createPlayerAtX:x y:y];}
- (void)handleMiscKeys {
    if(!loopMode&&!midMode){[super handleMiscKeys];return;}
    if(resumeMode){[self dumpWorldTrace:[NSString stringWithUTF8String:tracePhase]];
        printf("K\t%u\t%u\t%u\t%u\n",loopStep,compositeClocks,observedWallTick,worldRenderTick);
        if(++loopStep==256)@throw [NSException exceptionWithName:@"TraceFinished" reason:nil userInfo:nil];
        snprintf(resumeLabel,sizeof resumeLabel,"loop%u",loopStep);tracePhase=resumeLabel;
    }
}
- (uint32_t)playerClockTick {unsigned index=compositeClocks++;return 100+(advancing&&tracePhase&&strcmp(tracePhase,"before")?index:0);}
- (void)renderTick {if(!outerFrame)[super renderTick];}
@end
@implementation AstroView(CompositeArena)
- (void)captureMidFrame {
    [self dumpWorldTrace:[NSString stringWithUTF8String:tracePhase]];printf("K\t%u\t%u\t%u\t%u\n",loopStep,compositeClocks,observedWallTick,worldRenderTick);
    if(++loopStep==16&&!midFull)@throw [NSException exceptionWithName:@"MidTraceFinished" reason:nil userInfo:nil];
    snprintf(resumeLabel,sizeof resumeLabel,"mid%u",loopStep);tracePhase=resumeLabel;
}
- (void)runCompositeArena:(const char *)phaseOutput {
    midFull=phaseOutput&&!strncmp(phaseOutput,"midfull",7);midMode=phaseOutput&&!strncmp(phaseOutput,"mid",3);resumeMode=phaseOutput&&!strncmp(phaseOutput,"resume",6);loopMode=resumeMode||(phaseOutput&&!strncmp(phaseOutput,"loop",4));
    BOOL chainMode=phaseOutput&&!strcmp(phaseOutput,"chain");
    BOOL runMode=phaseOutput&&!strncmp(phaseOutput,"run",3);
    BOOL startMode=midMode||loopMode||chainMode||runMode||(phaseOutput&&!strncmp(phaseOutput,"start",5));
    BOOL inputs=phaseOutput&&!strcmp(phaseOutput,"outer-input256");
    [timer invalidate];timer=nil;[audio stop];audio=[[CompositeArenaAudio alloc]initWithAssets:assetPath error:NULL];assert(audio);
    entityIDs=[NSMapTable strongToStrongObjectsMapTable];nextEntityID=1;playerTraceID=1;
    world=[NSMutableArray array];enemies=[NSMutableArray array];visualEffects=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];starsInitialized=YES;renderClock=0;simulationTick=100;
    campaign=(AstroCampaign){8,2,0,0};inventory=(AstroInventory){0};selectedLevel=[levels indexOfObject:@"Data 8B"];
    if(phaseOutput&&(!strncmp(phaseOutput,"load",4)||startMode)){for(unsigned chain=0;chain<(chainMode?17u:1u);chain++){
        unsigned level=0;char half=0,extra=0;if(chainMode){level=chain/2+1;half=chain==16?'B':chain%2?'B':'A';}else assert(sscanf(phaseOutput+(midFull?7:midMode?3:resumeMode?6:loopMode?4:runMode?3:startMode?5:4),"%u%c%c",&level,&half,&extra)==2&&level>=1&&level<=9&&(half=='A'||half=='B'));
        selectedLevel=[levels indexOfObject:[NSString stringWithFormat:@"Data %u%c",level,half]];assert(selectedLevel!=NSNotFound);
        if(!chain){randomSeed=123;compositeClocks=0;}camera=-0.0;traceTick=100;char label[24];snprintf(label,sizeof label,"load%u%c",level,half);tracePhase=chainMode?label:"load";nextEntityID=playerTraceID=0;entityIDs=[NSMapTable strongToStrongObjectsMapTable];
        if(retainedStarPath&&!chain){NSData *d=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:retainedStarPath]];assert(d.length==96004);const unsigned char *b=d.bytes;
            for(unsigned i=0;i<12000;i++){uint64_t v=0;for(unsigned j=0;j<8;j++)v=(v<<8)|b[i*8+j];memcpy((unsigned char *)stars+i*8,&v,8);}randomSeed=((uint32_t)b[96000]<<24)|((uint32_t)b[96001]<<16)|((uint32_t)b[96002]<<8)|b[96003];}
        [self resetLevelWorld];
        if(startMode){inventory.lives=1;playerTraceID=++nextEntityID;[self createPlayerAtX:30 y:190];[self finishPlayerStart];inventory.weapon=playerWeapon=10;inventory.specials=1;}
        [self dumpWorldTrace:[NSString stringWithUTF8String:tracePhase]];
        unsigned index=0;unsigned char bytes[38];
        for(NSDictionary *m in mapPlacements){be64(bytes,number(m,@"x"));be64(bytes+8,number(m,@"y"));be64(bytes+16,number(m,@"width"));be64(bytes+24,number(m,@"height"));be16(bytes+32,[m[@"attribute"] intValue]);be32(bytes+34,[m[@"tag"] intValue]);printf("P\t%u\t",index++);dump(bytes,38);putchar('\n');}
        for(index=0;index<3000;index++){be64(bytes,stars[index].brightness);be64(bytes+8,stars[index].x);be64(bytes+16,stars[index].y);be64(bytes+24,stars[index].speed);printf("T\t%u\t",index);dump(bytes,32);putchar('\n');}
        if(midMode){
            ui.musicVolume=1;menuVisible=paused=gameOver=NO;flow.phase=ASTRO_FLOW_PLAY;automatic=YES;tracePhase="mid0";[self beginGameLoop];
            campaign.half=2;tickedScroll=0;[self beginStageTransition];
            midView=self;loopStep=0;@try {[self runMidlevelTransition];}@catch(NSException *e){assert([e.name isEqual:@"MidTraceFinished"]);}
            if(midFull){[self dumpWorldTrace:@"mid-end"];printf("K\tend\t%u\t%u\t%u\n",compositeClocks,observedWallTick,worldRenderTick);}
        }
        if(loopMode){
            menuVisible=paused=gameOver=changingStage=NO;flow.phase=ASTRO_FLOW_PLAY;automatic=YES;campaign.arena=0;
            int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);memset(keys,0,sizeof keys);
            tracePhase="loop0";[self beginGameLoop];
            if(resumeMode){loopStep=0;@try {while(loopStep<256)[self pollGame];}@catch(NSException *e){assert([e.name isEqual:@"TraceFinished"]);}}
            else for(loopStep=0;loopStep<256;loopStep++){char label[32];snprintf(label,sizeof label,"loop%u",loopStep);tracePhase=label;[self pollGame];[self dumpWorldTrace:[NSString stringWithUTF8String:label]];
                printf("K\t%u\t%u\t%u\t%u\n",loopStep,compositeClocks,observedWallTick,worldRenderTick);if(respawnPending||gameEndRequested||campaignAction!=ASTRO_CAMPAIGN_NONE){printf("B\t%u\t%d\t%d\n",loopStep,gameEndRequested?1:respawnPending?-1:0,campaignAction!=ASTRO_CAMPAIGN_NONE);break;}}
        }
        if(runMode){tickedScroll=1;for(unsigned step=0;step<256;step++){
            char label[32];snprintf(label,sizeof label,"run%u",step);tracePhase=label;
            unsigned input=(step/8)%16;int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);memset(keys,0,sizeof keys);keys[126]=(input&1)!=0;keys[125]=(input&2)!=0;keys[123]=(input&4)!=0;keys[124]=(input&8)!=0;keys[55]=step%7==0;
            [self cleanupWorld];[self calculateActors];[self handleVisualEffects];[self makeNewSprites];
            [self dumpWorldTrace:[NSString stringWithUTF8String:label]];
        }}
        fprintf(stderr,"LOAD %u%c maps%lu scenes%lu clocks%u RNG%08x\n",level,half,(unsigned long)mapPlacements.count,(unsigned long)backgrounds.count,compositeClocks,randomSeed);}return;
    }
    randomSeed=123;camera=0;tickedScroll=0;[self createPlayerAtX:1400 y:180];playerCombat=(AstroCombatState){.kind=1,.hit_points=73};playerState.frame=1;
    for(int i=0;i<2;i++){
        NSDictionary *a=game[@"attributes"][@"73"];int sprite=[a[@"sprite"] intValue];
        AstroEnemy *e=[self entityForPlacement:@{@"attribute":@73,@"x":@(1500+i*100),@"y":@(i?100:180),
            @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height),@"tag":@(i?0:-2)}];
        e->active=YES;if(!i)e->state.remove=-1;else e->hitPoints=71;[self prependEnemy:e];
    }
    camera=1234.25;ui.musicVolume=1;traceTick=100;tracePhase="before";[self dumpWorldTrace:@"before"];
    outerFrame=phaseOutput&&(!strcmp(phaseOutput,"outer")||!strcmp(phaseOutput,"outer64")||!strcmp(phaseOutput,"outer-map256")||inputs);
    if(outerFrame){
        campaign.arena=1;observedWallTick=100;compositeClocks=0;tracePhase="outer";[self advanceWorldForWait:NO];[self dumpWorldTrace:@"outer"];
        assert(compositeClocks==211&&camera==1&&randomSeed==0xf8ce7428&&nextEntityID==33&&renderClock==52);
        fprintf(stderr,"HOST outerbody camera%.17g clocks%u RNG%08x entities%u images%llu\n",camera,compositeClocks,randomSeed,nextEntityID,(unsigned long long)renderClock);if(strcmp(phaseOutput,"outer"))for(unsigned step=1;step<((!strcmp(phaseOutput,"outer-map256")||inputs)?256u:64u);step++){
            char label[32];snprintf(label,sizeof label,"follow%u",step);tracePhase=label;
            if(inputs){unsigned input=(step/8)%16;int controls[6]={55,58,126,125,123,124};memcpy(controlKeys,controls,sizeof controls);inventory.weapon=playerWeapon=10;memset(keys,0,sizeof keys);keys[126]=(input&1)!=0;keys[125]=(input&2)!=0;keys[123]=(input&4)!=0;keys[124]=(input&8)!=0;keys[55]=step%7==0;}
            [self cleanupWorld];[self calculateActors];[self handleVisualEffects];
            if(!strcmp(phaseOutput,"outer-map256")||inputs)[self makeNewSprites];
            [self dumpWorldTrace:[NSString stringWithUTF8String:label]];
        }
        return;
    }
    compositeClocks=0;tracePhase="cleanup";[self cleanupWorld];[self dumpWorldTrace:@"cleanup"];
    fprintf(stderr,"HOST finalarena composite clocks%u RNG%08x entities%u images%llu backgrounds%lu\n",compositeClocks,randomSeed,nextEntityID,(unsigned long long)renderClock,(unsigned long)backgrounds.count);
    if(phaseOutput){
        [world removeAllObjects];[enemies removeAllObjects];[self calculateActors];
        assert(worldTop==0&&signbit(worldTop)&&worldBottom==380);FILE *out=fopen(phaseOutput,"wb");assert(out);
        unsigned char bytes[32];for(unsigned i=0;i<3000;i++){be64(bytes,stars[i].brightness);be64(bytes+8,stars[i].x);be64(bytes+16,stars[i].y);be64(bytes+24,stars[i].speed);assert(fwrite(bytes,1,32,out)==32);}
        const AstroParallax *p=parallaxData.bytes;for(unsigned i=0;i<backgrounds.count;i++){be64(bytes,p[i].x);be64(bytes+8,p[i].y);be32(bytes+16,p[i].depth);assert(fwrite(bytes,1,20,out)==20);}
        assert(!fclose(out));fprintf(stderr,"HOST first CALC star phase RNG%08x\n",randomSeed);
    }
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc>=2&&argc<=5);if(argc==5)retainedStarPath=argv[4];advancing=argc>=3;if(advancing)assert(!strcmp(argv[2],"advancing"));[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    CompositeArenaView *view=[[CompositeArenaView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view runCompositeArena:argc>=4?argv[3]:NULL];
}}
