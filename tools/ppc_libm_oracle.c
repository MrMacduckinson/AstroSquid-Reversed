#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
static uint64_t b(double x){uint64_t u;memcpy(&u,&x,8);return u;}
/* Run only on the reference PowerPC host; calls its actual libSystem math. */
int main(int argc,char **argv){int atan_mode=argc>1;Dl_info i;if(dladdr((void*)sin,&i))fprintf(stderr,"sin image %s\n",i.dli_fname);if(dladdr((void*)asin,&i))fprintf(stderr,"asin image %s\n",i.dli_fname);puts(atan_mode?"input,atan":"input,asin");uint32_t r=1729;int n;for(n=0;n<4096;n++){r=r*1664525u+1013904223u;double x=((double)(r%2000001)-1000000)/(atan_mode?1000:1000000);printf("%016llx,%016llx\n",(unsigned long long)b(x),(unsigned long long)b(atan_mode?atan(x):asin(x)));}return 0;}
