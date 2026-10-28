/* Original fullscreen selection; AGL boundaries observed, no display changes. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static Handle strings;
static int target,current_ok,format_ok,context_ok,attempts,choose_calls,create_calls,current_calls,destroy_calls;
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
static void *choose(void *devices,int count,int *attrs){int expected[]={4,5,73,54,50,32,0};if(devices||count||memcmp(attrs,expected,sizeof(expected)))exit(3);choose_calls++;return format_ok?(void *)0x1234:NULL;}
static void *create(void *format,void *share){if(format!=(void *)0x1234||share)exit(3);create_calls++;return context_ok?(void *)0x5678:NULL;}
static int full(void *context,int width,int height,int hz,int device){if(context!=(void *)0x5678||width!=640||height!=480||device||hz!=200-attempts)exit(3);attempts++;return hz==target;}
static int current(void *context){if(context!=(void *)0x5678)exit(3);current_calls++;return current_ok;}
static void destroy(void *format){if(format!=(void *)0x1234)exit(3);destroy_calls++;}
void policy_message(void *message){(void)message;}
extern void policy_message_fb(void);
__asm__(".text\n.align 2\n.globl _policy_message_fb\n_policy_message_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _policy_message\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static unsigned char *input(const char *path,long expected){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=expected)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);*(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"aglChoosePixelFormat"))f=choose;if(!strcmp(import_names[i],"aglCreateContext"))f=create;if(!strcmp(import_names[i],"aglSetFullScreen"))f=full;if(!strcmp(import_names[i],"aglSetCurrentContext"))f=current;if(!strcmp(import_names[i],"aglDestroyPixelFormat"))f=destroy;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;jump_to(code+0x3366c,policy_message_fb);MakeDataExecutable(code,433284);
 int targets[]={200,199,60,56,0,200,200,200};
 for(int c=0;c<8;c++){
  target=targets[c];format_ok=c!=6;context_ok=c!=7;current_ok=c!=5;attempts=choose_calls=create_calls=current_calls=destroy_calls=0;
  *(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(void **)(g+0x38c)=heap;*(uint32_t *)(g+0xe8a)=0xdeadbeef;
  uint32_t result=invoke_fb(code+0x36898,g,toc,NULL,NULL,NULL);
  int expected=format_ok&&context_ok?(target?201-target:145):0;
  if(attempts!=expected||choose_calls!=1||create_calls!=format_ok||destroy_calls!=format_ok||current_calls!=(format_ok&&context_ok&&target!=0)||result!=(format_ok&&context_ok?0x5678u:0)||*(uint32_t *)(g+0xe8a)!=(format_ok&&context_ok&&target&&current_ok?0x5678u:0))return 3;
  printf("case%d,target%d,attempts%d,current%d,stored%08x,returned%08x\n",c,target,attempts,current_calls,*(uint32_t *)(g+0xe8a),result);
 }
 puts("PASS original fullscreen policy: exact descending200..56,firstsuccess,current gate,format/context failures; no real AGL display calls");return 0;
}
