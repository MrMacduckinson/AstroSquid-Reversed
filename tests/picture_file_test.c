#include "../src/picture.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(void){
 FILE *f=fopen("tests/picture_save_native.csv","r");assert(f);char line[256];unsigned opens=0,prefixes=0,payloads=0,closes=0,null_errors=0;
 while(fgets(line,sizeof(line),f)){
  unsigned id,seconds,type,creator;char native[64],name[64];
  if(sscanf(line,"%u,open,%u,%63[^,],%x,%x",&id,&seconds,native,&type,&creator)==5){
   assert(id==opens++);assert(astro_picture_filename(seconds,name,sizeof(name))&&!strcmp(name,native));
   assert(type==ASTRO_PICTURE_TYPE&&creator==ASTRO_PICTURE_CREATOR);
  }else if(strstr(line,",prefix,512,zero"))prefixes++;
  else if(strstr(line,",payload,4,TEST"))payloads++;
  else if(strstr(line,",close"))closes++;
  else if(strstr(line,"7,message,*** Error while taking screenshot"))null_errors++;
 }
 assert(!ferror(f));fclose(f);assert(opens==7&&prefixes==7&&payloads==7&&closes==7&&null_errors==1);
 char small[4];assert(!astro_picture_filename(0,small,sizeof(small))&&!astro_picture_filename(0,NULL,0));
 unsigned char rgb[]={17,43,255},*picture=NULL,*file=NULL;size_t n=0,size=0;
 assert(astro_picture_encode(rgb,3,1,1,&picture,&n));
 assert(astro_picture_file_encode(rgb,3,1,1,&file,&size)&&size==n+512);
 for(unsigned i=0;i<512;i++)assert(file[i]==0);
 assert(!memcmp(file+512,picture,n));free(file);free(picture);
 assert(!astro_picture_file_encode(NULL,3,1,1,&file,&size)&&!file&&!size);
 puts("PASS original SAVEPICTFILE metadata:7 timer boundaries/names,PICT creator/type,512zero prefix,payload and null/error contract");
}
