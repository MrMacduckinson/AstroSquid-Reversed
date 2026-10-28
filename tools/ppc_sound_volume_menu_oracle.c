/* Actual DOMOUSE SetSVolume branch; original LMCHANGE, observed sound/render APIs. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned sample,reads;
static int music_mode;
static unsigned char *node,*globals;
static Handle strings;
static uint32_t tick(void){uint32_t n=100+reads++;printf("T,%u,%u\n",sample,n);return n;}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static int zero(void){return 0;}
static void mouse(Point *p){p->h=0;p->v=0;}
void volume(double *v,int immediate){assert(immediate==1);printf("V,%u,%d\n",sample,(int)(255**v));}
void sound(unsigned char *name){assert(name[0]==5&&!memcmp(name+1,"Click",5));printf("S,%u,Click\n",sample);}
void draw(void){printf("D,%u,%d,%u",sample,*(short *)(node+38),*(uint32_t *)(node+34));if(music_mode)printf(",%d",*(short *)(globals+0xabc));putchar('\n');}
void swap(void){printf("W,%u\n",sample);}
void sound_pan(unsigned char *name,double *position){assert(name[0]==5&&!memcmp(name+1,"Click",5));uint64_t b;memcpy(&b,position,8);printf("P,%u,%016llx\n",sample,b);}
void track(unsigned id,int value){assert(id==1||id==2);printf("V,%u,%u,%d\n",sample,id,value);}
BRIDGE(track) BRIDGE(sound_pan) BRIDGE(volume) BRIDGE(sound) BRIDGE(draw) BRIDGE(swap)
int main(int argc,char **argv){
    if(argc!=5&&argc!=6)return 2;music_mode=argc==6;assert(!music_mode||!strcmp(argv[5],"music"));alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884&&!stat(argv[4],&st)&&st.st_size==14014);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*raw=read_file(argv[3]),*table=read_file(argv[4]),*g=calloc(1,0x1300),*heap=calloc(1,65536);assert(g&&heap);globals=g;strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=tick;if(!strcmp(import_names[i],"GetResource"))fn=resource;if(!strcmp(import_names[i],"GetMouse"))fn=mouse;if(!strcmp(import_names[i],"Button"))fn=zero;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x32c78,track_fb);jump_to(code+0x3ce84,sound_pan_fb);jump_to(code+0x24248,zero);jump_to(code+0x3d254,volume_fb);jump_to(code+0x3ccd8,sound_fb);jump_to(code+0x45af0,noop);jump_to(code+0x46394,noop);jump_to(code+0x35eb8,swap_fb);
    // LMDRAWSPRITES observed, with original pressed sprite state retained.
    jump_to(code+0x3aaf8,draw_fb);MakeDataExecutable(code,433284);
    for(sample=0;sample<11;sample++){
        memset(g,0,0x1300);reads=0;unsigned char sprite[308] __attribute__((aligned(8)))={0};node=sprite;double bounds[]={381,222,65,65};memcpy(node,bounds,32);*(short *)(node+32)=10;*(short *)(node+38)=900;node[40]=10;memcpy(node+41,music_mode?"SetMVolume":"SetSVolume",10);*(void **)(g+0xe86)=node;
        *(void **)(g+0x21c)=lit;*(void **)(g+0xe82)=table;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+(music_mode?0xabc:0xabe))=sample;*(short *)(g+0xed6)=640;*(unsigned *)(g+0xa3e)=1;*(unsigned *)(g+0xa42)=2;
        unsigned char name[]={10,'S','e','t',music_mode?'M':'S','V','o','l','u','m','e'};invoke_fb(code+0x3f178,g,toc,name,NULL,NULL);
        printf("Z,%u,%d,%d,%u,%u\n",sample,*(short *)(g+(music_mode?0xabc:0xabe)),*(short *)(node+38),*(uint32_t *)(node+34),reads);assert(reads==2);
    }
    fputs(music_mode?"PASS11 original DOMOUSE music-volume levels, old-label pressed draw and track ordering\n":"PASS11 original DOMOUSE sound-volume levels, preview and press/reset clocks\n",stderr);return 0;
}
