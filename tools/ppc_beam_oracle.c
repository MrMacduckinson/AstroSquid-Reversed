/* Original ordinary-weapon branch, isolated; projectile creation is captured. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/weapons.h"
#include "../src/beams.h"
extern uint32_t invoke5(void *,void *,void *,void *,void *,void *,void *,void *);
__asm__(
".text\n.align 2\n.globl _invoke5\n_invoke5:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\n"
"stmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r3,r6\nmr r4,r7\nmr r5,r8\nmr r6,r9\nmr r7,r10\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\n"
"lmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static AstroBeam beam_log[2];
static unsigned beam_count;
static int kill_on_hit;
static unsigned char world[6][128],beam_marker[128];
void *native_beam(int weapon,int damage,int x,int y,int ex,int ey,void *source) {
    (void)source;if(beam_count>=2) exit(2);
    beam_log[beam_count++]=(AstroBeam){weapon,damage,x,y,ex,ey,-1};return beam_marker;
}
void native_resolve(void *beam,int kind,void *target,int target_kind) {
    (void)beam;(void)kind;(void)target_kind;
    for(int i=0;i<6;i++) if(target==world[i]) {
        beam_log[beam_count-1].target=i;
        if(kill_on_hit) *(int16_t *)(world[i]+70)=-1;
    }
}
extern void beam_fb(void),resolve_fb(void);
__asm__(
".text\n.align 2\n.globl _beam_fb\n_beam_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_beam\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
".align 2\n.globl _resolve_fb\n_resolve_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_resolve\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void port_beam_hit(void *context,const AstroBeam *beam) {
    AstroTarget *targets=context;
    if(kill_on_hit&&beam->target>=0) targets[beam->target].remove=-1;
}
static int channel_status(void) {return 0;}
int main(int argc,char **argv) {
    if(argc!=5) return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    unsigned char *globals=calloc(1,0x1300),*heap=calloc(1,0x10000);
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++) {
        void *function=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"SndChannelStatus")) function=(void *)channel_status;
        if(!strcmp(import_names[i],"TickCount")) function=(void *)controlled_tick;
        descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:(void *)missing_import);
        toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    char path[2048];
    snprintf(path,sizeof(path),"%s/Attr.bin",argv[4]);unsigned char *attributes=read_file(path);
    snprintf(path,sizeof(path),"%s/sprt.bin",argv[4]);unsigned char *sprites=read_file(path);
    snprintf(path,sizeof(path),"%s/Wpns.bin",argv[4]);unsigned char *weapons=read_file(path);
    set_pointer(globals,0x21c,literals);set_double(globals,0x368,3.14159265358979323846);
    set_double(globals,0x378,4503601774854144.0);*(uint32_t *)(globals+0x380)=0x43300000;
    set_pointer(globals,0x388,heap);set_pointer(globals,0x38c,heap);
    set_pointer(globals,0xa94,attributes);set_pointer(globals,0xe82,sprites);set_pointer(globals,0xa98,weapons);
    toc[0]=(uint32_t)(uintptr_t)globals;
    jump_to(code+0x54594,(void *)beam_fb);
    jump_to(code+0x547b4,(void *)resolve_fb);
    set_pointer(globals,0x1004,calloc(1,0x800));
    set_double(globals,0xa1e,0);set_double(globals,0xa26,640);
    set_double(globals,0xa2e,0);set_double(globals,0xa36,380);
    *(uint32_t *)(code+0x3ce84)=0x4e800020; // Oracle-only mute of SOUNDPLAYPAN.
    MakeDataExecutable(code,433284);

    unsigned cases=0;
    FILE *fixture=getenv("ASTRO_BEAM_FIXTURE")?fopen(getenv("ASTRO_BEAM_FIXTURE"),"w"):NULL;
    FILE *edges=getenv("ASTRO_EDGE_BEAM_FIXTURE")?fopen(getenv("ASTRO_EDGE_BEAM_FIXTURE"),"w"):NULL;
    FILE *stale=getenv("ASTRO_STALE_BEAM_FIXTURE")?fopen(getenv("ASTRO_STALE_BEAM_FIXTURE"),"w"):NULL;
    int ids[]={40,41,42,43,50,51,52,53};
    for(unsigned k=0;k<8;k++) for(int n=0;n<208;n++) {
        AstroTarget targets[6];memset(world,0,sizeof(world));
        uint32_t seed=(uint32_t)n*123456789u;*(uint32_t *)(globals+0x244)=seed;
        int edge=n>=200;if(edge&&k<4)continue;
        int source_kind=edge?1:n%2?1:5;
        for(int i=0;i<6;i++) {
            int kind=i%3==0?1:i%3==1?5:20;
            double x=100+(n*13+i*37)%350,y=100+(n*7+i*17)%130,w=20+i*3,h=25+i*5;
            if(n>=100&&n<200){x+=.25*(i%3);y+=.5*(i%2);}
            if(edge){x=(n%2?-30000:30000)+i*37;y=(n%4<2?-30000:30000)+i*17;w=h=20;}
            AstroRect rect={(int)x,(int)y,(int)(x+w),(int)(y+h)};
            if(n>=100&&n<200){rect.left-=11-i;rect.top+=3-i;rect.right=rect.left+(int)w-7;rect.bottom=rect.top+(int)h+5;}
            targets[i]=(AstroTarget){.kind=kind,.parent=-1,.x=x,.y=y,.width=w+20,.height=h+17,
                .bounds_valid=1,.bounds=rect};
            set_short(world[i],0,kind);set_short(world[i],36,rect.top);set_short(world[i],38,rect.left);
            set_short(world[i],40,rect.bottom);set_short(world[i],42,rect.right);
            set_double(world[i],44,x);set_double(world[i],52,y);
            set_pointer(world[i],102,i<5?world[i+1]:NULL);
        }
        unsigned char source[128]={0};set_short(source,0,source_kind);
        set_pointer(globals,0xa76,world[0]);set_short(globals,0xa52,n%3+1);
        int id=ids[k],x=edge?(n%2?30000:-30000):70+n%100,y=edge?(n%4<2?30000:-30000):110+n%100,heading=n*17;
        beam_count=0;kill_on_hit=n%4==0;
        invoke5(code+0x58f40,globals,toc,(void *)(uintptr_t)id,
            (void *)(intptr_t)x,(void *)(intptr_t)y,(void *)(intptr_t)heading,source);
        AstroBeam beams[2];int count=astro_beam_shots(id,x,y,heading,n%3+1,
            source_kind,-1,targets,6,0,0,640,380,&seed,beams,port_beam_hit,targets);
        if(count!=(int)beam_count||seed!=*(uint32_t *)(globals+0x244)) {
            printf("FAIL beam%d case%d count original%u port%d seed%u/%u\n",id,n,beam_count,count,
                *(uint32_t *)(globals+0x244),seed);return 1;
        }
        for(int i=0;i<count;i++) if(memcmp(beams+i,beam_log+i,sizeof(AstroBeam))) {
            int *a=(int *)(beam_log+i),*b=(int *)(beams+i);
            printf("FAIL beam%d case%d shot%d\n",id,n,i);
            for(int j=0;j<7;j++) printf("field%d original%d port%d\n",j,a[j],b[j]);return 1;
        }
        FILE *capture=edge?edges:n<20?fixture:n>=100&&n<120?stale:NULL;
        if(capture) {
            fprintf(capture,"%d,%d,%u",id,n,beam_count);
            for(unsigned i=0;i<beam_count;i++) {
                int *values=(int *)(beam_log+i);
                for(int j=0;j<7;j++) fprintf(capture,",%d",values[j]);
            }
            fprintf(capture,",%u\n",*(uint32_t *)(globals+0x244));
        }
        cases++;
    }
    if(fixture) fclose(fixture);if(stale)fclose(stale);if(edges)fclose(edges);
    printf("PASS: %u original/portable beam cases, endpoints, damage, target, RNG (damage intercepted)\n",cases);
    return 0;
}
