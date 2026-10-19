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
    *(uint32_t *)(code+0x3b260)=0x38600001; // Return a non-null shield marker; no dereference follows.
    *(uint32_t *)(code+0x3b264)=0x4e800020;
    *(uint32_t *)(code+0x343b4)=0x4e800020; // Visual shield update only.
    *(uint32_t *)(code+0x3ce84)=0x4e800020; // Oracle-only mute of SOUNDPLAYPAN.
    MakeDataExecutable(code,433284);

    FILE *fixture=getenv("ASTRO_PICKUP_FIXTURE")?fopen(getenv("ASTRO_PICKUP_FIXTURE"),"w"):NULL;
    unsigned cases=0;
    for(int n=0;n<1000;n++) {
        unsigned char player[128]={0},pickup[128]={0};
        int type=n%10,health=n%101,removed=n%17==0?-1:0;
        int families[]={10,30,40,50};
        AstroInventory inventory={families[(n/10)%4],(n/40)%4,(n/160)%5,n%7};
        AstroCombatState p={.hit_points=n%201};
        set_short(player,88,p.hit_points);set_short(pickup,2,type);
        set_short(pickup,88,health);set_short(pickup,70,removed);
        set_short(globals,0xa8a,inventory.weapon);set_short(globals,0xa8c,inventory.upgrade);
        set_short(globals,0xa8e,inventory.specials);*(int32_t *)(globals+0xa86)=inventory.lives;
        invoke5(code+0x612c0,globals,toc,player,pickup,NULL,NULL,NULL);
        astro_pickup(&p,type,health,&removed,&inventory);
        if(p.hit_points!=*(int16_t *)(player+88)||removed!=*(int16_t *)(pickup+70)||
            inventory.weapon!=*(int16_t *)(globals+0xa8a)||inventory.upgrade!=*(int16_t *)(globals+0xa8c)||
            inventory.specials!=*(int16_t *)(globals+0xa8e)||inventory.lives!=*(int32_t *)(globals+0xa86)) {
            printf("FAIL pickup case%d\n",n);return 1;
        }
        if(fixture) fprintf(fixture,"%d,%d,%d,%d,%d,%d,%d\n",n,*(int16_t *)(player+88),
            *(int16_t *)(pickup+70),*(int16_t *)(globals+0xa8a),*(int16_t *)(globals+0xa8c),
            *(int16_t *)(globals+0xa8e),*(int32_t *)(globals+0xa86));
        cases++;
    }
    if(fixture) fclose(fixture);
    printf("PASS: %u original/portable pickup cases (sound intercepted)\n",cases);
    return 0;
}
