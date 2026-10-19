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

    unsigned cases=0;
    FILE *fixture=getenv("ASTRO_COMBAT_FIXTURE")?fopen(getenv("ASTRO_COMBAT_FIXTURE"),"w"):NULL;
    for(int player=0;player<2;player++) for(int n=0;n<1000;n++) {
        unsigned char bullet[128]={0},enemy[128]={0};
        AstroCombatState b={0},e={0};
        int kinds[]={2,5,999};b.kind=kinds[n%3];b.layer=n%5;
        b.hit_points=n%151;b.remove=n%13==0?-1:0;
        b.velocity=(AstroVelocity){n/10.0,-n/20.0};
        e.hit_points=n%201;e.velocity=(AstroVelocity){2,3};
        int value=n%7==0?30000:n%301,score=1000;
        set_short(bullet,0,b.kind);set_short(bullet,70,b.remove);
        set_short(bullet,88,b.hit_points);set_short(bullet,90,b.layer);
        set_double(bullet,72,b.velocity.x);set_double(bullet,80,b.velocity.y);
        set_short(enemy,68,62);set_short(enemy,88,e.hit_points);
        set_double(enemy,72,e.velocity.x);set_double(enemy,80,e.velocity.y);
        set_short(attributes,62*30+10,value);*(int32_t *)(globals+0xa7e)=score;
        native_hits=0;
        invoke5(code+(player?0x60430:0x6005c),globals,toc,bullet,enemy,NULL,NULL,NULL);
        int effects=0;
        if(player) astro_bullet_hits_player(&b,&e);
        else effects=astro_bullet_hits_enemy(&b,&e,value,&score);
        if(b.hit_points!=*(int16_t *)(bullet+88)||e.hit_points!=*(int16_t *)(enemy+88)||
           b.remove!=*(int16_t *)(bullet+70)||e.remove!=*(int16_t *)(enemy+70)||
           fabs(e.velocity.x-*(double *)(enemy+72))>1e-10||
           fabs(e.velocity.y-*(double *)(enemy+80))>1e-10||
           score!=*(int32_t *)(globals+0xa7e)||effects!=(int)native_hits) {
            printf("FAIL combat player%d case%d: original bHP%d eHP%d bRemove%d eRemove%d effects%u score%d, port %d %d %d %d %d %d\n",
                player,n,*(int16_t *)(bullet+88),*(int16_t *)(enemy+88),
                *(int16_t *)(bullet+70),*(int16_t *)(enemy+70),native_hits,*(int32_t *)(globals+0xa7e),
                b.hit_points,e.hit_points,b.remove,e.remove,effects,score);return 1;
        }
        if(fixture&&n<100) fprintf(fixture,"%d,%d,%d,%d,%d,%d,%d,%d,%d,%.17g,%.17g,%d,%u,%d,%d\n",
            player,n,b.kind,b.layer,n%151,n%201,value,*(int16_t *)(bullet+88),*(int16_t *)(enemy+88),
            *(double *)(enemy+72),*(double *)(enemy+80),*(int32_t *)(globals+0xa7e),native_hits,
            *(int16_t *)(bullet+70),*(int16_t *)(enemy+70));
        cases++;
    }
    if(fixture) fclose(fixture);
    printf("PASS: %u original/portable projectile damage cases (visual/audio effects intercepted)\n",cases);
    return 0;
}
