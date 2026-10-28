/* Original INITSAGAIA prefix: stop before menu allocation; all UI/GL boundaries observed. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static Handle strings;static unsigned phase,maps,tracks,volumes;static unsigned char *globals;
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
static uint32_t noop(void){return 0;}
void engine(void){if(phase)exit(3);phase=1;}
void picture(int id,double *x,double *y,double *w,double *h){if(phase!=1||id!=40||*x||*y||*w||*h)exit(3);phase=2;}
void swap(void){if(phase!=2)exit(3);phase=3;}
void message(unsigned char *text){
 const char *expected=phase==3?"Loading SpriteMaps...":phase==4?"Loading Sound...":phase==7?"Loading Music...":phase==9?"Loading Misc. Resources...":NULL;
 if(!expected||text[0]!=strlen(expected)||memcmp(text+1,expected,text[0])||(phase==4&&maps!=107))exit(3);phase++;
}
void load(int id){if(phase!=4||id!=(int)maps||maps>=107)exit(3);maps++;}
void sound(void){if(phase!=5||maps!=107)exit(3);phase=6;}
int sound_volume(double *value,int channel){if(phase!=6||channel!=1||*value!=0)exit(3);phase=7;return 0;}
int system_value(int selector){if(selector!=1)exit(3);return 123;}
int folder(int volume){if(volume!=123)exit(3);unsigned char *p=*(unsigned char **)(globals+0x38c)-256;*(void **)(globals+0x38c)=p;if(p[0]!=4||memcmp(p+1,"Data",4))exit(3);return 123;}
unsigned track(unsigned char *name,int volume){if(phase!=8||tracks>=3||volume!=123)exit(3);char expected[]="Music1.mp3";expected[5]+=(char)tracks;if(name[0]!=10||memcmp(name+1,expected,10))exit(3);return 101+tracks++;}
void music_volume(unsigned handle,int value){if(phase!=8||tracks!=3||volumes>=2||handle!=101+volumes||value)exit(3);volumes++;}
void play(unsigned handle){if(phase!=8||tracks!=3||volumes!=2||handle!=101)exit(3);phase=9;}
void misc(void){if(phase!=10)exit(3);phase=11;}
void weapons(void){if(phase!=11)exit(3);phase=12;}
void sprites(void){if(phase!=12)exit(3);phase=13;}
void vector(void){if(phase!=13)exit(3);phase=14;}
void controls(void){if(phase!=14)exit(3);puts("PASS native startup: maps -> sound/volume -> tracks/volumes -> play1 -> misc/weapon/sprite/vector initialization -> menu controls; stops before menu allocation");exit(0);}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(engine) WRAP(picture) WRAP(swap) WRAP(message) WRAP(load) WRAP(sound) WRAP(noop) WRAP(sound_volume) WRAP(system_value) WRAP(folder) WRAP(track) WRAP(music_volume) WRAP(play) WRAP(misc) WRAP(weapons) WRAP(sprites) WRAP(vector) WRAP(controls)
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;globals=g;*(short *)(g+0xaba)=60;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);*(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"glClear"))f=noop;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x2701c,noop_fb);jump_to(code+0x2754c,noop_fb);jump_to(code+0x27878,noop_fb);jump_to(code+0x37ec4,engine_fb);jump_to(code+0x3bb58,picture_fb);jump_to(code+0x35eb8,swap_fb);jump_to(code+0x3366c,message_fb);jump_to(code+0x33b40,load_fb);jump_to(code+0x3d4ec,sound_fb);jump_to(code+0x3d254,sound_volume_fb);jump_to(code+0x24450,system_value_fb);jump_to(code+0xce40,folder_fb);jump_to(code+0x30750,track_fb);jump_to(code+0x32c78,music_volume_fb);jump_to(code+0x31edc,play_fb);jump_to(code+0x65094,misc_fb);jump_to(code+0x65334,weapons_fb);jump_to(code+0x651e4,sprites_fb);jump_to(code+0x5257c,vector_fb);jump_to(code+0x64154,controls_fb);MakeDataExecutable(code,433284);
 invoke_fb(code+0x65484,g,toc,NULL,NULL,NULL);return 3;
}
