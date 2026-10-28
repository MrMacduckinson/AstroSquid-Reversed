/* Real native normal/back sprite draws and list passes, with GL calls observed. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static unsigned quads;
static void noop(void){}
static void begin(unsigned mode){if(mode==7)quads++;}
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(20);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536),*info=calloc(1001,14);if(!g||!heap||!info)return 2;
 *(void **)(g+0x21c)=input(argv[2],11812);*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xe82)=info;
 unsigned char map[8]={0};*(short *)map=256;*(short *)(map+2)=256;*(void **)(g+0xcd6)=map;*(short *)(info+14+6)=4;*(short *)(info+14+8)=4;
 *(short *)(g+0xeda)=1;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(short *)(g+0xa82)=4;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strncmp(import_names[i],"gl",2))f=noop;if(!strcmp(import_names[i],"glBegin"))f=begin;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;MakeDataExecutable(code,433284);
 unsigned char nodes[12][312];memset(nodes,0,sizeof(nodes));for(int i=0;i<12;i++){unsigned char *s=nodes[i];*(double *)s=10;*(double *)(s+8)=10;*(double *)(s+16)=20;*(double *)(s+24)=20;*(short *)(s+32)=i+1;*(short *)(s+38)=1;if(i<11)*(void **)(s+300)=nodes[i+1];}
 *(double *)nodes[2]=640;*(double *)(nodes[3]+16)=.9;
 *(int32_t *)(g+0xece)=100;quads=0;invoke_fb(code+0x3a278,g,toc,nodes[0],NULL,NULL);if(*(int32_t *)(g+0xece)!=101||quads!=1)return 3;puts("normal,count_delta1,quads1");
 *(int32_t *)(g+0xece)=100;quads=0;invoke_fb(code+0x39390,g,toc,nodes[0],NULL,NULL);if(*(int32_t *)(g+0xece)!=101||quads<=1)return 3;printf("background,count_delta1,quads%u\n",quads);
 *(void **)(g+0xe86)=nodes;*(int32_t *)(g+0xece)=100;quads=0;invoke_fb(code+0x3aaf8,g,toc,NULL,NULL,NULL);if(*(int32_t *)(g+0xece)!=8)return 3;printf("menu,count8,quads%u\n",quads);
 *(int32_t *)(g+0xece)=100;quads=0;invoke_fb(code+0x57afc,g,toc,NULL,NULL,NULL);if(*(int32_t *)(g+0xece)!=7)return 3;printf("game,count7,quads%u\n",quads);
 puts("PASS native count per visible linked sprite, independent of tiled quad count; menu layers1..10/game2..10; clipped and integer-empty excluded; counters reset");return 0;
}
