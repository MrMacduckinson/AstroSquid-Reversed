/* Original ordinary-weapon branch, isolated; projectile creation is captured. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/weapons.h"
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
    jump_to(code+0x54248,(void *)native_fire_fb);
    *(uint32_t *)(code+0x3ce84)=0x4e800020; // Oracle-only mute of SOUNDPLAYPAN.
    MakeDataExecutable(code,433284);

    int ids[]={10,11,12,13,30,31,32,33,60,61,62,63,64,65};
    unsigned cases=0;
    FILE *fixture=getenv("ASTRO_WEAPON_FIXTURE")?fopen(getenv("ASTRO_WEAPON_FIXTURE"),"w"):NULL;
    for(unsigned k=0;k<sizeof(ids)/sizeof(ids[0]);k++) {
        int id=ids[k];int16_t *w=(int16_t *)(weapons+id*52);
        AstroWeapon weapon;weapon.pattern=w[1];
        for(int j=0;j<6;j++) weapon.shots[j]=(AstroShot){w[2+j*4],w[3+j*4],w[4+j*4],w[5+j*4]};
        for(int n=0;n<100;n++) {
            uint32_t seed=(uint32_t)n*123456789u;*(uint32_t *)(globals+0x244)=seed;
            native_shots=0;AstroShot shots[6];
            int x=n-50,y=200-n,heading=n*7-100;
            invoke5(code+0x58f40,globals,toc,(void *)(uintptr_t)id,
                (void *)(intptr_t)x,(void *)(intptr_t)y,(void *)(intptr_t)heading,NULL);
            int count=astro_weapon_shots(&weapon,x,y,heading,&seed,shots);
            if(count!=(int)native_shots||seed!=*(uint32_t *)(globals+0x244)) {
                printf("FAIL weapon %d case %d count/seed\n",id,n);return 1;
            }
            for(int j=0;j<count;j++) if(shots[j].type!=native_log[j].weapon||
                shots[j].x!=native_log[j].x||shots[j].y!=native_log[j].y||
                shots[j].heading!=native_log[j].heading) {
                printf("FAIL weapon %d case %d shot %d: original %d,%d,%d,%d port %d,%d,%d,%d\n",
                    id,n,j,native_log[j].weapon,native_log[j].x,native_log[j].y,native_log[j].heading,
                    shots[j].type,shots[j].x,shots[j].y,shots[j].heading);return 1;
            }
            if(fixture&&n<10) {
                fprintf(fixture,"%d,%u,%d,%d,%d,%d",id,(uint32_t)n*123456789u,x,y,heading,count);
                for(int j=0;j<count;j++) fprintf(fixture,",%d,%d,%d,%d",native_log[j].weapon,
                    native_log[j].x,native_log[j].y,native_log[j].heading);
                fprintf(fixture,",%u\n",seed);
            }
            cases++;
        }
    }
    FILE *angles=getenv("ASTRO_HEADING_FIXTURE")?fopen(getenv("ASTRO_HEADING_FIXTURE"),"w"):NULL;
    for(int n=0;n<1004;n++) {
        unsigned char a[128]={0},b[128]={0},ar[312]={0},br[312]={0};
        int ax=n%311-150,ay=n%191-90,bx=(n*17)%701-350,by=(n*13)%501-250;
        int aw=n%79+1,ah=n%41+1,bw=n%53+1,bh=n%31+1;
        if(n>=1000) {ax=ay=bx=by=0;aw=ah=bw=bh=2;
            if(n==1001) by=1;if(n==1002) by=-1;if(n==1003) bx=-1;}
        set_pointer(a,62,ar);set_pointer(b,62,br);
        set_short(a,38,ax);set_short(a,36,ay);set_short(b,38,bx);set_short(b,36,by);
        set_double(ar,16,aw);set_double(ar,24,ah);set_double(br,16,bw);set_double(br,24,bh);
        int original=(int)invoke_fb(code+0x58978,globals,toc,a,b,NULL);
        int portable=astro_heading(ax,ay,aw,ah,bx,by,bw,bh);
        if(angles) fprintf(angles,"%d,%d,%d,%d,%d,%d,%d,%d,%d\n",ax,ay,aw,ah,bx,by,bw,bh,original);
        if(original!=portable) {printf("FAIL heading %d original%d port%d\n",n,original,portable);return 1;}
    }
    if(angles) fclose(angles);
    puts("PASS: 1004 original/portable center-heading cases");
    if(fixture) fclose(fixture);
    printf("PASS: %u original/portable weapon cases, all projectile arguments and RNG states\n",cases);
    return 0;
}
