/* Original GETPICT_ against an owned AGL window; no desktop capture. G5 only. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <AGL/agl.h>
#include <OpenGL/gl.h>
#include <unistd.h>
static unsigned char *picture_input(const char *path,long expected){
 FILE *f=fopen(path,"rb");if(!f)return NULL;
 if(fseek(f,0,SEEK_END)||ftell(f)!=expected){fclose(f);return NULL;}
 fclose(f);return read_file(path);
}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(20);
 unsigned char *pef=picture_input(argv[1],455780),*lit=picture_input(argv[2],11812),*code=NULL,*g=calloc(1,0x1300);uint32_t toc[489]={0};
 if(!pef||!lit||!g)return 2;code=pef+128;
 for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;*(void **)(g+0x21c)=lit;

 ProcessSerialNumber psn={0,kCurrentProcess};
 if(TransformProcessType(&psn,kProcessTransformToForegroundApplication))return 3;
 Rect bounds={80,80,560,720},rect={0,0,480,640};WindowRef window=NULL;
 if(CreateNewWindow(kDocumentWindowClass,kWindowStandardDocumentAttributes,&bounds,&window))return 3;
 SetWTitle(window,(const unsigned char *)"\040AstroSquid private capture probe");ShowWindow(window);SetPortWindowPort(window);ClipRect(&rect);
 RGBColor blue={0,0,65535};RGBForeColor(&blue);PaintRect(&rect);QDFlushPortBuffer(GetWindowPort(window),NULL);
 MakeDataExecutable(code,433284);
 PicHandle before=(PicHandle)(uintptr_t)invoke_fb(code+0x139dc,g,toc,&rect,NULL,NULL);
 if(!before)return 3;
 GLint attrs[]={4,5,0x49,0x32,32,0};AGLPixelFormat format=aglChoosePixelFormat(NULL,0,attrs);
 if(!format)return 3;AGLContext context=aglCreateContext(format,NULL);aglDestroyPixelFormat(format);
 if(!context||!aglSetDrawable(context,GetWindowPort(window))||!aglSetCurrentContext(context))return 3;
 glViewport(0,0,640,480);glClearColor(1,0,0,1);glClear(GL_COLOR_BUFFER_BIT);glFinish();aglSwapBuffers(context);glFinish();
 unsigned char front[4]={0};glReadBuffer(GL_FRONT);glReadPixels(320,240,1,1,GL_RGBA,GL_UNSIGNED_BYTE,front);
 if(glGetError()||front[0]!=255||front[1]||front[2])return 4;
 SetPortWindowPort(window);ClipRect(&rect);MakeDataExecutable(code,433284);
 PicHandle picture=(PicHandle)(uintptr_t)invoke_fb(code+0x139dc,g,toc,&rect,NULL,NULL);
 if(!picture)return 3;
 HLock((Handle)picture);unsigned char *h=(unsigned char *)*picture;
 unsigned direct=0;for(unsigned i=40;i<80;i+=2)if(h[i]==0&&h[i+1]==0x9b){direct=i;break;}
 if(!direct)return 4;
 unsigned pack=(h[direct+18]<<8)|h[direct+19],components=(h[direct+36]<<8)|h[direct+37];
 printf("window_pixmap packType=%u components=%u\n",pack,components);
 if(pack!=1||components!=3)return 4;
 GWorldPtr decoded=NULL;if(NewGWorld(&decoded,32,&rect,NULL,NULL,0)||!decoded)return 3;
 PixMapHandle pix=GetGWorldPixMap(decoded);if(!LockPixels(pix))return 3;
 unsigned stride=GetPixRowBytes(pix);unsigned char *base=(unsigned char *)GetPixBaseAddr(pix);
 memset(base,0x55,stride*480);SetGWorld(decoded,NULL);DrawPicture(picture,&rect);if(QDError())return 3;
 unsigned char *after=malloc(stride*480);if(!after)return 3;memcpy(after,base,stride*480);
 memset(base,0x55,stride*480);DrawPicture(before,&rect);if(QDError())return 3;
 unsigned red=0,blue_count=0,black=0,other=0,unpainted=0,different=0;
 for(unsigned y=0;y<480;y++)for(unsigned x=0;x<640;x++){
  unsigned char *p=after+y*stride+4*x,*q=base+y*stride+4*x;
  if(memcmp(p+1,q+1,3))different++;
  if(p[1]==255&&!p[2]&&!p[3])red++;
  else if(!p[1]&&!p[2]&&p[3]==255)blue_count++;
  else if(!p[1]&&!p[2]&&!p[3])black++;
  else {other++;if(p[1]==0x55&&p[2]==0x55&&p[3]==0x55)unpainted++;}
 }
 printf("front=%u,%u,%u capture_red=%u blue=%u black=%u other=%u unpainted=%u changed_from_preGL=%u bytes=%ld\n",front[0],front[1],front[2],red,blue_count,black,other,unpainted,different,(long)GetHandleSize((Handle)picture));
 free(after);KillPicture(before);KillPicture(picture);SetGWorld(NULL,NULL);UnlockPixels(pix);DisposeGWorld(decoded);
 aglSetCurrentContext(NULL);aglSetDrawable(context,NULL);aglDestroyContext(context);DisposeWindow(window);free(g);free(pef);free(lit);
 if(different||red||black||blue_count!=306975||other!=225)return 4;return 0;
}
