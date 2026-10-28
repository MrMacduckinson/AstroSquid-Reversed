/* Original INITSAGAIA prefix: stop before sound IO; all UI/GL boundaries observed. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static Handle strings;static unsigned phase,maps;
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
static uint32_t noop(void){return 0;}
void engine(void){if(phase)exit(3);phase=1;}
void picture(int id,double *x,double *y,double *w,double *h){if(phase!=1||id!=40||*x||*y||*w||*h)exit(3);phase=2;}
void swap(void){if(phase!=2)exit(3);phase=3;}
void message(unsigned char *text){const char *expected=phase==3?"Loading SpriteMaps...":"Loading Sound...";if((phase!=3&&phase!=4)||text[0]!=strlen(expected)||memcmp(text+1,expected,text[0])||(phase==4&&maps!=107))exit(3);phase++;}
void load(int id){if(phase!=4||id!=(int)maps||maps>=107)exit(3);maps++;}
void sound(void){if(phase!=5||maps!=107)exit(3);puts("PASS original startup: engine -> natural picture40 -> swap -> Loading SpriteMaps -> ordered0..106 map calls -> Loading Sound; probe stops before sound IO");exit(0);}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(engine) WRAP(picture) WRAP(swap) WRAP(message) WRAP(load) WRAP(sound) WRAP(noop)
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);*(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"glClear"))f=noop;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x2701c,noop_fb);jump_to(code+0x2754c,noop_fb);jump_to(code+0x27878,noop_fb);jump_to(code+0x37ec4,engine_fb);jump_to(code+0x3bb58,picture_fb);jump_to(code+0x35eb8,swap_fb);jump_to(code+0x3366c,message_fb);jump_to(code+0x33b40,load_fb);jump_to(code+0x3d4ec,sound_fb);MakeDataExecutable(code,433284);
 invoke_fb(code+0x65484,g,toc,NULL,NULL,NULL);return 3;
}
