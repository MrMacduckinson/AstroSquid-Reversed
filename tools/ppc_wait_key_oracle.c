/* Execute original WAITFORKEY; observe event/key/clock/render boundaries. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned scenario,reads,polls,frames,interval;static uint32_t base;
static uint32_t clock_tick(void){assert(reads<2000);uint32_t t=base+reads++;printf("T,%u,%u\n",scenario,t);return t;}
static int event(short mask,void *record){assert(mask==0);memset(record,0,16);printf("E,%u,%u\n",scenario,polls);return 0;}
static void get_keys(void *out){
    unsigned char *p=out;memset(p,0,16);unsigned n=polls++;
    if(scenario<128)p[scenario>>3]|=1u<<(scenario&7);
    else if(scenario==128){p[0]=0x81;}
    else if(scenario==129){p[0]=1;p[15]=0x80;}
    else if(scenario==130&&n>=4){p[7]=4;}
    printf("K,%u,%u,",scenario,n);for(unsigned i=0;i<16;i++)printf("%02x",p[i]);putchar('\n');
}
void move(double *x,double *y){assert(*x==0&&*y==0);printf("M,%u,%u\n",scenario,frames);}
void stars_draw(void){printf("S,%u,%u\n",scenario,frames);}
void sprites_draw(void){printf("D,%u,%u\n",scenario,frames);}
void menu_draw(void){printf("O,%u,%u\n",scenario,frames);}
void animate(void){printf("A,%u,%u\n",scenario,frames);}
void swap_frame(void){printf("W,%u,%u\n",scenario,frames++);}
void music(void){printf("U,%u,%u\n",scenario,frames);}
BRIDGE(move) BRIDGE(stars_draw) BRIDGE(sprites_draw) BRIDGE(menu_draw) BRIDGE(animate) BRIDGE(swap_frame) BRIDGE(music)
int main(int argc,char **argv){
    if(argc!=3)return 2;alarm(30);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*heap=calloc(1,0x100000),*g=calloc(1,0x1400);assert(heap&&g);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=clock_tick;if(!strcmp(import_names[i],"GetKeys"))fn=get_keys;if(!strcmp(import_names[i],"EventAvail"))fn=event;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    const struct{unsigned at;void *fn;}hooks[]={{0x42234,move_fb},{0x45af0,stars_draw_fb},{0x3aaf8,sprites_draw_fb},{0x46394,menu_draw_fb},{0x45f20,animate_fb},{0x35eb8,swap_frame_fb},{0x334bc,music_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(*hooks);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    for(scenario=0;scenario<134;scenario++){
        memset(g,0,0x1400);reads=polls=frames=0;interval=scenario<131?1:scenario-130;base=scenario==133?UINT32_MAX-300:1000;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xa52)=interval;*(uint32_t *)(g+0xa4a)=base;
        printf("P,%u,%u,%u\n",scenario,interval,base);int bit=(int)invoke_fb(code+0x3eb34,g,toc,NULL,NULL,NULL);
        printf("Z,%u,%d,%d,%u,%u,%u,%u\n",scenario,bit,bit<0?-1:bit^7,reads,polls,frames,*(uint32_t *)(g+0xa4a));
        if(scenario<128)assert(bit==(int)(scenario^7));if(scenario==128)assert(bit==7);if(scenario==129)assert(bit==120);if(scenario==130)assert(bit==(58^7));if(scenario>130)assert(bit==-1);
    }
    fputs("PASS134 original WAITFORKEY single/all-bit, simultaneous, delayed, timeout and wrap schedules\n",stderr);return 0;
}
