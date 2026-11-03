/* Original full DOPLAYER; capture FIREWEAPON entry, no audio or projectile allocation. */
#define main old_clock_main
#include "ppc_player_clock_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
static uint32_t now_tick;static unsigned interval,shots;
static uint32_t cadence_tick(void){return now_tick;}
void shot(void){printf("F,%u,%u\n",interval,now_tick);shots++;}
extern void shot_fb(void);
__asm__(".text\n.align 2\n.globl _shot_fb\n_shot_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _shot\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
int main(int argc,char **argv){
 assert(argc==4);alarm(10);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1400),*heap=calloc(1,65536);uint32_t toc[489]={0};
 for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=cadence_tick;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
 char path[2048];snprintf(path,sizeof(path),"%s/Attr.bin",argv[3]);unsigned char *attr=read_file(path);snprintf(path,sizeof(path),"%s/sprt.bin",argv[3]);unsigned char *sprt=read_file(path);snprintf(path,sizeof(path),"%s/Wpns.bin",argv[3]);unsigned char *wpns=read_file(path);
 assert(*(int16_t *)(wpns+10*52)==7);
 *(void **)(g+0x21c)=lit;*(double *)(g+0x368)=3.14159265358979323846;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xa94)=attr;*(void **)(g+0xe82)=sprt;*(void **)(g+0xa98)=wpns;toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x2ca8,no_resource);jump_to(code+0x3b260,no_sprite);jump_to(code+0x58f40,shot_fb);MakeDataExecutable(code,433284);
 for(interval=1;interval<=3;interval++){
 unsigned char entity[128] __attribute__((aligned(16)))={0},render[312] __attribute__((aligned(16)))={0};
 *(int16_t *)(entity+4)=1;*(int16_t *)(entity+24)=12;*(int16_t *)(entity+26)=3;*(int16_t *)(entity+68)=11;
 *(int16_t *)(entity+36)=180;*(int16_t *)(entity+38)=60;*(int16_t *)(entity+40)=200;*(int16_t *)(entity+42)=131;*(void **)(entity+62)=render;*(double *)(render+16)=71;*(double *)(render+24)=20;
 *(double *)(g+0xa1e)=0;*(double *)(g+0xa26)=640;*(double *)(g+0xa2e)=0;*(double *)(g+0xa36)=380;
 *(int16_t *)(g+0xa8a)=10;*(int16_t *)(g+0xa8c)=0;*(int16_t *)(g+0xab2)=-1;*(int16_t *)(g+0xa52)=interval;shots=0;
 for(now_tick=interval;now_tick<=180;now_tick+=interval)invoke_fb(code+0x5ed70,g,toc,entity,NULL,NULL);
 printf("N,%u,%u\n",interval,shots);assert(shots>0);
 }
 return 0;
}
