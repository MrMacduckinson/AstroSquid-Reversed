/* Actual GAMEOVER frame gate + real HANDLEFIELDEVENTS/HANDLEFIELDKEYS; no OS input. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *exit_globals;
static unsigned exit_case,recording,records;
static int composite;static unsigned polls,hover_frames;static const char *scene_path;static FILE *scene_file;
static unsigned char button_node[312],fade_node[312];
static unsigned clock_reads,queued;
static Handle strings;
static const unsigned char input[]={'A','B',13};
static void composite_event(char kind,unsigned value){
 unsigned char *g=exit_globals;assert(records++<10000);
 printf("%u,%c,%u,%u,%u,%d,%d,%d,%d,%d,%d,%u,%d,",exit_case,kind,value,clock_reads,*(uint32_t *)(g+0xa4a),*(short *)(g+0xa68),*(short *)(g+0x58c),*(short *)(g+0x5aa),*(void **)(g+0xa06)!=NULL,*(short *)(g+0x7da),*(short *)(g+0x5d6),*(uint32_t *)(g+0x5d2),*(short *)(g+0x5d8));
 for(unsigned i=0;i<g[0x6da];i++)printf("%02x",g[0x6db+i]);putchar('\n');
 if(kind=='O'||kind=='A'||kind=='Z')for(unsigned char *n=*(void **)(g+0xe86);n;n=*(void **)(n+300)){
  if(kind=='O'&&*(short *)(n+38)==902)hover_frames++;printf("N,%u,%c,",exit_case,kind);for(unsigned i=0;i<n[40];i++)printf("%02x",n[41+i]);printf(",%d,%d,%u,%d",*(short *)(n+32),*(short *)(n+38),*(uint32_t *)(n+34),*(int *)(n+296));
  for(unsigned i=0;i<4;i++){uint64_t v;memcpy(&v,n+8*i,8);printf(",%016llx",v);}putchar('\n');
 }
}
static void *scene_alloc(unsigned n){assert(n==308);void *p=calloc(1,n);assert(p);return p;}
int scene_system(int selector){assert(selector==1);return 123;}
int scene_folder(int volume){assert(volume==123);unsigned char *p=*(unsigned char **)(exit_globals+0x38c)-256;assert(p[0]==4&&!memcmp(p+1,"Data",4));*(void **)(exit_globals+0x38c)=p;return 123;}
void scene_open(int mode,int number,int kind,unsigned char *name,int z,int folder,int unused){assert(mode==0x52&&number==1&&kind==1&&!z&&folder==123&&!unused&&!scene_file&&name[0]==7&&!memcmp(name+1,"Data B1",7));scene_file=fopen(scene_path,"rb");assert(scene_file);}
int scene_read(int number,void *out,int bytes){assert(number==1&&bytes==308&&scene_file&&fread(out,1,308,scene_file)==308);return 0;}
long scene_length(int number){assert(number==1&&scene_file);return 924;}
int scene_eof(int number){assert(number==1&&scene_file);return ftell(scene_file)>=924?-1:0;}
void scene_close(int number){assert(number==1&&scene_file&&!fclose(scene_file));scene_file=NULL;}
BRIDGE(scene_system) BRIDGE(scene_folder) BRIDGE(scene_open) BRIDGE(scene_read) BRIDGE(scene_length) BRIDGE(scene_eof) BRIDGE(scene_close)
static void event_value(char code,unsigned value){
    if(!recording)return;if(composite){composite_event(code,value);return;}assert(records++<1000);
    printf("%u,%c,%u,%d,%d,%d,%u,",exit_case,code,value,*(int16_t *)(exit_globals+0xa68),*(int16_t *)(button_node+38),*(int16_t *)(exit_globals+0x7da),*(uint32_t *)(exit_globals+0xa4a));
    for(unsigned i=0;i<exit_globals[0x6da];i++)printf("%02x",exit_globals[0x6db+i]);printf(",%d\n",*(int16_t *)(exit_globals+0x5d6));
}
static void event(char code){event_value(code,0);}
static uint32_t clock_tick(void){if(!recording)return 1000;uint32_t value=1000+clock_reads++;event_value('T',value);return value;}
static int zero(void){return 0;}
static int held_button(void){return recording&&!(composite&&exit_case>=3&&polls>=8&&polls<=10);}
static unsigned char *held_entry,*change_entry,*animate_entry,*panel_entry;static uint32_t *held_toc;
static void held_position(Point *p){p->h=composite&&exit_case>=3&&polls>=16&&polls<=25?413:225;p->v=composite&&exit_case>=3&&polls>=16&&polls<=25?324:260;}
void held_dispatch(void){
    unsigned char empty[256]={0};
    invoke_fb(held_entry,exit_globals,held_toc,empty,NULL,NULL);event('D');
}
void click_sound(unsigned char *name,double *pan){assert(name[0]==5&&!memcmp(name+1,"Click",5));uint64_t bits;memcpy(&bits,pan,8);printf("C,%u,%016llx\n",exit_case,bits);}
BRIDGE(click_sound) BRIDGE(held_dispatch)
static Handle input_resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static Boolean input_event(EventMask mask,EventRecord *record){
    assert(mask==0x28&&queued<sizeof(input));if(composite&&polls<(queued==0?2u:queued==1?4u:35u))return false;memset(record,0,sizeof(*record));record->what=keyDown;record->message=input[queued++];event_value('E',record->message);return true;
}
void exit_flush(void){fprintf(stderr,"field %.17g/%.17g/%.17g/%.17g integerY%d\n",*(double *)(exit_globals+0x5b2),*(double *)(exit_globals+0x5ba),*(double *)(exit_globals+0x5c2),*(double *)(exit_globals+0x5ca),(int)*(double *)(exit_globals+0x5ba));recording=1;clock_reads=queued=polls=hover_frames=0;*(int16_t *)(exit_globals+0x5aa)=1;*(uint32_t *)(exit_globals+0xa4a)=1000;}
void exit_keys(void){if(composite)polls++;unsigned any=1;*(int16_t *)(exit_globals+0xab6)=any;event_value('K',any);}
void exit_animate(void){invoke_fb(animate_entry,exit_globals,held_toc,NULL,NULL,NULL);event('A');}void exit_music(void){event('S');}
void exit_world(void){event('R');}void exit_panel(void){if(composite)invoke_fb(panel_entry,exit_globals,held_toc,NULL,NULL,NULL);event('O');}void exit_hud(void){event('H');}void exit_swap(void){event('W');}
void exit_score(void){event('I');}
void *exit_lookup(unsigned char *name){assert(name);if(name[0]==10&&!memcmp(name+1,"GameOverOK",10))return button_node;assert(name[0]==12&&!memcmp(name+1,"GameOverFade",12));return fade_node;}
void exit_change(unsigned char *node,unsigned id){
    if(composite){invoke_fb(change_entry,exit_globals,held_toc,node,(void *)id,NULL);return;}assert(node==button_node&&id==901);invoke_fb(change_entry,exit_globals,held_toc,node,(void *)id,NULL);event('P');
    printf("%u,G,%u",exit_case,*(uint32_t *)(node+34));for(unsigned i=0;i<4;i++){uint64_t bits;memcpy(&bits,node+i*8,8);printf(",%016llx",bits);}putchar('\n');
}
void exit_kill(void *node){assert(node==button_node||node==fade_node);event(node==button_node?'B':'F');}
BRIDGE(exit_keys) BRIDGE(exit_flush) BRIDGE(exit_animate) BRIDGE(exit_music) BRIDGE(exit_world) BRIDGE(exit_panel) BRIDGE(exit_hud) BRIDGE(exit_swap) BRIDGE(exit_score) BRIDGE(exit_lookup) BRIDGE(exit_change) BRIDGE(exit_kill)
int main(int argc,char **argv){
    setvbuf(stdout,NULL,_IONBF,0);if(argc!=5&&argc!=6)return 2;composite=argc==6;scene_path=composite?argv[5]:NULL;alarm(30);struct stat input_stat;assert(!stat(argv[1],&input_stat)&&input_stat.st_size==455780&&!stat(argv[2],&input_stat)&&input_stat.st_size==11812);unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);exit_globals=g;
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=clock_tick;if(composite&&!strncmp(import_names[i],"gl",2))fn=noop;if(composite&&!strcmp(import_names[i],"NewPtrClear"))fn=scene_alloc;if(composite&&!strcmp(import_names[i],"DisposePtr"))fn=free;
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
    assert(*(uint32_t *)(code+0x343b4)==0x7c0802a6&&*(uint32_t *)(code+0x343b8)==0x90010008&&*(uint32_t *)(code+0x343bc)==0xbda1ffa0&&*(uint32_t *)(code+0x343c0)==0x9421ff20);
    change_entry=malloc(32);assert(change_entry);memcpy(change_entry,code+0x343b4,16);jump_to(change_entry+16,code+0x343c4);MakeDataExecutable(change_entry,32);
    assert(*(uint32_t *)(code+0x45f20)==0x7c0802a6&&*(uint32_t *)(code+0x45f24)==0x90010008&&*(uint32_t *)(code+0x45f28)==0xbda1ffa0&&*(uint32_t *)(code+0x45f2c)==0x9421ff20);
    animate_entry=malloc(32);assert(animate_entry);memcpy(animate_entry,code+0x45f20,16);jump_to(animate_entry+16,code+0x45f30);MakeDataExecutable(animate_entry,32);
    if(composite){assert(*(uint32_t *)(code+0x44e10)==0x7c0802a6&&*(uint32_t *)(code+0x44e14)==0x90010008&&*(uint32_t *)(code+0x44e18)==0xbda1ffa0);panel_entry=malloc(32);assert(panel_entry);memcpy(panel_entry,code+0x44e10,16);jump_to(panel_entry+16,code+0x44e20);MakeDataExecutable(panel_entry,32);}
    unsigned char *sprite_table=read_file(argv[4]);assert(!stat(argv[4],&input_stat)&&input_stat.st_size==14014);
    jump_to(code+0x24248,zero);
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++){
        if(composite&&(hooks[i].at==0x353e4||hooks[i].at==0x3b260||hooks[i].at==0x41448||hooks[i].at==0x34dd8||hooks[i].at==0x24450||hooks[i].at==0xce40))continue;
        jump_to(code+hooks[i].at,hooks[i].fn);
    }
    if(composite){const struct{unsigned at;void *fn;} scene_hooks[]={{0x24450,scene_system_fb},{0xce40,scene_folder_fb},{0xf064,scene_open_fb},{0xfd04,scene_read_fb},{0x109bc,scene_length_fb},{0x10f44,scene_eof_fb},{0xf8d4,scene_close_fb},{0x3a278,noop},{0x41730,noop},{0x3572c,noop},{0x342b4,noop},{0x3ce84,click_sound_fb}};for(unsigned i=0;i<sizeof(scene_hooks)/sizeof(scene_hooks[0]);i++)jump_to(code+scene_hooks[i].at,scene_hooks[i].fn);}MakeDataExecutable(code,433284);
    held_toc=toc;
    for(exit_case=0;exit_case<(composite?6u:3u);exit_case++){
        memset(g,0,0x1300);memset(button_node,0,sizeof(button_node));memset(fade_node,0,sizeof(fade_node));
        int values[12]={0};*(void **)(g+0xa72)=values;*(int *)(g+0xa7e)=100;*(int16_t *)(g+0xa52)=exit_case%3+1;
        *(short *)(g+0xed6)=640;*(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0xe82)=sprite_table;*(void **)(g+0xeb6)=font_widths;font_widths[65]=.75;font_widths[66]=.6875;
        double button_bounds[]={381,292,65,65},fade_bounds[]={0,69,640,380};memcpy(button_node,button_bounds,32);memcpy(fade_node,fade_bounds,32);
        if(!composite)*(void **)(g+0xe86)=button_node;*(void **)(button_node+300)=fade_node;*(int16_t *)(button_node+32)=10;*(int16_t *)(fade_node+32)=8;*(int16_t *)(fade_node+38)=998;
        *(int16_t *)(button_node+38)=900;recording=records=0;invoke_fb(code+0x4cef0,g,toc,NULL,NULL,NULL);event('Z');if(composite){assert((hover_frames>0)==(exit_case>=3));assert(!scene_file);while(*(void **)(g+0xe86))invoke_fb(code+0x34dd8,g,toc,*(void **)(g+0xe86),NULL,NULL);}assert(clock_reads>1&&queued==sizeof(input)&&g[0x6da]==2&&!memcmp(g+0x6db,"BA",2));
    }
    DisposeHandle(strings);fputs("PASS3 held GAMEOVER frame schedules; real field keys and DOMOUSE body, controlled empty-name adapter, real terminal LMCHANGESPRITEID\n",stderr);return 0;
}
