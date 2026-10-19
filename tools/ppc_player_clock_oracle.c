/* Full original DOPLAYERSPRITE, scripted independent TickCount reads.
   Fire keys false, named Shield/Glow absent; original player code unchanged. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
static unsigned char *original_code;static uint32_t times[4],sites[4];static unsigned clock_index,clock_count;
static uint32_t descriptors[484][2];
static uint32_t clock_value(void){if(clock_index>=clock_count){fputs("Unexpected clock read\n",stderr);exit(2);}sites[clock_index]=(uint32_t)((unsigned char *)__builtin_return_address(0)-original_code)+0x10000000;return times[clock_index++];}
static void no_resource(void){}
static void *no_sprite(void){return NULL;}
static void missing(void){fputs("Unexpected import\n",stderr);exit(2);}
static void jump_to(unsigned char *at,void *destination){uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
static unsigned char *read_file(const char *path){FILE *f=fopen(path,"rb");if(!f){perror(path);exit(2);}fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static unsigned long long bits(const void *p){unsigned long long v;memcpy(&v,p,8);return v;}
typedef struct {unsigned keys,n;uint32_t clocks[4],animation,update;} Case;
int main(int argc,char **argv){
    if(argc!=5)return 2;FILE *fixture=fopen(argv[4],"w");if(!fixture)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*globals=calloc(1,0x1300),*heap=calloc(1,0x10000);uint32_t toc[489]={0};original_code=code;
    for(int i=0;i<484;i++){void *function=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))function=clock_value;descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    char path[2048];snprintf(path,sizeof(path),"%s/Attr.bin",argv[3]);unsigned char *attributes=read_file(path);snprintf(path,sizeof(path),"%s/sprt.bin",argv[3]);unsigned char *sprites=read_file(path);snprintf(path,sizeof(path),"%s/Wpns.bin",argv[3]);unsigned char *weapons=read_file(path);
    *(void **)(globals+0x21c)=literals;*(double *)(globals+0x368)=3.14159265358979323846;*(double *)(globals+0x378)=4503601774854144.;*(uint32_t *)(globals+0x380)=0x43300000;*(void **)(globals+0x388)=heap;
    *(void **)(globals+0xa94)=attributes;*(void **)(globals+0xe82)=sprites;*(void **)(globals+0xa98)=weapons;toc[0]=(uint32_t)(uintptr_t)globals;
    jump_to(code+0x2ca8,no_resource);jump_to(code+0x3b260,no_sprite);MakeDataExecutable(code,433284);
    const Case cases[]={
        {0,2,{100,100,0,0},95,100},
        {0,3,{100,101,109,0},90,100},
        {0,3,{101,107,107,0},90,107},
        {0,4,{101,107,108,119},90,100},
        {8,4,{UINT32_MAX-1,2,3,4},UINT32_MAX-20,UINT32_MAX-5},
        {8,3,{101,107,107,0},90,107},
        {0,2,{0x80000000,0x80000001,0,0},0,0},
        {1,3,{110,111,120,0},100,110},
        {2,3,{111,115,115,0},100,115},
        {15,4,{111,112,113,114},100,110},
        {4,4,{111,115,117,125},100,110},
        {8,4,{111,115,117,125},100,110},
        {3,4,{UINT32_MAX-1,UINT32_MAX,0,1},UINT32_MAX-12,UINT32_MAX},
        {0,3,{UINT32_MAX,0,0,0},UINT32_MAX-11,0},
        {0,3,{100,100,101,0},95,99},
        {8,4,{100,102,103,104},89,100}
    };
    for(unsigned c=0;c<sizeof(cases)/sizeof(cases[0]);c++){
        const Case *v=&cases[c];memcpy(times,v->clocks,sizeof(times));clock_count=v->n;clock_index=0;memset(sites,0,sizeof(sites));
        unsigned char entity[128] __attribute__((aligned(16)))={0},render[312] __attribute__((aligned(16)))={0};
        *(int16_t *)(entity+4)=1;*(int16_t *)(entity+24)=12;*(int16_t *)(entity+26)=3;*(int16_t *)(entity+68)=11;
        *(uint32_t *)(entity+8)=v->update;*(uint32_t *)(entity+12)=v->animation;*(uint32_t *)(entity+16)=777;
        *(int16_t *)(entity+36)=180;*(int16_t *)(entity+38)=60;*(int16_t *)(entity+40)=200;*(int16_t *)(entity+42)=131;
        *(void **)(entity+62)=render;*(double *)(render+16)=71;*(double *)(render+24)=20;
        *(double *)(entity+72)=.25;*(double *)(entity+80)=-.5;
        *(double *)(globals+0xa1e)=0;*(double *)(globals+0xa26)=640;*(double *)(globals+0xa2e)=0;*(double *)(globals+0xa36)=380;
        *(int16_t *)(globals+0xaac)=v->keys&1?-1:0;*(int16_t *)(globals+0xaae)=v->keys&2?-1:0;*(int16_t *)(globals+0xaa8)=v->keys&4?-1:0;*(int16_t *)(globals+0xaaa)=v->keys&8?-1:0;
        *(void **)(globals+0x38c)=heap;invoke_fb(code+0x5ed70,globals,toc,entity,NULL,NULL);
        if(clock_index!=clock_count){fprintf(stderr,"Clockcount case%u %u/%u\n",c,clock_index,clock_count);return 1;}
        printf("case%u clocks%u",c,clock_count);for(unsigned j=0;j<clock_count;j++)printf(" %08x=%u",sites[j],times[j]);puts("");
        double initial_x=.25,initial_y=-.5;
        fprintf(fixture,"%u,%u,%u,%u,%u,%u,%u,%u,%u,%016llx,%016llx,12,3,1,%016llx,%016llx,%d,%d,%d,%u,%u,%u\n",c,v->keys,v->n,times[0],times[1],times[2],times[3],v->animation,v->update,bits(&initial_x),bits(&initial_y),bits(entity+72),bits(entity+80),*(int16_t *)(entity+24),*(int16_t *)(entity+26),*(int16_t *)(entity+4),*(uint32_t *)(entity+12),*(uint32_t *)(entity+8),*(uint32_t *)(entity+16));
    }
    fclose(fixture);puts("PASS16 original full-player independent-clock states; firingfalse, Shield/Glowabsent");return 0;
}
