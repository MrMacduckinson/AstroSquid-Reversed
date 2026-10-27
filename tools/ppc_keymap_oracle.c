/* Original GETKEYMAP in a private loaded PEF; no physical input or screenshots. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
static uint32_t descriptors[484][2];
static unsigned char scripted[32];
static unsigned copy_count=16,key_calls,shots,padding_before;
static void scripted_keys(unsigned char *out){key_calls++;padding_before=out[16];memcpy(out,scripted,copy_count);}
static void screenshot(void){shots++;}
static void missing(void){fputs("Unexpected import\n",stderr);exit(2);}
static unsigned char *read_file(const char *name){FILE *f=fopen(name,"rb");if(!f){perror(name);exit(2);}fseek(f,0,SEEK_END);long size=ftell(f);rewind(f);unsigned char *p=malloc(size);if(!p||fread(p,1,size,f)!=(size_t)size)exit(2);fclose(f);return p;}
static void jump_to(unsigned char *at,void *fn){uintptr_t p=(uintptr_t)fn;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(p>>16);w[1]=0x618c0000|(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
static void key(unsigned code){scripted[code>>3]|=1u<<(code&7);}
int main(int argc,char **argv){
    if(argc!=3)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,65536);
    uint32_t toc[489]={0};
    for(int i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetKeys"))fn=scripted_keys;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;toc[0]=(uint32_t)(uintptr_t)g;
    const int offsets[6]={0xcc2,0xcc4,0xcc6,0xcc8,0xccc,0xcca},codes[6]={55,58,126,125,123,124};
    for(int i=0;i<6;i++)*(int16_t *)(g+offsets[i])=codes[i]^7;
    jump_to(code+0x3e208,screenshot);MakeDataExecutable(code,433284);
    puts("id,map,copy_bytes,debug,quit_before,pad_before,left,right,up,down,pause,fire,special,any,quit_after,shots");
    for(int id=0;id<137;id++){
        memset(scripted,0,sizeof(scripted));copy_count=16;int debug=0,quit=0;
        if(id<128)key(id);
        else if(id==129){memset(scripted,255,16);debug=1;}
        else if(id==130){key(55);key(12);}
        else if(id==131){key(48);key(11);}
        else if(id==132)quit=1;
        else if(id==133){key(67);debug=1;}
        else if(id==134)key(67);
        else if(id==135){copy_count=32;scripted[16]=0x80;}
        *(int16_t *)(g+0xede)=debug;*(int16_t *)(g+0x58e)=quit;key_calls=shots=0;
        invoke_fb(code+0x4cb28,g,toc,NULL,NULL,NULL);
        if(key_calls!=1){fputs("Wrong GetKeys count\n",stderr);return 3;}
        printf("%d,",id);for(int i=0;i<16;i++)printf("%02x",scripted[i]);
        printf(",%u,%d,%d,%u",copy_count,debug,quit,padding_before);
        for(int off=0xaa8;off<=0xab6;off+=2)printf(",%d",*(int16_t *)(g+off));
        printf(",%d,%u\n",*(int16_t *)(g+0x58e),shots);
    }
    return 0;
}
