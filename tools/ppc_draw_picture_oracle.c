/* Actual LMDRAWPICTURE cached-map path, synthetic resource bounds, observed GL only. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
extern void invoke_picture(void *,void *,void *,void *);
__asm__(".text\n.align 2\n.globl _invoke_picture\n_invoke_picture:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\nstmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r11,r6\nlwz r3,0(r11)\nlwz r4,4(r11)\nlwz r5,8(r11)\nlwz r6,12(r11)\nlwz r7,16(r11)\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\nlmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static Handle txtr,picture;static unsigned resourceGets,picts,releases,binds,params,vertices,uvs;static double xy[8],uv[8];
static void noop(void){}
static void forbidden(void){fputs("Unexpected native texture load/delete/generation or debug call\n",stderr);exit(3);}
static Handle resource(ResType type,short id){if(type!='txtr'||id!=40)exit(3);resourceGets++;return txtr;}
static PicHandle get_picture(short id){if(id!=1234)exit(3);picts++;return (PicHandle)picture;}
static void release(Handle h){if(h!=txtr&&h!=picture)exit(3);releases++;}
static void bind(unsigned target,unsigned name){if(target!=0xde1||name!=77)exit(3);binds++;}
static void parameter(unsigned target,unsigned key,int value){if(target!=0xde1||key!=(params?0x2801:0x2800)||value!=0x2600)exit(3);params++;}
static void vertex(double x,double y){if(vertices>=4)exit(3);xy[2*vertices]=x;xy[2*vertices+1]=y;vertices++;}
static void texcoord(double x,double y){if(uvs>=4)exit(3);uv[2*uvs]=x;uv[2*uvs+1]=y;uvs++;}
static unsigned char *input(const char *path,long size){FILE *f=fopen(path,"rb");if(!f)exit(2);if(fseek(f,0,SEEK_END)||ftell(f)!=size)exit(2);fclose(f);return read_file(path);}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(15);unsigned char *pef=input(argv[1],455780),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);if(!g||!heap)return 2;
 *(void **)(g+0x21c)=input(argv[2],11812);*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;
 txtr=NewHandle(2);picture=NewHandleClear(10);if(!txtr||!picture)return 2;*(short *)*txtr=1234;*(short *)(*picture+6)=100;*(short *)(*picture+8)=200;
 uint32_t map[]={0x02000200,77};*(void **)(g+0xcd6+40*4)=map;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strncmp(import_names[i],"gl",2))f=noop;if(!strcmp(import_names[i],"GetResource"))f=resource;if(!strcmp(import_names[i],"GetPicture"))f=get_picture;if(!strcmp(import_names[i],"ReleaseResource"))f=release;if(!strcmp(import_names[i],"glBindTexture"))f=bind;if(!strcmp(import_names[i],"glTexParameteri"))f=parameter;if(!strcmp(import_names[i],"glVertex2d"))f=vertex;if(!strcmp(import_names[i],"glTexCoord2d"))f=texcoord;if(!strcmp(import_names[i],"glGenTextures")||!strcmp(import_names[i],"glDeleteTextures"))f=forbidden;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 jump_to(code+0x3b7c4,forbidden);jump_to(code+0x3366c,forbidden);jump_to(code+0x33b40,forbidden);MakeDataExecutable(code,433284);
 double cases[][4]={{0,0,0,0},{0,0,100,50},{13,17,100,50},{0,0,0,50},{0,0,0,0}};
 for(unsigned c=0;c<5;c++){resourceGets=picts=releases=binds=params=vertices=uvs=0;double *v=cases[c];uint32_t args[]={40,(uint32_t)(uintptr_t)(v+0),(uint32_t)(uintptr_t)(v+1),(uint32_t)(uintptr_t)(v+2),(uint32_t)(uintptr_t)(v+3)};invoke_picture(code+0x3bb58,g,toc,args);
  double w=v[2]?v[2]:200,h=v[3]?v[3]:100,x=v[0]?v[0]:320-w/2,y=v[1]?v[1]:240-h/2;double expected[]={x,y,x+w,y,x+w,y+h,x,y+h},expectedUV[]={0,0,200./512,0,200./512,100./512,0,100./512};
  if(resourceGets!=1||picts!=1||releases!=2||binds!=1||params!=((!v[2]&&!v[3])?2:0)||vertices!=4||uvs!=4||memcmp(xy,expected,sizeof xy)||memcmp(uv,expectedUV,sizeof uv))return 3;
  printf("case%u,resource1,picture1,releases2,cached_bind1,nearest_params%u,vertices4,no_temp_load_or_delete\n",c,params);
 }
 puts("PASS native cached picture path reuses map, changes filters only for both dimensions zero and leaves NEAREST in place; no LMDrawPict journal event on this path");return 0;
}
