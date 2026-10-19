/* Execute original ENDOFLEVEL trail-loop instructions0x1004f5b8..0x1004f6b4
 * in an isolated PEF image. Entered after normal setup with supplied globals;
 * no rendering/audio/game process starts. STOPTRACK marks the exit boundary. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include <setjmp.h>
static unsigned char*g;static unsigned calls;static jmp_buf end;static int scenario;
static uint64_t word(double v){uint64_t u;memcpy(&u,&v,8);return u;}
static uint32_t trail_tick(void){tick=100+calls++;printf("T,%u\n",tick);return tick;}
static void record(char type){printf("%c,%016llx,%u,%016llx,%016llx\n",type,(unsigned long long)word(*(double*)(g+0x592)),*(uint32_t*)(g+0xa4e),(unsigned long long)word(*(double*)(g+0xa58)),(unsigned long long)word(*(double*)(g+0xa1e)));}
uint32_t move_stars(void*a,void*b){(void)a;(void)b;record('M');return 0;}
void render_world(void){record('W');}
void swap_frame(void){record('P');}
void keymap(void){record('K');}
void service(void){record('V');}
void finished(void){record('E');longjmp(end,1);}
#define BRIDGE(name) \
extern void name##_fb(void); \
__asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" \
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n" \
"bl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
BRIDGE(move_stars) BRIDGE(render_world) BRIDGE(swap_frame) BRIDGE(keymap) BRIDGE(service) BRIDGE(finished)
int main(int argc,char**argv){
 if(argc!=3)return 2;unsigned char*pef=read_file(argv[1]),*code=pef+128,*lit=read_file(argv[2]);g=calloc(1,0x1300);unsigned char*heap=calloc(1,0x10000);uint32_t toc[489]={0};
 for(int i=0;i<484;i++){void*fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=(void*)trail_tick;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:(void*)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
 set_pointer(g,0x21c,lit);set_double(g,0x378,4503601774854144.0);*(uint32_t*)(g+0x380)=0x43300000;set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x42234,(void*)move_stars_fb);jump_to(code+0x57afc,(void*)render_world_fb);jump_to(code+0x35eb8,(void*)swap_frame_fb);jump_to(code+0x4cb28,(void*)keymap_fb);jump_to(code+0x334bc,(void*)service_fb);jump_to(code+0x31af4,(void*)finished_fb);MakeDataExecutable(code,433284);
 int intervals[]={-3,-1,0,1,2,3};
 for(scenario=0;scenario<24;scenario++){calls=0;int interval=intervals[scenario%6];double scale=scenario<6?.011:scenario<12?.006:scenario<18?.001:1.0; if(scenario>=18)for(int j=0;j<16;j++)scale-=.005;
  set_short(g,0xa52,interval);*(uint32_t*)(g+0xa4e)=100;set_double(g,0x592,scale);set_double(g,0xa58,217.79533378093692);set_double(g,0xa1e,1234.25);
  printf("CASE,%d,%d,%016llx\n",scenario,interval,(unsigned long long)word(scale));
  if(!setjmp(end))invoke_fb(code+0x4f5b8,g,toc,NULL,NULL,NULL);
  printf("FINAL,%u\n",calls);
 }
 return 0;
}
