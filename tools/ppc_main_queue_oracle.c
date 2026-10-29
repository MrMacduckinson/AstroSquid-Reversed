/* Actual Main loop frame/periodic gates and original field/service consumers. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g;static unsigned profile,reads,frames,queued,step;static uint32_t start;
static void record(char type,unsigned value){printf("%u,%c,%u,%u,%u,%u\n",profile,type,value,reads,frames,queued);}
static uint32_t clock_tick(void){uint32_t value=start+reads++*step;if(reads>=80)*(short *)(g+0x58e)=1;record('T',value);return value;}
static void fill_event(EventRecord *event){assert(event==(void *)(g+0x168)&&queued<128);memset(event,0,sizeof(*event));event->what=queued%2?5:3;event->message='A'+queued++%26;}
static Boolean field_event(uint32_t mask,EventRecord *event){assert(mask==0x28);fill_event(event);record('F',event->message);return true;}
static Boolean periodic_event(uint32_t mask,EventRecord *event,UInt32 sleep,RgnHandle region){assert(mask==0xffffffffu&&!sleep&&!region);fill_event(event);record('P',event->message);return true;}
static Boolean no_dialog(const EventRecord *event){assert(event==(void *)(g+0x168));return false;}
static void get_port(GrafPtr *p){*p=(void *)0x12345678;}
static void set_port(GrafPtr p){assert(p==(void *)0x12345678);}
static WindowPtr front(void){return NULL;}
static Boolean button(void){return false;}
/* GETKEYMAP scans bit128 too; the fixture explicitly initializes that extra byte. */
static void keys(void *p){memset(p,0,17);}
static Boolean bit_test(const unsigned char *p,long bit){assert(bit>=0&&bit<=128);return (p[bit/8]&(0x80u>>(bit%8)))!=0;}
void frame(void){frames++;record('W',0);} BRIDGE(frame)
extern void invoke_loop(void *,void *,void *,uint32_t);
__asm__(".text\n.align 2\n.globl _invoke_loop\n_invoke_loop:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\nstmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r19,r6\nli r20,0\nmtctr r12\nbctrl\n"
"lwz r2,24(r1)\nlfd f14,112(r1)\nlmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(60);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*heap=calloc(1,0x100000);g=calloc(1,0x1400);double *stars=calloc(3001*4,8);assert(g&&heap&&stars);uint32_t toc[489]={0};
 for(unsigned i=0;i<484;i++){
  void *fn=missing_import;
  if(!strcmp(import_names[i],"TickCount"))fn=clock_tick;
  if(!strcmp(import_names[i],"GetNextEvent"))fn=field_event;
  if(!strcmp(import_names[i],"WaitNextEvent"))fn=periodic_event;
  if(!strcmp(import_names[i],"IsDialogEvent"))fn=no_dialog;
  if(!strcmp(import_names[i],"GetPort"))fn=get_port;
  if(!strcmp(import_names[i],"SetPort"))fn=set_port;
  if(!strcmp(import_names[i],"FrontWindow"))fn=front;
  if(!strcmp(import_names[i],"Button"))fn=button;
  if(!strcmp(import_names[i],"GetKeys"))fn=keys;
  if(!strcmp(import_names[i],"BitTst"))fn=bit_test;
  descriptors[i][0]=(uint32_t)(uintptr_t)fn;toc[i]=(uint32_t)(uintptr_t)descriptors[i];
 }toc[0]=(uint32_t)(uintptr_t)g;toc[1]=(uint32_t)(uintptr_t)lit;
 const unsigned observers[]={0x45af0,0x3b55c,0x41448,0x3aaf8,0x46394,0x45f20,0x35eb8};
 for(unsigned i=0;i<sizeof(observers)/sizeof(*observers);i++)jump_to(code+observers[i],noop);jump_to(code+0x334bc,frame_fb);
 uint32_t *entry=(uint32_t *)(code+0x66ce4),*tail=(uint32_t *)(code+0x66f0c);
 entry[0]=0x7c0802a6;entry[1]=0x90010010;entry[2]=0x90410014;
 tail[0]=0x926e1300;tail[1]=0x928e1304;tail[2]=0x80010010;tail[3]=0x7c0803a6;tail[4]=0x4e800020;MakeDataExecutable(code,433284);
 const short intervals[]={1,2,3,1000};
 for(unsigned seed=0;seed<2;seed++)for(unsigned focus=0;focus<3;focus++)for(unsigned interval=0;interval<4;interval++)for(step=0;step<3;step++){
  memset(g,0,0x1400);reads=frames=queued=0;start=1000;
  *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xa54)=stars;
  *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xa52)=intervals[interval];*(uint32_t *)(g+0xa4a)=1000;
  *(void **)(g+0xa06)=focus?g+0x5b2+(focus-1)*0x22a:NULL;
  *(double *)(g+0x5c2)=*(double *)(g+0x7ec)=200;
  for(unsigned i=1;i<=3000;i++){stars[i*4]=80;stars[i*4+1]=(i*17)%640;stars[i*4+2]=(i*29)%480;stars[i*4+3]=i%5+1;}
  invoke_loop(code+0x66ce4,g,toc,seed?940:1000);
  assert(reads>=80&&reads<86);printf("%u,Z,%u,%u,%u,%u,%u,%u,",profile,reads,frames,queued,*(uint32_t *)(g+0xa4a),*(uint32_t *)(g+0x1300),*(uint32_t *)(g+0x1304));
  unsigned char *field=focus?g+0x5b2+(focus-1)*0x22a:NULL;if(field)for(unsigned i=0;i<field[296];i++)printf("%02x",field[297+i]);putchar('\n');profile++;
 }
 fprintf(stderr,"PASS %u actual Main queue schedules; frame and periodic gates retained, original consumers and MOVESTARS; renderer/window imports observed\n",profile);return 0;
}
