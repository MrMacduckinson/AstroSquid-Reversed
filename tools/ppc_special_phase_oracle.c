/* Original timed plasma with the phase host test's controlled clock boundaries.
   G5 only. Reuses private original loading, allocation and ABI bridges. */
#define main existing_active_world_oracle_main
#include "ppc_active_special_world_oracle.c"
#undef main
static unsigned char *phase_globals,*calc_original,*animate_original;
static uint32_t *phase_toc;
static unsigned phase_case,phase_reads,phase_calcs,phase_frames,phase_swaps;
static int phase_enabled,phase_fixed;
static uint32_t phase_tick(void){
 if(!phase_enabled)return tick=100;
 if(phase_fixed)return tick;
 if(phase_reads>40000)exit(3);
 if(phase_case==6){const uint32_t values[]={100,100,100,131};if(phase_reads>=4)exit(3);tick=values[phase_reads++];}
 else tick=100+phase_reads++/1000;
 return tick;
}
void phase_calc(void){phase_calcs++;phase_fixed=1;invoke_fb(calc_original,phase_globals,phase_toc,NULL,NULL,NULL);phase_fixed=0;}
void phase_animate(void){phase_fixed=1;invoke_fb(animate_original,phase_globals,phase_toc,NULL,NULL,NULL);phase_fixed=0;}
void phase_render(void){phase_frames++;}
void phase_sound(void){}
static int phase_swap(void *context){(void)context;phase_swaps++;return 1;}
OBSERVER(phase_calc) OBSERVER(phase_animate) OBSERVER(phase_render) OBSERVER(phase_sound)
static unsigned char *intercept(unsigned char *at,void *callback){
 unsigned char *original=malloc(32);if(!original)exit(2);memcpy(original,at,16);
 uint32_t *words=(uint32_t *)at;
 if(words[0]!=0x7c0802a6||words[1]!=0x90010008||words[2]!=0xbda1ffa0||(words[3]>>16)!=0x9421){fputs("Unexpected trampoline prologue\n",stderr);exit(2);}
 /* Checked save/link/stack prologues have no PC-relative instructions. */
 jump_to(original+16,at+16);MakeDataExecutable(original,32);jump_to(at,callback);return original;
}
static unsigned char *phase_input(const char *path,long expected){
 FILE *f=fopen(path,"rb");if(!f){perror(path);exit(2);}
 if(fseek(f,0,SEEK_END)||ftell(f)!=expected){fclose(f);fputs("Wrong phase input size\n",stderr);exit(2);}fclose(f);return read_file(path);
}
int main(int argc,char **argv){
 if(argc!=6)return 2;if(argv[5][0]<'0'||argv[5][0]>'6'||argv[5][1])return 2;storm=1;phase_case=(unsigned)(argv[5][0]-'0');alarm(20);
 unsigned char *pef=phase_input(argv[1],455780),*code=pef+128,*lit=phase_input(argv[2],11812),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);phase_globals=world_globals=g;
 uint32_t toc[489]={0};phase_toc=toc;
 for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);
  if(!strcmp(import_names[i],"TickCount"))f=phase_tick;if(!strcmp(import_names[i],"NewPtrClear"))f=world_alloc;if(!strcmp(import_names[i],"DisposePtr"))f=world_dispose;
  if(!strcmp(import_names[i],"GetKeys"))f=active_keys;if(!strcmp(import_names[i],"aglSwapBuffers"))f=phase_swap;if(!strncmp(import_names[i],"gl",2))f=noop_gl;
  descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 char path[2048];const char *files[]={"Attr.bin","sprt.bin","Wpns.bin"};int offsets[]={0xa94,0xe82,0xa98},sizes[]={13230,14014,12532};
 for(int i=0;i<3;i++){snprintf(path,sizeof(path),"%s/%s",argv[4],files[i]);set_pointer(g,offsets[i],phase_input(path,sizes[i]));}
 set_pointer(g,0x21c,lit);set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.);*(uint32_t *)(g+0x380)=0x43300000;
 set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);set_pointer(g,0xa54,calloc(3001*4,sizeof(double)));
 set_double(g,0xa26,640);set_double(g,0xa36,380);set_short(g,0xed6,640);set_short(g,0xed8,480);
 const int intervals[]={2,3,0,-1,3,3,3};set_short(g,0xa52,intervals[phase_case]);*(uint32_t *)(g+0x244)=12345;
 *(uint32_t *)(g+0xa4a)=100;*(uint32_t *)(g+0xa4e)=phase_case==0?99:phase_case==5?98:100;
 set_short(g,0xa8a,40);set_short(g,0xcc2,55);set_short(g,0xcc4,58);set_short(g,0xcc6,126);set_short(g,0xcc8,125);set_short(g,0xcca,124);set_short(g,0xccc,123);
 set_pointer(g,0xcd6,calloc(1,8));set_pointer(g,0x1004,calloc(7,0x108));
 jump_to(code+0x3ce84,phase_sound_fb);jump_to(code+0x57afc,phase_render_fb);jump_to(code+0x43134,noop_gl);jump_to(code+0x3a278,noop_gl);
 calc_original=intercept(code+0x54c64,phase_calc_fb);animate_original=intercept(code+0x3b55c,phase_animate_fb);MakeDataExecutable(code,433284);
 FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;OSStatus err=FSPathMakeRef((const UInt8*)argv[3],&ref,NULL);if(!err)err=FSGetResourceForkName(&fork);if(!err)err=FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf);if(err)return 2;UseResFile(rf);
 snprintf(path,sizeof(path),"%s.strings",argv[1]);unsigned char *expected=phase_input(path,6884);Handle actual=GetResource('STR#',25000);
 if(!actual||GetHandleSize(actual)!=6884||memcmp(*actual,expected,6884)){fputs("Reference STR#25000 differs\n",stderr);return 2;}
 unsigned char *player=spawn(code,toc,1,1,100,180);set_pointer(g,0xa7a,player);set_short(player,24,12);set_short(player,26,3);set_short(player,88,200);
 *(uint32_t *)(player+8)=99;*(uint32_t *)(player+12)=100;*(uint32_t *)(player+16)=0;set_double(player,72,2);
 phase_enabled=1;world_invoke5(code+0x5bd0c,g,toc,(void *)40,(void *)174,(void *)192,NULL,player);
 printf("%u,%d,%u,%u,%u,%u,%u,%u,%u,%u,%u\n",phase_case,intervals[phase_case],phase_calcs,entity_birth-1,phase_reads,*(uint32_t *)(player+16),*(uint32_t *)(g+0xa4a),*(uint32_t *)(g+0xa4e),tick,phase_frames,phase_swaps);
 if(phase_calcs!=entity_birth-1||phase_frames!=phase_swaps||*(int16_t *)player!=1)return 3;
 return 0;
}
