/* Native LMSPRITEINVIEW: real Carbon rectangle intersection, no rendering. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
static void noop(void){}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(20);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300);if(!g)return 2;
 *(void **)(g+0x21c)=input(argv[2],11812);*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strncmp(import_names[i],"gl",2))f=noop;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;MakeDataExecutable(code,433284);
 double xs[]={-21,-20,-19.9,-1.9,-.9,0,.9,639,639.9,640,640.9,641},ys[]={-21,-20,-19.9,-1.9,-.9,0,.9,379.9,380,479,479.9,480,480.9},sizes[]={0,.9,1,1.9,20},cameras[]={0,-.75,.75};unsigned cases=0,visible=0;
 for(unsigned mode=0;mode<3;mode++)for(unsigned cx=0;cx<3;cx++)for(unsigned cy=0;cy<3;cy++)for(unsigned x=0;x<12;x++)for(unsigned y=0;y<13;y++)for(unsigned w=0;w<5;w++)for(unsigned h=0;h<5;h++){
  double sprite[]={xs[x],ys[y],sizes[w],sizes[h]};*(double *)(g+0xea2)=cameras[cx];*(double *)(g+0xeaa)=cameras[cy];*(short *)(g+0xeda)=mode;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;
  int left=(int)(sprite[0]+cameras[cx]),top=(int)(sprite[1]+cameras[cy]),right=left+(int)sprite[2],bottom=top+(int)sprite[3];
  int expected=mode!=1||(right>left&&bottom>top&&right>0&&bottom>0&&left<640&&top<480);
  unsigned actual=invoke_fb(code+0x391dc,g,toc,sprite,NULL,NULL)&255;
  if(actual!=(unsigned)expected){fprintf(stderr,"Mismatch mode%u x%.17g y%.17g w%.17g h%.17g camera%.17g/%.17g actual%u expected%d\n",mode,sprite[0],sprite[1],sprite[2],sprite[3],cameras[cx],cameras[cy],actual,expected);return 3;}cases++;visible+=actual;
 }
 *(short *)(g+0xa82)=4;*(int32_t *)(g+0xece)=123;*(int32_t *)(g+0xed2)=456;
 invoke_fb(code+0x57afc,g,toc,NULL,NULL,NULL);if(*(int32_t *)(g+0xece)||*(int32_t *)(g+0xed2))return 3;
 *(int32_t *)(g+0xece)=123;*(int32_t *)(g+0xed2)=456;invoke_fb(code+0x3aaf8,g,toc,NULL,NULL,NULL);if(*(int32_t *)(g+0xece)||*(int32_t *)(g+0xed2))return 3;
 puts("PASS empty game and menu sprite passes reset signed32 sprite and area counters");
 printf("PASS %u native visibility cases,%u visible; signed integer truncation, empty rectangles, camera fractions, 640x480 bounds and culling==1 gate\n",cases,visible);return 0;
}
