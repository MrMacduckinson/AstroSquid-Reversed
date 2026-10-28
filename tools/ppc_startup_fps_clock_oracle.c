/* Original LMINITMINI slice: metadata -> swap interval -> FPS clock/reset. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
static unsigned char *globals;static unsigned phase;static uint32_t stamp;
void metadata(void){assert(phase++==0);}
extern void metadata_fb(void);
__asm__(".text\n.align 2\n.globl _metadata_fb\n_metadata_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _metadata\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static int interval(void *context,int parameter,int *value){assert(phase++==1&&context==(void *)0x1234&&parameter==0xde&&*value==1);return 1;}
static uint32_t tick(void){assert(phase++==2&&*(short *)(globals+0xec6)==0&&*(double *)(globals+0xebe)==0&&*(short *)(globals+0xecc)==7);return stamp;}
int main(int argc,char **argv){
    if(argc!=3)return 2;alarm(15);
    unsigned char *code=read_file(argv[1])+128,*g=calloc(1,0x1300);assert(g);globals=g;
    *(void **)(g+0x21c)=read_file(argv[2]);*(void **)(g+0xe8a)=(void *)0x1234;
    uint32_t toc[489]={0};
    for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"aglSetInteger"))fn=interval;
        if(!strcmp(import_names[i],"TickCount"))fn=tick;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    toc[0]=(uint32_t)(uintptr_t)g;jump_to(code+0x34fa4,metadata_fb);
    uint32_t *entry=(uint32_t *)(code+0x38890),*tail=(uint32_t *)(code+0x38900);
    entry[0]=0x7c0802a6;entry[1]=0x90010010;entry[2]=0x90410014;entry[3]=0x39ae1100;
    tail[0]=0x80010010;tail[1]=0x7c0803a6;tail[2]=0x4e800020;MakeDataExecutable(code,433284);
    const uint32_t clocks[]={0,1,0x7fffffff,0xffffffff};
    for(unsigned i=0;i<4;i++){
        phase=0;stamp=clocks[i];*(double *)(g+0xebe)=42;*(short *)(g+0xec6)=123;
        *(uint32_t *)(g+0xec8)=99;*(short *)(g+0xecc)=7;
        invoke_fb(code+0x38890,g,toc,NULL,NULL,NULL);
        assert(phase==3&&*(uint32_t *)(g+0xec8)==stamp&&*(short *)(g+0xecc)==0);
    }
    puts("PASS4 original startup FPS initialization: LMLOADSPRT then swap interval1, zero rate/count, fresh TickCount stored bit-exact, debug off after clock");
    return 0;
}
