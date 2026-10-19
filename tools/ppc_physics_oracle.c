/* Execute two original code routines in an isolated process on the real G5.
 * No game process is attached or modified. Only cos/sin import descriptors are
 * supplied; the original FCOD code and literal pool are read from local files.
 */
#include <Carbon/Carbon.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../src/physics.h"
#include "ppc_bridge.h"

static unsigned char *read_file(const char *name,size_t *size) {
    FILE *f=fopen(name,"rb");
    if(!f) { perror(name); exit(2); }
    fseek(f,0,SEEK_END); *size=(size_t)ftell(f); rewind(f);
    unsigned char *data=malloc(*size);
    if(!data||fread(data,1,*size,f)!=*size) { fprintf(stderr,"Read failed\n");exit(2); }
    fclose(f); return data;
}

static uint32_t rng=0x12345678;
static double random_value(void) {
    rng=rng*1664525u+1013904223u;
    return ((double)(rng%200001u)-100000.0)/10000.0;
}

int main(int argc,char **argv) {
    if(argc!=3 && argc!=4) { fprintf(stderr,"usage: oracle original.pef literals.bin [vectors.csv]\n"); return 2; }
    FILE *vectors=NULL;
    if(argc==4) {
        vectors=fopen(argv[3],"w");
        if(!vectors) { perror(argv[3]); return 2; }
        fputs("initial_x,initial_y,degrees,amount,friction,make_x,make_y,slow_x,slow_y\n",vectors);
    }
    size_t pef_size,literal_size;
    unsigned char *pef=read_file(argv[1],&pef_size);
    unsigned char *literals=read_file(argv[2],&literal_size);
    if(pef_size<0x6a000||literal_size!=11812) return 2;
    unsigned char *code=pef+128;
    unsigned char *globals=calloc(1,0x1300);
    uint32_t *toc=calloc(1,0x800);
    uint32_t cos_descriptor[2]={(uint32_t)(uintptr_t)cos,0};
    uint32_t sin_descriptor[2]={(uint32_t)(uintptr_t)sin,0};
    unsigned cos_offset=*(uint32_t *)(code+0x67324)&0xffff;
    unsigned sin_offset=*(uint32_t *)(code+0x6904c)&0xffff;
    toc[cos_offset/4]=(uint32_t)(uintptr_t)cos_descriptor;
    toc[sin_offset/4]=(uint32_t)(uintptr_t)sin_descriptor;
    *(void **)(globals+0x21c)=literals;
    *(double *)(globals+0x368)=3.14159265358979323846;
    *(double *)(globals+0x378)=4503601774854144.0;
    *(uint32_t *)(globals+0x380)=0x43300000;
    MakeDataExecutable(code,(unsigned long)(pef_size-128));
    unsigned i;
    for(i=0;i<1000;i++) {
        unsigned char object[128]; memset(object,0,sizeof(object));
        AstroVelocity expected={random_value(),random_value()};
        double initial_x=expected.x,initial_y=expected.y;
        *(double *)(object+0x48)=expected.x; *(double *)(object+0x50)=expected.y;
        double angle=random_value()*100.0,amount=random_value();
        invoke_fb(code+0x52098,globals,toc,object,&angle,&amount);
        astro_vector_make(&expected,angle,amount);
        double x=*(double *)(object+0x48),y=*(double *)(object+0x50);
        if(fabs(x-expected.x)>1e-10||fabs(y-expected.y)>1e-10) {
            printf("VECTORMAKE mismatch case %u: %.17g %.17g versus %.17g %.17g\n",i,x,y,expected.x,expected.y);return 1;
        }
        double make_x=x,make_y=y;
        double friction=fabs(random_value())/10.0;
        invoke_fb(code+0x522e8,globals,toc,object,&friction,NULL);
        astro_vector_slow(&expected,friction);
        x=*(double *)(object+0x48);y=*(double *)(object+0x50);
        if(fabs(x-expected.x)>1e-10||fabs(y-expected.y)>1e-10) {
            printf("VECTORSLOW mismatch case %u friction %.17g: %.17g %.17g versus %.17g %.17g\n",i,friction,x,y,expected.x,expected.y);return 1;
        }
        if(vectors) fprintf(vectors,"%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n",
            initial_x,initial_y,angle,amount,friction,make_x,make_y,x,y);
    }
    if(vectors) fclose(vectors);
    printf("PASS: 1000 VECTORMAKE and 1000 VECTORSLOW cases against original code on real PowerPC\n");
    return 0;
}
