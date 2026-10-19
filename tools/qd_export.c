/* Rasterize original PICT resources with Apple's original QuickDraw on PowerPC. */
#include <Carbon/Carbon.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

static int export_picture(short identifier,const char *directory){
    PicHandle picture=GetPicture(identifier);GWorldPtr world=NULL;Rect bounds;PixMapHandle pixels;
    char path[1024];FILE *file;int x,y;unsigned char *base;int rowbytes;
    if(!picture){fprintf(stderr,"PICT %d missing (%d)\n",identifier,ResError());return 0;}
    bounds=(**picture).picFrame;OffsetRect(&bounds,-bounds.left,-bounds.top);
    if(NewGWorld(&world,32,&bounds,NULL,NULL,0)!=noErr||!world){ReleaseResource((Handle)picture);return 0;}
    pixels=GetGWorldPixMap(world);if(!LockPixels(pixels)){DisposeGWorld(world);ReleaseResource((Handle)picture);return 0;}
    SetGWorld(world,NULL);RGBColor white={65535,65535,65535},black={0,0,0};RGBBackColor(&white);RGBForeColor(&black);EraseRect(&bounds);DrawPicture(picture,&bounds);
    snprintf(path,sizeof(path),"%s/%d.ppm",directory,identifier);file=fopen(path,"wb");
    if(!file){UnlockPixels(pixels);DisposeGWorld(world);ReleaseResource((Handle)picture);return 0;}
    fprintf(file,"P6\n%d %d\n255\n",bounds.right,bounds.bottom);
    base=(unsigned char *)GetPixBaseAddr(pixels);rowbytes=GetPixRowBytes(pixels);
    for(y=0;y<bounds.bottom;y++)for(x=0;x<bounds.right;x++)if(fwrite(base+y*rowbytes+x*4+1,1,3,file)!=3){fclose(file);UnlockPixels(pixels);DisposeGWorld(world);ReleaseResource((Handle)picture);return 0;}
    if(fclose(file)){UnlockPixels(pixels);DisposeGWorld(world);ReleaseResource((Handle)picture);return 0;}
    UnlockPixels(pixels);DisposeGWorld(world);ReleaseResource((Handle)picture);
    printf("PICT %d %dx%d\n",identifier,bounds.right,bounds.bottom);return 1;
}
int main(int argc,char **argv){
    FSRef ref;HFSUniStr255 forkName;SInt16 resourceFile;OSStatus error;int success=0,failures=0,i;
    if(argc<3){fprintf(stderr,"usage: qd_export original_application output_directory [PICT_ID ...]\n");return 2;}
    error=FSPathMakeRef((const UInt8 *)argv[1],&ref,NULL);
    if(!error)error=FSGetResourceForkName(&forkName);
    if(!error)error=FSOpenResourceFile(&ref,forkName.length,forkName.unicode,fsRdPerm,&resourceFile);
    if(error){fprintf(stderr,"Resource fork open failed: %ld\n",(long)error);return 1;}
    UseResFile(resourceFile);mkdir(argv[2],0700);
    if(argc>3){for(i=3;i<argc;i++){if(export_picture((short)atoi(argv[i]),argv[2]))success++;else failures++;}}
    else {short count=Count1Resources('PICT');for(i=1;i<=count;i++){Handle handle=Get1IndResource('PICT',i);short identifier;ResType type;Str255 name;GetResInfo(handle,&identifier,&type,name);ReleaseResource(handle);if(export_picture(identifier,argv[2]))success++;else failures++;}}
    CloseResFile(resourceFile);printf("Completed %d pictures; %d failures\n",success,failures);return failures?1:0;
}
