/* Actual FBHANDLEEVENTS/FBDOMACEVENT/FBANYKEY, no native TextEdit or dialog helper. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g;static unsigned character,kind,reads,waits,ports,restores,fronts;static uint32_t now;
static unsigned combined,queued;
static void queued_event(EventRecord *event){assert(queued<6);memset(event,0,sizeof(*event));event->what=kind;event->message='A'+queued++;}
static Boolean next_event(uint32_t mask,EventRecord *event){assert(combined&&mask==0x28u&&event==(void *)(g+0x168));queued_event(event);return true;}
static uint32_t tick(void){reads++;return now;}
/* CFM passes everyEvent sign-extended in r3; keep the full register here. */
static Boolean wait_event(uint32_t mask,EventRecord *event,UInt32 sleep,RgnHandle region){assert(mask==0xffffffffu);assert(event==(void *)(g+0x168));assert(!sleep);assert(!region);waits++;memset(event,0,sizeof(*event));event->what=kind;event->message=character;if(combined)queued_event(event);return true;}
static Boolean dialog_event(const EventRecord *event){assert(event==(void *)(g+0x168));return false;}
static void get_port(GrafPtr *p){ports++;*p=(void *)0x12345678;}
static void set_port(GrafPtr p){assert(p==(void *)0x12345678);restores++;}
static WindowPtr front_window(void){fronts++;return NULL;}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(30);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]);g=calloc(1,0x1400);assert(g);uint32_t toc[489]={0};
 for(unsigned i=0;i<484;i++){
  void *fn=missing_import;
  if(!strcmp(import_names[i],"TickCount"))fn=tick;
  if(!strcmp(import_names[i],"WaitNextEvent"))fn=wait_event;
  if(!strcmp(import_names[i],"GetNextEvent"))fn=next_event;
  if(!strcmp(import_names[i],"IsDialogEvent"))fn=dialog_event;
  if(!strcmp(import_names[i],"GetPort"))fn=get_port;
  if(!strcmp(import_names[i],"SetPort"))fn=set_port;
  if(!strcmp(import_names[i],"FrontWindow"))fn=front_window;
  descriptors[i][0]=(uint32_t)(uintptr_t)fn;toc[i]=(uint32_t)(uintptr_t)descriptors[i];
 }toc[0]=(uint32_t)(uintptr_t)g;toc[1]=(uint32_t)(uintptr_t)lit;MakeDataExecutable(code,433284);
 const uint32_t clocks[]={1000,0x7fffffd0u,0xfffffff0u};unsigned cases=0;
 for(unsigned clock=0;clock<3;clock++)for(unsigned focus=0;focus<3;focus++)for(unsigned repeat=0;repeat<2;repeat++)for(character=0;character<256;character++){
  memset(g,0,0x1400);*(void **)(g+0x21c)=lit;*(void **)(g+0xa06)=focus?g+0x5b2+(focus-1)*0x22a:NULL;
  unsigned char before[0x454];for(unsigned i=0;i<sizeof(before);i++)before[i]=(i*17+character)&255;memcpy(g+0x5b2,before,sizeof(before));
  now=clocks[clock];kind=repeat?5:3;reads=waits=ports=restores=fronts=0;
  invoke_fb(code+0x24064,g,toc,NULL,NULL,NULL);
  assert(reads==1&&waits==1&&*(uint32_t *)(g+0x194)==now+60u);
  assert(ports==(character!=16)&&restores==ports&&fronts==ports);
  assert(!memcmp(before,g+0x5b2,sizeof(before))&&*(void **)(g+0xa06)==(focus?g+0x5b2+(focus-1)*0x22a:NULL));
  assert(!*(uint32_t *)(g+0x184)&&!*(uint32_t *)(g+0x2c0));cases++;
 }
 unsigned char *heap=calloc(1,0x100000);assert(heap);unsigned coupled=0;combined=1;
 for(unsigned focus=0;focus<3;focus++)for(unsigned pre=0;pre<3;pre++)for(unsigned post=0;post<3;post++)for(unsigned repeat=0;repeat<2;repeat++){
  memset(g,0,0x1400);*(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;
  *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
  unsigned char *field=focus?g+0x5b2+(focus-1)*0x22a:NULL;*(void **)(g+0xa06)=field;
  now=1000;kind=repeat?5:3;queued=reads=waits=ports=restores=fronts=0;
  for(unsigned i=0;i<pre&&field;i++){*(void **)(g+0x38c)=heap;invoke_fb(code+0x3ecf4,g,toc,NULL,NULL,NULL);}
  unsigned dropped=queued;invoke_fb(code+0x24064,g,toc,NULL,NULL,NULL);
  for(unsigned i=0;i<post&&field;i++){*(void **)(g+0x38c)=heap;invoke_fb(code+0x3ecf4,g,toc,NULL,NULL,NULL);}
  assert(queued==1+(field?pre+post:0)&&reads==1&&waits==1);
  if(field){assert(field[296]==pre+post&&*(short *)(field+36)==(int)(pre+post));for(unsigned i=0;i<pre+post;i++)assert((unsigned)field[297+i]=='A'+i+(i>=dropped));}
  else assert(!g[0x6da]&&!g[0x904]);coupled++;
 }
 printf("PASS %u coupled field/periodic/field sequences: shared queue, one dropped event, preserved order, keyDown/autoKey; explicit call schedule\n",coupled);
 printf("PASS %u actual periodic key services: keyDown/autoKey bytes0..255, three custom-field focuses, tick wrap; event consumed and custom fields untouched; no TE/helper/Command/dialog\n",cases);return 0;
}
