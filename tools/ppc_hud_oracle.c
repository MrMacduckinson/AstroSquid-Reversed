/* Execute original DRAWOVERLAY privately; collect its draw stream without a GL context. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
#include "hud.h"
#include <math.h>
#include <assert.h>
static uint32_t descriptors[484][2];
static double color[4]={1,1,1,1};
static unsigned char *sprites;
static unsigned sequence,clock_reads;
static uint32_t hud_tick(void){return 100+clock_reads++;}
static AstroHUDCommand native_commands[32];
static double font_widths[257];
static void capture(AstroHUDKind kind,int sprite,int value,double x,double y,double w,double h){native_commands[sequence++]=(AstroHUDCommand){kind,sprite,value,x,y,w,h,color[0],color[1],color[2],color[3]};}
static void color3(double r,double g,double b){color[0]=r;color[1]=g;color[2]=b;color[3]=1;}
static void color4(double r,double g,double b,double a){color3(r,g,b);color[3]=a;}
static void noop(void){}
static void viewport(int x,int y,int w,int h){if(!((x==0&&y==0&&w==640&&h==480)||(x==0&&y==30&&w==640&&h==380)))abort();}
static void ortho(double x,double y,double z,double w){if(!(x==0&&y==640&&(z==480||z==379)&&w==0))abort();}
void missing_import_report(uint32_t *descriptor){int index=(int)(descriptor-&descriptors[0][0])/2;fprintf(stderr,"Unresolved HUD oracle import %d %s\n",index,index>=0&&index<484?import_names[index]:"unknown");exit(2);}
extern void missing_import(void);
__asm__(".text\n.align 2\n.globl _missing_import\n_missing_import:\nmr r3,r12\nb _missing_import_report\n");
void *new_sprite(int identifier,int kind,double *x,double *y){
    unsigned char *p=calloc(1,312);(void)kind;
    *(double *)p=*x;*(double *)(p+8)=*y;*(double *)(p+16)=*(int16_t *)(sprites+identifier*14+6);*(double *)(p+24)=*(int16_t *)(sprites+identifier*14+8);*(int16_t *)(p+38)=identifier;return p;
}
void kill_sprite(void *p){free(p);}
void draw_sprite(unsigned char *p){capture(ASTRO_HUD_SPRITE,*(int16_t *)(p+38),0,*(double *)p,*(double *)(p+8),*(double *)(p+16),*(double *)(p+24));}
void draw_box(double *x,double *y,double *right,double *bottom){capture(ASTRO_HUD_BOX,0,0,*x,*y,*right-*x,*bottom-*y);}
void draw_text(double *x,double *y,unsigned char *text,double *size){char string[256];memcpy(string,text+1,text[0]);string[text[0]]=0;int lives=string[0]=='x';capture(lives?ASTRO_HUD_LIVES:ASTRO_HUD_SCORE,0,atoi(string+lives),*x,*y,0,*size);}
#define BRIDGE(N) extern void N##_fb(void); __asm__(".text\n.align 2\n.globl _" #N "_fb\n_" #N "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #N "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
BRIDGE(new_sprite) BRIDGE(kill_sprite) BRIDGE(draw_sprite) BRIDGE(draw_box) BRIDGE(draw_text)
static unsigned char *read_file(const char *name){FILE *f=fopen(name,"rb");if(!f){perror(name);exit(2);}fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static void jump_to(unsigned char *at,void *destination){uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
int main(int argc,char **argv){
    if(argc!=5&&argc!=6){fputs("usage: ppc_hud_oracle original.pef literals.bin original-app sprt.bin [fixture.csv]\n",stderr);return 2;}
    int native_sprites=getenv("ASTRO_HUD_NATIVE_SPRITES")!=NULL;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*globals=calloc(1,0x1300),*heap=calloc(1,0x10000);sprites=read_file(argv[4]);uint32_t toc[489]={0};
    for(int i=0;i<484;i++){
        void *function=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"TickCount"))function=hud_tick;
        if(!strcmp(import_names[i],"glColor3d"))function=color3;
        if(!strcmp(import_names[i],"glColor4d"))function=color4;
        if(!strcmp(import_names[i],"glViewport"))function=viewport;
        if(!strcmp(import_names[i],"gluOrtho2D"))function=ortho;
        if(!strncmp(import_names[i],"gl",2)&&function!=color3&&function!=color4&&function!=viewport&&function!=ortho)function=noop;
        descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:(void *)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    *(void **)(globals+0xe82)=sprites;*(void **)(globals+0x21c)=literals;*(double *)(globals+0x378)=4503601774854144.;*(uint32_t *)(globals+0x380)=0x43300000;
    *(void **)(globals+0x388)=heap;*(void **)(globals+0x38c)=heap;toc[0]=(uint32_t)(uintptr_t)globals;
    *(int16_t *)(globals+0xed6)=640;*(int16_t *)(globals+0xed8)=480;
    Str255 text;*(void **)(globals+0xeb6)=font_widths;
    FSRef ref;SInt16 resourceFile;HFSUniStr255 forkName;OSStatus error=FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL);
    if(!error)error=FSGetResourceForkName(&forkName);if(!error)error=FSOpenResourceFile(&ref,forkName.length,forkName.unicode,fsRdPerm,&resourceFile);if(error)return 2;UseResFile(resourceFile);
    for(int i=1;i<=256;i++){GetIndString(text,129,i);text[text[0]+1]=0;font_widths[i]=atof((char *)text+1)/32;}font_widths[32]=.2;
    if(!native_sprites){jump_to(code+0x34a34,new_sprite_fb);jump_to(code+0x34dd8,kill_sprite_fb);}jump_to(code+0x3a278,draw_sprite_fb);jump_to(code+0x41730,draw_box_fb);jump_to(code+0x3572c,draw_text_fb);jump_to(code+0x342b4,noop);MakeDataExecutable(code,433284);
    FILE *fixture=argc==6?fopen(argv[5],"w"):NULL;
    if(argc==6&&!fixture)return 2;
    unsigned cases=0;
    for(int present=0;present<=1;present++)for(int hp=0;hp<=250;hp+=50)for(int weapon=10;weapon<=50;weapon+=10)for(int upgrade=0;upgrade<4;upgrade++)for(int ammo=0;ammo<=4;ammo++){
        if(weapon==20)continue;
        unsigned char player[128]={0};*(void **)(globals+0xa7a)=present?player:NULL;*(int16_t *)(player+88)=hp;
        *(int16_t *)(globals+0xa8a)=weapon;*(int16_t *)(globals+0xa8c)=upgrade;*(int16_t *)(globals+0xa8e)=ammo;*(int *)(globals+0xa86)=4;*(int *)(globals+0xa7e)=12345;
        sequence=0;clock_reads=0;*(void **)(globals+0x38c)=heap;
        double camera_x=cases%2?-1234.25:1234.75,camera_y=cases%4<2?19.5:-19.5;
        *(double *)(globals+0xea2)=camera_x;*(double *)(globals+0xeaa)=camera_y;
        double bounds[4]={-camera_x,640-camera_x,-camera_y,380-camera_y};
        memcpy(globals+0xa1e,bounds,sizeof(bounds));
        invoke_fb(code+0x43134,globals,toc,NULL,NULL,NULL);
        assert(*(double *)(globals+0xea2)==(double)(int32_t)camera_x);
        assert(*(double *)(globals+0xeaa)==(double)(int32_t)camera_y);
        assert(!memcmp(globals+0xa1e,bounds,sizeof(bounds)));
        AstroHUDState state={present,hp,weapon,upgrade,ammo,4,12345};AstroHUDCommand ported[32];size_t n=astro_hud_commands(&state,ported,32);
        if(native_sprites){unsigned expected=0;for(unsigned i=0;i<n;i++)expected+=ported[i].kind==ASTRO_HUD_SPRITE;assert(clock_reads==expected);assert(!*(void **)(globals+0xe86));if(!cases)fprintf(stderr,"Native HUD creates and destroys %u sprites with %u TickCount calls per draw\n",expected,clock_reads);}
        if(n!=sequence){fprintf(stderr,"Command count differs %lu %u\n",(unsigned long)n,sequence);return 1;}
        for(unsigned i=0;i<n;i++){
            AstroHUDCommand a=native_commands[i],b=ported[i];
            if(b.kind==ASTRO_HUD_SCORE){char text[256];snprintf(text,sizeof(text)," %d",b.value);double width=0;for(unsigned j=0;j<strlen(text);j++)width+=b.height*font_widths[(unsigned char)text[j]];b.x-=(int)width/2.;}
            if(a.kind!=b.kind||a.sprite!=b.sprite||a.value!=b.value||fabs(a.x-b.x)>1e-9||fabs(a.y-b.y)>1e-9||fabs(a.width-b.width)>1e-9||fabs(a.height-b.height)>1e-9||fabs(a.r-b.r)>1e-9||fabs(a.g-b.g)>1e-9||fabs(a.b-b.b)>1e-9||fabs(a.a-b.a)>1e-9){
                fprintf(stderr,"HUD mismatch case%u command%u native x%.12g y%.12g alpha%.12g port x%.12g y%.12g alpha%.12g\n",cases,i,a.x,a.y,a.a,b.x,b.y,b.a);return 1;
            }
        }
        if(fixture&&(cases%137==0||cases==959))for(unsigned i=0;i<n;i++){
            AstroHUDCommand c=native_commands[i];
            fprintf(fixture,"%d,%d,%d,%d,%d,%d,%d,%u,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n",present,hp,weapon,upgrade,ammo,4,12345,i,c.kind,c.sprite,c.value,c.x,c.y,c.width,c.height,c.r,c.g,c.b,c.a);
        }
        cases++;
    }
    if(fixture)fclose(fixture);
    CloseResFile(resourceFile);printf("PASS %u native DRAWOVERLAY cases, %u commands including geometry/colors/alpha/text and viewport\n",cases,cases*21);return 0;
}
