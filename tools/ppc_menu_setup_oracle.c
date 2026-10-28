/* Actual PUTCONTROLSINWINDOW, scene factory, RNG/stars and fast MOVEMENUTO.
   Resource, allocation, FutureBASIC file/OS and debug boundaries are observed. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned profile,reads,allocs,file_records;
static int visibility;
static FILE *scene_file;static const char *scene_path;
static unsigned char *allocated[52],*globals;static Handle strings;
static uint64_t bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static uint32_t setup_tick(void){uint32_t t=1000+reads++;assert(reads<1000);printf("T,%u,%u,%u,%016llx,%016llx\n",profile,t,*(uint32_t *)(globals+0x244),bits(*(double *)(globals+0xea2)),bits(*(double *)(globals+0xeaa)));return t;}
static void *setup_alloc(unsigned bytes){assert(bytes==308&&allocs<52);void *p=calloc(1,bytes);assert(p);allocated[allocs++]=p;return p;}
static void setup_dispose(void *p){for(unsigned i=0;i<allocs;i++)if(allocated[i]==p){allocated[i]=NULL;free(p);return;}abort();}
static void dummy_registration(unsigned char *g){
    const unsigned char name[]="TEST";int a=(4*128%26+name[2]*42%26)%26,b=(name[1]*35%26+a)%26,c=(name[1]*35%26+b)%26;
    int digits[]={a,(name[0]*13%26+name[1]*35%26)%26,(name[2]*42%26+name[2]*24%26)%26,b,(name[0]*72%26+name[2]*24%26)%26,c,(name[2]*24%26+name[2]*11%26)%26,(name[2]*11%26+c)%26};
    g[0xac2]=4;memcpy(g+0xac3,name,4);g[0xbc2]=8;for(unsigned i=0;i<8;i++)g[0xbc3+i]='A'+digits[i];
}
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
    if(argc!=6&&argc!=7)return 2;visibility=argc==7;assert(!visibility||!strcmp(argv[6],"visibility"));alarm(60);struct stat st;
    const long sizes[]={455780,11812,6884,14014,52*308};for(unsigned i=1;i<6;i++)assert(!stat(argv[i],&st)&&st.st_size==sizes[i-1]);scene_path=argv[5];
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*raw=read_file(argv[3]),*table=read_file(argv[4]),*scene=read_file(argv[5]);
    unsigned char *heap=calloc(1,0x100000),*g=calloc(1,0x1400);double *stars=calloc(3001*4,8);assert(heap&&g&&stars);globals=g;
    strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=setup_tick;if(!strcmp(import_names[i],"NewPtrClear"))fn=setup_alloc;if(!strcmp(import_names[i],"GetResource"))fn=resource;if(!strcmp(import_names[i],"DisposePtr"))fn=setup_dispose;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    const struct{unsigned at;void *fn;}hooks[]={{0x342b4,noop},{0x24450,setup_system_fb},{0xce40,setup_folder_fb},{0xf064,setup_open_fb},{0xfd04,setup_read_fb},{0x109bc,setup_length_fb},{0x10f44,setup_eof_fb},{0xf8d4,setup_close_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(*hooks);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    const uint32_t seeds[]={0,0x12345678,UINT32_MAX};
    for(profile=0;profile<(visibility?32u:9u);profile++){
        memset(g,0,0x1400);reads=allocs=file_records=0;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xe82)=table;*(void **)(g+0xa54)=stars;
        *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(short *)(g+0xa52)=profile%3+1;*(short *)(g+0xcce)=16;*(uint32_t *)(g+0x244)=seeds[visibility?1:profile/3];
        *(double *)(g+0xea2)=profile/3==1?-1234.25:profile/3==2?33.25:0;*(double *)(g+0xeaa)=profile/3==1?19.5:profile/3==2?-44.5:0;
        if(visibility){*(short *)(g+0xa52)=1;*(short *)(g+0xcce)=profile%16+1;*(uint32_t *)(g+0x244)=0x12345678;*(double *)(g+0xea2)=*(double *)(g+0xeaa)=0;if(profile>=16)dummy_registration(g);printf("V,%u,%u,%u\n",profile,profile>=16,profile%16+1);}else printf("P,%u,%u,%u\n",profile,profile%3+1,seeds[profile/3]);
        invoke_fb(code+0x64154,g,toc,NULL,NULL,NULL);assert(allocs==52&&file_records==52&&!scene_file);
        unsigned index=0;for(unsigned char *n=*(void **)(g+0xe86);n;n=*(void **)(n+300)){
            unsigned raw=0;while(raw<52&&allocated[raw]!=n)raw++;assert(raw<52);index++;printf("N,%u,%u,%d,%d,%u",profile,raw,*(short *)(n+38),*(int *)(n+296),*(uint32_t *)(n+34));for(unsigned a=0;a<4;a++)printf(",%016llx",bits(*(double *)(n+a*8)));putchar('\n');
        }assert(index==(visibility?52-(16-(profile%16+1))-(profile>=16):52));if(visibility)assert((*(short *)(g+0xa0c)!=0)==(profile>=16));
        if(visibility)for(unsigned i=0;i<52;i++){
            double *raw=(double *)(scene+i*308);short x=(short)(*(double *)(g+0xea2)+raw[0]+raw[2]/2),y=(short)(*(double *)(g+0xeaa)+raw[1]+raw[3]/2);
            uint32_t point=((uint32_t)(uint16_t)y<<16)|(uint16_t)x;uintptr_t hit=invoke_fb(code+0x3b378,g,toc,(void *)(uintptr_t)point,NULL,NULL);int found=-1;
            for(unsigned j=0;j<52;j++)if(allocated[j]&&hit==(uintptr_t)allocated[j])found=j;
            assert(!hit||found>=0);printf("Q,%u,%u,%d,%d,%d\n",profile,i,x,y,found);
        }
        for(unsigned i=1;i<=3000;i++)printf("S,%u,%u,%016llx,%016llx,%016llx,%016llx\n",profile,i-1,bits(stars[i*4]),bits(stars[i*4+1]),bits(stars[i*4+2]),bits(stars[i*4+3]));
        printf("Z,%u,%u,%u,%016llx,%016llx,%016llx,%016llx\n",profile,reads,*(uint32_t *)(g+0x244),bits(*(double *)(g+0xea2)),bits(*(double *)(g+0xeaa)),bits(*(double *)(g+0xa58)),bits(*(double *)(g+0xa60)));
        for(unsigned i=0;i<allocs;i++)free(allocated[i]);
    }
    DisposeHandle(strings);fputs(visibility?"PASS32 original registration/unlock menu profiles\n":"PASS9 actual PUTCONTROLSINWINDOW factory/RNG/stars/clock profiles\n",stderr);return 0;
}
