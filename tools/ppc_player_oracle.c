/* Original ordinary-weapon branch, isolated; projectile creation is captured. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/weapons.h"
#include "../src/combat.h"
#include "../src/player.h"
extern uint32_t invoke5(void *,void *,void *,void *,void *,void *,void *,void *);
__asm__(
".text\n.align 2\n.globl _invoke5\n_invoke5:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\n"
"stmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r3,r6\nmr r4,r7\nmr r5,r8\nmr r6,r9\nmr r7,r10\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\n"
"lmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
int main(int argc,char **argv) {
    if(argc!=5) return 2;
    int loaded=getenv("ASTRO_PLAYER_LOADED")!=NULL;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    unsigned char *globals=calloc(1,0x1300),*heap=calloc(1,0x10000);
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++) {
        void *function=dlsym(RTLD_DEFAULT,import_names[i]);
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
    jump_to(code+0x52a94,(void *)native_hit_fb);
    *(uint32_t *)(code+0x3b260)=0x38600000;
    *(uint32_t *)(code+0x3b264)=0x4e800020;
    *(uint32_t *)(code+0x343b4)=0x4e800020; // Visual shield update only.
    *(uint32_t *)(code+0x3ce84)=0x4e800020; // Oracle-only mute of SOUNDPLAYPAN.
    MakeDataExecutable(code,433284);

    FILE *fixture=getenv("ASTRO_PLAYER_FIXTURE")?fopen(getenv("ASTRO_PLAYER_FIXTURE"),"w"):NULL;
    unsigned cases=0;
    for(int variant=0;variant<16;variant++) {
        unsigned char entity[128]={0},render[312]={0};
        set_short(entity,4,1);set_short(entity,24,12);set_short(entity,26,3);set_short(entity,68,11);
        set_pointer(entity,62,render);set_double(render,16,71);set_double(render,24,20);
        AstroPlayer p={{0,0},12,3,1,0,0};
        set_double(globals,0xa1e,0);set_double(globals,0xa26,640);
        set_double(globals,0xa2e,loaded?70:0);set_double(globals,0xa36,loaded?450:380);
        for(tick=1;tick<=200;tick++) {
            unsigned controls=(variant+tick/25)%16;
            int x=tick%4==0?-20:tick%4==1?620:60,y=tick%4==2?(loaded?50:-20):tick%4==3?(loaded?445:375):180;
            AstroRect bounds={x,y,x+71,y+20};AstroViewport viewport={0,loaded?70:0,640,loaded?450:380};
            set_short(entity,36,y);set_short(entity,38,x);set_short(entity,40,y+20);set_short(entity,42,x+71);
            set_short(globals,0xaac,controls&1?-1:0);set_short(globals,0xaae,controls&2?-1:0);
            set_short(globals,0xaa8,controls&4?-1:0);set_short(globals,0xaaa,controls&8?-1:0);
            invoke5(code+0x5ed70,globals,toc,entity,NULL,NULL,NULL,NULL);
            astro_player_step(&p,tick,controls,1,bounds,71,20,viewport,0);
            if(ieee_word(p.velocity.x)!=ieee_word(*(double *)(entity+72))||ieee_word(p.velocity.y)!=ieee_word(*(double *)(entity+80))||
               p.frame!=*(int16_t *)(entity+24)||p.tilt!=*(int16_t *)(entity+26)||p.state!=*(int16_t *)(entity+4)||
               p.animation_tick!=*(uint32_t *)(entity+12)||p.update_tick!=*(uint32_t *)(entity+8)) {
                printf("FAIL player variant%d tick%u\n",variant,tick);return 1;
            }
            if(fixture&&(loaded||variant<4)) fprintf(fixture,"%d,%u,%.17g,%.17g,%d,%d,%d,%u,%u\n",variant,tick,
                *(double *)(entity+72),*(double *)(entity+80),*(int16_t *)(entity+24),*(int16_t *)(entity+26),
                *(int16_t *)(entity+4),*(uint32_t *)(entity+12),*(uint32_t *)(entity+8));
            cases++;
        }
    }
    if(fixture) fclose(fixture);
    printf("PASS: %u original/portable player animation/control/boundary ticks (firing disabled)\n",cases);return 0;
}
