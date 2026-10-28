/* Original LMHANDLESPRITES including real LMCHANGESPRITEID, key/debug and FPS clocks. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned sample,reads;
static const uint32_t starts[]={100,101,160,UINT32_MAX-1,0x7fffffff,0x80000000};
static uint32_t tick(void){uint32_t n=starts[sample]+reads++;printf("T,%u,%u\n",sample,n);return n;}
static void keys(void *p){memset(p,0,16);if(sample&1)((unsigned char *)p)[15]=4;printf("K,%u,%u\n",sample,sample&1);}
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==14014);unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*table=read_file(argv[3]),*g=calloc(1,0x1300),*heap=calloc(1,65536);assert(g&&heap);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=tick;if(!strcmp(import_names[i],"GetKeys"))fn=keys;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;MakeDataExecutable(code,433284);
    for(sample=0;sample<6;sample++){
        memset(g,0,0x1300);reads=0;*(void **)(g+0x21c)=lit;*(void **)(g+0xe82)=table;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xec6)=-7;*(uint32_t *)(g+0xec8)=sample==3?UINT32_MAX-59:100;*(double *)(g+0xebe)=3.5;
        unsigned char nodes[6][308] __attribute__((aligned(8)))={{0}};const short ids[]={0,1,900,901,902,902};
        for(unsigned i=0;i<6;i++){
            double bounds[]={381+i*.125,222-i*.25,65+i*.125,65-i*.125};memcpy(nodes[i],bounds,32);*(short *)(nodes[i]+38)=ids[i];*(uint32_t *)(nodes[i]+34)=i==5?starts[sample]-1:starts[sample];if(i<5)*(void **)(nodes[i]+300)=nodes[i+1];
        }*(void **)(g+0xe86)=nodes[0];
        invoke_fb(code+0x3b55c,g,toc,NULL,NULL,NULL);
        for(unsigned i=0;i<6;i++){printf("N,%u,%u,%d,%u",sample,i,*(short *)(nodes[i]+38),*(uint32_t *)(nodes[i]+34));for(unsigned a=0;a<4;a++){uint64_t bits;memcpy(&bits,nodes[i]+a*8,8);printf(",%016llx",bits);}putchar('\n');}
        uint64_t bits;memcpy(&bits,g+0xebe,8);printf("F,%u,%d,%d,%u,%016llx,%u\n",sample,*(short *)(g+0xecc),*(short *)(g+0xec6),*(uint32_t *)(g+0xec8),bits,reads);
    }
    fputs("PASS6 original menu sprite-handler profiles: strict signed deadline, keys, FPS and wrap\n",stderr);return 0;
}
