/* Original CLOSEDOWN boundary order; no real resources/files changed. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static unsigned step;static unsigned char *globals;
static void next(unsigned expected){if(step++!=expected)exit(3);}
void prefs(void){next(0);}void graphics(void){next(1);}void sound(void){next(2);}void world(void){next(3);}
void track(void *handle){if(step==4&&handle==globals+0xa3e)next(4);else if(step==5&&handle==globals+0xa42)next(5);else exit(3);}
void media(void){next(6);}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(prefs) WRAP(graphics) WRAP(sound) WRAP(world) WRAP(track) WRAP(media)
static unsigned char *input(const char *path,long expected){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=expected)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=2)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300);if(!g)return 2;
 globals=g;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){descriptors[i][0]=(uint32_t)(uintptr_t)missing;toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x3dee8,prefs_fb);jump_to(code+0x38ecc,graphics_fb);jump_to(code+0x3d6d8,sound_fb);jump_to(code+0x529f8,world_fb);jump_to(code+0x31d18,track_fb);jump_to(code+0x32a68,media_fb);MakeDataExecutable(code,433284);
 for(unsigned c=0;c<4;c++){step=0;*(short *)(g+0x58e)=c;invoke_fb(code+0x66c74,g,toc,NULL,NULL,NULL);if(step!=7||*(short *)(g+0x58e)!=1)return 3;printf("case%u,prefs-graphics-sound-world-track1-track2-media,quit1\n",c);}
 puts("PASS original CLOSEDOWN seven ordered boundaries and final quit store");return 0;
}
