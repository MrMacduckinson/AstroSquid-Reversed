/* Validate generated PICT pixels with the native G5 QuickDraw decoder. */
#include <Carbon/Carbon.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(15);int pattern=atoi(argv[2]);if(pattern<0||pattern>4)return 2;
 FILE *f=fopen(argv[1],"rb");if(!f)return 2;if(fseek(f,0,SEEK_END))return 2;long size=ftell(f);if(size<136||size>3000000)return 2;rewind(f);
 PicHandle pic=(PicHandle)NewHandle(size);if(!pic)return 2;HLock((Handle)pic);
 if(fread(*pic,1,size,f)!=(size_t)size||fclose(f))return 2;
 Rect r=(*pic)->picFrame;int width=r.right,height=r.bottom;if(r.top||r.left||width<1||width>640||height<1||height>480)return 2;
 GWorldPtr port=NULL;if(NewGWorld(&port,32,&r,NULL,NULL,0)||!port)return 3;
 PixMapHandle pix=GetGWorldPixMap(port);if(!LockPixels(pix))return 3;unsigned stride=GetPixRowBytes(pix);unsigned char *base=(unsigned char *)GetPixBaseAddr(pix);
 memset(base,0x55,stride*height);SetGWorld(port,NULL);DrawPicture(pic,&r);if(QDError())return 3;
 for(int y=0;y<height;y++)for(int x=0;x<width;x++){
  unsigned char *p=base+y*stride+4*x;
  unsigned char red=pattern==4?((x/80&1)?255:0):pattern==3?255:pattern==1?(x*17+y*3)&255:pattern==2?255:0,green=pattern==4?((x/80&2)?255:0):pattern==3?255:pattern==1?(x*7+y*11)&255:0,blue=pattern==4?((x/80&4)?255:0):pattern==3?255:pattern==1?(x*5+y*19)&255:0;
  if(p[1]!=red||p[2]!=green||p[3]!=blue){fprintf(stderr,"Pixel mismatch at%d,%d\n",x,y);return 3;}
 }
 printf("PASS native QuickDraw decoded%d x%d pattern%d\n",width,height,pattern);KillPicture(pic);return 0;
}
