/* Original FBANYKEY fallback and stop/quit routing; no TextEdit/window callbacks. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
#include <setjmp.h>
static unsigned expected_character,menus,beeps,stops,ends;
static uint32_t menu_result,stop_location;static jmp_buf end_return;
static WindowPtr no_window(void){return NULL;}
static uint32_t no_menu(uint32_t character){assert(character==expected_character);menus++;return menu_result;}
static void beep(short duration){assert(duration==1);beeps++;}
static void get_port(GrafPtr *p){*p=(void *)0x12345678;}
static void set_port(GrafPtr p){assert(p==(void *)0x12345678);}
void observe_stop(uint32_t location){stops++;stop_location=location;}
void observe_end(void){ends++;longjmp(end_return,1);}
BRIDGE(observe_stop) BRIDGE(observe_end)
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(30);struct stat st;
 assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1400);assert(g);uint32_t toc[489]={0};
 for(unsigned i=0;i<484;i++){
  void *fn=missing_import;
  if(!strcmp(import_names[i],"FrontWindow"))fn=no_window;
  if(!strcmp(import_names[i],"MenuKey"))fn=no_menu;
  if(!strcmp(import_names[i],"SysBeep"))fn=beep;
  if(!strcmp(import_names[i],"GetPort"))fn=get_port;
  if(!strcmp(import_names[i],"SetPort"))fn=set_port;
  descriptors[i][0]=(uint32_t)(uintptr_t)fn;toc[i]=(uint32_t)(uintptr_t)descriptors[i];
 }toc[0]=(uint32_t)(uintptr_t)g;toc[1]=(uint32_t)(uintptr_t)lit;MakeDataExecutable(code,433284);
 unsigned cases=0;
 for(unsigned kind=3;kind<=5;kind+=2)for(unsigned ch=0;ch<256;ch++){
  if(ch=='.'||ch=='q'||ch=='Q')continue; /* Separate stop/quit paths. */
  memset(g,0,0x1400);*(void **)(g+0x21c)=lit;*(uint32_t *)(g+0x128)=0x00010001;
  EventRecord *event=(void *)(g+0x168);event->what=kind;event->message=ch;event->modifiers=0x100;
  expected_character=ch;menus=beeps=0;unsigned char before[0x454];memset(before,0x5a,sizeof(before));memcpy(g+0x5b2,before,sizeof(before));
  invoke_fb(code+0x22558,g,toc,NULL,NULL,NULL);
  assert(menus==(ch!=16)&&beeps==menus&&!memcmp(g+0x5b2,before,sizeof(before)));cases++;
 }
 jump_to(code+0x1b360,observe_stop_fb);jump_to(code+0x1b2cc,observe_end_fb);MakeDataExecutable(code,433284);
 unsigned char *heap=calloc(1,0x10000);assert(heap);unsigned special=0;
 for(unsigned kind=3;kind<=5;kind+=2)for(unsigned selected=0;selected<2;selected++)for(unsigned i=0;i<3;i++){
  const unsigned chars[]={'.','q','Q'};expected_character=chars[i];menu_result=selected?0x00010001:0;
  memset(g,0,0x1400);*(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(uint32_t *)(g+0x128)=0x00010001;
  EventRecord *event=(void *)(g+0x168);event->what=kind;event->message=expected_character;event->modifiers=0x100;
  menus=beeps=stops=ends=stop_location=0;
  if(!setjmp(end_return))invoke_fb(code+0x22558,g,toc,NULL,NULL,NULL);
  assert(menus==(i!=0));
  if(!i)assert(stops==1&&stop_location==0x800ac0&&!ends&&!beeps);
  else if(selected)assert(ends==1&&!stops&&!beeps&&event->what==16);
  else assert(stops==1&&stop_location==0x800ace&&!ends&&beeps==1);
  assert(!*(short *)(g+0x58e));
  printf("special,%u,%u,%u,%u,%u,%u,%u,%x\n",kind,selected,expected_character,menus,stops,ends,beeps,stop_location);special++;
 }
 printf("PASS %u special Command routes: dot Stop; unmatched Q Stop then beep; menu-matched Q runtime End, without game quit flag; Stop/End observed only\n",special);
 printf("PASS %u original Command key cases: unmatched menu beeps once; function-key byte16 ignored; fields unchanged; no OS UI/audio executed\n",cases);return 0;
}
