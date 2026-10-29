/* Actual GAMEOVER frame gate + real HANDLEFIELDEVENTS/HANDLEFIELDKEYS; no OS input. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *exit_globals;
static unsigned exit_case,recording,records;
/* Clock-only HUD observer:17 reads verified with original LMNEWSPRITE separately. */
static int hud_clock_model;
static unsigned char button_node[312],fade_node[312];
static unsigned clock_reads,key_polls,queued,setup_reads;
static unsigned char saved_fields[0x454];
static Handle strings;
static const unsigned char input[]={'A','B',28,'C',13};
static void event_value(char code,unsigned value){
    if(!recording)return;assert(records++<1000);
    printf("%u,%c,%u,%d,%d,%d,%u,",exit_case,code,value,*(int16_t *)(exit_globals+0xa68),*(int16_t *)(button_node+38),*(int16_t *)(exit_globals+0x7da),*(uint32_t *)(exit_globals+0xa4a));
    for(unsigned i=0;i<exit_globals[0x6da];i++)printf("%02x",exit_globals[0x6db+i]);printf(",%d\n",*(int16_t *)(exit_globals+0x5d6));
}
static void event(char code){event_value(code,0);}
static uint32_t clock_tick(void){if(!recording){setup_reads++;return 1000;}uint32_t value=1000+clock_reads++;event_value('T',value);return value;}
static int zero(void){return 0;}
static Handle input_resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static Boolean input_event(EventMask mask,EventRecord *record){
    assert(mask==0x28&&queued<sizeof(input));memset(record,0,sizeof(*record));record->what=keyDown;record->message=input[queued++];event_value('E',record->message);return true;
}
void exit_flush(void){assert(setup_reads==1+(exit_case>=3));assert(*(void **)(exit_globals+0xa06)==(exit_case>=3?exit_globals+0x5b2:NULL));if(exit_case>=3)assert(*(double *)(exit_globals+0x7ec)==0);if(exit_case<3)assert(!memcmp(exit_globals+0x5b2,saved_fields,sizeof(saved_fields)));recording=1;clock_reads=key_polls=queued=0;*(uint32_t *)(exit_globals+0xa4a)=1000;}
void exit_keys(void){unsigned any=exit_case>=3||++key_polls>=2;*(int16_t *)(exit_globals+0xab6)=any;event_value('K',any);}
void exit_animate(void){event('A');}void exit_music(void){event('S');}
void exit_world(void){event('R');}void exit_panel(void){event('O');}void exit_hud(void){event('H');if(recording&&hud_clock_model)for(unsigned i=0;i<17;i++)clock_tick();}void exit_swap(void){event('W');}
void exit_score(void){event('I');}
void *exit_lookup(unsigned char *name){assert(name);if(name[0]==10&&!memcmp(name+1,"GameOverOK",10))return button_node;assert(name[0]==12&&!memcmp(name+1,"GameOverFade",12));return fade_node;}
void exit_change(unsigned char *node,unsigned id){assert(node==button_node&&id==901);*(int16_t *)(node+38)=id;event('P');}
void exit_kill(void *node){assert(node==button_node||node==fade_node);event(node==button_node?'B':'F');}
BRIDGE(exit_keys) BRIDGE(exit_flush) BRIDGE(exit_animate) BRIDGE(exit_music) BRIDGE(exit_world) BRIDGE(exit_panel) BRIDGE(exit_hud) BRIDGE(exit_swap) BRIDGE(exit_score) BRIDGE(exit_lookup) BRIDGE(exit_change) BRIDGE(exit_kill)
int main(int argc,char **argv){
    hud_clock_model=getenv("ASTRO_HUD_CLOCK_MODEL")!=NULL;
    if(argc!=4)return 2;alarm(15);struct stat input_stat;assert(!stat(argv[1],&input_stat)&&input_stat.st_size==455780&&!stat(argv[2],&input_stat)&&input_stat.st_size==11812);unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);exit_globals=g;
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=clock_tick;
        if(!strcmp(import_names[i],"GetResource"))fn=input_resource;if(!strcmp(import_names[i],"GetNextEvent"))fn=input_event;
        if(!strcmp(import_names[i],"ShowCursor"))fn=noop;if(!strcmp(import_names[i],"Button"))fn=zero;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    unsigned char *raw=read_file(argv[3]);assert(!stat(argv[3],&input_stat)&&input_stat.st_size==6884);strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    const struct{unsigned at;void *fn;}hooks[]={
        {0x539b8,noop},{0x54c64,noop},{0x3b55c,noop},{0x57afc,exit_world_fb},{0x43134,exit_hud_fb},{0x35eb8,exit_swap_fb},
        {0x3760,noop},{0x353e4,noop},{0x24450,zero},{0xce40,zero},{0x3b260,exit_lookup_fb},{0x4cd48,noop},{0x2b290,exit_flush_fb},
        {0x4cb28,exit_keys_fb},{0x41448,noop},{0x44e10,exit_panel_fb},{0x45f20,exit_animate_fb},{0x334bc,exit_music_fb},
        {0x343b4,exit_change_fb},{0x3ed88,exit_score_fb},{0x34dd8,exit_kill_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    for(exit_case=0;exit_case<6;exit_case++){
        memset(g,0,0x1300);memset(button_node,0,sizeof(button_node));memset(fade_node,0,sizeof(fade_node));
        int values[12]={0};*(void **)(g+0xa72)=values;*(int *)(g+0xa7e)=exit_case>=3?100:0;*(int16_t *)(g+0xa52)=exit_case%3+1;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
        if(exit_case<3)for(unsigned i=0;i<sizeof(saved_fields);i++)g[0x5b2+i]=(i*17+exit_case+31)&255;
        if(exit_case<3){g[0x6da]=0;*(short *)(g+0x5d6)=0;*(short *)(g+0x7da)=0;}
        *(void **)(g+0xa06)=exit_case%3?g+0x5b2+(exit_case%3-1)*0x22a:NULL;
        memcpy(saved_fields,g+0x5b2,sizeof(saved_fields));setup_reads=0;
        *(int16_t *)(button_node+38)=900;recording=records=0;invoke_fb(code+0x4cef0,g,toc,NULL,NULL,NULL);event('Z');assert(clock_reads>1&&queued==(exit_case>=3?sizeof(input):0));
    }
    DisposeHandle(strings);fputs("PASS6 actual GAMEOVER frame/input schedules; real GetNextEvent and field editing at intervals1/2/3; incoming focus replaced by qualification, second width zero iff initialized; nonqualifying fields unchanged and no field initialization clock\n",stderr);return 0;
}
