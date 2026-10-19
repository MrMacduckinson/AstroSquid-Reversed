/* Original MIDLEVEL versus portable transition controls on a deterministic
 * movement plant. WAITLOOP and world destruction are test doubles; the live
 * original and its files are untouched. */
#include <Carbon/Carbon.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../src/transition.h"
#include "ppc_bridge.h"
static unsigned char *g,*body,*render;
static unsigned native_keys[10000],native_count;
static void bounds(unsigned char *p,int x,int y) {
    *(int16_t *)(p+36)=y;*(int16_t *)(p+38)=x;*(int16_t *)(p+40)=y+40;*(int16_t *)(p+42)=x+40;
}
void native_wait(int n,int input) {
    (void)input;unsigned keys=(*(int16_t *)(g+0xaaa)?ASTRO_KEY_RIGHT:0)|(*(int16_t *)(g+0xaa8)?ASTRO_KEY_LEFT:0)|
        (*(int16_t *)(g+0xaae)?ASTRO_KEY_DOWN:0)|(*(int16_t *)(g+0xaac)?ASTRO_KEY_UP:0);
    int x=*(int16_t *)(body+38),y=*(int16_t *)(body+36);
    for(int i=0;i<=n;i++) {
        if(native_count>=10000)exit(2);native_keys[native_count++]=keys;
        x+=(keys&ASTRO_KEY_RIGHT?1:0)-(keys&ASTRO_KEY_LEFT?1:0);
        y+=(keys&ASTRO_KEY_DOWN?1:0)-(keys&ASTRO_KEY_UP?1:0);
    }
    bounds(body,x,y);*(double *)render=x;*(double *)(render+8)=y;
}
extern void native_wait_fb(void);
__asm__(".text\n.align 2\n.globl _native_wait_fb\n_native_wait_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_wait\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void jump_to(unsigned char *at,void *destination) {
    uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;
    w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;
}
static unsigned char *read_file(const char *name) {
    FILE *f=fopen(name,"rb");if(!f)exit(2);fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);
    unsigned char *p=malloc(n);if(!p||fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;
}
int main(int argc,char **argv) {
    if(argc!=3)return 2;
    unsigned char *pef=read_file(argv[1]),*literals=read_file(argv[2]),*code=pef+128;
    g=calloc(1,0x1300);body=calloc(1,128);render=calloc(1,312);unsigned char *heap=calloc(1,0x10000);
    *(void **)(g+0x21c)=literals;*(double *)(g+0x378)=4503601774854144.0;*(uint32_t *)(g+0x380)=0x43300000;
    *(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xa7a)=body;*(void **)(body+62)=render;
    *(double *)(render+16)=40;*(double *)(render+24)=40;
    *(double *)(g+0xa1e)=0;*(double *)(g+0xa26)=640;*(double *)(g+0xa2e)=0;*(double *)(g+0xa36)=380;
    jump_to(code+0x4ded4,(void *)native_wait_fb);
    unsigned off[]={0x31af4,0x3e66c,0x34edc,0x529f8};for(unsigned i=0;i<4;i++)*(uint32_t *)(code+off[i])=0x4e800020;
    MakeDataExecutable(code,433284);
    for(int trial=0;trial<20;trial++) {
        int initial_x=trial%2?800:-100,initial_y=trial%3?550:-200;bounds(body,initial_x,initial_y);native_count=0;
        invoke_fb(code+0x4e9c4,g,NULL,NULL,NULL,NULL);
        if(*(int16_t *)(body+88)!=200)return 1;
        AstroTransition t;astro_transition_begin(&t,ASTRO_TRANSITION_MID,0,0);
        int x=initial_x,y=initial_y;uint32_t tick;
        for(tick=0;tick<=native_count;tick++) {
            astro_transition_step(&t,tick,(AstroRect){x,y,x+40,y+40},40,40,(AstroRect){0,0,640,380},0,0);
            if(t.phase==ASTRO_TRANSITION_DONE)break;
            if(tick>=native_count||t.controls!=native_keys[tick]) {printf("control mismatch trial%d tick%u native%u port%u\n",trial,tick,tick<native_count?native_keys[tick]:99,t.controls);return 1;}
            x+=(t.controls&ASTRO_KEY_RIGHT?1:0)-(t.controls&ASTRO_KEY_LEFT?1:0);y+=(t.controls&ASTRO_KEY_DOWN?1:0)-(t.controls&ASTRO_KEY_UP?1:0);
        }
        if(tick!=native_count) {printf("duration mismatch %u/%u\n",tick,native_count);return 1;}
    }
    puts("PASS:20 original/portable MIDLEVEL complete steering/timer streams on PowerPC with controlled movement plant");return 0;
}
