/* Original bounded menu gate slices; only semantic call observers replace draw/
   input/animation services. Original comparisons, stores, branches/order retained. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
static unsigned char *g;static uint32_t clocks[2];static unsigned nclock;static char trace[1024];static size_t used;
static uint32_t descriptors[484][2];
static void log_event(char ch){used+=snprintf(trace+used,sizeof(trace)-used,"%c@%u;",ch,*(uint32_t *)(g+0xa4a));if(used>=sizeof(trace))exit(2);}
static uint32_t clock_value(void){if(nclock>=2)exit(2);log_event(nclock?'T':'C');return clocks[nclock++];}
#define EVENT(name,ch) void name(void){log_event(ch);} extern void name##_fb(void); \
__asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" \
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
EVENT(stars,'S') EVENT(star_draw,'L') EVENT(handle,'H') EVENT(over,'O')
EVENT(sprite_draw,'D') EVENT(menu_draw,'M') EVENT(animate,'A') EVENT(swap,'W')
EVENT(music,'U') EVENT(keys,'K') EVENT(fields,'F') EVENT(render,'R')
EVENT(pause_draw,'P') EVENT(gameover_draw,'G') EVENT(hud,'V')
static void missing(void){exit(2);}
static unsigned char *read_file(const char *path){FILE *f=fopen(path,"rb");if(!f)exit(2);fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static void jump_to(unsigned char *at,void *destination){uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
static void bound_slice(unsigned char *code,unsigned start,unsigned end){uint32_t *entry=(uint32_t *)(code+start-12),*tail=(uint32_t *)(code+end);entry[0]=0x7c0802a6;entry[1]=0x90010010;entry[2]=0x90410014;tail[0]=0x80010010;tail[1]=0x7c0803a6;tail[2]=0x4e800020;}
int main(int argc,char **argv){
 if(argc!=4)return 2;FILE *fixture=fopen(argv[3],"w");if(!fixture)return 2;
 unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*heap=calloc(1,0x10000);g=calloc(1,0x1300);uint32_t toc[489]={0};
 for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))f=clock_value;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
 *(void **)(g+0x21c)=literals;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0x388)=heap;toc[0]=(uint32_t)(uintptr_t)g;
 struct {unsigned off;void *callback;} events[]={
 {0x42234,stars_fb},{0x45af0,star_draw_fb},{0x3b55c,handle_fb},{0x41448,over_fb},{0x3aaf8,sprite_draw_fb},{0x46394,menu_draw_fb},{0x45f20,animate_fb},{0x35eb8,swap_fb},{0x334bc,music_fb},{0x4cb28,keys_fb},{0x3ecf4,fields_fb},{0x57afc,render_fb},{0x44898,pause_draw_fb},{0x44e10,gameover_draw_fb},{0x43134,hud_fb}};
 for(unsigned i=0;i<sizeof(events)/sizeof(events[0]);i++)jump_to(code+events[i].off,events[i].callback);
 const unsigned start[]={0x66cf8,0x4dc48,0x4d348,0x3ebd4},end[]={0x66e90,0x4dcd4,0x4d3f8,0x3ec70};for(int i=0;i<4;i++)bound_slice(code,start[i],end[i]);MakeDataExecutable(code,433284);
 const struct {int16_t interval;uint32_t old,comparison,store;} cases[]={
 {2,100,101,109},{2,100,102,109},{3,100,102,110},{3,100,103,110},{0,100,100,101},{-1,100,99,100},{2,UINT32_MAX-1,0,5},{3,UINT32_MAX-1,0,5},{0,0,0x80000000,0x80000001},{-1,0,0x80000000,0x80000001}};
 unsigned char field[600]={0};
 for(int mode=0;mode<4;mode++)for(unsigned j=0;j<sizeof(cases)/sizeof(cases[0]);j++){
  memset(trace,0,sizeof(trace));used=0;nclock=0;clocks[0]=cases[j].comparison;clocks[1]=cases[j].store;*(uint32_t *)(g+0xa4a)=cases[j].old;*(int16_t *)(g+0xa52)=cases[j].interval;*(int16_t *)(g+0xa6a)=1;*(void **)(g+0xa06)=field;*(void **)(g+0x38c)=heap;
  invoke_fb(code+start[mode]-12,g,toc,NULL,NULL,NULL);
  int open=(int32_t)(cases[j].comparison-cases[j].old)>=cases[j].interval;
  if(nclock!=(open?2:1)||*(uint32_t *)(g+0xa4a)!=(open?cases[j].store:cases[j].old)){fprintf(stderr,"Gate mismatch mode%d case%u\n",mode,j);return 1;}
  fprintf(fixture,"%d,%u,%d,%u,%u,%u,%u,%u,%s\n",mode,j,cases[j].interval,cases[j].old,cases[j].comparison,cases[j].store,nclock,*(uint32_t *)(g+0xa4a),trace);
 }
 fclose(fixture);puts("PASS40 original menu signed interval gates, fresh comparison/store clocks and ordered semantic traces");return 0;
}
