/* Coupled original active timed-special world oracle. Original CALC/DOPLAYER/
   FIREWEAPONSPECIAL/nested cleanup/CALC/LMHANDLE preserved; semantic render,
   sound and GPU import observers only. Run solely on reference G5. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"

static uint32_t descriptors[484][2];
static uint32_t tick;
static uint64_t ieee_word(double x){uint64_t u;memcpy(&u,&x,8);return u;}
static unsigned native_shots,ported_shots;
static unsigned native_hits,ported_hits;
typedef struct {int weapon,x,y,heading;} Shot;
static Shot native_log[1024],ported_log[1024];
static uint32_t controlled_tick(void) { return tick; }
void report_missing(uint32_t *descriptor) {
    int i=(int)(descriptor-&descriptors[0][0])/2;
    fprintf(stderr,"Unresolved oracle import %d %s\n",i,i>=0&&i<484?import_names[i]:"unknown");exit(2);
}
extern void missing_import(void);
__asm__(".text\n.align 2\n.globl _missing_import\n_missing_import:\nmr r3,r12\nb _report_missing\n");
void native_fire(int weapon,int x,int y,int direction,void *source) {
    (void)source;
    if(native_shots>=1024) exit(2);
    native_log[native_shots++]=(Shot){weapon,x,y,direction};
}
void native_hit(void *a,void *b) { (void)a;(void)b;native_hits++; }
extern void native_fire_fb(void),native_hit_fb(void);
__asm__(
".text\n.align 2\n.globl _native_fire_fb\n_native_fire_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_fire\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
".align 2\n.globl _native_hit_fb\n_native_hit_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_hit\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void port_fire(void *p,int weapon,int x,int y,int direction) {
    (void)p;
    if(ported_shots>=1024) exit(2);
    ported_log[ported_shots++]=(Shot){weapon,x,y,direction};
}
static void port_hit(void *p) { (void)p;ported_hits++; }
static unsigned char *read_file(const char *name) {
    FILE *f=fopen(name,"rb");if(!f) {perror(name);exit(2);}
    fseek(f,0,SEEK_END);long size=ftell(f);rewind(f);
    unsigned char *b=malloc((size_t)size);if(!b||fread(b,1,(size_t)size,f)!=(size_t)size) exit(2);
    fclose(f);return b;
}
static void jump_to(unsigned char *at,void *destination) {
    uintptr_t p=(uintptr_t)destination;
    uint32_t *w=(uint32_t *)at;
    w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);
    w[2]=0x7d8903a6;w[3]=0x4e800420;
}
static void set_short(unsigned char *p,int offset,int value) { *(int16_t *)(p+offset)=(int16_t)value; }
static void set_double(unsigned char *p,int offset,double value) { *(double *)(p+offset)=value; }
static void set_pointer(unsigned char *p,int offset,void *value) { *(void **)(p+offset)=value; }


typedef struct {unsigned char *p;size_t size;unsigned id;int alive;} Allocation;
static Allocation allocations[65536];static unsigned allocation_count,entity_birth,render_birth;
static unsigned char *world_globals;static const char *phase;
static Allocation *allocation(void *p){for(unsigned i=0;i<allocation_count;i++)if(allocations[i].p==p)return &allocations[i];return NULL;}
static unsigned identity(void *p){Allocation*a=allocation(p);if(!p)return 0;if(!a){fputs("Unregistered pointer in canonical state\n",stderr);exit(2);}return a->id;}
static void *world_alloc(long bytes){if(bytes<0||allocation_count==65536)exit(2);unsigned char*p=calloc(1,bytes?bytes:1);if(!p)exit(2);unsigned id=bytes==106?++entity_birth:bytes==308?++render_birth:allocation_count+1;allocations[allocation_count++]=(Allocation){p,(size_t)bytes,id,1};return p;}
static unsigned disposed;static int storm;static uint32_t *storm_toc;
static void world_dispose(void *p){disposed++;if(storm){Allocation *a=allocation(p);if(!a||!a->alive)exit(2);a->alive=0;return;}fputs("Unexpected disposal in no-deletion active-special fixture\n",stderr);exit(2);}
void world_sound(unsigned char *name,double *pan){printf("S\t%u\t%s\t",tick,phase);for(unsigned i=1;i<=name[0];i++)printf("%02x",name[i]);printf("\t%016llx\n",(unsigned long long)ieee_word(*pan));}
extern void world_sound_fb(void);
__asm__(".text\n.align 2\n.globl _world_sound_fb\n_world_sound_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _world_sound\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
extern uint32_t world_invoke5(void *,void *,void *,void *,void *,void *,void *,void *);
__asm__(".text\n.align 2\n.globl _world_invoke5\n_world_invoke5:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\nstmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r3,r6\nmr r4,r7\nmr r5,r8\nmr r6,r9\nmr r7,r10\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\nlmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void hex(const unsigned char*p,int n){for(int i=0;i<n;i++)printf("%02x",p[i]);}
static void snapshot(void){
 unsigned char*g=world_globals;printf("G\t%u\t%s\t%08x\t%u\t",tick,phase,*(uint32_t*)(g+0x244),identity(*(void**)(g+0xa7a)));
 hex(g+0xa1e,32);putchar('\t');hex(g+0xa58,16);putchar('\t');hex(g+0xa8a,10);putchar('\t');hex(g+0xa7e,12);putchar('\n');
 unsigned guard=0;for(unsigned char*e=*(void**)(g+0xa76);e;e=*(void**)(e+102)){
  if(++guard>65536)exit(2);Allocation*a=allocation(e);if(!a||!a->alive||a->size!=106)exit(2);
  printf("E\t%u\t%s\t%u\t%u\t%u\t%u\t%u\t",tick,phase,a->id,identity(*(void**)(e+62)),identity(*(void**)(e+92)),identity(*(void**)(e+98)),identity(*(void**)(e+102)));
  hex(e,62);hex(e+66,26);hex(e+96,2);putchar('\n');
 }
 guard=0;for(unsigned char*r=*(void**)(g+0xe86);r;r=*(void**)(r+300)){
  if(++guard>65536)exit(2);Allocation*a=allocation(r);if(!a||!a->alive||a->size!=308)exit(2);
  printf("R\t%u\t%s\t%u\t%u\t%u\t",tick,phase,a->id,identity(*(void**)(r+304)),identity(*(void**)(r+300)));hex(r,40);putchar('\t');hex(r+296,4);putchar('\n');
 }
}
static void *spawn(unsigned char*code,uint32_t*toc,int kind,int subtype,int x,int y){
 return(void*)(uintptr_t)world_invoke5(code+0x53bf4,world_globals,toc,(void*)(intptr_t)kind,(void*)(intptr_t)subtype,(void*)(intptr_t)x,(void*)(intptr_t)y,NULL);
}

static FILE *clock_trace;static unsigned char *active_code;static uint32_t serial;static int clock_enabled;static unsigned renders,swaps,huds,flashes;
static uint32_t active_tick(void){
 if(!clock_enabled)return tick=100;
 if(serial>2000000){fputs("Clock guard exceeded\n",stderr);exit(2);}
 tick=100+serial/4096;uint32_t pc=(uint32_t)((unsigned char *)__builtin_return_address(0)-active_code)-4+0x10000000;
 fprintf(clock_trace,"%u,%08x,%u\n",serial++,pc,tick);return tick;
}
static void active_keys(void *keys){memset(keys,0,16);((unsigned char *)keys)[7]=0x20;}
static void noop_gl(void){}
static void active_snapshot(const char *label){phase=label;printf("Q\t%u\t%s\t%u\t%u\t%u\t%u\t%u\t%u\n",tick,label,serial,*(uint32_t *)(world_globals+0xa4a),*(uint32_t *)(world_globals+0xa4e),*(uint32_t *)(world_globals+0xa90),(unsigned)*(uint16_t *)(world_globals+0xec6),*(uint32_t *)(world_globals+0xec8));snapshot();}
void active_render(void){
 renders++;
 if(storm)for(unsigned char *e=*(void **)(world_globals+0xa76);e;e=*(void **)(e+102))
  if(*(int16_t *)e==999)invoke_fb(active_code+0x559e8,world_globals,storm_toc,e,NULL,NULL);
 active_snapshot("render");
}
void active_hud(void){huds++;printf("V\t%u\t%u\n",tick,huds);}
void active_flash(int sprite,double *x,double *y,double *w,double *h){flashes++;printf("F\t%u\t%d\t%016llx\t%016llx\t%016llx\t%016llx\n",tick,sprite,(unsigned long long)ieee_word(*x),(unsigned long long)ieee_word(*y),(unsigned long long)ieee_word(*w),(unsigned long long)ieee_word(*h));}
static int active_swap(void *context){(void)context;swaps++;active_snapshot("swap");return 1;}
#define OBSERVER(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" "mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
OBSERVER(active_render) OBSERVER(active_hud) OBSERVER(active_flash)
int main(int argc,char **argv){
 if(argc<7||argc>10)return 2;int tail=argc>=8&&!strcmp(argv[7],"tail");storm=argc>=8&&!strcmp(argv[7],"storm");if(argc>=8&&!tail&&!storm)return 2;int weapon=argc>=9?atoi(argv[8]):50;if(argc>=9&&(!storm||!((weapon>=40&&weapon<=43)||(weapon>=50&&weapon<=53))))return 2;
 int pair=argc==10&&!strcmp(argv[9],"pair"),kill=argc==10&&!strcmp(argv[9],"kill");if(argc==10&&(!storm||weapon<51||weapon>53||(!pair&&!kill)))return 2;
 if(!freopen(argv[5],"w",stdout))return 2;clock_trace=fopen(argv[6],"w");if(!clock_trace)return 2;
 unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);world_globals=g;active_code=code;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);
 if(!strcmp(import_names[i],"TickCount"))f=active_tick;if(!strcmp(import_names[i],"NewPtrClear"))f=world_alloc;if(!strcmp(import_names[i],"DisposePtr"))f=world_dispose;if(!strcmp(import_names[i],"GetKeys"))f=active_keys;if(!strcmp(import_names[i],"aglSwapBuffers"))f=active_swap;if(!strcmp(import_names[i],"glLoadIdentity")||(storm&&!strncmp(import_names[i],"gl",2)))f=noop_gl;
 descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;storm_toc=toc;
 char path[2048];snprintf(path,sizeof path,"%s/Attr.bin",argv[4]);set_pointer(g,0xa94,read_file(path));snprintf(path,sizeof path,"%s/sprt.bin",argv[4]);set_pointer(g,0xe82,read_file(path));snprintf(path,sizeof path,"%s/Wpns.bin",argv[4]);set_pointer(g,0xa98,read_file(path));
 set_pointer(g,0x21c,literals);set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.0);*(uint32_t*)(g+0x380)=0x43300000;set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);
 set_short(g,0xed6,640);set_short(g,0xed8,480);set_pointer(g,0xa54,calloc(3001*4,sizeof(double)));set_double(g,0xa26,640);set_double(g,0xa36,380);set_short(g,0xa52,1);*(uint32_t*)(g+0x244)=0x12345678;
 set_short(g,0xa8a,weapon);set_short(g,0xa8e,1);set_short(g,0xab4,-1);*(uint32_t *)(g+0xa4a)=*(uint32_t *)(g+0xa4e)=100;
 set_short(g,0xcc2,55);set_short(g,0xcc4,58);set_short(g,0xcc6,126);set_short(g,0xcc8,125);set_short(g,0xcca,124);set_short(g,0xccc,123);
 jump_to(code+0x3ce84,world_sound_fb);jump_to(code+0x57afc,active_render_fb);jump_to(code+0x43134,active_hud_fb);if(!storm)jump_to(code+0x55878,active_flash_fb);else{jump_to(code+0x3a278,noop_gl);set_pointer(g,0xcd6,calloc(1,8));set_pointer(g,0x1004,calloc(7,0x108));}MakeDataExecutable(code,433284);
 FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;OSStatus err=FSPathMakeRef((const UInt8*)argv[3],&ref,NULL);if(!err)err=FSGetResourceForkName(&fork);if(!err)err=FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf);if(err)return 2;UseResFile(rf);
 if(storm){snprintf(path,sizeof(path),"%s.strings",argv[1]);unsigned char *expected=read_file(path);Handle actual=GetResource('STR#',25000);if(!actual||GetHandleSize(actual)!=6884||memcmp(*actual,expected,6884)){fputs("Reference STR#25000 differs from download3\n",stderr);return 2;}}
 phase="setup";tick=100;if(storm){unsigned char *target=spawn(code,toc,20,4,300,180);set_short(target,88,kill?1:30000);if(pair||kill){unsigned char *second=spawn(code,toc,20,4,350,190);set_short(second,88,30000);}}
 if(tail)spawn(code,toc,4,1,500,300);
 unsigned char *player=spawn(code,toc,1,1,100,180);set_pointer(g,0xa7a,player);set_short(player,24,12);set_short(player,26,3);set_short(player,88,200);*(uint32_t *)(player+8)=99;*(uint32_t *)(player+12)=100;*(uint32_t *)(player+16)=0;
 active_snapshot("initial");clock_enabled=1;phase="calc";invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);active_snapshot("return");
 fclose(clock_trace);fflush(stdout);if((!storm&&(disposed||entity_birth!=(tail?2:1)||render_birth!=(tail?2:1)))||(storm&&(!disposed||entity_birth<(weapon<50?2:3)||render_birth<3))||*(int16_t *)(g+0xa8e)!=0||*(int16_t *)player!=1||!serial)return 1;
 fprintf(stderr,"PASS active coupled original special%d tail%d clockreads%u renders%u swaps%u huds%u flashes%u entities%u rendersprites%u disposals%u\n",weapon,tail,serial,renders,swaps,huds,flashes,entity_birth,render_birth,disposed);return 0;
}
