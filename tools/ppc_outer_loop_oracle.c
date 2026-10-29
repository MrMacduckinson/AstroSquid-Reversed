/* Execute actual GAMELOOP; stop after its first misc-key callback.
   World, drawing, music, map factory and input are semantic observers. */
#include <Carbon/Carbon.h>
#include <assert.h>
#include <dlfcn.h>
#include <setjmp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "ppc_bridge.h"
#include "imports.h"
#include "../tests/outer_loop_cases.h"
static unsigned char *globals;
static unsigned scenario,reads,iterations;static int repeated;
static jmp_buf finished;
static uint32_t descriptors[484][2];
static void event(char name,uint32_t value){
    printf("%u,%c,%u,%u,%u,%u\n",scenario,name,reads,value,
        *(uint32_t *)(globals+0xa4a),*(uint32_t *)(globals+0xa4e));
}
static uint32_t clock_value(void){
    assert(repeated||reads<loop_cases[scenario].count);
    uint32_t value=repeated?(scenario>=8?0xfffffff0u:1000u)+reads++*(scenario%4):loop_cases[scenario].clocks[reads++];event('C',value);return value;
}
void cleanup(void){event('U',0);if(loop_cases[scenario].world_clock)clock_value();}
void calculate(void){event('A',0);if(loop_cases[scenario].world_clock)clock_value();}
void render(void){event('R',0);} void swap(void){event('W',0);}
void hud(void){event('V',*(uint16_t *)(globals+0xa6a));}
void handle(void){event('H',0);} void music(void){event('S',0);}
void factory(void){event('F',0);if(loop_cases[scenario].factory_clock)clock_value();}
void keys(void){event('K',0);}
void misc(void){event('M',0);if(++iterations==(repeated?64u:1u))longjmp(finished,1);}
#define WRAP(name) extern void name##_fb(void); \
__asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" \
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(cleanup) WRAP(calculate) WRAP(render) WRAP(swap) WRAP(handle)
WRAP(music) WRAP(factory) WRAP(keys) WRAP(misc) WRAP(hud)
static void missing(void){fputs("Unexpected original service\n",stderr);exit(2);}
static unsigned char *read_file(const char *path,long expected){
    FILE *f=fopen(path,"rb");assert(f&&!fseek(f,0,SEEK_END)&&ftell(f)==expected);rewind(f);
    unsigned char *data=malloc(expected);assert(data&&fread(data,1,expected,f)==(size_t)expected&&!fclose(f));return data;
}
static void jump_to(unsigned char *at,void *destination){
    uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;
    w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;
}
int main(int argc,char **argv){
    if(argc<3||argc>5)return 2;repeated=argc==5;assert(!repeated||!strcmp(argv[4],"repeat"));
    unsigned overlay=argc>=4?(unsigned)strtoul(argv[3],NULL,10):0;assert(overlay<=2);alarm(15);
    unsigned char *code=read_file(argv[1],455780)+128,*literals=read_file(argv[2],11812),*heap=calloc(1,65536);
    globals=calloc(1,0x1300);assert(globals&&heap);uint32_t toc[489]={0};
    for(unsigned i=0;i<484;i++){
        void *fn=!strcmp(import_names[i],"TickCount")?clock_value:dlsym(RTLD_DEFAULT,import_names[i]);
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)globals;
    const struct {unsigned offset;void *fn;} hooks[]={
        {0x539b8,cleanup_fb},{0x54c64,calculate_fb},{0x57afc,render_fb},{0x35eb8,swap_fb},
        {0x3b55c,handle_fb},{0x334bc,music_fb},{0x4c854,factory_fb},{0x4cb28,keys_fb},{0x4de74,misc_fb},{0x43134,hud_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].offset,hooks[i].fn);
    MakeDataExecutable(code,433284);
    for(scenario=0;scenario<sizeof(loop_cases)/sizeof(loop_cases[0]);scenario++){
        memset(globals,0,0x1300);reads=iterations=0;
        *(void **)(globals+0x21c)=literals;*(void **)(globals+0x388)=heap;*(void **)(globals+0x38c)=heap;
        *(int16_t *)(globals+0xa52)=loop_cases[scenario].interval;
        *(int16_t *)(globals+0xa6a)=overlay;
        if(!setjmp(finished))invoke_fb(code+0x51a68,globals,toc,NULL,NULL,NULL);
        assert(repeated||reads==loop_cases[scenario].count);event('Z',*(uint16_t *)(globals+0xa6a));
    }
    fprintf(stderr,"PASS10 original outer-loop clock/order schedules, %u iterations each\n",repeated?64u:1u);return 0;
}
