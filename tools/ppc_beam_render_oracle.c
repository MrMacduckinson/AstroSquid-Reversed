/* Compare original RENDERBEAM GL line stream in an isolated PowerPC process.
 * GL calls, temporary sprites and transformations are recorded without a display context. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../src/scene.h"
#include "ppc_bridge.h"
#include "imports.h"
typedef struct {double x,y,ex,ey;AstroLineStyle style;} Segment;
static Segment native[20000],ported[20000];static unsigned nc,pc;static int pending;
static double px,py;static AstroLineStyle style;

static AstroSceneSprite ns[32],ps[32];static unsigned nsc,psc;
static unsigned char sprite_pool[32][312];static unsigned allocated;
static double matrix[6],camera_x,camera_y;
static void record_sprite(unsigned char *p,int persistent) {
    if(nsc>=32)exit(2);AstroSceneSprite *s=&ns[nsc++];memset(s,0,sizeof(*s));
    s->sprite=*(int16_t *)(p+38);s->persistent=persistent;s->alpha=style.a;
    double x=*(double *)p+camera_x,y=*(double *)(p+8)+camera_y;
    double w=*(double *)(p+16),h=*(double *)(p+24);
    double xx[4]={x,x+w,x+w,x},yy[4]={y,y,y+h,y+h};
    for(int i=0;i<4;i++){s->xy[2*i]=matrix[0]*xx[i]+matrix[2]*yy[i]+matrix[4];s->xy[2*i+1]=matrix[1]*xx[i]+matrix[3]*yy[i]+matrix[5];}
}
void *native_new(int id,int layer,double *x,double *y,void *name) {
    (void)layer;(void)name;if(allocated>=32)exit(2);unsigned char *p=sprite_pool[allocated++];memset(p,0,312);
    *(double *)p=*x;*(double *)(p+8)=*y;*(int16_t *)(p+38)=id;
    *(double *)(p+16)=id==116?22:id==115?41:39;
    *(double *)(p+24)=id==116?30:41;
    if(id==89||id==90)record_sprite(p,1);return p;
}
void native_draw(unsigned char *p) {record_sprite(p,0);}
static void translated(double x,double y,double z) {(void)z;matrix[4]+=matrix[0]*x+matrix[2]*y;matrix[5]+=matrix[1]*x+matrix[3]*y;}
static void rotated(double angle,double x,double y,double z) {
    (void)x;(void)y;(void)z;double c=cos(angle*3.14159265358979323846/180),sn=sin(angle*3.14159265358979323846/180);
    double a=matrix[0]*c+matrix[2]*sn,b=matrix[1]*c+matrix[3]*sn;
    matrix[2]=-matrix[0]*sn+matrix[2]*c;matrix[3]=-matrix[1]*sn+matrix[3]*c;matrix[0]=a;matrix[1]=b;
}
extern void native_new_fb(void),native_draw_fb(void);
__asm__(
".text\n.align 2\n.globl _native_new_fb\n_native_new_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_new\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
".align 2\n.globl _native_draw_fb\n_native_draw_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_draw\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void noop(void) {}
static void color(double r,double g,double b,double a) {style.r=r;style.g=g;style.b=b;style.a=a;}
static void color3(double r,double g,double b) {color(r,g,b,1);}
static void width(float w) {style.width=w;}
static void vertex(double x,double y) {
    if(!pending) {px=x;py=y;pending=1;return;}
    if(nc>=20000)exit(2);native[nc++]=(Segment){px,py,x,y,style};pending=0;
}
static void output(void *p,double x,double y,double ex,double ey,AstroLineStyle s) {
    (void)p;if(pc>=20000)exit(2);ported[pc++]=(Segment){x,y,ex,ey,s};
}
static void sprite(void *p,const AstroSceneSprite *s) {(void)p;if(psc>=32)exit(2);ps[psc++]=*s;}
static void jump_to(unsigned char *at,void *destination) {
    uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;
    w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);
    w[2]=0x7d8903a6;w[3]=0x4e800420;
}
static unsigned char *read_file(const char *name) {
    FILE *f=fopen(name,"rb");if(!f)exit(2);fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);
    unsigned char *p=malloc(n);if(!p||fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;
}
int main(int argc,char **argv) {
    if(argc!=4&&argc!=5)return 2;
    FILE *fixture=argc==5?fopen(argv[4],"w"):NULL;if(argc==5&&!fixture)return 2;
    if(fixture)fputs("weapon,x,y,end_x,end_y,camera_x,camera_y,seed,line_count,sprite_count,final_seed,weighted_sum\n",fixture);
    unsigned char *pef=read_file(argv[1]),*literals=read_file(argv[2]),*code=pef+128;
    unsigned char *globals=calloc(1,0x1300),*heap=calloc(1,0x10000);
    uint32_t descriptors[484][2],toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++) {
        void *f=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strncmp(import_names[i],"gl",2))f=(void *)noop;
        if(!strcmp(import_names[i],"glColor4d"))f=(void *)color;
        if(!strcmp(import_names[i],"glColor3d"))f=(void *)color3;
        if(!strcmp(import_names[i],"glLineWidth"))f=(void *)width;
        if(!strcmp(import_names[i],"glVertex2d"))f=(void *)vertex;
        if(!strcmp(import_names[i],"glTranslated"))f=(void *)translated;
        if(!strcmp(import_names[i],"glRotated"))f=(void *)rotated;
        descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:(void *)noop);descriptors[i][1]=0;
        toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    toc[0]=(uint32_t)(uintptr_t)globals;
    *(void **)(globals+0x21c)=literals;*(double *)(globals+0x368)=3.14159265358979323846;
    *(double *)(globals+0x378)=4503601774854144.0;*(uint32_t *)(globals+0x380)=0x43300000;
    *(void **)(globals+0x388)=heap;*(void **)(globals+0x38c)=heap;
    jump_to(code+0x34a34,(void *)native_new_fb);
    jump_to(code+0x3a278,(void *)native_draw_fb);*(uint32_t *)(code+0x34dd8)=0x4e800020;
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;
    OSStatus err=FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL);
    if(!err)err=FSGetResourceForkName(&fork);
    if(!err)err=FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf);
    if(err){printf("resource error%ld\n",(long)err);return 2;}UseResFile(rf);
    *(uint32_t *)(code+0x342b4)=0x4e800020;
    MakeDataExecutable(code,433284);
    uint32_t seed=0x12345678;
    for(int trial=0;trial<400;trial++) {
        AstroBeam beam={0};beam.weapon=trial%8<4?40+trial%4:50+trial%4;
        beam.x=30+trial%7;beam.y=100+trial%19;
        beam.end_x=trial%11==0?beam.x:beam.x+(trial%3?-250:350);
        beam.end_y=trial%13==0?beam.y:beam.y+(trial%2?-40:140);
        double cx=trial%3*1.3,cy=trial%5*.8;camera_x=cx;camera_y=cy;
        unsigned char entity[128];memset(entity,0,sizeof(entity));
        *(int16_t *)(entity+2)=beam.weapon;*(double *)(entity+44)=beam.x;*(double *)(entity+52)=beam.y;
        *(double *)(entity+72)=beam.end_x;*(double *)(entity+80)=beam.end_y;
        *(double *)(globals+0xea2)=cx;*(double *)(globals+0xeaa)=cy;
        *(double *)(globals+0xa1e)=0;*(double *)(globals+0xa26)=640;*(double *)(globals+0xa2e)=70;*(double *)(globals+0xa36)=450;
        uint32_t initial_seed=seed;*(uint32_t *)(globals+0x244)=seed;
        nc=pc=nsc=psc=allocated=0;matrix[0]=matrix[3]=1;matrix[1]=matrix[2]=matrix[4]=matrix[5]=0;pending=0;style=(AstroLineStyle){1,1,1,1,1};
        invoke_fb(code+0x559e8,globals,toc,entity,NULL,NULL);
        uint32_t native_seed=*(uint32_t *)(globals+0x244);
        AstroSceneSink sink={0};sink.line=output;sink.sprite=sprite;
        astro_beam_render(&beam,cx,cy,0,70,640,450,&seed,&sink);
        if(nc!=pc||native_seed!=seed) {
            printf("count/seed mismatch trial%d weapon%d native%u port%u seed%08x/%08x\n",trial,beam.weapon,nc,pc,native_seed,seed);return 1;
        }
        if(nsc!=psc){printf("spritecount mismatch trial%d native%u port%u\n",trial,nsc,psc);return 1;}
        for(unsigned i=0;i<nsc;i++) {
            if(ns[i].sprite!=ps[i].sprite||ns[i].persistent!=ps[i].persistent||fabs(ns[i].alpha-ps[i].alpha)>1e-9) {printf("sprite metadata mismatch trial%d sprite%u %d/%d alpha%g/%g\n",trial,i,ns[i].sprite,ps[i].sprite,ns[i].alpha,ps[i].alpha);return 1;}
            for(int j=0;j<8;j++)if(fabs(ns[i].xy[j]-ps[i].xy[j])>1e-8){printf("spritevertex mismatch trial%d weapon%d sprite%u component%d original%.17g port%.17g\n",trial,beam.weapon,i,j,ns[i].xy[j],ps[i].xy[j]);return 1;}
        }
        for(unsigned i=0;i<nc;i++) for(int j=0;j<9;j++) {
            double a=((double *)&native[i])[j],b=((double *)&ported[i])[j];
            if(fabs(a-b)>1e-9) {
                printf("segment mismatch trial%d weapon%d segment%u component%d original%.17g portable%.17g\n",trial,beam.weapon,i,j,a,b);return 1;
            }
        }
        if(fixture&&trial<8) {
            double sum=0;
            for(unsigned i=0;i<nc;i++)for(int j=0;j<9;j++)sum+=((double *)&native[i])[j]*(i%23+1)*(j+1);
            for(unsigned i=0;i<nsc;i++) {sum+=ns[i].sprite*31+ns[i].persistent*37+ns[i].alpha*41;for(int j=0;j<8;j++)sum+=ns[i].xy[j]*(i+1)*(j+1);}
            fprintf(fixture,"%d,%d,%d,%d,%d,%.17g,%.17g,%u,%u,%u,%u,%.17g\n",beam.weapon,beam.x,beam.y,beam.end_x,beam.end_y,cx,cy,initial_seed,nc,nsc,seed,sum);
        }
    }
    if(fixture)fclose(fixture);
    puts("PASS:400 original/portable laser+lightning beam line+sprite streams incl vertices,RGBA,width,RNG state on PowerPC");return 0;
}
