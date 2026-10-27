/* Full original DOBULLETSPRITE; private code and finite TickCount scripts only. */
#include <Carbon/Carbon.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
static unsigned char *code_base,*entity;
static uint32_t values[2];static unsigned used,limit;
uint32_t bullet_clock_value(uintptr_t pc){
    if(used>=limit)exit(3);uint32_t v=values[used];
    printf("T,%u,%08x,%u,%u\n",used++,(unsigned)(pc-(uintptr_t)code_base-4+0x10000000),v,*(uint32_t *)(entity+8));return v;
}
extern void bullet_clock_fb(void);
/* Preserve both the caller's CFM linkage slot and this trampoline's own r2. */
__asm__(".text\n.align 2\n.globl _bullet_clock_fb\n_bullet_clock_fb:\nstw r2,20(r1)\nmflr r3\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _bullet_clock_value\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
int main(int argc,char **argv){
    if(argc!=2)return 2;FILE *f=fopen(argv[1],"rb");if(!f)return 2;fseek(f,0,SEEK_END);long size=ftell(f);rewind(f);
    if(size<433412)return 2;unsigned char *pef=malloc(size);if(!pef||fread(pef,1,size,f)!=(size_t)size)return 2;fclose(f);code_base=pef+128;
    uintptr_t target=(uintptr_t)bullet_clock_fb;uint32_t *jump=(uint32_t *)(code_base+0x694e4);
    jump[0]=0x3d800000|(target>>16);jump[1]=0x618c0000|(target&65535);jump[2]=0x7d8903a6;jump[3]=0x4e800420;MakeDataExecutable(code_base,433284);
    unsigned char *globals=calloc(1,0x1300);uint32_t toc[489]={0};toc[0]=(uint32_t)(uintptr_t)globals;
    const struct {int state;uint32_t old,comparison,store;unsigned reads;} cases[]={
        {1,100,100,0,1},{1,100,101,130,2},{1,UINT32_MAX,0,4,2},{1,0,0x80000000u,0,1},
        {1,200,199,0,1},{0,100,101,130,0},{2,100,101,130,0},{-1,100,101,130,0}};
    for(unsigned id=0;id<8;id++){
        unsigned char bytes[128],before[128];memset(bytes,0x5a,sizeof(bytes));entity=bytes;
        *(int16_t *)(bytes+4)=cases[id].state;*(uint32_t *)(bytes+8)=cases[id].old;memcpy(before,bytes,sizeof(bytes));
        used=0;limit=cases[id].reads;values[0]=cases[id].comparison;values[1]=cases[id].store;
        printf("CASE,%u,%d,%u,%u\n",id,cases[id].state,cases[id].old,limit);invoke_fb(code_base+0x61a48,globals,toc,bytes,NULL,NULL);
        if(used!=limit)return 3;for(unsigned i=0;i<sizeof(bytes);i++)if((i<8||i>=12)&&bytes[i]!=before[i])return 4;
        printf("O,%u\n",*(uint32_t *)(bytes+8));
    }
    return 0;
}
