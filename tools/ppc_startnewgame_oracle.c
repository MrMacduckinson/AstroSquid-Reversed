/* Actual STARTNEWGAME order; load/player/loop/render/OS bodies are observers. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g;static unsigned phase,profile;static int32_t previous_score;
static void record(char kind){printf("%u,%c,%d,%d,%d,%d\n",profile,kind,*(int32_t *)(g+0xa7e),*(int32_t *)(g+0xa86),*(short *)(g+0x58c),*(short *)(g+0x58e));}
void start_load(int level){assert(phase++==0&&level==*(short *)(g+0xa82)&&*(int32_t *)(g+0xa7e)==previous_score);record('L');*(int32_t *)(g+0xa7e)=12345;}
void start_swap(void){assert(phase++==1&&!*(int32_t *)(g+0xa7e)&&*(int32_t *)(g+0xa86)==7);record('S');}
static void start_hide(void){assert(phase++==2&&*(int32_t *)(g+0xa86)==1&&!*(short *)(g+0x58c));record('H');}
void start_player(int mode){assert(phase++==3&&mode==1);record('N');}
void start_loop(void){assert(phase++==4);record('G');}
BRIDGE(start_load) BRIDGE(start_swap) BRIDGE(start_player) BRIDGE(start_loop)
int main(int argc,char **argv){
 assert(argc==3);alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]);g=calloc(1,0x1400);assert(g);uint32_t toc[489]={0};
 for(unsigned i=0;i<484;i++){void *fn=!strcmp(import_names[i],"HideCursor")?start_hide:missing_import;descriptors[i][0]=(uint32_t)(uintptr_t)fn;toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x510c8,start_load_fb);jump_to(code+0x35eb8,start_swap_fb);jump_to(code+0x50bfc,start_player_fb);jump_to(code+0x51a68,start_loop_fb);MakeDataExecutable(code,433284);
 for(profile=0;profile<3;profile++){
  memset(g,0,0x1400);*(void **)(g+0x21c)=lit;phase=0;previous_score=profile==0?0:profile==1?123456:-1;
  *(int32_t *)(g+0xa7e)=previous_score;*(short *)(g+0xa82)=profile==0?1:profile==1?4:9;*(int32_t *)(g+0xa86)=7;*(short *)(g+0x58c)=-1;*(short *)(g+0x58e)=9;
  invoke_fb(code+0x51ee0,g,toc,NULL,NULL,NULL);assert(phase==5&&*(short *)(g+0x58e)==9);
 }
 puts("PASS3 original STARTNEWGAME: load with old score, clear score, swap, reset lives/end, hide cursor, player1, loop; quit flag retained");return 0;
}
