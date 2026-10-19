/* Controlled original RENDERGAMEWINDOW drawstream. Not a gameplay screenshot.
 * Original painter/layer loops execute; GL driver and final textured sprite
 * draw calls are observed without a display context. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
static int ids[64],layers[64],count,points,point_batches;
static int primitive;
static void noop(void) {}
static void begin(int p) {primitive=p;if(p==0)point_batches++;}
static void vertex3(double x,double y,double z) {(void)x;(void)y;(void)z;if(primitive==0)points++;}
void native_draw(unsigned char *sprite) {if(count>=64)exit(2);ids[count]=*(int16_t *)(sprite+38);layers[count++]=*(int16_t *)(sprite+32);}
void native_beam(unsigned char *beam) {if(count>=64)exit(2);ids[count]=*(int16_t *)(beam+96);layers[count++]=999;}
extern void native_draw_fb(void),native_beam_fb(void);
__asm__(".text\n.align 2\n.globl _native_draw_fb\n_native_draw_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_draw\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
".align 2\n.globl _native_beam_fb\n_native_beam_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_beam\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void jump_to(unsigned char *at,void *destination) {uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
static unsigned char *read_file(const char *name) {FILE *f=fopen(name,"rb");if(!f)exit(2);fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(!p||fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
int main(int argc,char **argv) {
    if(argc!=3)return 2;unsigned char *pef=read_file(argv[1]),*literals=read_file(argv[2]),*code=pef+128;
    unsigned char *g=calloc(1,0x1300),*heap=calloc(1,0x10000),sprites[10][312],entities[2][128];
    double *stars=calloc(3001*4,sizeof(double));
    *(void **)(g+0x21c)=literals;*(double *)(g+0x378)=4503601774854144.0;*(uint32_t *)(g+0x380)=0x43300000;
    *(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xa54)=stars;
    uint32_t descriptors[484][2],toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++) {void *f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strncmp(import_names[i],"gl",2))f=(void *)noop;
        if(!strcmp(import_names[i],"glBegin"))f=(void *)begin;if(!strcmp(import_names[i],"glVertex3d"))f=(void *)vertex3;
        descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:(void *)noop);descriptors[i][1]=0;toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    toc[0]=(uint32_t)(uintptr_t)g;
    int sprite_ids[10]={44,1,70,115,116,80,900,40,41,91},sprite_layers[10]={2,6,6,8,4,7,10,5,5,7};
    memset(sprites,0,sizeof(sprites));memset(entities,0,sizeof(entities));
    for(int i=0;i<10;i++){*(int16_t *)(sprites[i]+38)=sprite_ids[i];*(int16_t *)(sprites[i]+32)=sprite_layers[i];if(i<9)*(void **)(sprites[i]+300)=sprites[i+1];}
    *(void **)(g+0xe86)=sprites;
    for(int i=0;i<2;i++){*(int16_t *)entities[i]=999;*(int16_t *)(entities[i]+96)=777+i;}
    *(void **)(entities[0]+102)=entities[1];*(void **)(g+0xa76)=entities;
    jump_to(code+0x3a278,(void *)native_draw_fb);jump_to(code+0x559e8,(void *)native_beam_fb);*(uint32_t *)(code+0x342b4)=0x4e800020;
    MakeDataExecutable(code,433284);
    int expected_ids[12]={44,116,40,41,1,70,777,778,80,91,115,900};
    for(int stage=1;stage<=9;stage++){
        count=points=point_batches=0;*(int16_t *)(g+0xa82)=stage;
        invoke_fb(code+0x57afc,g,toc,NULL,NULL,NULL);
        if(count!=12||memcmp(ids,expected_ids,sizeof(expected_ids))){printf("Composite mismatch stage%d count%d\n",stage,count);return 1;}
        int expected_points=(stage<4||stage==7)?1000:0;
        if(points!=expected_points){printf("Stars mismatch stage%d points%d\n",stage,points);return 1;}
        printf("stage%d stars%d composite:",stage,points);for(int i=0;i<count;i++)printf(" %d@%d",ids[i],layers[i]);puts("");
    }
    puts("PASS:9stage completeoriginal painter stream:starconditions,layerorder,creationorder,beamseparator");return 0;
}
