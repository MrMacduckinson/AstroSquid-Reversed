/* Isolate original GAMEOVER warmup ordering; world/render callbacks observed. */
#define main unused_hud_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <setjmp.h>
#include <unistd.h>
static jmp_buf done;
static unsigned delays;
static uint32_t warm_tick(void){puts("T");return 100;}
static void warm_delay(unsigned ticks,unsigned *final){static const unsigned expected[]={0,1,1,2,3,3,4,4,5,6};assert(delays<10&&ticks==expected[delays++]);*final=100;printf("D%u\n",ticks);}
static void warm_cursor(void){puts("cursor");longjmp(done,1);}
void warm_cleanup(void){puts("cleanup");} void warm_calc(void){puts("calc");}
void warm_visual(void){puts("visual");} void warm_render(void){puts("render");}
void warm_hud(void){puts("hud");} void warm_swap(void){puts("swap");}
BRIDGE(warm_cleanup) BRIDGE(warm_calc) BRIDGE(warm_visual) BRIDGE(warm_render) BRIDGE(warm_hud) BRIDGE(warm_swap)
int main(int argc,char **argv){
 assert(argc==3);alarm(15);unsigned char *code=read_file(argv[1])+128,*g=calloc(1,0x1300);
 uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
  void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
  if(!strcmp(import_names[i],"TickCount"))fn=warm_tick;
  if(!strcmp(import_names[i],"Delay"))fn=warm_delay;
  if(!strcmp(import_names[i],"ShowCursor"))fn=warm_cursor;
  descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
 }toc[0]=(uint32_t)(uintptr_t)g;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0x21c)=read_file(argv[2]);*(int16_t *)(g+0xa6a)=2;
 const struct{unsigned at;void *fn;} hooks[]={{0x539b8,warm_cleanup_fb},{0x54c64,warm_calc_fb},{0x3b55c,warm_visual_fb},{0x57afc,warm_render_fb},{0x43134,warm_hud_fb},{0x35eb8,warm_swap_fb}};
 for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].at,hooks[i].fn);
 MakeDataExecutable(code,433284);if(!setjmp(done))invoke_fb(code+0x4cef0,g,toc,NULL,NULL,NULL);
 assert(delays==10&&*(int16_t *)(g+0xa6a)==0);return 0;
}
