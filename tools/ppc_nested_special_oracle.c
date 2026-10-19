/* Native CALC/CLEANUP iteration oracle. World callbacks log; original list loops
 * and CHECKSPRITECOLLISION execute unchanged in an isolated memory image. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
static FILE *trace;
static unsigned char *g,*nested_code;static uint32_t *nested_toc;static unsigned clocks;static int launched,passes;
extern uint32_t invoke5(void *,void *,void *,void *,void *,void *,void *,void *);
__asm__(
".text\n.align 2\n.globl _invoke5\n_invoke5:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\n"
"stmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r3,r6\nmr r4,r7\nmr r5,r8\nmr r6,r9\nmr r7,r10\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\n"
"lmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");

static unsigned char nodes[4][128],renders_order[4][312];
static char events[16384];static size_t used;
static void event(char type,int a,int b){used+=(size_t)snprintf(events+used,sizeof(events)-used,"%c%d,%d;",type,a,b);}
void order_resolve(void *a,int kind,void *b,int target_kind){(void)kind;(void)target_kind;event('R',*(int16_t *)((char *)a+96),*(int16_t *)((char *)b+96));}
static void prepend(void){unsigned char *head=*(unsigned char **)(g+0xa76);set_pointer(nodes[3],102,head);set_pointer(nodes[3],98,NULL);if(head)set_pointer(head,98,nodes[3]);set_pointer(g,0xa76,nodes[3]);}
static uint32_t nested_tick(void){tick=100+clocks++/1000;return tick;}
static void nothing(void){}
void order_ai(void *a){int id=*(int16_t *)((char *)a+96);event('S',id,(int)tick);if(trace)fprintf(trace,"A,%d,%u\n",id,tick);}
static unsigned char beam_dummy[128];
void *nested_beam(int weapon,int damage,int x,int y,int ex,int ey,void *source){(void)weapon;if(trace&&damage==200)fprintf(trace,"E,0,%u\n",tick);(void)x;(void)y;(void)ex;(void)ey;(void)source;return beam_dummy;}
void nested_flash(int id,double *x,double *y,double *w,double *h){(void)id;(void)x;(void)y;(void)w;(void)h;}

void order_bullet(void *a){event('B',*(int16_t *)((char *)a+96),0);}
void order_player(void *a){event('P',*(int16_t *)((char *)a+96),(int)tick);passes++;if(trace)fprintf(trace,"A,%d,%u\n",*(int16_t *)((char *)a+96),tick);
    if(!launched){launched=1;if(trace)fprintf(trace,"S,0,%u\n",tick);invoke5(nested_code+0x5bd0c,g,nested_toc,(void *)40,(void *)174,(void *)112,NULL,a);event('X',0,(int)tick);if(trace)fprintf(trace,"R,0,%u\n",tick);}
}
void order_effect(void *a){event('E',*(int16_t *)((char *)a+96),0);prepend();}
void order_delete(void *a){unsigned char *e=a,*next=*(unsigned char **)(e+102),*prev=*(unsigned char **)(e+98);if(a==beam_dummy)return;event('D',*(int16_t *)(e+96),0);if(next)set_pointer(next,98,prev);if(prev)set_pointer(prev,102,next);if(*(void **)(g+0xa76)==e)set_pointer(g,0xa76,next);}
#define BRIDGE(name) \
extern void name##_fb(void); \
__asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" \
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n" \
"bl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
BRIDGE(nested_beam) BRIDGE(nested_flash) BRIDGE(order_resolve) BRIDGE(order_ai) BRIDGE(order_bullet) BRIDGE(order_player) BRIDGE(order_effect) BRIDGE(order_delete)
static void reset(void){
    used=0;events[0]=0;memset(nodes,0,sizeof(nodes));memset(renders_order,0,sizeof(renders_order));
    for(int i=0;i<4;i++) {
        set_short(nodes[i],0,i==1?1:5);set_short(nodes[i],96,i+1);
        set_pointer(nodes[i],62,renders_order[i]);set_double(nodes[i],72,i<3?i+1:0);
        set_short(nodes[i],36,100);set_short(nodes[i],38,100);set_short(nodes[i],40,120);set_short(nodes[i],42,120);
        set_double(renders_order[i],0,100);set_double(renders_order[i],8,100);
        set_double(renders_order[i],16,20);set_double(renders_order[i],24,20);
        if(i<3){set_pointer(nodes[i],98,i?nodes[i-1]:NULL);set_pointer(nodes[i],102,i<2?nodes[i+1]:NULL);}
    }
    set_pointer(g,0xa76,nodes[0]);set_pointer(g,0xa7a,nodes[1]);
}
int main(int argc,char **argv){
    if(argc!=3)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    g=calloc(1,0x1300);unsigned char *heap=calloc(1,0x10000),*attrs=calloc(441,30);
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"TickCount"))fn=(void *)nested_tick;
        if(!strncmp(import_names[i],"gl",2))fn=(void *)nothing;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:(void *)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    set_pointer(g,0x21c,literals);set_double(g,0x378,4503601774854144.0);*(uint32_t *)(g+0x380)=0x43300000;
    set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);set_pointer(g,0xa94,attrs);toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x547b4,(void *)order_resolve_fb);jump_to(code+0x61c40,(void *)order_ai_fb);
    jump_to(code+0x61a48,(void *)order_bullet_fb);jump_to(code+0x5ed70,(void *)order_player_fb);
    jump_to(code+0x52a94,(void *)order_effect_fb);jump_to(code+0x528b4,(void *)order_delete_fb);
    *(uint32_t *)(code+0x42234)=0x4e800020;MakeDataExecutable(code,433284);
    jump_to(code+0x54594,(void *)nested_beam_fb);jump_to(code+0x55878,(void *)nested_flash_fb);
    int noops[]={0x3ce84,0x35eb8,0x3b55c,0x43134,0x4cb28,0x57afc};
    for(unsigned i=0;i<sizeof(noops)/sizeof(noops[0]);i++)*(uint32_t *)(code+noops[i])=0x4e800020;
    MakeDataExecutable(code,433284);nested_code=code;nested_toc=toc;
    trace=getenv("ASTRO_NESTED_FIXTURE")?fopen(getenv("ASTRO_NESTED_FIXTURE"),"w"):NULL;
    reset();tick=100;set_short(g,0xa52,1);*(uint32_t *)(g+0xa4a)=100;*(uint32_t *)(g+0xa4e)=100;
    invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);
    printf("NESTED %s\n",events);
    printf("positions %.0f %.0f %.0f playercalls%d tick%u playerkind%d\n",*(double *)renders_order[0],*(double *)renders_order[1],*(double *)renders_order[2],passes,tick,*(int16_t *)nodes[1]);
    if(passes!=32||tick!=131||*(int16_t *)nodes[1]!=1||*(double *)renders_order[0]!=132||*(double *)renders_order[1]!=164||*(double *)renders_order[2]!=196)return 1;
    if(!strstr(events,"P2,100;")||!strstr(events,"P2,101;")||!strstr(events,"S3,131;R0,3;X0,131;S3,131;"))return 1;
    if(trace){fprintf(trace,"F,%.0f,%.0f,%.0f,%u,%d,%u\n",*(double *)renders_order[0],*(double *)renders_order[1],*(double *)renders_order[2],tick,*(int16_t *)nodes[1],*(uint32_t *)(g+0x244));fclose(trace);}
    puts("PASS native nested-special delay,31fullpasses,postworldeffect,outertailresume");return 0;
}
