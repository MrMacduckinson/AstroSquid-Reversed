/* Original INITSAGAIA Float2Int/store slice; private code copy, no preference writes. */
#include <Carbon/Carbon.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "ppc_bridge.h"
static unsigned char *read_file(const char *name){FILE *f=fopen(name,"rb");if(!f){perror(name);exit(2);}fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
int main(int argc,char **argv){if(argc!=3)return 2;unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*globals=calloc(1,0x1300);uint32_t toc[489]={0};
*(void **)(globals+0x21c)=literals;*(double *)(globals+0x378)=4503601774854144.;*(uint32_t *)(globals+0x380)=0x43300000;toc[0]=(uint32_t)(uintptr_t)globals;
*(uint32_t *)(code+0x658e8)=0x7de802a6;*(uint32_t *)(code+0x6590c)=0x7de803a6;*(uint32_t *)(code+0x65910)=0x4e800020;MakeDataExecutable(code,433284);
for(int fps=-32768;fps<=32767;fps++) {
    *(int16_t *)(globals+0xaba)=(int16_t)fps;
    invoke_fb(code+0x658e8,globals,toc,NULL,NULL,NULL);
    printf("%d,%d\n",fps,*(int16_t *)(globals+0xa52));
}
return 0;}
