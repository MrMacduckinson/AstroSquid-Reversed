#include "../src/picture.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc,char **argv){
 if(argc!=4)return 2;int w=atoi(argv[1]),h=atoi(argv[2]),pattern=atoi(argv[3]);
 if(w<1||w>640||h<1||h>480||pattern<0||pattern>2)return 2;
 unsigned char *rgb=malloc((size_t)w*h*3),*output=NULL;size_t size=0;if(!rgb)return 2;
 assert(!astro_picture_encode(NULL,3,1,1,&output,&size)&&!output&&!size);
 assert(!astro_picture_encode(rgb,0,1,1,&output,&size));
 assert(!astro_picture_encode(rgb,3,0,1,&output,&size));
 assert(!astro_picture_encode(rgb,3,1,481,&output,&size));
 assert(!astro_picture_encode(rgb,SIZE_MAX,1,2,&output,&size));
 for(int y=0;y<h;y++)for(int x=0;x<w;x++){
  unsigned char *p=rgb+((size_t)y*w+x)*3;
  p[0]=pattern==1?(x*17+y*3)&255:pattern==2?255:0;
  p[1]=pattern==1?(x*7+y*11)&255:0;p[2]=pattern==1?(x*5+y*19)&255:0;
 }
 assert(astro_picture_encode(rgb,(size_t)w*3,w,h,&output,&size));
 int failed=fwrite(output,1,size,stdout)!=size||fflush(stdout);free(output);free(rgb);return failed?2:0;
}
