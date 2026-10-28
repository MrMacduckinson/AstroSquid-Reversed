/* Original LMINITMINI graphics selection prefix; stop before final context check. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <setjmp.h>
#include <unistd.h>
static unsigned char *globals;
static Handle strings;
static jmp_buf stop;
static int modern,agl_ok,dsp_ok,drawable_ok;
static char events[32];static unsigned used;
static unsigned char dsp_port[256],window_port[256];
static void event(char c){if(used>=sizeof(events)-1)exit(3);events[used++]=c;events[used]=0;}
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
int setup_system(int selector){if(selector!=8)exit(3);return modern?1000:999;}
void setup_message(void *message){(void)message;}
int setup_agl(void){event('A');*(uint32_t *)(globals+0xe8a)=agl_ok?0x1111:0;return 0x9999;}
void setup_dsp(void){event('D');*(uint32_t *)(globals+0xe8e)=dsp_ok?0x2222:0;}
static int front(void *dsp,void **port){if(dsp!=(void *)0x2222)exit(3);event('F');*port=dsp_port;return 0;}
int setup_drawable(void *port){if(port==dsp_port)event('P');else if(port==window_port)event('W');else exit(3);return drawable_ok?0x3333:0;}
void setup_window(int id,void *title,Rect *rect,int style,int flags,int extra){(void)title;if(id!=1||style!=5||flags||extra||rect->top||rect->left||rect->bottom!=480||rect->right!=640)exit(3);event('N');}
void *setup_get_window(int selector){if(selector!=31)exit(3);event('G');return window_port;}
void setup_finished(void){longjmp(stop,1);}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(setup_system) WRAP(setup_message) WRAP(setup_agl) WRAP(setup_dsp) WRAP(setup_drawable) WRAP(setup_window) WRAP(setup_get_window) WRAP(setup_finished)
static unsigned char *input(const char *path,long expected){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=expected)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;globals=g;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);*(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"GetKeys"))f=scripted_keys;if(!strcmp(import_names[i],"DSpContext_GetFrontBuffer"))f=front;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x24450,setup_system_fb);jump_to(code+0x3366c,setup_message_fb);jump_to(code+0x36898,setup_agl_fb);jump_to(code+0x36130,setup_dsp_fb);jump_to(code+0x363dc,setup_drawable_fb);jump_to(code+0x26040,setup_window_fb);jump_to(code+0x25454,setup_get_window_fb);jump_to(code+0x38240,setup_finished_fb);MakeDataExecutable(code,433284);
 struct Case {int full,modern,agl,dsp,drawable,option;const char *events;int final_full;uint32_t context;} cases[]={
 {0,1,1,1,1,0,"NGW",0,0x3333},{1,1,1,1,1,0,"A",1,0x1111},
 {1,1,0,1,1,0,"ADFP",1,0x3333},{1,1,0,0,1,0,"ADNGW",0,0x3333},
 {1,0,1,1,1,0,"DFP",1,0x3333},{1,0,1,0,1,0,"DNGW",0,0x3333},
 {1,1,0,1,0,0,"ADFP",1,0},{0,1,1,1,0,0,"NGW",0,0},
 {1,1,1,1,1,1,"NGW",0,0x3333}};
 Rect dsp_rect={12,34,492,674};memcpy(dsp_port+16,&dsp_rect,8);
 for(unsigned i=0;i<sizeof(cases)/sizeof(cases[0]);i++){
  const struct Case *c=&cases[i];modern=c->modern;agl_ok=c->agl;dsp_ok=c->dsp;drawable_ok=c->drawable;used=0;events[0]=0;key_calls=0;
  memset(scripted,0,sizeof(scripted));if(c->option)key(58);
  *(short *)(g+0xede)=0;*(short *)(g+0xee0)=c->full;*(uint32_t *)(g+0xe8a)=*(uint32_t *)(g+0xe8e)=0;
  *(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(void **)(g+0x38c)=heap;
  if(!setjmp(stop))invoke_fb(code+0x37ec4,g,toc,NULL,NULL,NULL);
  int has_dsp=strchr(events,'F')!=NULL;
  if(strcmp(events,c->events)||key_calls!=1||*(short *)(g+0xee0)!=c->final_full||*(short *)(g+0xee2)!=(modern?0:1)||*(uint32_t *)(g+0xe8a)!=c->context||*(int *)(g+0xe96)!=(has_dsp?34:0)||*(int *)(g+0xe9a)!=(has_dsp?12:0))return 3;
  printf("case%u,%s,fullscreen%d,context%04x,offset%d,%d\n",i,events,c->final_full,c->context,*(int *)(g+0xe96),*(int *)(g+0xe9a));
 }
 puts("PASS original AGL/DSp/window fallback prefix:9 cases,system gate,leftOption,frontbuffer offsets,failed drawable remains fullscreen with null context");return 0;
}
