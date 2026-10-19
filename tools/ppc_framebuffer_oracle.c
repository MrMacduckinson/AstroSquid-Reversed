/* Controlled full RENDERGAMEWINDOW framebuffer, not a live campaign capture.
 * Intel uses source-cross-checked duplicate primitives, not production linkage.
 * Both contexts disable dithering for controlled cross-GPU comparison.
 * Run only G5(original code) or Intel(port math), never primaryMac runtime. */
#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef __ppc__
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include "ppc_bridge.h"
#include "imports.h"
#endif
static unsigned char *read_file(const char *name){FILE*f=fopen(name,"rb");if(!f){perror(name);exit(2);}fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char*p=malloc(n);if(!p||fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static uint32_t be32(const unsigned char*p){return (uint32_t)p[0]<<24|(uint32_t)p[1]<<16|(uint32_t)p[2]<<8|p[3];}
static int16_t be16(const unsigned char*p){return (int16_t)((unsigned)p[0]<<8|p[1]);}
typedef struct {int id,layer;double x,y,w,h;} Object;
static Object objects[]={
 {44,2,40.25,30.5,350,300},{116,4,120.5,180.25,88,120},
 {240,5,210.25,170.5,144,52},{200,4,250.5,170.25,117,114},
 {1,6,230.25,180.5,142,40},{47,6,260.5,180.25,30,34},
 {71,7,220.25,155.5,100,100},{83,7,280.5,155.25,80,90},{115,8,195.25,160.5,82,82}};
static GLuint textures[108];static int widths[108];static unsigned char *sprt;
static void port_sprite(const Object*o,double cx,double cy){
 const unsigned char*s=sprt+o->id*14;int atlas=be16(s);double size=widths[atlas];
 double u=be16(s+2)/size,v=be16(s+4)/size,du=be16(s+6)/size,dv=be16(s+8)/size;
 glBindTexture(GL_TEXTURE_2D,textures[atlas]);glBegin(GL_QUADS);
 glTexCoord2d(u,v);glVertex2d(o->x+cx,o->y+cy);
 glTexCoord2d(u+du,v);glVertex2d(o->x+cx+o->w,o->y+cy);
 glTexCoord2d(u+du,v+dv);glVertex2d(o->x+cx+o->w,o->y+cy+o->h);
 glTexCoord2d(u,v+dv);glVertex2d(o->x+cx,o->y+cy+o->h);glEnd();
}
int main(int argc,char**argv){
 if(argc!=3)return 2;char path[2048];
#ifdef __ppc__
 CGLPixelFormatAttribute pa[]={kCGLPFAPBuffer,kCGLPFAColorSize,24,kCGLPFAAlphaSize,8,0};
#else
 CGLPixelFormatAttribute pa[]={kCGLPFAColorSize,24,kCGLPFAAlphaSize,8,0};
#endif
 CGLPixelFormatObj pf;GLint n;CGLError err=CGLChoosePixelFormat(pa,&pf,&n);
 CGLContextObj ctx;if(err||!pf){printf("UNAVAILABLE pixel format %d\n",err);return 3;}
 err=CGLCreateContext(pf,NULL,&ctx);CGLDestroyPixelFormat(pf);
#ifdef __ppc__
 CGLPBufferObj pb;if(!err)err=CGLCreatePBuffer(640,380,GL_TEXTURE_RECTANGLE_EXT,GL_RGBA,0,&pb);
 if(!err)err=CGLSetPBuffer(ctx,pb,0,0,0);
#endif
 if(!err)err=CGLSetCurrentContext(ctx);
 if(err){printf("UNAVAILABLE offscreencontext %d\n",err);return 3;}
#ifndef __ppc__
 GLuint fb,color;glGenFramebuffersEXT(1,&fb);glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fb);
 glGenTextures(1,&color);glBindTexture(GL_TEXTURE_2D,color);glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,640,380,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
 glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,color,0);
 if(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)!=GL_FRAMEBUFFER_COMPLETE_EXT){puts("UNAVAILABLE framebuffer");return 3;}
#endif
 printf("GL vendor%s renderer%s version%s\n",glGetString(GL_VENDOR),glGetString(GL_RENDERER),glGetString(GL_VERSION));
 snprintf(path,sizeof(path),"%s/sprt.bin",argv[1]);sprt=read_file(path);
 int atlas_ids[]={0,1,2,5,10,12,18};
 for(unsigned i=0;i<sizeof(atlas_ids)/sizeof(atlas_ids[0]);i++){
  int id=atlas_ids[i];snprintf(path,sizeof(path),"%s/atlas%d.rgba",argv[1],id);unsigned char*b=read_file(path);int size=(int)be32(b);widths[id]=size;
  glGenTextures(1,textures+id);glBindTexture(GL_TEXTURE_2D,textures[id]);glPixelStorei(GL_UNPACK_ALIGNMENT,1);
  glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,size,size,0,GL_RGBA,GL_UNSIGNED_BYTE,b+4);free(b);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
 }
#ifdef __ppc__
 snprintf(path,sizeof(path),"%s/original.pef",argv[1]);unsigned char *pef=read_file(path),*code=pef+128;
 snprintf(path,sizeof(path),"%s/literals.bin",argv[1]);unsigned char*literals=read_file(path);
 unsigned char*g=calloc(1,0x1300),*heap=calloc(1,0x10000),native_sprites[9][312],maps[108][8];double*stars=calloc(3001*4,sizeof(double));
 *(void**)(g+0x21c)=literals;*(double*)(g+0x378)=4503601774854144.;*(uint32_t*)(g+0x380)=0x43300000;
 *(void**)(g+0x388)=heap;*(void**)(g+0x38c)=heap;*(void**)(g+0xe82)=sprt;*(void**)(g+0xa54)=stars;
 uint32_t descriptors[484][2],toc[489];memset(toc,0,sizeof(toc));
 for(int i=0;i<484;i++){void*f=dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)f;descriptors[i][1]=0;toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 memset(maps,0,sizeof(maps));for(unsigned i=0;i<sizeof(atlas_ids)/sizeof(atlas_ids[0]);i++){int id=atlas_ids[i];*(int16_t*)maps[id]=widths[id];*(int16_t*)(maps[id]+2)=widths[id];*(GLuint*)(maps[id]+4)=textures[id];*(void**)(g+0xcd6+id*4)=maps[id];}
 memset(native_sprites,0,sizeof(native_sprites));for(unsigned i=0;i<9;i++){Object*o=objects+i;unsigned char*s=native_sprites[i];*(double*)s=o->x;*(double*)(s+8)=o->y;*(double*)(s+16)=o->w;*(double*)(s+24)=o->h;*(int16_t*)(s+32)=o->layer;*(int16_t*)(s+38)=o->id;if(i<8)*(void**)(s+300)=native_sprites[i+1];}
 *(void**)(g+0xe86)=native_sprites;
 for(int i=0;i<1000;i++){double*s=stars+(i+1)*4;s[0]=i%100+1;s[1]=(i*37)%640+.25;s[2]=(i*29)%380+.5;}
 MakeDataExecutable(code,433284);
#endif
 unsigned char*pixels=malloc(640*380*4);
 for(int smooth=0;smooth<2;smooth++)for(int trial=0;trial<6;trial++){
  int stage=trial%3==0?1:trial%3==1?4:7;double cx=trial<3?0:-37.25,cy=trial<3?0:-13.5;
  for(unsigned i=0;i<sizeof(atlas_ids)/sizeof(atlas_ids[0]);i++){glBindTexture(GL_TEXTURE_2D,textures[atlas_ids[i]]);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,smooth?GL_LINEAR:GL_NEAREST);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,smooth?GL_LINEAR:GL_NEAREST);}
  glViewport(0,0,640,380);glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,379,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();
  glDisable(GL_DITHER);glClearColor(0,0,0,1);glClear(GL_COLOR_BUFFER_BIT);glEnable(GL_TEXTURE_2D);glShadeModel(GL_FLAT);
#ifdef __ppc__
  *(double*)(g+0xea2)=cx;*(double*)(g+0xeaa)=cy;*(int16_t*)(g+0xa82)=stage;invoke_fb(code+0x57afc,g,toc,NULL,NULL,NULL);
#else
  if(stage<4||stage==7){glDisable(GL_BLEND);glBindTexture(GL_TEXTURE_2D,textures[0]);glBegin(GL_POINTS);for(int i=0;i<1000;i++){double gray=(i%100+1)/100.;glColor3d(gray,gray,gray);glVertex3d((i*37)%640+.25,(i*29)%380+.5,0);}glEnd();}
  glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);glColor3d(1,1,1);
  for(int layer=2;layer<11;layer++)for(unsigned i=0;i<9;i++)if(objects[i].layer==layer)port_sprite(objects+i,cx,cy);
#endif
  glFinish();GLenum ge=glGetError();if(ge){printf("GLerror %u\n",ge);return 1;}
  glPixelStorei(GL_PACK_ALIGNMENT,1);glReadPixels(0,0,640,380,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
  snprintf(path,sizeof(path),"%s-%d-%d.rgba",argv[2],smooth,trial);FILE*f=fopen(path,"wb");if(!f||fwrite(pixels,1,640*380*4,f)!=640*380*4)return 2;fclose(f);
 }
 puts("PASS12 controlledfullplayfieldframebuffers written; originalPPC or portIntel path");return 0;
}
