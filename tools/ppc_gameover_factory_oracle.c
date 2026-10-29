/* Real LMLOADSCENE/LMNEWSPRITE/GAMEOVERTRANS/field setup; only FB file/OS/render IO observed. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <setjmp.h>
#include <unistd.h>
#include <sys/stat.h>
static jmp_buf ready;
static unsigned scenario,reads,allocs,file_records,rect_calls;
static uint32_t base_tick;
static int advancing,real_hud;
static FILE *scene_file;
static const char *scene_path;
static unsigned char *allocated[2048],*globals;
static Handle strings;
static Point point;
static Rect field_rect;
static uint64_t word(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static uint32_t factory_tick(void){uint32_t tick=base_tick+(advancing?reads:0);printf("T,%u,%u,%u\n",scenario,reads++,tick);return tick;}
static void *factory_alloc(unsigned bytes){assert(bytes==308&&allocs<2048);void *p=calloc(1,bytes);assert(p);allocated[allocs++]=p;return p;}
static void factory_dispose(void *p){for(unsigned i=0;i<allocs;i++)if(allocated[i]==p){free(p);allocated[i]=NULL;return;}abort();}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static void get_mouse(Point *p){*p=point;}
static int zero(void){return 0;}
static void rect(Rect *out,short l,short t,short r,short b){SetRect(out,l,t,r,b);if(!rect_calls++)field_rect=*out;}
int factory_system(int selector){assert(selector==1);return 123;}
int factory_folder(int volume){assert(volume==123);unsigned char *p=*(unsigned char **)(globals+0x38c)-256;assert(p[0]==4&&!memcmp(p+1,"Data",4));*(void **)(globals+0x38c)=p;return 123;}
void factory_open(int mode,int number,int kind,unsigned char *name,int z,int folder,int unused){assert(mode==0x52&&number==1&&kind==1&&!z&&folder==123&&!unused&&!scene_file&&name[0]==7&&!memcmp(name+1,"Data B1",7));scene_file=fopen(scene_path,"rb");assert(scene_file);}
int factory_read(int number,void *out,int bytes){assert(number==1&&bytes==308&&scene_file&&fread(out,1,308,scene_file)==308);file_records++;return 0;}
long factory_length(int number){assert(number==1&&scene_file);return 924;}
int factory_eof(int number){assert(number==1&&scene_file);return ftell(scene_file)>=924?-1:0;}
void factory_close(int number){assert(number==1&&scene_file&&!fclose(scene_file));scene_file=NULL;}
void factory_ready(void){assert(allocs==(real_hud?1023u:3u)&&file_records==3&&!scene_file);longjmp(ready,1);}
BRIDGE(factory_system) BRIDGE(factory_folder) BRIDGE(factory_open) BRIDGE(factory_read) BRIDGE(factory_length) BRIDGE(factory_eof) BRIDGE(factory_close) BRIDGE(factory_ready)
int main(int argc,char **argv){
    real_hud=getenv("ASTRO_WORLD_REAL_HUD")!=NULL;
    if(argc!=6&&argc!=7)return 2;advancing=argc==7;assert(!advancing||!strcmp(argv[6],"advancing"));alarm(30);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884&&!stat(argv[4],&st)&&st.st_size==14014&&!stat(argv[5],&st)&&st.st_size==924);scene_path=argv[5];
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*heap=calloc(1,0x100000),*g=calloc(1,0x1300),*table=read_file(argv[4]),*raw=read_file(argv[3]);assert(g&&heap);globals=g;strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=factory_tick;if(real_hud&&!strncmp(import_names[i],"gl",2))fn=noop;if(!strcmp(import_names[i],"DisposePtr"))fn=factory_dispose;if(!strcmp(import_names[i],"NewPtrClear"))fn=factory_alloc;if(!strcmp(import_names[i],"GetResource"))fn=resource;if(!strcmp(import_names[i],"ShowCursor"))fn=noop;if(!strcmp(import_names[i],"GetMouse"))fn=get_mouse;if(!strcmp(import_names[i],"SetRect"))fn=rect;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    const struct{unsigned at;void *fn;}hooks[]={{0x539b8,noop},{0x54c64,noop},{0x3b55c,noop},{0x57afc,noop},{0x43134,noop},{0x35eb8,noop},{0x3760,noop},{0x44e10,noop},{0x342b4,noop},{0x24248,zero},{0x24450,factory_system_fb},{0xce40,factory_folder_fb},{0xf064,factory_open_fb},{0xfd04,factory_read_fb},{0x109bc,factory_length_fb},{0x10f44,factory_eof_fb},{0xf8d4,factory_close_fb},{0x2b290,factory_ready_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)if(!real_hud||hooks[i].at!=0x43134)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    if(real_hud){unsigned drawings[]={0x3a278,0x41730,0x3572c};for(unsigned i=0;i<3;i++)jump_to(code+drawings[i],noop);MakeDataExecutable(code,433284);}
    for(scenario=0;scenario<3;scenario++){
        memset(g,0,0x1300);reads=allocs=file_records=0;base_tick=scenario==1?UINT32_MAX-10:1000;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xe82)=table;*(void **)(g+0xeb6)=font_widths;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(short *)(g+0xa52)=1;
        int values[12]={0};*(void **)(g+0xa72)=values;*(int *)(g+0xa7e)=100;*(double *)(g+0xea2)=scenario==2?-1234.25:0;*(double *)(g+0xeaa)=scenario==2?19.5:0;
        if(!setjmp(ready))invoke_fb(code+0x4cef0,g,toc,NULL,NULL,NULL);
        unsigned index=0;for(unsigned char *node=*(void **)(g+0xe86);node;node=*(void **)(node+300)){
            printf("N,%u,%u,",scenario,index++);for(unsigned c=0;c<node[40];c++)printf("%02x",node[41+c]);printf(",%d,%d,%u,%d",*(short *)(node+32),*(short *)(node+38),*(uint32_t *)(node+34),*(int *)(node+296));for(unsigned a=0;a<4;a++)printf(",%016llx",word(*(double *)(node+a*8)));putchar('\n');
        }assert(index==3&&reads==(real_hud?1025u:5u));
        printf("F,%u",scenario);for(unsigned a=0;a<4;a++)printf(",%016llx",word(*(double *)(g+0x5b2+a*8)));printf(",%u\n",*(uint32_t *)(g+0x5d2));
        for(int y=250;y<=280;y++){
            *(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xa06)=NULL;*(short *)(g+0x5d6)=77;*(short *)(g+0xa68)=1;*(short *)(g+0x5aa)=1;point.h=225;point.v=y;rect_calls=0;unsigned char empty[256]={0};invoke_fb(code+0x3f178,g,toc,empty,NULL,NULL);
            printf("M,%u,%d,%d,%d,%d,%d,%d,%d\n",scenario,y,*(void **)(g+0xa06)==g+0x5b2,*(short *)(g+0x5d6),field_rect.left,field_rect.top,field_rect.right,field_rect.bottom);
        }
        for(unsigned i=0;i<allocs;i++)free(allocated[i]);
    }
    DisposeHandle(strings);fputs("PASS actual DataB1 factory/TRANS/field geometry,3clock-camera profiles and93DOMOUSE edges\n",stderr);return 0;
}
