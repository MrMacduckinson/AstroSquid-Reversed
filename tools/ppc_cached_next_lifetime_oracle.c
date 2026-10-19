/* Original CALCSPRITES/CLEANUPMARKEDSPRITES/DELETESPRITE traversal.
   Private player callback substitutes a synchronous nested cleanup; no live game changes.
   Case0 really frees a later node safely; case1 retains immediate stale-next storage
   as a deterministic observer only (not a claim about real allocator reuse). */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
static unsigned char *code,*g,*a,*b,*c;static uint32_t *toc;
static unsigned mode,callback_calls,dispose_calls,kill_calls;
static uint32_t descriptors[484][2];
static void noop(void){}
static void dispose_node(void *p){dispose_calls++;if(mode==0)DisposePtr(p);}
void kill_render(void *p){(void)p;kill_calls++;}
void nested_cleanup(void *entity){
    if(entity!=a||callback_calls++)exit(2);
    unsigned char *victim=mode?b:c;*(int16_t *)(victim+70)=1;
    invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);
}
extern void kill_render_fb(void),nested_cleanup_fb(void);
__asm__(".text\n.align 2\n.globl _kill_render_fb\n_kill_render_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _kill_render\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
".align 2\n.globl _nested_cleanup_fb\n_nested_cleanup_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _nested_cleanup\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void missing(void){fputs("Unexpected import\n",stderr);exit(2);}
static unsigned char *read_file(const char *path){FILE *f=fopen(path,"rb");if(!f){perror(path);exit(2);}fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static void jump_to(unsigned char *at,void *destination){uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
int main(int argc,char **argv){
    if(argc!=5)return 2;FILE *fixture=fopen(argv[4],"w");if(!fixture)return 2;
    unsigned char *pef=read_file(argv[1]),*literals=read_file(argv[2]),*heap=calloc(1,0x10000);code=pef+128;g=calloc(1,0x1300);uint32_t toc_storage[489]={0};toc=toc_storage;
    for(int i=0;i<484;i++){void *function=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"DisposePtr"))function=dispose_node;descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    char path[2048];snprintf(path,sizeof(path),"%s/Attr.bin",argv[3]);*(void **)(g+0xa94)=read_file(path);
    *(void **)(g+0x21c)=literals;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x42234,noop); /* Stars irrelevant to entity traversal. */
    jump_to(code+0x5ed70,nested_cleanup_fb);jump_to(code+0x52a94,noop);jump_to(code+0x343b4,noop);jump_to(code+0x34dd8,kill_render_fb);MakeDataExecutable(code,433284);
    for(mode=0;mode<2;mode++){
        a=(unsigned char *)NewPtrClear(106);b=(unsigned char *)NewPtrClear(106);c=(unsigned char *)NewPtrClear(106);if(!a||!b||!c)return 2;
        unsigned char render[312] __attribute__((aligned(16)))={0};*(double *)(render+16)=71;*(double *)(render+24)=20;
        *(int16_t *)a=1;*(int16_t *)(a+68)=11;*(void **)(a+62)=render;
        *(int16_t *)b=999;*(int16_t *)c=999;
        *(void **)(a+102)=b;*(void **)(b+98)=a;*(void **)(b+102)=c;*(void **)(c+98)=b;
        *(void **)(g+0xa76)=a;*(void **)(g+0xa7a)=a;callback_calls=dispose_calls=kill_calls=0;
        invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);
        unsigned visits=*(uint32_t *)(g+0xa90),live=0;for(unsigned char *p=*(void **)(g+0xa76);p;p=*(void **)(p+102)){if(++live>3)exit(2);}
        printf("OBS mode%u visits%u live%u callback%u dispose%u kill%u\n",mode,visits,live,callback_calls,dispose_calls,kill_calls);
        if(visits!=(mode?3:2)||live!=2||callback_calls!=1||dispose_calls!=1||kill_calls!=1)return 1;
        printf("case%u dispose=%s outervisits%u live%u cachednext=%s\n",mode,mode?"retained observer":"actual DisposePtr",visits,live,mode?"removed B still visited":"surviving B rereads NULL, removed C skipped");
        fprintf(fixture,"%u,3,%u,%u,%u,%u,%u\n",mode,visits,live,callback_calls,dispose_calls,kill_calls);
        DisposePtr((Ptr)a);DisposePtr((Ptr)b);if(mode)DisposePtr((Ptr)c);
    }
    fclose(fixture);puts("PASS native cached-next survivor deletion and isolated retained-stale observer");return 0;
}
