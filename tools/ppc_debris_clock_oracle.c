/* Original shrapnel and whole CALC kind20 branch with independent clock reads. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
static unsigned char *code_base,*entity_current;static uint32_t values[8];static unsigned calls,limit;
static uint64_t word(double v){uint64_t u;memcpy(&u,&v,8);return u;}
uint32_t clock_value(uintptr_t pc){if(calls>=limit){fputs("clockexhaustion\n",stderr);exit(3);}uint32_t v=values[calls];printf("T,%u,%08x,%u,%u,%u,%d\n",calls++,(unsigned)(pc-(uintptr_t)code_base-4+0x10000000u),v,*(uint32_t*)(entity_current+8),*(uint32_t*)(entity_current+12),*(int16_t*)(entity_current+70));return v;}
extern void clock_fb(void);
__asm__(".text\n.align 2\n.globl _clock_fb\n_clock_fb:\nstw r2,20(r1)\nmflr r3\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _clock_value\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
int main(int argc,char**argv){
 if(argc!=3)return 2;unsigned char*pef=read_file(argv[1]),*code=pef+128,*lit=read_file(argv[2]);code_base=code;unsigned char*g=calloc(1,0x1300),*heap=calloc(1,0x10000),*attrs=calloc(441,30);uint32_t toc[489]={0};
 for(int i=0;i<484;i++){void*fn=dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:(void*)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
 set_pointer(g,0x21c,lit);set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.0);*(uint32_t*)(g+0x380)=0x43300000;set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);set_pointer(g,0xa94,attrs);toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x694e4,(void*)clock_fb);*(uint32_t*)(code+0x42234)=0x4e800020;*(uint32_t*)(code+0x549e8)=0x4e800020;MakeDataExecutable(code,433284);
 static const uint32_t schedules[12][5]={{0},{106,100,145},{107,200,100,146},{106,101,202,145},{107,200,101,202,146},{106,100,145},{100},{101,205},{0x80000000u,0x80000003u},{0x7fffffffu},{0x80000000u,0x80000000u,0x80000002u,0x8000002du},{106,100,145}};
 static const unsigned lengths[]={0,3,4,4,5,3,1,2,2,1,4,3};
 for(int n=0;n<12;n++){
  unsigned char e[128]={0},render[312]={0};entity_current=e;int kind=n>=6&&n<=9?20:4,state=n==0||kind==20?2:1,remove=n==11?-1:0;uint32_t update=n==8||n==10?0x7fffffffu:n==9?0x80000000u:100,anim=n==10?0x7fffffffu:100,action=n==10?0x7fffffffu:100;int right=n==5?99:101;double left=kind==20?0:100,gravity=n%2?.3:-.2;
  calls=0;limit=lengths[n];memcpy(values,schedules[n],sizeof(values[0])*5);set_short(e,0,kind);set_short(e,4,state);set_short(e,24,2);set_short(e,70,remove);*(uint32_t*)(e+8)=update;*(uint32_t*)(e+12)=anim;*(uint32_t*)(e+16)=action;set_double(e,72,.125);set_double(e,80,-.25);set_short(e,42,right);set_short(e,68,kind==20?200:42);set_pointer(e,62,render);set_pointer(g,0xa76,e);set_double(render,0,300);set_double(render,8,200);set_double(render,16,20);set_double(render,24,20);set_double(g,0xa1e,left);set_double(g,0xa26,640);set_double(g,0xa2e,0);set_double(g,0xa36,380);set_double(g,0xaa0,gravity);
  printf("CASE,%d,%d,%d,2,%d,%u,%u,%u,%016llx,%016llx,%d,%016llx,%016llx,%u\n",n,kind,state,remove,update,anim,action,(unsigned long long)word(.125),(unsigned long long)word(-.25),right,(unsigned long long)word(left),(unsigned long long)word(gravity),limit);
  invoke_fb(code+(kind==20?0x54c64:0x636a0),g,toc,e,NULL,NULL);
  printf("O,%d,%d,%d,%d,%u,%u,%u,%016llx,%016llx\n",*(int16_t*)e,*(int16_t*)(e+4),*(int16_t*)(e+24),*(int16_t*)(e+70),*(uint32_t*)(e+8),*(uint32_t*)(e+12),*(uint32_t*)(e+16),(unsigned long long)word(*(double*)(e+72)),(unsigned long long)word(*(double*)(e+80)));if(calls!=limit)return 4;
 }
 return 0;
}
