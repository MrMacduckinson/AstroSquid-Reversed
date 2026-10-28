/* Native _RANDOM seeding, with scripted GetDateTime only; no actual clock reads. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static uint32_t scriptedTime;static unsigned clockReads;
static void clock_value(uint32_t *out){clockReads++;*out=scriptedTime;}
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=2)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300);if(!g)return 2;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetDateTime"))f=clock_value;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;MakeDataExecutable(code,433284);
 for(unsigned value=1;value<=10000;value++){clockReads=0;*(uint32_t *)(g+0x244)=0xdeadbeef;invoke_fb(code+0x3884,g,toc,(void *)(uintptr_t)value,NULL,NULL);uint32_t expected=value*UINT32_C(1664525)+UINT32_C(1013904223);if(clockReads||*(uint32_t *)(g+0x244)!=expected)return 3;}
 const int32_t arguments[]={0,-1,INT32_MIN};const uint32_t times[]={0,1,123,0x80000000u,0xffffffffu};
 for(unsigned a=0;a<3;a++)for(unsigned t=0;t<5;t++){clockReads=0;scriptedTime=times[t];*(uint32_t *)(g+0x244)=0xdeadbeef;invoke_fb(code+0x3884,g,toc,(void *)(uintptr_t)(uint32_t)arguments[a],NULL,NULL);uint32_t expected=scriptedTime*UINT32_C(1664525)+UINT32_C(1013904223);if(clockReads!=1||*(uint32_t *)(g+0x244)!=expected)return 3;printf("arg%d,time%08x,reads1,seed%08x\n",arguments[a],scriptedTime,expected);}
 puts("PASS native RANDOM:10000 positive seeds without clock;15 nonpositive/time/wrap cases read once and discard exactly one FBrnd(1) step");return 0;
}
