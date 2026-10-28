/* Owned original G5 process only; report port metadata and restore display. */
#include <Carbon/Carbon.h>
#include <AGL/agl.h>
#include <DrawSprocket/DrawSprocket.h>
#include <stdio.h>
#include <OpenGL/gl.h>
#include <stdlib.h>
#include "ppc_bridge.h"
int astro_fullscreen_port_reference(unsigned char *code,unsigned char *g,void *toc){
 if(!code||!g||!toc)return 2;
 FILE *log=fopen("/tmp/astrosquid-fullscreen-port-20261028/report.txt","w");
 int captured=0,matched=0;
 CGrafPtr current=NULL,front=NULL;GetPort(&current);
 DSpContextReference dsp=(DSpContextReference)(uintptr_t)*(uint32_t *)(g+0xe8e);
 OSStatus error=dsp?DSpContext_GetFrontBuffer(dsp,&front):-1;
 Rect a={0},b={0};if(current)GetPortBounds(current,&a);if(front)GetPortBounds(front,&b);
 fprintf(log?log:stderr,"fullscreen%d,current_available%d,front_error%ld,front_available%d,current_equals_front%d,saved_port_equals_current%d\n",*(short *)(g+0xee0),current!=NULL,(long)error,front!=NULL,current==front,current==*(CGrafPtr *)(g+0x24c));
 fprintf(log?log:stderr,"current_bounds%d,%d,%d,%d front_bounds%d,%d,%d,%d\n",a.top,a.left,a.bottom,a.right,b.top,b.left,b.bottom,b.right);
 if(current&&current==front&&!error&&a.top==0&&a.left==0&&a.bottom==480&&a.right==640){
  FILE *out=NULL;unsigned char *rgb=malloc(640*480*4);PicHandle pic=NULL;GWorldPtr decoded=NULL;PixMapHandle pix=NULL;
  GLint old_read;glGetIntegerv(GL_READ_BUFFER,&old_read);glReadBuffer(GL_FRONT);
  if(rgb){glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,rgb);}
  GLenum gl_error=glGetError();glReadBuffer(old_read);
  Rect rect={0,0,480,640};pic=(PicHandle)(uintptr_t)invoke_fb(code+0x139dc,g,toc,&rect,NULL,NULL);
  if(pic){HLock((Handle)pic);Size length=GetHandleSize((Handle)pic);unsigned char *h=(unsigned char *)*pic;
   unsigned direct=0;for(unsigned i=40;i<160&&i+40<(unsigned)length;i+=2)if(h[i]==0&&h[i+1]==0x9b){direct=i;break;}
   fprintf(log?log:stderr,"pict_bytes%ld,direct_offset%u,packType%u,components%u\n",(long)length,direct,direct?((h[direct+18]<<8)|h[direct+19]):0,direct?((h[direct+36]<<8)|h[direct+37]):0);
   out=fopen("/tmp/astrosquid-fullscreen-port-20261028/fullscreen.pict","wb");if(out){captured=fwrite(*pic,1,length,out)==(size_t)length;if(fclose(out))captured=0;}
   if(rgb&&!gl_error&&!NewGWorld(&decoded,32,&rect,NULL,NULL,0)&&decoded){pix=GetGWorldPixMap(decoded);if(LockPixels(pix)){
    SetGWorld(decoded,NULL);DrawPicture(pic,&rect);unsigned different=0,lit=0;unsigned stride=GetPixRowBytes(pix);unsigned char *base=(unsigned char *)GetPixBaseAddr(pix);
    for(unsigned y=0;y<480;y++)for(unsigned x=0;x<640;x++){unsigned char *q=base+y*stride+x*4,*r=rgb+((479-y)*640+x)*4;if(q[1]!=r[0]||q[2]!=r[1]||q[3]!=r[2])different++;if(q[1]||q[2]||q[3])lit++;}
    int qd_error=QDError();fprintf(log?log:stderr,"decoded_vs_GL_different_pixels%u,decoded_nonblack%u,qd_error%d\n",different,lit,qd_error);
    if(!different&&!qd_error){FILE *raw=fopen("/tmp/astrosquid-fullscreen-port-20261028/fullscreen.rgba","wb");if(raw){matched=1;for(unsigned row=0;row<480;row++)if(fwrite(rgb+(479-row)*640*4,1,640*4,raw)!=640*4)matched=0;if(fclose(raw))matched=0;}}
    UnlockPixels(pix);
   }}
   SetGWorld(current,NULL);if(decoded)DisposeGWorld(decoded);KillPicture(pic);
  }
  free(rgb);
 }
 uint32_t context=*(uint32_t *)(g+0xe8a);if(context)invoke_fb(code+0x36db4,g,toc,(void *)(uintptr_t)context,NULL,NULL);
 if(dsp)invoke_fb(code+0x36328,g,toc,NULL,NULL,NULL);
 fprintf(log?log:stderr,"cleanup_current_null%d,mode%ldx%ld\n",aglGetCurrentContext()==NULL,(long)CGDisplayPixelsWide(CGMainDisplayID()),(long)CGDisplayPixelsHigh(CGMainDisplayID()));
 if(log)fclose(log);return current&&front&&!error&&log&&captured&&matched?0:3;
}
