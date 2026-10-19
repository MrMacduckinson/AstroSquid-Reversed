/* Original nonfatal BULLETHITSPLAYER + DOPLAYER follow + LMHANDLESPRITES.
 * Sound and sprite allocation/deallocation are observed in an isolated process. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/hit_visual.h"
static unsigned char shield[312],*hit_globals;static int shield_active,sounds,created,requested_scenery;
void *hit_new(int id,int layer,double *x,double *y,unsigned char *name) {
    if(id!=71||layer!=(requested_scenery?8:7))exit(2);memset(shield,0,sizeof(shield));shield_active=1;created++;
    *(double *)shield=*x;*(double *)(shield+8)=*y;*(double *)(shield+16)=50;*(double *)(shield+24)=50;
    *(int16_t *)(shield+32)=layer;*(uint32_t *)(shield+34)=tick+2;*(int16_t *)(shield+38)=id;
    memcpy(shield+40,name,(size_t)name[0]+1);*(void **)(hit_globals+0xe86)=shield;return shield;
}
void hit_kill(void *p) {(void)p;shield_active=0;*(void **)(hit_globals+0xe86)=NULL;}
void hit_sound(unsigned char *name,double *pan) {if(name[0]!=3||memcmp(name+1,"Hit",3)||*pan<0||*pan>1)exit(2);sounds++;}
extern void hit_new_fb(void),hit_kill_fb(void),hit_sound_fb(void);
#define WRAP(name) ".align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" \
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n" \
"bl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
__asm__(".text\n" WRAP(hit_new) WRAP(hit_kill) WRAP(hit_sound));
static int verify_visual(AstroPlayerHitVisual *p,int trial) {
    if(shield_active!=p->active){printf("active mismatch tick%u trial%d\n",tick,trial);return 0;}
    if(!shield_active)return 1;
    if(*(int16_t *)(shield+38)!=p->visual.sprite||*(uint32_t *)(shield+34)!=p->visual.next_tick)return 0;
    double a[]={*(double *)shield,*(double *)(shield+8),*(double *)(shield+16),*(double *)(shield+24)};
    double b[]={p->visual.x,p->visual.y,p->visual.width,p->visual.height};
    for(int i=0;i<4;i++)if(fabs(a[i]-b[i])>1e-9){printf("geometry mismatch tick%u trial%d component%d %.17g/%.17g\n",tick,trial,i,a[i],b[i]);return 0;}
    return 1;
}
int main(int argc,char **argv) {
    if(argc!=5)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    hit_globals=calloc(1,0x1300);unsigned char *heap=calloc(1,0x10000),*g=hit_globals;
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++){void*f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))f=(void*)controlled_tick;
        descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:(void*)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    char path[2048];snprintf(path,sizeof(path),"%s/Attr.bin",argv[4]);unsigned char *attr=read_file(path);
    snprintf(path,sizeof(path),"%s/sprt.bin",argv[4]);unsigned char *sprt=read_file(path);
    snprintf(path,sizeof(path),"%s/Wpns.bin",argv[4]);unsigned char *wpns=read_file(path);
    AstroSpriteInfo info[1001];memset(info,0,sizeof(info));for(int i=0;i<1001;i++)info[i]=(AstroSpriteInfo){*(int16_t*)(sprt+i*14+6),*(int16_t*)(sprt+i*14+8),*(int16_t*)(sprt+i*14+10),*(int16_t*)(sprt+i*14+12)};
    set_pointer(g,0x21c,literals);set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.0);*(uint32_t*)(g+0x380)=0x43300000;
    set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);set_pointer(g,0xa94,attr);set_pointer(g,0xe82,sprt);set_pointer(g,0xa98,wpns);toc[0]=(uint32_t)(uintptr_t)g;
    set_double(g,0xa26,640);set_double(g,0xa36,380);
    jump_to(code+0x34a34,(void*)hit_new_fb);jump_to(code+0x34dd8,(void*)hit_kill_fb);jump_to(code+0x3ce84,(void*)hit_sound_fb);MakeDataExecutable(code,433284);
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;OSStatus err=FSPathMakeRef((const UInt8*)argv[3],&ref,NULL);if(!err)err=FSGetResourceForkName(&fork);if(!err)err=FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf);if(err)return 2;UseResFile(rf);
    for(int trial=0;trial<20;trial++) {
        unsigned char player[128]={0},bullet[128]={0},scenery[128]={0},render[312]={0};
        set_short(player,0,1);set_short(player,4,1);set_short(player,24,12);set_short(player,26,3);set_short(player,68,11);set_short(player,88,100);
        set_pointer(player,62,render);set_double(render,16,71);set_double(render,24,20);set_pointer(g,0xa7a,player);
        AstroPlayerHitVisual p={0};shield_active=sounds=created=0;set_pointer(g,0xe86,NULL);
        for(tick=1;tick<100;tick++) {
            AstroRect b={100+(int)tick,120+trial,171+(int)tick+trial%3*7,140+trial+trial%4*3};
            set_short(player,36,b.top);set_short(player,38,b.left);set_short(player,40,b.bottom);set_short(player,42,b.right);
            if(tick==1||tick==5||tick==trial+10) {
                set_short(bullet,0,2);set_short(bullet,70,0);set_short(bullet,88,1);set_short(bullet,90,1);
                requested_scenery=(trial+(int)tick)%2;
                if(requested_scenery) {
                    set_short(scenery,70,0);set_short(scenery,88,1000);
                    set_short(scenery,36,b.top+3);set_short(scenery,38,b.left+2);
                    set_short(scenery,40,b.bottom+4);set_short(scenery,42,b.right+3);
                    invoke_fb(code+0x60990,g,toc,player,scenery,NULL);
                    if(!astro_player_scenery_hit_visual(&p,b,info,1001,tick))return 1;
                } else {
                    invoke_fb(code+0x60430,g,toc,bullet,player,NULL);
                    if(!astro_player_hit_visual(&p,b,info,1001,tick))return 1;
                }
                if(!verify_visual(&p,trial))return 1;
            }
            invoke_fb(code+0x5ed70,g,toc,player,NULL,NULL);astro_player_hit_follow(&p,b);if(!verify_visual(&p,trial))return 1;
            invoke_fb(code+0x3b55c,g,toc,NULL,NULL,NULL);if(astro_player_hit_step(&p,info,1001,tick)<0||!verify_visual(&p,trial))return 1;
        }
        if(sounds!=3||shield_active)return 1;
    }
    puts("PASS:1980 original/portable mixed bullet/scenery playerhit lifecycle ticks including Hitcue,layer7/8,create71,reset72,follow,expiry onPowerPC");return 0;
}
