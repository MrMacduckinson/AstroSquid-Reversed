/* Real original screenshot IO, confined to an owned G5 scratch directory. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <signal.h>
static Handle strings;
static unsigned messages;
static void date_time(uint32_t *out){*out=123;}
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
void file_message(unsigned char *name){messages++;printf("message,%.*s\n",name[0],name+1);}
extern void file_message_fb(void);
__asm__(".text\n.align 2\n.globl _file_message_fb\n_file_message_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _file_message\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static unsigned char *input(const char *path,long expected){
 FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=expected)exit(2);fclose(f);return read_file(path);
}
static void check_file(const char *path,unsigned length,unsigned char value){
 FILE *f=fopen(path,"rb");if(!f)exit(3);if(fseek(f,0,SEEK_END)||ftell(f)!=512+length)exit(3);rewind(f);
 for(unsigned i=0;i<512+length;i++)if(fgetc(f)!=(i<512?0:value))exit(3);fclose(f);
 FSRef ref;FSCatalogInfo info;if(FSPathMakeRef((const UInt8 *)path,&ref,NULL)||FSGetCatalogInfo(&ref,kFSCatInfoFinderInfo,&info,NULL,NULL,NULL))exit(3);
 FileInfo *finder=(FileInfo *)info.finderInfo;
 printf("file,payload%u,type%08x,creator%08x\n",length,(unsigned)finder->fileType,(unsigned)finder->fileCreator);
 if(finder->fileType!='PICT'||finder->fileCreator!=0x3f3f3f3f)exit(3);
}
int main(int argc,char **argv){
 setvbuf(stdout,NULL,_IONBF,0);
 if(argc!=5||strcmp(argv[4],"/tmp/astrosquid-window-bars-20261028/io-v4"))return 2;alarm(20);
 unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536),*files=calloc(272,4);if(!g||!heap||!files)return 2;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);
 *(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0x534)=files;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetDateTime"))f=date_time;if(!strcmp(import_names[i],"GetResource"))f=resource;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x3366c,file_message_fb);MakeDataExecutable(code,433284);
 if(mkdir(argv[4],0700))return 2;
 FSRef base;FSCatalogInfo info;if(FSPathMakeRef((const UInt8 *)argv[4],&base,NULL)||FSGetCatalogInfo(&base,kFSCatInfoNodeID|kFSCatInfoVolume,&info,NULL,NULL,NULL))return 3;
 unsigned char pb[128]={0};*(short *)(pb+22)=info.volume;*(uint32_t *)(pb+48)=info.nodeID;
 invoke_fb(code+0x458,g,toc,pb,NULL,NULL);*(short *)(g+0x23e)=*(short *)(pb+22);
 Handle picture=NewHandle(16);if(!picture)return 2;memset(*picture,'A',16);
 const char *path="/tmp/astrosquid-window-bars-20261028/io-v4/Screenshots/Screen 123.pict";
 invoke_fb(code+0x3dfc4,g,toc,picture,NULL,NULL);if(*(short *)(g+0x260))return 3;check_file(path,16,'A');
 SetHandleSize(picture,4);if(MemError())return 3;memset(*picture,'B',4);
 invoke_fb(code+0x3dfc4,g,toc,picture,NULL,NULL);if(*(short *)(g+0x260))return 3;check_file(path,4,'B');
 if(messages!=2)return 3;
 if(geteuid()==0||chmod(path,0444)||access(path,W_OK)==0)return 3;
 SetHandleSize(picture,8);if(MemError())return 3;memset(*picture,'C',8);
 pid_t child=fork();if(child<0)return 3;
 if(child==0){struct rlimit no_core={0,0};if(setrlimit(RLIMIT_CORE,&no_core))_exit(3);invoke_fb(code+0x3dfc4,g,toc,picture,NULL,NULL);_exit(4);}
 int status;if(waitpid(child,&status,0)!=child||!WIFSIGNALED(status)||WTERMSIG(status)!=SIGBUS)return 3;
 puts("readonly,original_null_file_write,SIGBUS,unchanged_file");
 check_file(path,4,'B');if(messages!=2)return 3;if(chmod(path,0600))return 3;
 puts("PASS actual SAVEPICTFILE: owned folder creation,512zero prefix,exact metadata,same-name truncation; readonly original SIGBUS isolated in child");return 0;
}
