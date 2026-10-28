/* Original LMCHANGESPRITEID: clocks, centering and IEEE geometry, including901. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned sample,step,reads;
static uint32_t tick(void){uint32_t n=(sample==3?UINT32_MAX-2:1000)+reads++;printf("T,%u,%u,%u\n",sample,step,n);return n;}
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==14014);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*table=read_file(argv[3]),*g=calloc(1,0x1300),*heap=calloc(1,65536);assert(g&&heap);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=tick;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    *(void **)(g+0x21c)=lit;*(void **)(g+0xe82)=table;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
    for(unsigned id=900;id<=902;id++)assert(*(short *)(table+id*14+6)==222&&*(short *)(table+id*14+8)==222&&*(short *)(table+id*14+12)==(id==902?1:0));
    MakeDataExecutable(code,433284);
    const double bounds[][4]={{381,222,65,65},{-.125,1.25,65.125,64.875},{1e16,-1e16,222,222},{-83.25,5.5,.125,1000.5}};const unsigned ids[]={902,900,901,900,901};
    for(sample=0;sample<4;sample++){
        unsigned char node[308] __attribute__((aligned(8)))={0};memcpy(node,bounds[sample],32);*(short *)(node+38)=900;reads=0;
        for(step=0;step<5;step++){
            invoke_fb(code+0x343b4,g,toc,node,(void *)ids[step],NULL);
            printf("N,%u,%u,%d,%u",sample,step,*(short *)(node+38),*(uint32_t *)(node+34));
            for(unsigned i=0;i<4;i++){uint64_t bits;memcpy(&bits,node+i*8,8);printf(",%016llx",bits);}putchar('\n');
        }assert(reads==5);
    }
    fputs("PASS20 original sprite changes including pressed901,80 IEEE bounds and clock wrap\n",stderr);return 0;
}
