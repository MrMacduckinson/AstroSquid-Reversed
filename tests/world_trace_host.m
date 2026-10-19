// Production host canonical state. Run only on remote Intel; no primary GUI.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static void be16(unsigned char *p,int value){uint16_t u=(uint16_t)value;p[0]=u>>8;p[1]=u;}
static void be32(unsigned char *p,uint32_t u){for(int i=3;i>=0;i--){p[i]=u;u>>=8;}}
static void be64(unsigned char *p,double value){uint64_t u;memcpy(&u,&value,8);for(int i=7;i>=0;i--){p[i]=u;u>>=8;}}
static void dump(const unsigned char *p,int count){for(int i=0;i<count;i++)printf("%02x",p[i]);}
static void rectBytes(unsigned char *p,AstroRect r){be16(p,r.top);be16(p+2,r.left);be16(p+4,r.bottom);be16(p+6,r.right);}
@interface AstroView (WorldTrace)
- (void)initialWorldTrace;
@end
@implementation AstroView (WorldTrace)
- (void)initialWorldTrace {
    [timer invalidate];timer=nil;audio.soundVolume=audio.musicVolume=0;[audio setPaused:YES];
    selftestPath=@"canonical-world";campaignTestPath=selftestPath;
    simulationTick=0;renderClock=1;randomSeed=0x12345678;camera=0;tickedScroll=1;
    enemies=[NSMutableArray array];world=[NSMutableArray arrayWithObject:[NSNull null]];
    visualEffects=[NSMutableArray array];liveBeams=[NSMutableArray array];
    playerVisual=(AstroVisual){1,100,180,71,20,0};playerRenderBirth=1;
    playerEntityX=100;playerEntityY=180;playerX=100;playerY=180;
    playerBounds=(AstroRect){100,180,171,200};previousPlayerBounds=(AstroRect){0};
    playerCombat=(AstroCombatState){.kind=1,.hit_points=200};
    playerState=(AstroPlayer){.frame=12,.tilt=3,.state=1};playerVelocity=(AstroVelocity){0};
    lastPlayerShot=0;inventory=(AstroInventory){10,0,2,0};campaign=(AstroCampaign){0};score=0;
    int attrs[]={73,204,73,401},xs[]={300,200,450,160},ys[]={180,250,100,180};
    for(int i=0;i<4;i++){
        NSDictionary *a=game[@"attributes"][[NSString stringWithFormat:@"%d",attrs[i]]];
        int sprite=[a[@"sprite"] intValue];
        AstroEnemy *e=[self entityForPlacement:@{@"attribute":@(attrs[i]),@"x":@(xs[i]),@"y":@(ys[i]),
            @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height)}];
        e->active=YES;if(i<2)e->hitPoints=1;[self prependEnemy:e];
    }
    AstroShot shot={.type=1,.x=300,.y=180};[self spawnShot:&shot source:1];
    shot.x=200;shot.y=250;[self spawnShot:&shot source:1];
    unsigned char viewport[32]={0},scroll[16]={0},inv[10]={0},stats[12]={0};
    be64(viewport,0);be64(viewport+8,640);be64(viewport+16,0);be64(viewport+24,380);
    be64(scroll,tickedScroll);be64(scroll+8,0);be16(inv,inventory.weapon);be16(inv+2,inventory.upgrade);be16(inv+4,inventory.specials);
    printf("G\t0\tinitial\t%08x\t1\t",randomSeed);dump(viewport,32);putchar('\t');dump(scroll,16);putchar('\t');dump(inv,10);putchar('\t');dump(stats,12);putchar('\n');
    for(NSUInteger i=0;i<world.count;i++){
        id object=world[i];BOOL player=object==[NSNull null];AstroEnemy *e=player?nil:object;
        unsigned eid=player?1:(unsigned)e->renderBirth;
        unsigned before=i? (world[i-1]==[NSNull null]?1:(unsigned)((AstroEnemy*)world[i-1])->renderBirth):0;
        unsigned after=i+1<world.count?(world[i+1]==[NSNull null]?1:(unsigned)((AstroEnemy*)world[i+1])->renderBirth):0;
        unsigned char bytes[106]={0};int attr=player?11:[e->placement[@"attribute"] intValue];
        NSDictionary *a=game[@"attributes"][[NSString stringWithFormat:@"%d",attr]];
        AstroScriptState st=player?(AstroScriptState){.frame=playerState.frame,.tilt=playerState.tilt,.state=playerState.state,.x=playerEntityX,.y=playerEntityY,.velocity=playerVelocity}:e->state;
        be16(bytes,player?playerCombat.kind:e->kind);be16(bytes+2,attr%10);be16(bytes+4,st.state);
        be32(bytes+8,st.update_tick);be32(bytes+12,st.animation_tick);be32(bytes+16,st.action_tick);
        be16(bytes+20,[a[@"script"] intValue]);be16(bytes+22,(int)st.line+1);be16(bytes+24,st.frame);be16(bytes+26,st.tilt);
        rectBytes(bytes+28,player?previousPlayerBounds:e->previousBounds);rectBytes(bytes+36,player?playerBounds:e->bounds);
        be64(bytes+44,st.x);be64(bytes+52,st.y);be16(bytes+60,[a[@"sprite"] intValue]-1);
        be16(bytes+68,attr);be16(bytes+70,player?playerCombat.remove:st.remove);
        be64(bytes+72,st.velocity.x);be64(bytes+80,st.velocity.y);
        be16(bytes+88,player?playerCombat.hit_points:e->hitPoints);be16(bytes+90,player?playerCombat.layer:e->layer);
        be16(bytes+96,player?0:[e->placement[@"tag"] intValue]);
        printf("E\t0\tinitial\t%u\t%u\t0\t%u\t%u\t",eid,eid,before,after);
        dump(bytes,62);dump(bytes+66,26);dump(bytes+96,2);putchar('\n');
    }
    for(unsigned rid=1;rid<=7;rid++){
        AstroVisual v=playerVisual;int layer=6;
        if(rid!=1)for(AstroEnemy *e in enemies)if(e->renderBirth==rid){v=e->visual;layer=e->renderLayer;break;}
        unsigned char bytes[40]={0};be64(bytes,v.x);be64(bytes+8,v.y);be64(bytes+16,v.width);be64(bytes+24,v.height);
        be16(bytes+32,layer);be32(bytes+34,v.next_tick);be16(bytes+38,v.sprite);
        printf("R\t0\tinitial\t%u\t%u\t%u\t",rid,rid-1,rid==7?0:rid+1);dump(bytes,40);puts("\t00000000");
    }
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
    assert(view);[view initialWorldTrace];
}}
