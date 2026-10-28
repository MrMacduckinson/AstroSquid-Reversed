/* Actual LMGETSPRITE/MOVEMENUTO resolution of the startup credits anchor. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned reads;static Handle strings;
static uint32_t tick(void){return 1000+reads++;}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static uint64_t bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static void make_name(unsigned char *p,const char *s){p[0]=strlen(s);memcpy(p+1,s,p[0]);}
int main(int argc,char **argv){
    if(argc!=5)return 2;alarm(20);struct stat st;const long sizes[]={455780,11812,6884,16016};for(unsigned i=1;i<5;i++)assert(!stat(argv[i],&st)&&st.st_size==sizes[i-1]);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*raw=read_file(argv[3]),*scene=read_file(argv[4]),*g=calloc(1,0x1400),*heap=calloc(1,0x100000),*nodes[52];assert(g&&heap);
    strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    for(unsigned i=0;i<52;i++){nodes[i]=calloc(1,308);assert(nodes[i]);memcpy(nodes[i],scene+i*308,308);if(i)*(void **)(nodes[i-1]+300)=nodes[i];*(void **)(nodes[i]+300)=NULL;}
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=tick;if(!strcmp(import_names[i],"GetResource"))fn=resource;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;MakeDataExecutable(code,433284);
    *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xe86)=nodes[0];*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;
    const char *queries[]={"CreditsMenu","Credits Menu","Main Menu"};unsigned char name[256]={0};
    for(unsigned q=0;q<3;q++){make_name(name,queries[q]);uintptr_t p=invoke_fb(code+0x3b260,g,toc,name,NULL,NULL);int found=-1;for(unsigned i=0;i<52;i++)if(p==(uintptr_t)nodes[i])found=i;assert(!p||found>=0);printf("L,%u,%d\n",q,found);}
    for(unsigned interval=1;interval<=3;interval++){
        reads=0;*(short *)(g+0xa52)=interval;*(double *)(g+0xea2)=*(double *)(g+0xeaa)=0;
        const char *moves[]={"Main Menu","Credits Menu","Main Menu"};
        for(unsigned m=0;m<3;m++){make_name(name,moves[m]);invoke_fb(code+0x4b3a4,g,toc,name,NULL,NULL);printf("C,%u,%u,%u,%016llx,%016llx\n",interval,m,reads,bits(*(double *)(g+0xea2)),bits(*(double *)(g+0xeaa)));}
    }
    fputs("PASS actual startup anchor lookup and fast-camera movement\n",stderr);return 0;
}
