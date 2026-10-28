/* Original SAVEPICTFILE; all filesystem boundaries are private observers. G5 only. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static unsigned char *globals;
static Handle strings;
static uint32_t date_value;
static unsigned case_id,writes,opens,closes,messages;
static void date_time(uint32_t *out){*out=date_value;}
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
int save_system(int selector){if(selector!=1)exit(3);return 73;}
int save_folder(int volume){
 unsigned char **stack=(unsigned char **)(globals+0x38c);*stack-=256;
 if(volume!=73||(*stack)[0]!=11||memcmp(*stack+1,"Screenshots",11))exit(3);return 91;
}
void save_open(int mode,int number,int flag,unsigned char *name,int record,int folder,int extra){
 if(mode!=0x4f||number!=1||flag!=1||record||folder!=91||extra)exit(3);opens++;
 printf("%u,open,%u,%.*s,%08x,%08x\n",case_id,date_value,name[0],name+1,*(uint32_t *)(globals+0x53c),*(uint32_t *)(globals+0x540));
}
void save_write(int number,unsigned char *data,int size){
 if(number!=1)exit(3);writes++;
 if(writes==1){if(size!=512)exit(3);for(int i=0;i<size;i++)if(data[i])exit(3);printf("%u,prefix,512,zero\n",case_id);}
 else {if(writes!=2||size!=4||memcmp(data,"TEST",4))exit(3);printf("%u,payload,4,TEST\n",case_id);}
}
void save_close(int number){if(number!=1)exit(3);closes++;printf("%u,close\n",case_id);}
void save_message(unsigned char *name){messages++;printf("%u,message,%.*s\n",case_id,name[0],name+1);}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(save_system) WRAP(save_folder) WRAP(save_open) WRAP(save_write) WRAP(save_close) WRAP(save_message)
static unsigned char *save_input(const char *path,long expected){
 FILE *f=fopen(path,"rb");if(!f){perror(path);exit(2);}if(fseek(f,0,SEEK_END)||ftell(f)!=expected){fclose(f);exit(2);}fclose(f);return read_file(path);
}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);
 unsigned char *pef=save_input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);globals=g;if(!g||!heap)return 2;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,save_input(argv[3],6884),6884);
 *(void **)(g+0x21c)=save_input(argv[2],11812);*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetDateTime"))f=date_time;if(!strcmp(import_names[i],"GetResource"))f=resource;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x24450,save_system_fb);jump_to(code+0xce40,save_folder_fb);jump_to(code+0xf064,save_open_fb);jump_to(code+0xfdcc,save_write_fb);jump_to(code+0xf8d4,save_close_fb);jump_to(code+0x3366c,save_message_fb);MakeDataExecutable(code,433284);
 Handle picture=NewHandle(4);if(!picture)return 2;memcpy(*picture,"TEST",4);
 uint32_t values[]={0,1,86399,86400,0x7fffffff,0x80000000,0xffffffff};
 for(case_id=0;case_id<8;case_id++){
  date_value=values[case_id%7];opens=writes=closes=messages=0;*(void **)(g+0x38c)=heap;
  invoke_fb(code+0x3dfc4,g,toc,case_id==7?NULL:picture,NULL,NULL);
  if(messages!=1||opens!=(case_id==7?0u:1u)||writes!=(case_id==7?0u:2u)||closes!=opens)return 3;
 }
 return 0;
}
