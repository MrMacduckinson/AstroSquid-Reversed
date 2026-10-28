/* Original PAUSE loop; UI/audio/mouse boundaries observed without a GUI. G5 only. */
#define main existing_keymap_oracle_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static unsigned char *globals;
static unsigned case_id,reads,polls,frames,lookups,transitions;
static int interval,release_polls,quit_key;
static uint32_t clock_base;
static Handle constant_strings;
static double sprites[4][40];
static void event(const char *name,int value){
 printf("%u,%s,%d,%u,%u,%u,%u,%d,%d,%d,%d\n",case_id,name,value,reads,polls,frames,
  *(uint32_t *)(globals+0xa4a),*(int16_t *)(globals+0xa68),*(int16_t *)(globals+0xab6),
  *(int16_t *)(globals+0x58e),*(int16_t *)(globals+0xa6a));
}
uint32_t pause_tick(void){if(reads>1000)exit(3);uint32_t value=clock_base+reads++;event("clock",value);return value;}
void pause_keys(unsigned char *out){memset(out,0,16);polls++;if((int)polls>release_polls){if(quit_key){out[6]|=0x80;out[1]|=0x10;}else if(!release_polls)out[6]|=0x20;else out[0]|=1;}event("keys",0);}
Handle strings_resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return constant_strings;}
uint32_t zero(void){return 0;}
uint32_t mouse(void){event("mouse",0);return 0;}
void show_cursor(void){event("show",0);}
void hide_cursor(void){event("hide",0);}
void observe_load(void){event("scene",0);}
void *observe_sprite(void){event("sprite",lookups);return sprites[(lookups++)%4];}
void observe_kill(void){event("kill",0);}
void observe_sound(void){event("sound",0);}
void observe_trans(int value){transitions++;event("transition",value);}
void observe_hover(void){event("hover",0);}
void observe_world(void){frames++;event("world",0);}
void observe_pause_overlay(void){event("pause_overlay",0);}
void observe_hud(void){event("hud",0);}
void observe_music(void){event("music",0);}
void observe_animate(void){event("animate",0);}
void observe_swap(void){event("swap",0);}
/* Import glue already saved caller r2; do not overwrite its linkage slot. */
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" "mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(pause_keys) WRAP(strings_resource) WRAP(show_cursor) WRAP(hide_cursor) WRAP(pause_tick) WRAP(zero) WRAP(mouse) WRAP(observe_load) WRAP(observe_sprite) WRAP(observe_kill) WRAP(observe_sound)
WRAP(observe_trans) WRAP(observe_hover) WRAP(observe_world) WRAP(observe_pause_overlay)
WRAP(observe_hud) WRAP(observe_music) WRAP(observe_animate) WRAP(observe_swap)
static void require_size(const char *path,long expected){
 FILE *f=fopen(path,"rb");if(!f){perror(path);exit(2);}
 if(fseek(f,0,SEEK_END)||ftell(f)!=expected){fclose(f);fputs("Wrong oracle input size\n",stderr);exit(2);}fclose(f);
}
int main(int argc,char **argv){
 setvbuf(stdout,NULL,_IONBF,0);
 if(argc!=4)return 2;
 require_size(argv[1],455780);require_size(argv[2],11812);require_size(argv[3],6884);alarm(15);
 unsigned char *pef=read_file(argv[1]),*code=pef+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,65536);globals=g;
 unsigned char *raw=read_file(argv[3]);constant_strings=NewHandle(6884);if(!constant_strings)return 2;memcpy(*constant_strings,raw,6884);
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetKeys"))fn=pause_keys_fb;if(!strcmp(import_names[i],"TickCount"))fn=pause_tick_fb;if(!strcmp(import_names[i],"GetResource"))fn=strings_resource_fb;if(!strcmp(import_names[i],"ShowCursor"))fn=show_cursor_fb;if(!strcmp(import_names[i],"HideCursor"))fn=hide_cursor_fb;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 jump_to(code+0x24450,zero_fb);jump_to(code+0xce40,zero_fb);jump_to(code+0x24248,mouse_fb);
 jump_to(code+0x353e4,observe_load_fb);jump_to(code+0x3b260,observe_sprite_fb);jump_to(code+0x34dd8,observe_kill_fb);jump_to(code+0x3ccd8,observe_sound_fb);
 jump_to(code+0x4d574,observe_trans_fb);jump_to(code+0x41448,observe_hover_fb);jump_to(code+0x57afc,observe_world_fb);jump_to(code+0x44898,observe_pause_overlay_fb);jump_to(code+0x43134,observe_hud_fb);jump_to(code+0x334bc,observe_music_fb);jump_to(code+0x45f20,observe_animate_fb);jump_to(code+0x35eb8,observe_swap_fb);MakeDataExecutable(code,433284);
 
 puts("case,event,value,reads,polls,frames,cpu,paused,any,quit,hud_dirty");
 for(case_id=0;case_id<16;case_id++){
  unsigned scenario=case_id%8;clock_base=case_id<8?100:UINT32_MAX-3;
  reads=polls=frames=lookups=transitions=0;interval=scenario%3+1;release_polls=scenario/3;quit_key=scenario==6;
  memset(sprites,0,sizeof(sprites));*(int16_t *)(g+0xa52)=interval;*(uint32_t *)(g+0xa4a)=clock_base;*(int16_t *)(g+0xa6a)=2;*(int16_t *)(g+0xa68)=0;*(int16_t *)(g+0xab6)=0;*(int16_t *)(g+0x58e)=0;*(int16_t *)(g+0x58c)=scenario==7;
  invoke_fb(code+0x4d818,g,toc,NULL,NULL,NULL);event("return",0);
  if(polls!=(unsigned)release_polls+1||frames!=polls||lookups!=8||transitions!=(scenario==7?1:2)||*(int16_t *)(g+0xa68)!=0||*(int16_t *)(g+0xab6)==0||*(int16_t *)(g+0x58e)!=quit_key)return 3;
 }
 return 0;
}
