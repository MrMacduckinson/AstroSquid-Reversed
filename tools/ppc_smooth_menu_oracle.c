/* Actual DOMOUSE SetSmooth and LMKILLSPRITEMAP; texture loading observed. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned sample,reads;
#include "../tests/smooth_maps.h"
static unsigned char *node,*globals;
static Handle strings;
static uint32_t tick(void){uint32_t n=100+reads++;printf("T,%u,%u\n",sample,n);return n;}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static void mouse(Point *p){p->h=0;p->v=0;}
static int zero(void){return 0;}
static int present(unsigned id){for(unsigned i=0;i<sizeof(smooth_map_ids)/sizeof(*smooth_map_ids);i++)if(smooth_map_ids[i]==id)return 1;return 0;}
static void cursor(int value){assert(value==0||value==4);printf("C,%u,%d\n",sample,value);}
static void deleted(int count,unsigned *texture){assert(count==1&&*texture>=10000&&*texture<10107);printf("D,%u,%u,%d,%d\n",sample,*texture-10000,*(short *)(node+38),*(short *)(globals+0xcd0));}
void load(unsigned id){assert(id<107&&!*(void **)(globals+0xcd6+id*4));int yes=present(id);printf("L,%u,%u,%d,%d,%d\n",sample,id,yes,*(short *)(node+38),*(short *)(globals+0xee6));if(yes){unsigned char *map=(unsigned char *)NewPtrClear(8);assert(map);*(unsigned *)(map+4)=20000+id;*(void **)(globals+0xcd6+id*4)=map;}}
void sound_pan(unsigned char *name,double *position){assert(name[0]==5&&!memcmp(name+1,"Click",5));uint64_t b;memcpy(&b,position,8);printf("P,%u,%016llx\n",sample,b);}
BRIDGE(cursor) BRIDGE(load) BRIDGE(sound_pan)
int main(int argc,char **argv){
    if(argc!=5)return 2;alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884&&!stat(argv[4],&st)&&st.st_size==14014);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*raw=read_file(argv[3]),*table=read_file(argv[4]),*g=calloc(1,0x1300),*heap=calloc(1,65536);assert(g&&heap);globals=g;strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=tick;if(!strcmp(import_names[i],"glDeleteTextures"))fn=deleted;if(!strcmp(import_names[i],"GetResource"))fn=resource;if(!strcmp(import_names[i],"GetMouse"))fn=mouse;if(!strcmp(import_names[i],"Button"))fn=zero;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x24248,zero);jump_to(code+0x2b020,cursor_fb);jump_to(code+0x3ce84,sound_pan_fb);jump_to(code+0x33b40,load_fb);MakeDataExecutable(code,433284);
    for(sample=0;sample<2;sample++){
        memset(g,0,0x1300);reads=0;unsigned char sprite[308] __attribute__((aligned(8)))={0};node=sprite;double bounds[]={381,222,65,65};memcpy(node,bounds,32);*(short *)(node+32)=10;*(short *)(node+38)=900;node[40]=9;memcpy(node+41,"SetSmooth",9);*(void **)(g+0xe86)=node;
        *(void **)(g+0x21c)=lit;*(void **)(g+0xe82)=table;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xed6)=640;*(short *)(g+0xcd0)=*(short *)(g+0xee6)=sample;
        for(unsigned id=0;id<107;id++)if(present(id)){unsigned char *map=(unsigned char *)NewPtrClear(8);assert(map);*(unsigned *)(map+4)=10000+id;*(void **)(g+0xcd6+id*4)=map;}
        unsigned char name[]={9,'S','e','t','S','m','o','o','t','h'};invoke_fb(code+0x3f178,g,toc,name,NULL,NULL);
        printf("Z,%u,%d,%d,%u,%u\n",sample,*(short *)(g+0xcd0),*(short *)(node+38),*(uint32_t *)(node+34),reads);assert(reads==2);
        for(unsigned id=0;id<107;id++){void *map=*(void **)(g+0xcd6+id*4);assert((map!=NULL)==present(id));if(map)DisposePtr(map);}
    }
    fputs("PASS2 original smooth toggles,107 ordered kill/load slots,54 actual deletions each\n",stderr);return 0;
}
