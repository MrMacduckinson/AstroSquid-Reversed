/* Original LMSWAP formatting and ordered boundaries, without a GL context. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static const char *expectedText[]={" 0 fps  0 sprites drawn"," 60 fps  1 sprites drawn"," 59.5 fps  42 sprites drawn","-7 fps -1 sprites drawn"," 32767 fps  2147483647 sprites drawn"};
static unsigned caseIndex;
static Handle strings;static unsigned step,enabled;static unsigned char *globals;
static Handle resource(ResType type,short id){if(type!='STR#'||id!=25000)exit(3);return strings;}
static void color(double r,double g,double b){if(step++!=0||!enabled||r!=1||g!=1||b!=1)exit(3);printf("color,%.17g,%.17g,%.17g\n",r,g,b);}
void text(double *x,double *y,unsigned char *s,double *size){if(step++!=1||!enabled||*x!=6||*y!=22||*size!=12||s[0]!=strlen(expectedText[caseIndex])||memcmp(s+1,expectedText[caseIndex],s[0]))exit(3);printf("text,%.17g,%.17g,%.17g,",*x,*y,*size);for(unsigned i=1;i<=s[0];i++)printf("%02x",s[i]);puts("");}
extern void text_fb(void);
__asm__(".text\n.align 2\n.globl _text_fb\n_text_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _text\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static int swap(void *context){if(context!=(void *)0x1234||*(short *)(globals+0xec6)!=(caseIndex==4?-32768:18)||step++!=(enabled?2:0))exit(3);printf("swap,counter%d\n",*(short *)(globals+0xec6));return 1;}
static void identity(void){if(step++!=(enabled?3:1))exit(3);puts("identity");}
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=4)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);globals=g;
 strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,input(argv[3],6884),6884);
 *(void **)(g+0x21c)=input(argv[2],11812);*(void **)(g+0x388)=heap;*(void **)(g+0xe8a)=(void *)0x1234;
 *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"glColor3d"))f=color;if(!strcmp(import_names[i],"aglSwapBuffers"))f=swap;if(!strcmp(import_names[i],"glLoadIdentity"))f=identity;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x3572c,text_fb);MakeDataExecutable(code,433284);
 double rates[]={0,60,59.5,-7,32767};int32_t counts[]={0,1,42,-1,2147483647};
 for(unsigned c=0;c<7;c++){caseIndex=c;enabled=c<5;step=0;*(short *)(g+0xecc)=c<5?1:c==5?0:2;*(double *)(g+0xebe)=rates[c%5];*(int32_t *)(g+0xece)=counts[c%5];*(short *)(g+0xec6)=c==4?32767:17;*(void **)(g+0x38c)=heap;printf("case%u\n",c);invoke_fb(code+0x35eb8,g,toc,NULL,NULL,NULL);if(step!=(enabled?4:2))return 3;}
 puts("PASS original LMSWAP text, exact debug==1 gate, increment-before-swap and final identity");return 0;
}
