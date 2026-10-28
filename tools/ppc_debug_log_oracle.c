/* Native debug append routine; observe file/print boundaries, never open a file. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static Handle strings;static unsigned char *globals;static char output[4096];static unsigned length,opens,closes,errorReads;static int route,errorCode,initializing;static unsigned kills;static SInt32 clockValue=1000000000,memoryValue=536870912;
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
static int agl_error(void){errorReads++;if(route||opens!=1||closes)exit(3);return errorCode;}
int system_value(int selector){if(selector==1)return 123;if(initializing&&selector==8)return 10411;exit(3);}
void open_file(int mode,int number,int kind,unsigned char *name,int record,int volume,int dir){if(mode!=(initializing?0x52:0x41)||number!=1||kind!=1||record||volume!=123||dir||name[0]!=19||memcmp(name+1,"LMEngine Debug file",19)||opens++||closes||(initializing&&kills!=1))exit(3);}
void close_file(int number){if(number!=1||opens!=1||route||closes++||errorReads!=(initializing?0:1))exit(3);}
void print_route(int value){if(value!=0&&value!=1)exit(3);route=value;}
void print_string(void){unsigned char *s=*(unsigned char **)(globals+0x38c);if(route!=1||opens!=1||closes||length+s[0]>=sizeof(output))exit(3);memcpy(output+length,s+1,s[0]);length+=s[0];}
void print_cr(void){if(route!=1||length+1>=sizeof(output))exit(3);output[length++]='\r';}
void kill_file(int unused){(void)unused;unsigned char *s=*(unsigned char **)(globals+0x38c);if(!initializing||kills++||opens||s[0]!=19||memcmp(s+1,"LMEngine Debug file",19))exit(3);}
static OSStatus gestalt(OSType selector,SInt32 *value){if(selector=='pclk')*value=clockValue;else if(selector=='ram ')*value=memoryValue;else exit(3);return 0;}
static void version(int *major,int *minor){*major=1;*minor=4;}
static void date_time(uint32_t *value){*value=123;}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(kill_file) WRAP(system_value) WRAP(open_file) WRAP(close_file) WRAP(print_route) WRAP(print_string) WRAP(print_cr)
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;globals=g;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);*(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"aglGetError"))f=agl_error;if(!strcmp(import_names[i],"Gestalt"))f=gestalt;if(!strcmp(import_names[i],"aglGetVersion"))f=version;if(!strcmp(import_names[i],"GetDateTime"))f=date_time;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 MakeDataExecutable(code,433284);
 for(unsigned v=0;v<65536;v++){*(uint32_t *)(g+0x22c)=v;unsigned expected=((v>>12)&15)*1000+((v>>8)&15)*100+((v>>4)&15)*10+(v&15);unsigned actual=invoke_fb(code+0x24450,g,toc,(void *)8,NULL,NULL);if(actual!=expected)return 3;}
 puts("PASS65536 original SYSTEM8 packed version conversions");
 jump_to(code+0xfc18,kill_file_fb);jump_to(code+0x24450,system_value_fb);jump_to(code+0xf064,open_file_fb);jump_to(code+0xf8d4,close_file_fb);jump_to(code+0x2d0e8,print_route_fb);jump_to(code+0x2c460,print_string_fb);jump_to(code+0x2c4a4,print_cr_fb);MakeDataExecutable(code,433284);
 int flags[]={0,1,1,2,-1},errors[]={7,0,10000,7,7};unsigned char message[]={5,'H','e','l','l','o'};
 for(unsigned c=0;c<5;c++){length=opens=closes=errorReads=0;route=0;errorCode=errors[c];*(short *)(g+0xede)=flags[c];*(void **)(g+0x38c)=heap;invoke_fb(code+0x3366c,g,toc,message,NULL,NULL);output[length]=0;
  const char *expected=c==1?"Hello\r":c==2?"Hello\r   *** AGL Error:  10000\r":"";
  if(strcmp(output,expected)||opens!=(flags[c]==1)||closes!=opens||errorReads!=opens||route)return 3;
  printf("case%u,debug%d,error%d,opens%u,error_reads%u,closes%u,hex",c,flags[c],errors[c],opens,errorReads,closes);for(unsigned i=0;i<length;i++)printf("%02x",(unsigned char)output[i]);puts("");
 }
 initializing=1;kills=length=opens=closes=errorReads=0;route=0;*(void **)(g+0x38c)=heap;
 *(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(short *)(g+0xeda)=1;*(short *)(g+0xedc)=0;*(short *)(g+0xede)=1;*(short *)(g+0xee0)=1;*(short *)(g+0xee2)=0;*(short *)(g+0xee6)=1;g[0xee8]=10;memcpy(g+0xee9,"AstroSquid",10);
 invoke_fb(code+0x37620,g,toc,NULL,NULL,NULL);if(kills!=1||opens!=1||closes!=1||errorReads||route||*(uint32_t *)(g+0x53c)!=0x54455854)return 3;
 const char *expectedHeader="---------- Lost Minds Sprite Engine Debug File -----------\rIf you are having problems, send this file to bugs@lostminds.com\rFile created 01/01/04    at 00:02:03\r\r---------- System Info -----------\rProcessor: 1000 MHz\rMemory:  512 MB\rMacOS version: 04.1.1\rAGL version:  1.4\r\r---------- LM Engine Info -----------\rBuild # 22\r\rLMSettings.ScreenWidth =  640\rLMSettings.ScreenHeight =  480\rLMSettings.SpriteCullingFlag = TRUE\rLMSettings.ClearBackgroundFlag = FALSE\rLMSettings.DebugFlag= TRUE\rLMSettings.FullscreenFlag= TRUE\rLMSettings.WindowTitle$ = 'AstroSquid'\rLMSettings.SmoothScalingFlag = TRUE\rLMSettings.ClassicFlag = FALSE\r\r\r---------- Startup -----------\r";if(length!=strlen(expectedHeader)||memcmp(output,expectedHeader,length))return 3;
 printf("header,hex");for(unsigned i=0;i<length;i++)printf("%02x",(unsigned char)output[i]);puts("");
 SInt32 clocks[]={100000000,2000000000,-2147483647,100499999,100500000,100500001,98500000},memories[]={67108864,1073741824,-2147483647};
 const char *processor[]={"Processor:  100 MHz\r","Processor: 2000 MHz\r","Processor: ?147 MHz\r","Processor:  100 MHz\r","Processor:  100 MHz\r","Processor:  101 MHz\r","Processor:   98 MHz\r"};
 const char *memory[]={"Memory:   64 MB\r","Memory: 1024 MB\r","Memory:-2048 MB\r"};
 for(unsigned i=0;i<7;i++){clockValue=clocks[i];memoryValue=memories[i%3];kills=length=opens=closes=errorReads=0;route=0;*(void **)(g+0x38c)=heap;invoke_fb(code+0x37620,g,toc,NULL,NULL,NULL);output[length]=0;
  printf("format%u,hex",i);for(unsigned j=0;j<length;j++)printf("%02x",(unsigned char)output[j]);puts("");
  if(!strstr(output,processor[i])||!strstr(output,memory[i%3])||kills!=1||opens!=1||closes!=1||errorReads||route)return 3;
 }
 puts("PASS original exact-debug gate, append-open/close per message, CR line endings and AGL error queried after message only when enabled");return 0;
}
