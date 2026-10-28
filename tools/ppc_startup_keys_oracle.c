/* Original LMINITMINI key prefix, stopping before SYSTEM8 or any UI/audio setup. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <setjmp.h>
#include <unistd.h>
static jmp_buf stop;
static unsigned system_calls;
void startup_system(int selector){if(selector!=8)exit(3);system_calls++;longjmp(stop,1);}
extern void startup_system_fb(void);
__asm__(".text\n.align 2\n.globl _startup_system_fb\n_startup_system_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _startup_system\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static unsigned char *input(const char *path,long expected){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=expected)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(15);
 unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300);if(!g)return 2;
 *(void **)(g+0x21c)=input(argv[2],11812);uint32_t toc[489]={0};
 for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetKeys"))f=scripted_keys;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x24450,startup_system_fb);MakeDataExecutable(code,433284);unsigned cases=0;
 for(int debug=0;debug<3;debug++)for(int fullscreen=0;fullscreen<2;fullscreen++)for(int held=-1;held<129;held++){
  memset(scripted,0,sizeof(scripted));if(held>=0&&held<128)key(held);if(held==128){key(55);key(58);}
  *(short *)(g+0xede)=debug;*(short *)(g+0xee0)=fullscreen;*(short *)(g+0xee2)=99;key_calls=system_calls=0;
  if(!setjmp(stop))invoke_fb(code+0x37ec4,g,toc,NULL,NULL,NULL);
  int expected_debug=held==55||held==128?1:debug,expected_full=held==58||held==128?0:fullscreen;
  if(key_calls!=1||system_calls!=1||*(short *)(g+0xede)!=expected_debug||*(short *)(g+0xee0)!=expected_full||*(short *)(g+0xee2)!=0){fprintf(stderr,"startup mismatch debug%d fullscreen%d key%d\n",debug,fullscreen,held);return 3;}cases++;
 }
 printf("PASS original startup key prefix: %u cases; leftCmd55 latches debug1, leftOption58 clears fullscreen, other keys preserve initial flags; one GetKeys snapshot\n",cases);return 0;
}
