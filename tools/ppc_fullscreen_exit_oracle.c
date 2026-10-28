/* Original LMEXIT cleanup ordering; graphics/destruction boundaries observed only. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static Handle strings;
static unsigned step,context_value,dsp_value,failures;
static void expect_step(unsigned expected){if(step++!=expected)exit(3);}
static int current(void *context){if(context)exit(3);expect_step(108);return !failures;}
static int drawable(void *context,void *port){if((uintptr_t)context!=context_value||port)exit(3);expect_step(109);return !failures;}
static int destroy_context(void *context){if((uintptr_t)context!=context_value)exit(3);expect_step(110);return !failures;}
static int dsp_state(void *context,int state){if((uintptr_t)context!=dsp_value||state!=2)exit(3);expect_step(111);return failures?-1:0;}
static int dsp_release(void *context){if((uintptr_t)context!=dsp_value)exit(3);expect_step(112);return failures?-1:0;}
static void dsp_shutdown(void){expect_step(113);}
void kill_map(int index){if(index<0||index>=107)exit(3);expect_step(index);}
void kill_list(void){expect_step(107);}
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
void policy_message(void *message){(void)message;}
extern void policy_message_fb(void);
__asm__(".text\n.align 2\n.globl _policy_message_fb\n_policy_message_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _policy_message\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
extern void kill_map_fb(void),kill_list_fb(void);
#define WRAP(name) __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(kill_map) WRAP(kill_list)
static unsigned char *input(const char *path,long expected){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=expected)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);*(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"aglSetCurrentContext"))f=current;if(!strcmp(import_names[i],"aglSetDrawable"))f=drawable;if(!strcmp(import_names[i],"aglDestroyContext"))f=destroy_context;if(!strcmp(import_names[i],"DSpContext_SetState"))f=dsp_state;if(!strcmp(import_names[i],"DSpContext_Release"))f=dsp_release;if(!strcmp(import_names[i],"DSpShutdown"))f=dsp_shutdown;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;jump_to(code+0x3366c,policy_message_fb);jump_to(code+0x34178,kill_map_fb);jump_to(code+0x34edc,kill_list_fb);MakeDataExecutable(code,433284);
 for(unsigned c=0;c<8;c++){
  context_value=c&1?0x5678:0;dsp_value=c&2?0x9abc:0;failures=c&4?1:0;step=0;
  *(uint32_t *)(g+0xe8a)=context_value;*(uint32_t *)(g+0xe8e)=dsp_value;*(void **)(g+0x38c)=heap;
  for(unsigned i=0;i<107;i++){uint32_t value=i&1?i+1:0;memcpy(g+0xcd6+4*i,&value,4);}
  invoke_fb(code+0x38ecc,g,toc,NULL,NULL,NULL);
  if(step!=(dsp_value?114u:111u)||*(uint32_t *)(g+0xe8a)!=context_value||*(uint32_t *)(g+0xe8e)!=dsp_value)return 3;
  printf("case%u,context%04x,dsp%04x,import_failures%u,events%u\n",c,context_value,dsp_value,failures,step);
 }
 puts("PASS original LMEXIT order:107 map calls,list,currentNULL,detach,destroy,optionalDSp2/release/shutdown; import failures ignored; globals retained");return 0;
}
