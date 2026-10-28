/* Real original AGL fullscreen/deactivation on G5 with parent display recovery. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
#include <AGL/agl.h>
#include <DrawSprocket/DrawSprocket.h>
#include <OpenGL/gl.h>
#include <sys/wait.h>
#include <signal.h>
#include <errno.h>
static Handle strings;
static int attempts,successful_hz,format_calls,context_calls;
static AGLPixelFormat live_choose(const AGLDevice *devices,GLint count,const GLint *attrs){format_calls++;AGLPixelFormat f=aglChoosePixelFormat(devices,count,attrs);printf("pixel_format_available%d\n",f!=NULL);return f;}
static AGLContext live_create(AGLPixelFormat format,AGLContext share){context_calls++;AGLContext c=aglCreateContext(format,share);printf("context_available%d\n",c!=NULL);return c;}
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
static GLboolean full(AGLContext context,GLsizei width,GLsizei height,GLsizei hz,GLint device){
 if(width!=640||height!=480||hz!=200-attempts||device)exit(3);attempts++;
 GLboolean result=aglSetFullScreen(context,width,height,hz,device);if(result)successful_hz=hz;return result;
}
static int mode_int(CFDictionaryRef mode,CFStringRef key){int value=0;CFNumberRef n=(CFNumberRef)CFDictionaryGetValue(mode,key);if(n)CFNumberGetValue(n,kCFNumberIntType,&value);return value;}
static void print_mode(const char *phase){CFDictionaryRef mode=CGDisplayCurrentMode(CGMainDisplayID());if(!mode){printf("%s,mode_unavailable\n",phase);return;}printf("%s,width%d,height%d,bpp%d,hz%d\n",phase,mode_int(mode,kCGDisplayWidth),mode_int(mode,kCGDisplayHeight),mode_int(mode,kCGDisplayBitsPerPixel),mode_int(mode,kCGDisplayRefreshRate));}
void policy_message(void *message){(void)message;}
extern void policy_message_fb(void);
__asm__(".text\n.align 2\n.globl _policy_message_fb\n_policy_message_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _policy_message\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static unsigned char *input(const char *path,long expected){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=expected)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4&&argc!=5)return 2;int dsp_requested=argc==5&&!strcmp(argv[4],"--dsp");setvbuf(stdout,NULL,_IONBF,0);
 if(argc==4||dsp_requested){
  CFDictionaryRef initial=CGDisplayCurrentMode(CGMainDisplayID());if(!initial)return 3;CFDictionaryRef before=CFDictionaryCreateCopy(NULL,initial);if(!before)return 3;print_mode("before");
  pid_t child=fork();if(child<0)return 3;if(!child){execl(argv[0],argv[0],argv[1],argv[2],argv[3],dsp_requested?"--dsp-child":"--child",NULL);_exit(2);}
  int status=0,done=0;for(unsigned i=0;i<150;i++){pid_t p=waitpid(child,&status,WNOHANG);if(p==child){done=1;break;}if(p<0&&errno!=EINTR)break;usleep(100000);}
  if(!done){kill(child,SIGKILL);if(waitpid(child,&status,0)!=child)return 3;}
  CFDictionaryRef after=CGDisplayCurrentMode(CGMainDisplayID());int same=after&&CFEqual(before,after);
  if(!same){CGError err=CGDisplaySwitchToMode(CGMainDisplayID(),before);printf("recovery_required,error%d\n",err);}
  after=CGDisplayCurrentMode(CGMainDisplayID());int restored=after&&CFEqual(before,after);print_mode("after");CFRelease(before);
  printf("child_done%d,exit%d,native_restore%d,final_restore%d\n",done,WIFEXITED(status)?WEXITSTATUS(status):-1,same,restored);
  if(!done||!WIFEXITED(status)||!same||!restored)return 3;return WEXITSTATUS(status);
 }
 int dsp_child=!strcmp(argv[4],"--dsp-child");if(strcmp(argv[4],"--child")&&!dsp_child)return 2;alarm(12);
 ProcessSerialNumber psn={0,kCurrentProcess};if(TransformProcessType(&psn,kProcessTransformToForegroundApplication))return 3;
 SetFrontProcess(&psn);
unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);*(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"aglSetFullScreen"))f=full;if(!strcmp(import_names[i],"aglChoosePixelFormat"))f=live_choose;if(!strcmp(import_names[i],"aglCreateContext"))f=live_create;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;jump_to(code+0x3366c,policy_message_fb);MakeDataExecutable(code,433284);
 *(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(void **)(g+0x38c)=heap;
 uint32_t context=0,active=0;
 if(!dsp_child){context=invoke_fb(code+0x36898,g,toc,NULL,NULL,NULL);active=*(uint32_t *)(g+0xe8a);}
 else {
  *(short *)(g+0x580)=0x4000;*(short *)(g+0x582)=*(short *)(g+0x584)=0x6000;
  invoke_fb(code+0x36130,g,toc,NULL,NULL,NULL);DSpContextReference dsp=(DSpContextReference)(uintptr_t)*(uint32_t *)(g+0xe8e);CGrafPtr port=NULL;
  OSStatus error=dsp?DSpContext_GetFrontBuffer(dsp,&port):-1;printf("dsp_context_available%d,front_error%ld,front_available%d\n",dsp!=NULL,(long)error,port!=NULL);
  if(dsp&&!error&&port){Rect bounds;GetPortBounds(port,&bounds);printf("dsp_front_bounds%d,%d,%d,%d\n",bounds.top,bounds.left,bounds.bottom,bounds.right);context=invoke_fb(code+0x363dc,g,toc,port,NULL,NULL);active=aglGetCurrentContext()==(AGLContext)(uintptr_t)context?context:0;}
 }
 if(!active)printf("unavailable_agl_error%d,format_calls%d,context_calls%d\n",aglGetError(),format_calls,context_calls);
 print_mode("active");printf("attempts%d,requested_success_hz%d,context%08x,active%08x\n",attempts,successful_hz,context,active);
 int rendered=0;if(active){glViewport(0,0,640,480);glClearColor(1,0,0,1);glClear(GL_COLOR_BUFFER_BIT);glFinish();aglSwapBuffers((AGLContext)(uintptr_t)active);glFinish();unsigned char pixel[4]={0};glReadBuffer(GL_FRONT);glReadPixels(320,240,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel);rendered=glGetError()==GL_NO_ERROR&&pixel[0]==255&&!pixel[1]&&!pixel[2];printf("owned_front_rgb%u,%u,%u,rendered%d\n",pixel[0],pixel[1],pixel[2],rendered);}
 if(context)invoke_fb(code+0x36db4,g,toc,(void *)(uintptr_t)context,NULL,NULL);
 if(dsp_child&&*(uint32_t *)(g+0xe8e))invoke_fb(code+0x36328,g,toc,NULL,NULL,NULL);
 int detached=aglGetCurrentContext()==NULL;printf("original_deactivation_current_null%d\n",detached);
 return active&&rendered&&detached?0:4;
}
