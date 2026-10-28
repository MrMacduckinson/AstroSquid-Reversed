/* Actual GAMEOVER frame gate + real HANDLEFIELDEVENTS/HANDLEFIELDKEYS; no OS input. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *exit_globals;
static unsigned exit_case,recording,records;
static unsigned char button_node[312],fade_node[312];
static unsigned clock_reads,queued;
static Handle strings;
static const unsigned char input[]={'A','B',13};
static void event_value(char code,unsigned value){
    if(!recording)return;assert(records++<1000);
    printf("%u,%c,%u,%d,%d,%d,%u,",exit_case,code,value,*(int16_t *)(exit_globals+0xa68),*(int16_t *)(button_node+38),*(int16_t *)(exit_globals+0x7da),*(uint32_t *)(exit_globals+0xa4a));
    for(unsigned i=0;i<exit_globals[0x6da];i++)printf("%02x",exit_globals[0x6db+i]);printf(",%d\n",*(int16_t *)(exit_globals+0x5d6));
}
static void event(char code){event_value(code,0);}
static uint32_t clock_tick(void){if(!recording)return 1000;uint32_t value=1000+clock_reads++;event_value('T',value);return value;}
static int zero(void){return 0;}
static int held_button(void){return recording?1:0;}
static unsigned char *held_entry;static uint32_t *held_toc;
static void held_position(Point *p){p->h=225;p->v=260;}
void held_dispatch(void){
    unsigned char empty[256]={0};
    invoke_fb(held_entry,exit_globals,held_toc,empty,NULL,NULL);event('D');
}
BRIDGE(held_dispatch)
static Handle input_resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static Boolean input_event(EventMask mask,EventRecord *record){
    assert(mask==0x28&&queued<sizeof(input));memset(record,0,sizeof(*record));record->what=keyDown;record->message=input[queued++];event_value('E',record->message);return true;
}
void exit_flush(void){fprintf(stderr,"field %.17g/%.17g/%.17g/%.17g integerY%d\n",*(double *)(exit_globals+0x5b2),*(double *)(exit_globals+0x5ba),*(double *)(exit_globals+0x5c2),*(double *)(exit_globals+0x5ca),(int)*(double *)(exit_globals+0x5ba));recording=1;clock_reads=queued=0;*(int16_t *)(exit_globals+0x5aa)=1;*(uint32_t *)(exit_globals+0xa4a)=1000;}
void exit_keys(void){unsigned any=1;*(int16_t *)(exit_globals+0xab6)=any;event_value('K',any);}
void exit_animate(void){event('A');}void exit_music(void){event('S');}
void exit_world(void){event('R');}void exit_panel(void){event('O');}void exit_hud(void){event('H');}void exit_swap(void){event('W');}
void exit_score(void){event('I');}
void *exit_lookup(unsigned char *name){assert(name);if(name[0]==10&&!memcmp(name+1,"GameOverOK",10))return button_node;assert(name[0]==12&&!memcmp(name+1,"GameOverFade",12));return fade_node;}
void exit_change(unsigned char *node,unsigned id){assert(node==button_node&&id==901);*(int16_t *)(node+38)=id;event('P');}
void exit_kill(void *node){assert(node==button_node||node==fade_node);event(node==button_node?'B':'F');}
BRIDGE(exit_keys) BRIDGE(exit_flush) BRIDGE(exit_animate) BRIDGE(exit_music) BRIDGE(exit_world) BRIDGE(exit_panel) BRIDGE(exit_hud) BRIDGE(exit_swap) BRIDGE(exit_score) BRIDGE(exit_lookup) BRIDGE(exit_change) BRIDGE(exit_kill)
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(15);struct stat input_stat;assert(!stat(argv[1],&input_stat)&&input_stat.st_size==455780&&!stat(argv[2],&input_stat)&&input_stat.st_size==11812);unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);exit_globals=g;
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=clock_tick;
        if(!strcmp(import_names[i],"GetMouse"))fn=held_position;
        if(!strcmp(import_names[i],"GetResource"))fn=input_resource;if(!strcmp(import_names[i],"GetNextEvent"))fn=input_event;
        if(!strcmp(import_names[i],"ShowCursor"))fn=noop;if(!strcmp(import_names[i],"Button"))fn=held_button;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    unsigned char *raw=read_file(argv[3]);assert(!stat(argv[3],&input_stat)&&input_stat.st_size==6884);strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    const struct{unsigned at;void *fn;}hooks[]={
        {0x539b8,noop},{0x54c64,noop},{0x3b55c,noop},{0x57afc,exit_world_fb},{0x43134,exit_hud_fb},{0x35eb8,exit_swap_fb},
        {0x3760,noop},{0x353e4,noop},{0x24450,zero},{0xce40,zero},{0x3b260,exit_lookup_fb},{0x2b290,exit_flush_fb},
        {0x4cb28,exit_keys_fb},{0x41448,noop},{0x44e10,exit_panel_fb},{0x45f20,exit_animate_fb},{0x334bc,exit_music_fb},
        {0x3f178,held_dispatch_fb},{0x343b4,exit_change_fb},{0x3ed88,exit_score_fb},{0x34dd8,exit_kill_fb}};
    // Copy only PC-independent prologue; input adapter supplies controlled empty name.
    assert(*(uint32_t *)(code+0x3f178)==0x7c0802a6&&*(uint32_t *)(code+0x3f17c)==0x90010008&&*(uint32_t *)(code+0x3f180)==0xbda1ffa0&&*(uint32_t *)(code+0x3f184)==0x9421fe20);
    held_entry=malloc(32);assert(held_entry);memcpy(held_entry,code+0x3f178,16);jump_to(held_entry+16,code+0x3f188);MakeDataExecutable(held_entry,32);
    jump_to(code+0x24248,zero);
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    held_toc=toc;
    for(exit_case=0;exit_case<3;exit_case++){
        memset(g,0,0x1300);memset(button_node,0,sizeof(button_node));memset(fade_node,0,sizeof(fade_node));
        int values[12]={0};*(void **)(g+0xa72)=values;*(int *)(g+0xa7e)=100;*(int16_t *)(g+0xa52)=exit_case%3+1;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0xeb6)=font_widths;font_widths[65]=.75;font_widths[66]=.6875;
        double button_bounds[]={381,292,65,65},fade_bounds[]={0,69,640,380};memcpy(button_node,button_bounds,32);memcpy(fade_node,fade_bounds,32);
        *(int16_t *)(button_node+38)=900;recording=records=0;invoke_fb(code+0x4cef0,g,toc,NULL,NULL,NULL);event('Z');assert(clock_reads>1&&queued==sizeof(input)&&g[0x6da]==2&&!memcmp(g+0x6db,"BA",2));
    }
    DisposeHandle(strings);fputs("PASS3 held GAMEOVER frame schedules; real field keys and DOMOUSE body, controlled empty-name call adapter\n",stderr);return 0;
}
