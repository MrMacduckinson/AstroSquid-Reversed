/* Original post-FIREWEAPONSPECIAL continuation only. Private code patches,
   controlled clock/resource lookup; no original application or preferences writes. */
#include <Carbon/Carbon.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
static unsigned char shield[312] __attribute__((aligned(16)));
static unsigned char glow[312] __attribute__((aligned(16)));
static uint32_t tick,clock_calls,lookup_calls;static unsigned present;
static uint32_t clock_value(void){clock_calls++;return tick;}
static void no_resource(void){}
static void *find_sprite(void){unsigned index=lookup_calls++;if(index>1)exit(2);return present&(1u<<index)?(index?glow:shield):NULL;}
static void jump_to(unsigned char *at,void *destination){uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
static unsigned char *read_file(const char *path){FILE *f=fopen(path,"rb");if(!f)exit(2);fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static unsigned long long bits(const void *p){unsigned long long v;memcpy(&v,p,8);return v;}
int main(int argc,char **argv){
    if(argc!=4)return 2;FILE *fixture=fopen(argv[3],"w");if(!fixture)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*globals=calloc(1,0x1300),*heap=calloc(1,0x10000);uint32_t toc[489]={0};
    *(void **)(globals+0x21c)=literals;*(double *)(globals+0x378)=4503601774854144.;*(uint32_t *)(globals+0x380)=0x43300000;*(void **)(globals+0x388)=heap;toc[0]=(uint32_t)(uintptr_t)globals;
    /* Enter immediately after the original synchronous call, supplying entity r22.
       Keep 1005fc8c..10060028 unchanged, including clock/store/follow/glow math. */
    *(uint32_t *)(code+0x5fc80)=0x7de802a6; /* mflr r15 */
    *(uint32_t *)(code+0x5fc84)=0x7c761b78; /* mr r22,r3 */
    *(uint32_t *)(code+0x5fc88)=0x90410014; /* stw r2,20(r1) */
    *(uint32_t *)(code+0x6002c)=0x7de803a6; /* mtlr r15 */
    *(uint32_t *)(code+0x60030)=0x4e800020; /* blr, replacing normal full-function epilogue */
    jump_to(code+0x694e4,clock_value);jump_to(code+0x2ca8,no_resource);jump_to(code+0x3b260,find_sprite);MakeDataExecutable(code,433284);
    const int frames[]={-32768,-1,0,4,12,32767};unsigned cases=0;
    for(present=0;present<4;present++)for(unsigned f=0;f<sizeof(frames)/sizeof(frames[0]);f++)for(int variant=0;variant<2;variant++){
        unsigned char entity[128] __attribute__((aligned(16)))={0},render[312] __attribute__((aligned(16)))={0};
        tick=variant?UINT32_MAX:100;uint32_t animation=variant?2:70,update=42;
        int16_t left=variant?-32768:81,top=variant?32767:-20;
        *(uint32_t *)(entity+8)=update;*(uint32_t *)(entity+12)=animation;*(int16_t *)(entity+24)=frames[f];*(int16_t *)(entity+36)=top;*(int16_t *)(entity+38)=left;
        *(void **)(entity+62)=render;*(void **)(globals+0xa7a)=entity;
        double *r=(double *)render;r[0]=variant?-0.0:101.1;r[1]=variant?0.125:-14.3;r[2]=71.25;r[3]=variant?25.75:20.2;
        double *s=(double *)shield,*g=(double *)glow;s[0]=-123.25;s[1]=456.5;g[0]=-19.25;g[1]=23.5;g[2]=7.75;g[3]=9.5;
        clock_calls=lookup_calls=0;*(void **)(globals+0x38c)=heap;invoke_fb(code+0x5fc80,globals,toc,entity,NULL,NULL);
        if(clock_calls!=1||lookup_calls!=2||*(uint32_t *)(entity+8)!=tick||*(uint32_t *)(entity+12)!=(present&2?animation-5:animation))return 1;
        fprintf(fixture,"%u,%d,%d,%u,%u,%u,%d,%d,%016llx,%016llx,%016llx,%016llx,%u,%u,%016llx,%016llx,%016llx,%016llx,%016llx,%016llx\n",present,frames[f],variant,tick,update,animation,left,top,bits(r),bits(r+1),bits(r+2),bits(r+3),*(uint32_t *)(entity+8),*(uint32_t *)(entity+12),bits(s),bits(s+1),bits(g),bits(g+1),bits(g+2),bits(g+3));cases++;
    }
    fclose(fixture);printf("PASS %u native postfire tails: one clock/store, conditional Shield/Glow, signed frames and animation wrap\n",cases);return 0;
}
