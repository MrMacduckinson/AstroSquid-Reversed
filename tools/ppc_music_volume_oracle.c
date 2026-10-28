/* Original MIDWorld default and volume clamps; QuickTime entry/volume calls observed only. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static unsigned enters,volumeCalls,stopCalls,playCalls;static int lastVolume;
static int version(void){return 1;}static int folder(void){return 17;}
static OSErr enter(void){enters++;return 0;}static uint32_t tick(void){return 456;}
static void movie_volume(void *movie,short volume){if(movie!=(void *)0x1234)exit(3);volumeCalls++;lastVolume=volume;}
void star_move(void){}
void stop_track(void){if(playCalls)exit(3);stopCalls++;}
void play_track(unsigned handle){if(stopCalls!=1||handle!=0x3456||playCalls++)exit(3);}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(version) WRAP(folder) WRAP(star_move) WRAP(stop_track) WRAP(play_track)
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300);if(!g)return 2;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"EnterMovies"))f=enter;if(!strcmp(import_names[i],"TickCount"))f=tick;if(!strcmp(import_names[i],"SetMovieVolume"))f=movie_volume;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;jump_to(code+0x2fee8,version_fb);jump_to(code+0x32334,folder_fb);MakeDataExecutable(code,433284);
 invoke_fb(code+0x325c8,g,toc,NULL,NULL,NULL);Handle state=*(Handle *)(g+0xfe8);if(!state||*(short *)(*state+6)!=126||enters!=1)return 3;invoke_fb(code+0x325c8,g,toc,NULL,NULL,NULL);if(enters!=1)return 3;
 for(int n=-32768;n<=32767;n++){short out=-300;invoke_fb(code+0x32be4,g,toc,(void *)(uintptr_t)(uint32_t)n,&out,NULL);int expected=n<-126?-126:n>126?126:n;if(out!=expected)return 3;}
 Handle track=NewHandleClear(82);if(!track)return 2;*(uint32_t *)(*track+2)=0x1234;
 for(int step=0;step<=10;step++){int n=(int)(12.8*step),expected=n>126?126:n;volumeCalls=0;invoke_fb(code+0x32c78,g,toc,track,(void *)(uintptr_t)n,NULL);if(volumeCalls!=1||lastVolume!=expected)return 3;printf("step%d,native_volume%d\n",step,lastVolume);}
 unsigned char *heap=calloc(1,65536),*entity=calloc(1,106),*render=calloc(1,308),*attrs=calloc(442,30);if(!heap||!entity||!render||!attrs)return 2;
 *(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xa94)=attrs;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 *(void **)(g+0xa76)=entity;*(void **)(g+0xa46)=(void *)0x3456;
 jump_to(code+0x42234,star_move_fb);jump_to(code+0x31af4,stop_track_fb);jump_to(code+0x31edc,play_track_fb);MakeDataExecutable(code,433284);
 for(int tag=-1;tag<=1;tag++)for(int step=0;step<=10;step++){
  memset(entity,0,106);*(short *)entity=39;*(short *)(entity+2)=9;*(short *)(entity+68)=399;*(short *)(entity+96)=tag;*(void **)(entity+62)=render;
  *(double *)render=100;*(double *)(render+8)=100;*(double *)(render+16)=10;*(double *)(render+24)=10;
  *(short *)(g+0xabc)=step;*(short *)(g+0x5ac)=0;stopCalls=playCalls=volumeCalls=0;
  invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);
  if(stopCalls!=(unsigned)(tag!=-1)||playCalls!=(unsigned)(tag!=-1&&step>0)||volumeCalls||*(short *)(entity+70)!=(tag!=-1)||*(short *)(g+0x5ac)!=(tag==-1))return 3;
 }
 puts("PASS33 actual native trigger399 cases: tag-1 no audio; other tag stop first, play3 only when music setting>0; no volume change");
 DisposeHandle(track);DisposeHandle(state);puts("PASS original MIDWorld default126, idempotent init,65536 signed clamps and11 slider SetMovieVolume values");return 0;
}
