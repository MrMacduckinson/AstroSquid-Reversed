#include "picture.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
static void word(unsigned char **p,unsigned value){*(*p)++=(unsigned char)(value>>8);*(*p)++=(unsigned char)value;}
static void longword(unsigned char **p,uint32_t value){word(p,value>>16);word(p,value);}
static void rect(unsigned char **p,unsigned height,unsigned width){word(p,0);word(p,0);word(p,height);word(p,width);}
static size_t run(const unsigned char *data,size_t count,size_t at){size_t n=1;while(at+n<count&&n<128&&data[at+n]==data[at])n++;return n;}
static size_t pack(const unsigned char *data,size_t count,unsigned char *out){
 size_t i=0,used=0;
 while(i<count){
  size_t n=run(data,count,i);
  if(n>=3){out[used++]=(unsigned char)(1-(int)n);out[used++]=data[i];i+=n;continue;}
  size_t start=i;i+=n;
  while(i<count&&i-start<128){n=run(data,count,i);if(n>=3)break;size_t room=128-(i-start);i+=n<room?n:room;}
  out[used++]=(unsigned char)(i-start-1);for(size_t j=start;j<i;j++)out[used++]=data[j];
 }
 return used;
}
static int picture_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,unsigned char **output,size_t *size,int window){
 if(!output||!size)return 0;*output=NULL;*size=0;
 if(!rgb||!width||width>640||!height||height>480||stride<width*3||stride>SIZE_MAX/height)return 0;
 size_t row=width*4,capacity=136+height*(2*row+2);
 unsigned char *bytes=malloc(capacity),*planar=malloc(row),*packed=malloc(2*row);
 if(!bytes||!planar||!packed){free(bytes);free(planar);free(packed);return 0;}
 unsigned char *p=bytes;
 word(&p,0);rect(&p,height,width);word(&p,0x11);word(&p,0x2ff);word(&p,0xc00);
 longword(&p,0xfffe0000);longword(&p,72u<<16);longword(&p,72u<<16);rect(&p,height,width);longword(&p,0);
 word(&p,0x1e);word(&p,1);word(&p,10);if(window)rect(&p,height,width);else {word(&p,0x8001);word(&p,0x8001);word(&p,0x7fff);word(&p,0x7fff);}
 word(&p,0x9b);longword(&p,0xff);word(&p,0x8000|row);rect(&p,height,width);
 word(&p,0);word(&p,window?1:4);longword(&p,0);longword(&p,72u<<16);longword(&p,72u<<16);
 word(&p,16);word(&p,32);word(&p,window?3:4);word(&p,8);longword(&p,32);
 /* QuickDraw serializes process-local pmTable/pmExt handles here; omit addresses. */
 longword(&p,0);longword(&p,0);rect(&p,height,width);rect(&p,height,width);word(&p,0);word(&p,10);rect(&p,height,width);
 for(unsigned y=0;y<height;y++){
  if(window){for(unsigned x=0;x<width;x++){*p++=255;for(unsigned c=0;c<3;c++)*p++=rgb[y*stride+3*x+c];}continue;}
  for(unsigned x=0;x<width;x++){planar[x]=0;for(unsigned c=0;c<3;c++)planar[(c+1)*width+x]=rgb[y*stride+3*x+c];}
  size_t n=row<8?row:pack(planar,row,packed);
  if(row>=8){if(row>250)word(&p,(unsigned)n);else *p++=(unsigned char)n;}
  const unsigned char *data=row<8?planar:packed;for(size_t i=0;i<n;i++)*p++=data[i];
 }
 if((size_t)(p-bytes)&1)*p++=0;word(&p,0xff);
 *size=(size_t)(p-bytes);unsigned char *header=bytes;word(&header,(unsigned)*size);
 free(planar);free(packed);*output=bytes;return 1;
}

int astro_picture_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,unsigned char **output,size_t *size){
 return picture_encode(rgb,stride,width,height,output,size,0);
}
int astro_picture_window_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,unsigned char **output,size_t *size){
 return picture_encode(rgb,stride,width,height,output,size,1);
}

int astro_picture_filename(uint32_t mac_seconds,char *name,size_t capacity){
 if(!name||!capacity)return 0;
 int length=snprintf(name,capacity,"Screen %u.pict",(unsigned)(mac_seconds%86400u));
 return length>=0&&(size_t)length<capacity;
}
int astro_picture_file_encode(const unsigned char *rgb,size_t stride,unsigned width,unsigned height,unsigned char **output,size_t *size){
 if(!output||!size)return 0;*output=NULL;*size=0;
 unsigned char *picture=NULL;size_t length=0;
 if(!astro_picture_encode(rgb,stride,width,height,&picture,&length))return 0;
 unsigned char *file=realloc(picture,length+512);
 if(!file){free(picture);return 0;}
 memmove(file+512,file,length);memset(file,0,512);*output=file;*size=length+512;return 1;
}
