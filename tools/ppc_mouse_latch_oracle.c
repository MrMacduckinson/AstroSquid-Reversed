/* Actual DOMOUSE/LMPOINTSPRITE against all three DataB1 nodes, settled panel. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
#include "../tests/mouse_latch_steps.h"
static unsigned mouse_case,step,clock_reads;
static int held;
static uint32_t latch_clock(void){uint32_t tick=100+clock_reads++;printf("%u,%u,T,%u\n",mouse_case,step,tick);return tick;}
static int latch_button(void){return held;}
static Point point;
static Handle strings;
static void get_mouse(Point *out){*out=point;}
static int zero(void){return 0;}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
void mouse_sound(unsigned char *name,double *pan){uint64_t bits;assert(name[0]==5&&!memcmp(name+1,"Click",5));memcpy(&bits,pan,8);printf("%u,%u,S,%016llx\n",mouse_case,step,bits);}
BRIDGE(mouse_sound)
int main(int argc,char **argv){
    setvbuf(stdout,NULL,_IONBF,0);if(argc!=5)return 2;alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884&&!stat(argv[4],&st)&&st.st_size==14014);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000),*raw=read_file(argv[3]);assert(g&&heap);strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetMouse"))fn=get_mouse;if(!strcmp(import_names[i],"Button"))fn=latch_button;if(!strcmp(import_names[i],"TickCount"))fn=latch_clock;if(!strcmp(import_names[i],"GetResource"))fn=resource;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x24248,zero);jump_to(code+0x57afc,noop);jump_to(code+0x44e10,noop);jump_to(code+0x43134,noop);jump_to(code+0x35eb8,noop);jump_to(code+0x3ce84,mouse_sound_fb);MakeDataExecutable(code,433284);
    unsigned char *sprite_table=read_file(argv[4]);assert(*(int16_t *)(sprite_table+902*14+6)==222&&*(int16_t *)(sprite_table+902*14+12)==1);
    for(mouse_case=0;mouse_case<2;mouse_case++){
        unsigned focus=mouse_case;
        memset(g,0,0x1300);*(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(int16_t *)(g+0xed6)=640;*(int16_t *)(g+0xa68)=1;
        unsigned char node[312] __attribute__((aligned(8)))={0},empty[256]={0};double bounds[]={381,-158,65,65};memcpy(node,bounds,32);*(int16_t *)(node+32)=10;*(int16_t *)(node+38)=900;*(uint32_t *)(node+34)=500;node[40]=10;memcpy(node+41,"GameOverOK",10);unsigned char fade[312] __attribute__((aligned(8)))={0},unnamed[312] __attribute__((aligned(8)))={0};
        double fade_bounds[]={0,-381,640,380},other_bounds[]={-328.5,-237.5,83,31};memcpy(fade,fade_bounds,32);memcpy(unnamed,other_bounds,32);
        *(int16_t *)(fade+32)=8;*(int16_t *)(fade+38)=998;fade[40]=12;memcpy(fade+41,"GameOverFade",12);
        *(int16_t *)(unnamed+32)=2;*(int16_t *)(unnamed+38)=1;unnamed[40]=7;memcpy(unnamed+41,"Unnamed",7);
        *(void **)(node+300)=fade;*(void **)(fade+300)=unnamed;*(void **)(g+0xe86)=node;
        double field[]={223,185,200,22};memcpy(g+0x5b2,field,32);*(int16_t *)(g+0x5d6)=77;*(void **)(g+0xeb6)=font_widths;*(void **)(g+0xa06)=focus?g+0x5b2:NULL;*(void **)(g+0xe82)=sprite_table;
        invoke_fb(code+0x4cd48,g,toc,(void *)1,NULL,NULL);clock_reads=0;
        for(step=0;step<sizeof(mouse_latch_steps)/sizeof(mouse_latch_steps[0]);step++){
            point.h=mouse_latch_steps[step].x;point.v=mouse_latch_steps[step].y;held=mouse_latch_steps[step].down;
            if(!focus&&(step==10||step==12))point.h=0;
            if(mouse_latch_steps[step].op=='H')invoke_fb(code+0x41448,g,toc,NULL,NULL,NULL);
            if(mouse_latch_steps[step].op=='D')invoke_fb(code+0x3f178,g,toc,empty,NULL,NULL);
            printf("%u,%u,%c,%d,%u,%d,%d,%d,%d,%d",mouse_case,step,mouse_latch_steps[step].op,*(int16_t *)(node+38),*(uint32_t *)(node+34),*(int16_t *)(g+0x5aa),*(int16_t *)(g+0xa68),*(int16_t *)(g+0x58c),*(int16_t *)(g+0x5d6),*(void **)(g+0xa06)!=NULL);
            for(unsigned axis=0;axis<4;axis++){uint64_t bits;memcpy(&bits,node+axis*8,8);printf(",%016llx",bits);}putchar('\n');
            if(step<16)assert(*(int16_t *)(g+0xa68)==1&&*(int16_t *)(g+0x58c)==0);
        }
        assert(*(int16_t *)(g+0xa68)==0&&*(int16_t *)(g+0x58c)==1&&clock_reads==5);
        invoke_fb(code+0x41448,g,toc,NULL,NULL,NULL);
            printf("%u,%u,%c,%d,%u,%d,%d,%d,%d,%d",mouse_case,step,'H',*(int16_t *)(node+38),*(uint32_t *)(node+34),*(int16_t *)(g+0x5aa),*(int16_t *)(g+0xa68),*(int16_t *)(g+0x58c),*(int16_t *)(g+0x5d6),*(void **)(g+0xa06)!=NULL);
            for(unsigned axis=0;axis<4;axis++){uint64_t bits;memcpy(&bits,node+axis*8,8);printf(",%016llx",bits);}putchar('\n');
        assert(*(int16_t *)(node+38)==900&&clock_reads==5);
    }
    DisposeHandle(strings);fputs("PASS2 actual hover/held/release/repress streams; real LMCHANGESPRITEID clock/geometry retained\n",stderr);return 0;
}
