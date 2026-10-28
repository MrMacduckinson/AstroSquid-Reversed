/* Execute original WAITFORKEY; observe event/key/clock/render boundaries. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned scenario,reads,polls,frames,interval,input_case;
static int dispatch_mode;static unsigned char *gref,*clicked;static Handle strings;
static const unsigned offsets[]={0xcc2,0xcc4,0xcc6,0xcc8,0xccc,0xcca};
static const char *names[]={"SetKeyFire","SetKeySpecial","SetKeyUp","SetKeyDown","SetKeyLeft","SetKeyRight"};
static uint64_t bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static void controls(void){for(unsigned i=0;i<6;i++)printf(",%d",*(short *)(gref+offsets[i])^7);}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static void mouse(Point *p){p->h=p->v=-30000;}
static int zero(void){return 0;}static uint32_t base;
static uint32_t clock_tick(void){assert(reads<2000);uint32_t t=base+reads++;printf("T,%u,%u",scenario,t);if(dispatch_mode)printf(",%d,%d",*(short *)(clicked+38),*(short *)(gref+0x5aa));putchar('\n');return t;}
static int event(short mask,void *record){assert(mask==0);memset(record,0,16);printf("E,%u,%u\n",scenario,polls);return 0;}
static void get_keys(void *out){
    unsigned char *p=out;memset(p,0,16);unsigned n=polls++;
    if(input_case<128)p[input_case>>3]|=1u<<(input_case&7);
    else if(input_case==128){p[0]=0x81;}
    else if(input_case==129){p[0]=1;p[15]=0x80;}
    else if(input_case==130&&n>=4){p[7]=4;}
    printf("K,%u,%u,",scenario,n);for(unsigned i=0;i<16;i++)printf("%02x",p[i]);putchar('\n');
}
void move(double *x,double *y){assert(*x==0&&*y==0);printf("M,%u,%u\n",scenario,frames);}
void stars_draw(void){printf("S,%u,%u\n",scenario,frames);}
void sprites_draw(void){printf("D,%u,%u\n",scenario,frames);}
void menu_draw(void){printf("O,%u,%u",scenario,frames);if(dispatch_mode){printf(",%d,%d",*(short *)(clicked+38),*(short *)(gref+0x5aa));controls();}putchar('\n');}
void animate(void){printf("A,%u,%u\n",scenario,frames);}
void swap_frame(void){printf("W,%u,%u\n",scenario,frames++);}
void music(void){printf("U,%u,%u\n",scenario,frames);}
void sound(unsigned char *name,double *p){assert(name[0]==5&&!memcmp(name+1,"Click",5));printf("P,%u,%016llx,%d\n",scenario,bits(*p),*(short *)(gref+0x5aa));}
BRIDGE(sound) BRIDGE(move) BRIDGE(stars_draw) BRIDGE(sprites_draw) BRIDGE(menu_draw) BRIDGE(animate) BRIDGE(swap_frame) BRIDGE(music)
int main(int argc,char **argv){
    if(argc!=3&&argc!=7)return 2;dispatch_mode=argc==7;assert(!dispatch_mode||!strcmp(argv[6],"dispatch"));alarm(30);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*heap=calloc(1,0x100000),*g=calloc(1,0x1400);assert(heap&&g);gref=g;unsigned char *table=NULL,*scene=NULL;
    if(dispatch_mode){assert(!stat(argv[3],&st)&&st.st_size==6884&&!stat(argv[4],&st)&&st.st_size==14014&&!stat(argv[5],&st)&&st.st_size==16016);unsigned char *raw=read_file(argv[3]);strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);table=read_file(argv[4]);scene=read_file(argv[5]);}
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=clock_tick;if(!strcmp(import_names[i],"GetKeys"))fn=get_keys;if(!strcmp(import_names[i],"EventAvail"))fn=event;if(dispatch_mode&&!strcmp(import_names[i],"GetResource"))fn=resource;if(dispatch_mode&&!strcmp(import_names[i],"GetMouse"))fn=mouse;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    const struct{unsigned at;void *fn;}hooks[]={{0x42234,move_fb},{0x45af0,stars_draw_fb},{0x3aaf8,sprites_draw_fb},{0x46394,menu_draw_fb},{0x45f20,animate_fb},{0x35eb8,swap_frame_fb},{0x334bc,music_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(*hooks);i++)jump_to(code+hooks[i].at,hooks[i].fn);if(dispatch_mode){jump_to(code+0x24248,zero);jump_to(code+0x3ce84,sound_fb);}MakeDataExecutable(code,433284);
    for(scenario=0;scenario<(dispatch_mode?18u:134u);scenario++){
        memset(g,0,0x1400);reads=polls=frames=0;interval=scenario<131?1:scenario-130;base=scenario==133?UINT32_MAX-300:1000;
        input_case=scenario;unsigned char *nodes[52]={0};
        if(dispatch_mode){input_case=scenario%3==0?128:scenario%3==1?130:131;interval=(scenario/3)%3+1;base=scenario/3==5?UINT32_MAX-300:1000;for(unsigned i=0;i<52;i++){nodes[i]=calloc(1,308);assert(nodes[i]);memcpy(nodes[i],scene+i*308,308);if(i)*(void **)(nodes[i-1]+300)=nodes[i];*(void **)(nodes[i]+304)=i?nodes[i-1]:NULL;*(void **)(nodes[i]+300)=NULL;if(nodes[i][40]==strlen(names[scenario/3])&&!memcmp(nodes[i]+41,names[scenario/3],nodes[i][40]))clicked=nodes[i];}assert(clicked);*(void **)(g+0xe86)=nodes[0];*(void **)(g+0xe82)=table;const short raw[]={55,58,126,125,123,124};for(unsigned i=0;i<6;i++)*(short *)(g+offsets[i])=raw[i]^7;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;}
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xa52)=interval;*(uint32_t *)(g+0xa4a)=base;
        if(dispatch_mode){printf("C,%u,%u,%u\n",scenario,interval,base);unsigned char name[256]={0};name[0]=strlen(names[scenario/3]);memcpy(name+1,names[scenario/3],name[0]);invoke_fb(code+0x3f178,g,toc,name,NULL,NULL);printf("Z,%u,%u,%u,%u,%u,%d,%d",scenario,reads,polls,frames,*(uint32_t *)(g+0xa4a),*(short *)(clicked+38),*(short *)(g+0x5aa));controls();putchar('\n');assert(*(short *)(clicked+38)==900&&*(short *)(g+0x5aa)==1);const short defaults[]={55,58,126,125,123,124};for(unsigned i=0;i<6;i++){int expected=i==scenario/3&&scenario%3<2?(scenario%3?58:0):defaults[i];assert((*(short *)(g+offsets[i])^7)==expected);}for(unsigned i=0;i<52;i++)free(nodes[i]);continue;}
        printf("P,%u,%u,%u\n",scenario,interval,base);int bit=(int)invoke_fb(code+0x3eb34,g,toc,NULL,NULL,NULL);
        printf("Z,%u,%d,%d,%u,%u,%u,%u\n",scenario,bit,bit<0?-1:bit^7,reads,polls,frames,*(uint32_t *)(g+0xa4a));
        if(scenario<128)assert(bit==(int)(scenario^7));if(scenario==128)assert(bit==7);if(scenario==129)assert(bit==120);if(scenario==130)assert(bit==(58^7));if(scenario>130)assert(bit==-1);
    }
    fputs(dispatch_mode?"PASS18 original DOMOUSE key capture transactions\n":"PASS134 original WAITFORKEY single/all-bit, simultaneous, delayed, timeout and wrap schedules\n",stderr);return 0;
}
