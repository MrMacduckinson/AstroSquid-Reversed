/* Actual SOUNDSETVOLUME; capture commands without opening audio devices. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned level,mask,flag,commands;
static OSErr command(SndChannelPtr channel,const SndCommand *c){unsigned i=(unsigned)(uintptr_t)channel;assert(i>=1&&i<=6&&c->cmd==43&&c->param2==0);printf("C,%u,%u,%u,%u,%d,%d\n",level,mask,flag,i,c->cmd,c->param1);commands++;return 0;}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1400),*heap=calloc(1,65536),*channels=calloc(7,264);assert(g&&heap&&channels);
 uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"SndDoImmediate"))fn=command;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0x1004)=channels;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;MakeDataExecutable(code,433284);
 for(level=0;level<=10;level++)for(mask=0;mask<3;mask++)for(flag=0;flag<2;flag++){
  for(unsigned i=1;i<=6;i++)*(void **)(channels+i*264)=mask==2||(mask==1&&(i==1||i==3||i==6))?(void *)i:NULL;
  double volume=level/20.;commands=0;uint32_t result=invoke_fb(code+0x3d254,g,toc,&volume,(void *)flag,NULL);uint64_t bits;memcpy(&bits,g+0x100a,8);
  printf("F,%u,%u,%u,%016llx,%u,%u\n",level,mask,flag,bits,commands,result);assert(commands==(flag?(mask==2?6:mask==1?3:0):0));
 }
 fputs("PASS66 original amplitude profiles;99 ordered ampCmd channel commands\n",stderr);return 0;
}
