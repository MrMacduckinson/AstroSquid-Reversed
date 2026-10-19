/* Original ordinary-weapon branch, isolated; projectile creation is captured. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/weapons.h"
#include "../src/combat.h"
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
    unsigned char shield[312]={0};uintptr_t shield_address=(uintptr_t)shield;
    *(uint32_t *)(code+0x3b260)=0x3c600000|(uint32_t)(shield_address>>16);
    *(uint32_t *)(code+0x3b264)=0x60630000|(uint32_t)(shield_address&65535);
    *(uint32_t *)(code+0x3b268)=0x4e800020;
    *(uint32_t *)(code+0x343b4)=0x4e800020; // Visual shield update only.
    *(uint32_t *)(code+0x3ce84)=0x4e800020; // Oracle-only mute of SOUNDPLAYPAN.
    MakeDataExecutable(code,433284);

    FILE *fixture=getenv("ASTRO_SCENERY_FIXTURE")?fopen(getenv("ASTRO_SCENERY_FIXTURE"),"w"):NULL;
    for(int n=0;n<1000;n++) {
        unsigned char player[128]={0},scenery[128]={0};
        AstroCombatState p={.hit_points=n%201,.velocity={1,2}};
        AstroCombatState s={.hit_points=n%77,.remove=n%17==0?1:0,.velocity={3,4}};
        AstroRect a={n%11,n%13,71+n%11,20+n%13};
        AstroRect b={10+n%27,5+n%17,12+n%27+n%60,7+n%17+n%45};
        int coords_a[]={a.top,a.left,a.bottom,a.right},coords_b[]={b.top,b.left,b.bottom,b.right};
        for(int i=0;i<4;i++) {set_short(player,36+i*2,coords_a[i]);set_short(scenery,36+i*2,coords_b[i]);}
        set_short(player,88,p.hit_points);set_short(scenery,88,s.hit_points);set_short(scenery,70,s.remove);
        set_double(player,72,1);set_double(player,80,2);set_double(scenery,72,3);set_double(scenery,80,4);
        invoke5(code+0x60990,globals,toc,player,scenery,NULL,NULL,NULL);
        astro_player_hits_scenery(&p,a,&s,b);
        if(p.hit_points!=*(int16_t *)(player+88)||s.hit_points!=*(int16_t *)(scenery+88)||
            p.remove!=*(int16_t *)(player+70)||s.remove!=*(int16_t *)(scenery+70)||
            fabs(p.velocity.x-*(double *)(player+72))>1e-10||fabs(p.velocity.y-*(double *)(player+80))>1e-10||
            fabs(s.velocity.x-*(double *)(scenery+72))>1e-10||fabs(s.velocity.y-*(double *)(scenery+80))>1e-10) {
            printf("FAIL scenery case%d\n",n);return 1;
        }
        if(fixture&&n<200) fprintf(fixture,"%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g\n",n,
            *(int16_t *)(player+88),*(int16_t *)(scenery+88),*(int16_t *)(player+70),*(int16_t *)(scenery+70),
            *(double *)(player+72),*(double *)(player+80),*(double *)(scenery+72),*(double *)(scenery+80));
    }
    if(fixture) fclose(fixture);
    puts("PASS: 1000 original/portable player/scenery cases (shield/audio intercepted)");return 0;
}
