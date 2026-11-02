/* Coupled original world oracle. No gameplay routine is replaced. The private
 * loaded FCOD copy only redirects SOUNDPLAYPAN to a semantic event observer;
 * native OS imports supply deterministic clock/allocation. Never launch on the
 * primary Mac. Compile/run only on original PowerPC reference hardware. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main

typedef struct {unsigned char *p;size_t size;unsigned id;int alive;} Allocation;
enum { ALLOCATION_LIMIT = 2097152, ALLOCATION_SLOTS = 4194304 };
static Allocation allocations[ALLOCATION_LIMIT];
static unsigned allocation_slots[ALLOCATION_SLOTS];static unsigned allocation_count,entity_birth,render_birth;
static unsigned char *world_globals;static const char *phase;
static unsigned allocation_slot(void *p){
 unsigned slot=(unsigned)(((uintptr_t)p>>4)*2654435761u)&(ALLOCATION_SLOTS-1);
 while(allocation_slots[slot]&&allocations[allocation_slots[slot]-1].p!=p)slot=(slot+1)&(ALLOCATION_SLOTS-1);
 return slot;
}
static Allocation *allocation(void *p){unsigned index=allocation_slots[allocation_slot(p)];return index?&allocations[index-1]:NULL;}
static unsigned identity(void *p){Allocation*a=allocation(p);if(!p)return 0;if(!a){fputs("Unregistered pointer in canonical state\n",stderr);exit(2);}return a->id;}
static void *world_alloc(long bytes){if(bytes<0||allocation_count==ALLOCATION_LIMIT)exit(2);unsigned char*p=calloc(1,bytes?bytes:1);if(!p)exit(2);unsigned id=bytes==106?++entity_birth:bytes==308?++render_birth:allocation_count+1;allocations[allocation_count++]=(Allocation){p,(size_t)bytes,id,1};allocation_slots[allocation_slot(p)]=allocation_count;return p;}
static void world_dispose(void *p){Allocation*a=allocation(p);if(!a){fputs("Unknown DisposePtr\n",stderr);exit(2);}a->alive=0;/* Retain storage to prevent host allocator pointer reuse affecting IDs. */}
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
#ifndef ASTRO_WORLD_ORACLE_LIBRARY
int main(int argc,char**argv){
 if(argc!=5&&argc!=6&&argc!=7){fputs("usage: ppc_world_oracle original.pef literals.bin original-app tables-dir [ticks] [parents]\n",stderr);return 2;}
 int parents=argc==7&&!strcmp(argv[6],"parents");
 unsigned steps=argc>=6?(unsigned)strtoul(argv[5],NULL,10):180;if(!steps||steps>36000)return 2;
 unsigned char*pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);world_globals=g;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void*f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))f=(void*)controlled_tick;if(!strcmp(import_names[i],"NewPtrClear"))f=(void*)world_alloc;if(!strcmp(import_names[i],"DisposePtr"))f=(void*)world_dispose;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:(void*)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 char path[2048];snprintf(path,sizeof path,"%s/Attr.bin",argv[4]);set_pointer(g,0xa94,read_file(path));snprintf(path,sizeof path,"%s/sprt.bin",argv[4]);set_pointer(g,0xe82,read_file(path));snprintf(path,sizeof path,"%s/Wpns.bin",argv[4]);set_pointer(g,0xa98,read_file(path));
 set_pointer(g,0x21c,literals);set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.0);*(uint32_t*)(g+0x380)=0x43300000;set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);
 set_short(g,0xed6,640);set_short(g,0xed8,480);
 set_pointer(g,0xa54,calloc(3001*4,sizeof(double)));set_double(g,0xa26,640);set_double(g,0xa36,380);set_double(g,0xa58,1);set_short(g,0xa52,1);*(uint32_t*)(g+0x244)=0x12345678;set_short(g,0xa8a,10);set_short(g,0xa8e,2);
 jump_to(code+0x3ce84,(void*)world_sound_fb);MakeDataExecutable(code,433284);
 FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;OSStatus err=FSPathMakeRef((const UInt8*)argv[3],&ref,NULL);if(!err)err=FSGetResourceForkName(&fork);if(!err)err=FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf);if(err){fprintf(stderr,"Original resources unavailable:%ld\n",(long)err);return 2;}UseResFile(rf);
 tick=0;phase="initial";unsigned char*player=spawn(code,toc,1,1,100,180);set_pointer(g,0xa7a,player);set_short(player,24,12);set_short(player,26,3);set_short(player,88,200);
 /* Real shipped enemy/turret, scenery/debris source and pickup constructors. */
 unsigned char*enemy=spawn(code,toc,7,3,300,180);set_short(enemy,88,1);
 unsigned char*rock=spawn(code,toc,20,4,200,250);set_short(rock,88,1);
 unsigned char *survivor=spawn(code,toc,7,3,450,100),*pickup=spawn(code,toc,40,1,160,180);
 if(parents){set_pointer(enemy,92,rock);set_pointer(rock,92,survivor);set_pointer(pickup,92,enemy);set_double(survivor,72,2.75);set_double(survivor,80,-1.125);}
 world_invoke5(code+0x54248,g,toc,(void*)1,(void*)300,(void*)180,(void*)0,player);
 world_invoke5(code+0x54248,g,toc,(void*)1,(void*)200,(void*)250,(void*)0,player);snapshot();
 for(tick=1;tick<=steps;tick++){
  unsigned keys=(tick/30)%16;set_short(g,0xaac,keys&1?-1:0);set_short(g,0xaae,keys&2?-1:0);set_short(g,0xaa8,keys&4?-1:0);set_short(g,0xaaa,keys&8?-1:0);set_short(g,0xab2,tick%7==0?-1:0);
  phase="calc";invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);snapshot();
  phase="cleanup";invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);snapshot();
  phase="animate";invoke_fb(code+0x3b55c,g,toc,NULL,NULL,NULL);snapshot();
 }
 fprintf(stderr,"PASS: original coupled world %u ticks entities-created=%u render-created=%u\n",steps,entity_birth,render_birth);return 0;
}
#endif
