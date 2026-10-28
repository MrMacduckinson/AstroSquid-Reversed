/* Actual PUTCONTROLSINWINDOW, scene factory, RNG/stars and fast MOVEMENUTO.
   Resource, allocation, FutureBASIC file/OS and debug boundaries are observed. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned profile,reads,allocs,file_records;
static FILE *scene_file;static const char *scene_path;
static unsigned char *allocated[52],*globals;static Handle strings;
static uint64_t bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static uint32_t setup_tick(void){uint32_t t=1000+reads++;assert(reads<1000);printf("T,%u,%u,%u,%016llx,%016llx\n",profile,t,*(uint32_t *)(globals+0x244),bits(*(double *)(globals+0xea2)),bits(*(double *)(globals+0xeaa)));return t;}
static void *setup_alloc(unsigned bytes){assert(bytes==308&&allocs<52);void *p=calloc(1,bytes);assert(p);allocated[allocs++]=p;return p;}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
int setup_system(int selector){assert(selector==1);return 123;}
int setup_folder(int volume){assert(volume==123);unsigned char *p=*(unsigned char **)(globals+0x38c)-256;assert(p[0]==4&&!memcmp(p+1,"Data",4));*(void **)(globals+0x38c)=p;return 123;}
void setup_open(int mode,int number,int kind,unsigned char *name,int z,int folder,int unused){assert(mode==0x52&&number==1&&kind==1&&!z&&folder==123&&!unused&&!scene_file&&name[0]==7&&!memcmp(name+1,"Data B2",7));scene_file=fopen(scene_path,"rb");assert(scene_file);}
int setup_read(int number,void *out,int bytes){assert(number==1&&bytes==308&&scene_file&&fread(out,1,308,scene_file)==308);file_records++;return 0;}
long setup_length(int number){assert(number==1&&scene_file);return 52*308;}
int setup_eof(int number){assert(number==1&&scene_file);return ftell(scene_file)>=52*308?-1:0;}
void setup_close(int number){assert(number==1&&scene_file&&!fclose(scene_file));scene_file=NULL;}
BRIDGE(setup_system) BRIDGE(setup_folder) BRIDGE(setup_open) BRIDGE(setup_read) BRIDGE(setup_length) BRIDGE(setup_eof) BRIDGE(setup_close)
int main(int argc,char **argv){
    if(argc!=6)return 2;alarm(60);struct stat st;
    const long sizes[]={455780,11812,6884,14014,52*308};for(unsigned i=1;i<6;i++)assert(!stat(argv[i],&st)&&st.st_size==sizes[i-1]);scene_path=argv[5];
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*raw=read_file(argv[3]),*table=read_file(argv[4]);
    unsigned char *heap=calloc(1,0x100000),*g=calloc(1,0x1400);double *stars=calloc(3001*4,8);assert(heap&&g&&stars);globals=g;
    strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=setup_tick;if(!strcmp(import_names[i],"NewPtrClear"))fn=setup_alloc;if(!strcmp(import_names[i],"GetResource"))fn=resource;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    const struct{unsigned at;void *fn;}hooks[]={{0x342b4,noop},{0x24450,setup_system_fb},{0xce40,setup_folder_fb},{0xf064,setup_open_fb},{0xfd04,setup_read_fb},{0x109bc,setup_length_fb},{0x10f44,setup_eof_fb},{0xf8d4,setup_close_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(*hooks);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    const uint32_t seeds[]={0,0x12345678,UINT32_MAX};
    for(profile=0;profile<9;profile++){
        memset(g,0,0x1400);reads=allocs=file_records=0;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xe82)=table;*(void **)(g+0xa54)=stars;
        *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(short *)(g+0xa52)=profile%3+1;*(short *)(g+0xcce)=16;*(uint32_t *)(g+0x244)=seeds[profile/3];
        *(double *)(g+0xea2)=profile/3==1?-1234.25:profile/3==2?33.25:0;*(double *)(g+0xeaa)=profile/3==1?19.5:profile/3==2?-44.5:0;
        printf("P,%u,%u,%u\n",profile,profile%3+1,seeds[profile/3]);
        invoke_fb(code+0x64154,g,toc,NULL,NULL,NULL);assert(allocs==52&&file_records==52&&!scene_file);
        unsigned index=0;for(unsigned char *n=*(void **)(g+0xe86);n;n=*(void **)(n+300)){
            printf("N,%u,%u,%d,%d,%u",profile,index++,*(short *)(n+38),*(int *)(n+296),*(uint32_t *)(n+34));for(unsigned a=0;a<4;a++)printf(",%016llx",bits(*(double *)(n+a*8)));putchar('\n');
        }assert(index==52);
        for(unsigned i=1;i<=3000;i++)printf("S,%u,%u,%016llx,%016llx,%016llx,%016llx\n",profile,i-1,bits(stars[i*4]),bits(stars[i*4+1]),bits(stars[i*4+2]),bits(stars[i*4+3]));
        printf("Z,%u,%u,%u,%016llx,%016llx,%016llx,%016llx\n",profile,reads,*(uint32_t *)(g+0x244),bits(*(double *)(g+0xea2)),bits(*(double *)(g+0xeaa)),bits(*(double *)(g+0xa58)),bits(*(double *)(g+0xa60)));
        for(unsigned i=0;i<allocs;i++)free(allocated[i]);
    }
    DisposeHandle(strings);fputs("PASS9 actual PUTCONTROLSINWINDOW factory/RNG/stars/clock profiles\n",stderr);return 0;
}
