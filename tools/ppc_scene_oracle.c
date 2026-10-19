/* Execute MOVESTARS in an isolated PowerPC process, preserving original files. */
#include <Carbon/Carbon.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../src/scene.h"
#include "../src/weapons.h"
#include "ppc_bridge.h"
static unsigned char *read_file(const char *name) {
    FILE *f=fopen(name,"rb");if(!f)exit(2);fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);
    unsigned char *p=malloc(n);if(!p||fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;
}
static void hex_double(FILE*f,double d){uint64_t u;memcpy(&u,&d,8);fprintf(f,"%016llx ",(unsigned long long)u);}
int main(int argc,char **argv) {
    if(argc!=3)return 2;FILE *bits=getenv("ASTRO_STAR_BITS")?fopen(getenv("ASTRO_STAR_BITS"),"w"):NULL;
    unsigned char *pef=read_file(argv[1]),*literals=read_file(argv[2]),*code=pef+128;
    unsigned char *globals=calloc(1,0x1300),*heap=calloc(1,0x10000);
    double *original=calloc(3001*4,sizeof(double));AstroStar stars[3000];
    *(void **)(globals+0x21c)=literals;*(double *)(globals+0x368)=3.14159265358979323846;
    *(double *)(globals+0x378)=4503601774854144.0;*(uint32_t *)(globals+0x380)=0x43300000;
    *(void **)(globals+0x388)=heap;*(void **)(globals+0x38c)=heap;*(void **)(globals+0xa54)=original;
    MakeDataExecutable(code,433284);
    uint32_t seed=0x12345678,fixture=0x98765432;
    for(int trial=0;trial<100;trial++) {
        double cx=trial%3*33.3,cy=trial%5*-17.3,l=-cx,t=70-cy,r=640-cx,b=450-cy;
        double sx=(trial%20-10)*33.333,sy=(trial%9-4)*8.888,ix=trial%2?0:12,iy=trial%3?7:0;
        int interval=trial%5+1,menu=trial%2;
        for(int i=0;i<3000;i++) {
            stars[i]=(AstroStar){astro_random(&fixture,100),astro_random(&fixture,2000)-700,
                astro_random(&fixture,1200)-400,astro_random(&fixture,100)};
            memcpy(original+(i+1)*4,&stars[i],sizeof(AstroStar));
        }
        AstroParallax layers[3]={{55,66,10},{777,888,0},{91,92,-5}};
        unsigned char native_layers[3][312];memset(native_layers,0,sizeof(native_layers));
        for(int i=0;i<3;i++) {
            *(double *)(native_layers[i])=layers[i].x;*(double *)(native_layers[i]+8)=layers[i].y;
            *(int *)(native_layers[i]+296)=layers[i].depth;
            if(i<2)*(void **)(native_layers[i]+300)=native_layers[i+1];
        }
        *(void **)(globals+0xe86)=native_layers;*(int16_t *)(globals+0x58c)=menu;
        *(uint32_t *)(globals+0x244)=seed;
        *(double *)(globals+0xea2)=cx;*(double *)(globals+0xeaa)=cy;
        *(double *)(globals+0xa1e)=l;*(double *)(globals+0xa26)=r;
        *(double *)(globals+0xa2e)=t;*(double *)(globals+0xa36)=b;
        *(double *)(globals+0xa58)=sx;*(double *)(globals+0xa60)=sy;*(int16_t *)(globals+0xa52)=interval;
        invoke_fb(code+0x42234,globals,NULL,&ix,&iy,NULL);
        astro_stars_move(stars,cx,cy,l,t,r,b,sx,sy,ix,iy,interval,&seed,layers,3,menu);
        if(seed!=*(uint32_t *)(globals+0x244)) {printf("seed mismatch trial%d\n",trial);return 1;}
        for(int i=0;i<3000;i++) for(int j=0;j<4;j++) {
            double a=original[(i+1)*4+j],z=((double *)&stars[i])[j];
            if(memcmp(&a,&z,8)) {printf("star mismatch trial%d star%d component%d original%.17g portable%.17g\n",trial,i,j,a,z);return 1;}
        }
        for(int i=0;i<3;i++) {
            if(memcmp(native_layers[i],&layers[i].x,8)||memcmp(native_layers[i]+8,&layers[i].y,8)) {
                printf("parallax mismatch trial%d layer%d\n",trial,i);return 1;
            }
        }
        if(bits&&trial<4){fprintf(bits,"C %d %u\n",trial,seed);
            for(int i=0;i<3000;i++){for(int j=0;j<4;j++)hex_double(bits,original[(i+1)*4+j]);fputc('\n',bits);}
            for(int i=0;i<3;i++){hex_double(bits,*(double*)native_layers[i]);hex_double(bits,*(double*)(native_layers[i]+8));fputc('\n',bits);}
        }
    }
    if(bits)fclose(bits);
    puts("PASS: MOVESTARS300000 original/portable star updates, RNG state and300 parallax results on PowerPC");return 0;
}
