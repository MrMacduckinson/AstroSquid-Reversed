/* Native CALC/CLEANUP iteration oracle. World callbacks log; original list loops
 * and CHECKSPRITECOLLISION execute unchanged in an isolated memory image. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
static unsigned char *g;
static unsigned char nodes[4][128],renders_order[4][312];
static char events[2048];static size_t used;
static void event(char type,int a,int b){used+=(size_t)snprintf(events+used,sizeof(events)-used,"%c%d,%d;",type,a,b);}
void order_resolve(void *a,int kind,void *b,int target_kind){(void)kind;(void)target_kind;event('R',*(int16_t *)((char *)a+96),*(int16_t *)((char *)b+96));}
static void prepend(void){unsigned char *head=*(unsigned char **)(g+0xa76);set_pointer(nodes[3],102,head);set_pointer(nodes[3],98,NULL);if(head)set_pointer(head,98,nodes[3]);set_pointer(g,0xa76,nodes[3]);}
void order_ai(void *a){event('S',*(int16_t *)((char *)a+96),0);prepend();}
void order_bullet(void *a){event('B',*(int16_t *)((char *)a+96),0);}
void order_player(void *a){event('P',*(int16_t *)((char *)a+96),0);}
void order_effect(void *a){event('E',*(int16_t *)((char *)a+96),0);prepend();}
void order_delete(void *a){unsigned char *e=a,*next=*(unsigned char **)(e+102),*prev=*(unsigned char **)(e+98);event('D',*(int16_t *)(e+96),0);if(next)set_pointer(next,98,prev);if(prev)set_pointer(prev,102,next);if(*(void **)(g+0xa76)==e)set_pointer(g,0xa76,next);}
#define BRIDGE(name) \
extern void name##_fb(void); \
__asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" \
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n" \
"bl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
BRIDGE(order_resolve) BRIDGE(order_ai) BRIDGE(order_bullet) BRIDGE(order_player) BRIDGE(order_effect) BRIDGE(order_delete)
static void reset(void){
    used=0;events[0]=0;memset(nodes,0,sizeof(nodes));memset(renders_order,0,sizeof(renders_order));
    for(int i=0;i<4;i++) {
        set_short(nodes[i],0,i==0?5:i==2?1:2);set_short(nodes[i],96,i+1);
        set_pointer(nodes[i],62,renders_order[i]);set_double(nodes[i],72,i<3?i+1:0);
        set_short(nodes[i],36,100);set_short(nodes[i],38,100);set_short(nodes[i],40,120);set_short(nodes[i],42,120);
        set_double(renders_order[i],0,100);set_double(renders_order[i],8,100);
        set_double(renders_order[i],16,20);set_double(renders_order[i],24,20);
        if(i<3){set_pointer(nodes[i],98,i?nodes[i-1]:NULL);set_pointer(nodes[i],102,i<2?nodes[i+1]:NULL);}
    }
    set_pointer(g,0xa76,nodes[0]);set_pointer(g,0xa7a,nodes[2]);
}
int main(int argc,char **argv){
    if(argc!=3)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    g=calloc(1,0x1300);unsigned char *heap=calloc(1,0x10000),*attrs=calloc(441,30);
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:(void *)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    set_pointer(g,0x21c,literals);set_double(g,0x378,4503601774854144.0);*(uint32_t *)(g+0x380)=0x43300000;
    set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);set_pointer(g,0xa94,attrs);toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x547b4,(void *)order_resolve_fb);jump_to(code+0x61c40,(void *)order_ai_fb);
    jump_to(code+0x61a48,(void *)order_bullet_fb);jump_to(code+0x5ed70,(void *)order_player_fb);
    jump_to(code+0x52a94,(void *)order_effect_fb);jump_to(code+0x528b4,(void *)order_delete_fb);
    *(uint32_t *)(code+0x42234)=0x4e800020;MakeDataExecutable(code,433284);
    reset();invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);
    const char *expected="R1,2;R1,3;S1,0;R2,1;R2,3;B2,0;R3,4;R3,1;R3,2;P3,0;";
    printf("CALC %s\n",events);if(strcmp(events,expected))return 1;
    if(*(void **)(g+0xa76)!=nodes[3]||*(double *)renders_order[3]!=100||*(double *)renders_order[0]!=101||*(double *)renders_order[1]!=102||*(double *)renders_order[2]!=103)return 1;
    reset();set_short(nodes[0],70,-1);set_short(nodes[2],70,1);
    invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);
    printf("CLEANUP %s\n",events);if(strcmp(events,"E1,0;D1,0;D3,0;"))return 1;
    if(*(void **)(g+0xa76)!=nodes[3]||*(void **)(nodes[3]+102)!=nodes[1]||*(void **)(nodes[1]+102)!=NULL)return 1;
    puts("PASS native head insertion, cached-next update order, live-head collision sweep, delayed cleanup");return 0;
}
