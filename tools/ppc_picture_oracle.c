/* Original GETPICT_ using a private offscreen QuickDraw port. G5 only. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <unistd.h>
static unsigned char *picture_input(const char *path,long expected){
 FILE *f=fopen(path,"rb");if(!f){perror(path);exit(2);}if(fseek(f,0,SEEK_END)||ftell(f)!=expected){fclose(f);exit(2);}fclose(f);return read_file(path);
}
int main(int argc,char **argv){
 if(argc!=7)return 2;alarm(15);
 int width=atoi(argv[3]),height=atoi(argv[4]),pattern=atoi(argv[5]);
 if(width<1||width>640||height<1||height>480||pattern<0||pattern>2)return 2;
 unsigned char *pef=picture_input(argv[1],455780),*lit=picture_input(argv[2],11812),*code=pef+128,*g=calloc(1,0x1300);uint32_t toc[489]={0};
 for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;*(void **)(g+0x21c)=lit;
 Rect rect={0,0,height,width};GWorldPtr port=NULL;OSErr err=NewGWorld(&port,32,&rect,NULL,NULL,0);if(err||!port)return 3;
 PixMapHandle pixels=GetGWorldPixMap(port);if(!LockPixels(pixels))return 3;
 unsigned char *base=(unsigned char *)GetPixBaseAddr(pixels);unsigned stride=GetPixRowBytes(pixels);
 for(int y=0;y<height;y++)for(unsigned x=0;x<stride;x++)base[y*stride+x]=0;
 for(int y=0;y<height;y++)for(int x=0;x<width;x++){
  unsigned char *p=base+y*stride+4*x;
  p[1]=pattern==1?(x*17+y*3)&255:pattern==2?255:0;
  p[2]=pattern==1?(x*7+y*11)&255:0;p[3]=pattern==1?(x*5+y*19)&255:0;
 }
 SetGWorld(port,NULL);MakeDataExecutable(code,433284);
 PicHandle picture=(PicHandle)(uintptr_t)invoke_fb(code+0x139dc,g,toc,&rect,NULL,NULL);
 if(!picture)return 3;Size size=GetHandleSize((Handle)picture);HLock((Handle)picture);
 FILE *out=fopen(argv[6],"wb");if(!out)return 2;if(fwrite(*picture,1,size,out)!=(size_t)size||fclose(out))return 2;
 printf("pixmap_components%d table%08x extension%08x\n",(**pixels).cmpCount,(unsigned)(uintptr_t)(**pixels).pmTable,(unsigned)(uintptr_t)(**pixels).pmExt);
 printf("width%d height%d pattern%d rowbytes%u picturebytes%ld\n",width,height,pattern,stride,(long)size);
 KillPicture(picture);return 0;
}
