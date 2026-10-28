/* Actual GAMEOVER control flow; world/input/IO/render boundaries are observers. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *exit_globals;
static unsigned exit_case,recording,records;
static unsigned char button_node[312],fade_node[312];
static void event(char code){if(!recording)return;records++;printf("%u,%c,%d,%d,%d,%d\n",exit_case,code,*(int16_t *)(exit_globals+0xa68),*(void **)(exit_globals+0xa06)!=NULL,*(int16_t *)(button_node+38),*(int16_t *)(exit_globals+0x58c));}
static uint32_t clock_tick(void){return 1000;}
static int zero(void){return 0;}
void exit_keys(void){*(int16_t *)(exit_globals+0xab6)=1;}
void exit_field(void){*(int16_t *)(exit_globals+0x5b2+0x228)=1;}
void exit_world(void){event('R');}void exit_panel(void){event('O');}void exit_hud(void){event('H');}void exit_swap(void){event('W');}
void exit_score(void){event('I');}
void *exit_lookup(unsigned char *name){assert(name);if(name[0]==10&&!memcmp(name+1,"GameOverOK",10))return button_node;assert(name[0]==12&&!memcmp(name+1,"GameOverFade",12));return fade_node;}
void exit_change(unsigned char *node,unsigned id){assert(node==button_node&&id==901);*(int16_t *)(node+38)=id;recording=1;event('C');}
void exit_kill(void *node){assert(node==button_node||node==fade_node);event(node==button_node?'B':'F');}
BRIDGE(exit_keys) BRIDGE(exit_field) BRIDGE(exit_world) BRIDGE(exit_panel) BRIDGE(exit_hud) BRIDGE(exit_swap) BRIDGE(exit_score) BRIDGE(exit_lookup) BRIDGE(exit_change) BRIDGE(exit_kill)
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(15);struct stat input;assert(!stat(argv[1],&input)&&input.st_size==455780&&!stat(argv[2],&input)&&input.st_size==11812);unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);exit_globals=g;
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=clock_tick;
        if(!strcmp(import_names[i],"ShowCursor"))fn=noop;if(!strcmp(import_names[i],"Button"))fn=zero;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;assert(!FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL)&&!FSGetResourceForkName(&fork)&&!FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf));UseResFile(rf);
    const struct{unsigned at;void *fn;}hooks[]={
        {0x539b8,noop},{0x54c64,noop},{0x3b55c,noop},{0x57afc,exit_world_fb},{0x43134,exit_hud_fb},{0x35eb8,exit_swap_fb},
        {0x3760,noop},{0x353e4,noop},{0x24450,zero},{0xce40,zero},{0x3b260,exit_lookup_fb},{0x4cd48,noop},{0x2b290,noop},
        {0x4cb28,exit_keys_fb},{0x3ecf4,exit_field_fb},{0x41448,noop},{0x44e10,exit_panel_fb},{0x45f20,noop},{0x334bc,noop},
        {0x343b4,exit_change_fb},{0x3ed88,exit_score_fb},{0x34dd8,exit_kill_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    for(exit_case=0;exit_case<2;exit_case++){
        memset(g,0,0x1300);memset(button_node,0,sizeof(button_node));memset(fade_node,0,sizeof(fade_node));
        int values[12]={0};*(void **)(g+0xa72)=values;*(int *)(g+0xa7e)=exit_case?100:0;*(int16_t *)(g+0xa52)=1;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
        *(int16_t *)(button_node+38)=900;recording=records=0;invoke_fb(code+0x4cef0,g,toc,NULL,NULL,NULL);event('Z');assert(records==(exit_case?12u:11u));
    }
    CloseResFile(rf);fputs("PASS actual GAMEOVER2 complete control-flow scenarios,23 terminal events; semantic IO/world/input observers\n",stderr);return 0;
}
