/* G5 debugger-only hook for an owned original window, never a desktop port. */
#include <Carbon/Carbon.h>
#include <stdio.h>
#include <string.h>
#include "ppc_bridge.h"
int astro_capture_reference(unsigned char *code,void *globals,void *toc,WindowRef window,const char *path){
 if(!code||!globals||!toc||!window||!path||strcmp(path,"/tmp/astrosquid-full-port-20261028/window.pict"))return 2;
 CGrafPtr port=NULL;GetPort(&port);if(port!=GetWindowPort(window))return 3;
 Rect rect={0,0,480,640},bounds;GetPortBounds(port,&bounds);if(!EqualRect(&rect,&bounds))return 3;
 PicHandle pic=(PicHandle)(uintptr_t)invoke_fb(code+0x139dc,globals,toc,&rect,NULL,NULL);if(!pic)return 3;
 HLock((Handle)pic);Size size=GetHandleSize((Handle)pic);FILE *out=fopen(path,"wb");if(!out){KillPicture(pic);return 2;}
 int failed=fwrite(*pic,1,size,out)!=(size_t)size;if(fclose(out))failed=1;KillPicture(pic);return failed?2:0;
}
