/* Original score insertion/editing oracle; SAVEHIGHSCORES is disabled in private code only. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
#include "ui_model.h"
static uint32_t descriptors[484][2];

void missing_import_report(uint32_t *descriptor){int index=(int)(descriptor-&descriptors[0][0])/2;fprintf(stderr,"Unresolved scores oracle import %d\n",index);exit(2);}
extern void missing_import(void);
__asm__(".text\n.align 2\n.globl _missing_import\n_missing_import:\nmr r3,r12\nb _missing_import_report\n");
static unsigned char *read_file(const char *name){FILE *f=fopen(name,"rb");if(!f){perror(name);exit(2);}fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static unsigned char panels[4][312] __attribute__((aligned(16)));
static AstroUIMotion panel_model[4];
static int panel_count,panel_frames,panel_expected,panel_lookup,panel_mode,panel_direction;static FILE *panel_vectors;static double panel_step;
static void noop(void){}
static void *panel_sprite(void){void *result=panels[panel_lookup++%panel_count];return result;}
static Handle native_resource(ResType type,short identifier){return GetResource(type,identifier);}
static void panel_render(void){
    for(int i=0;i<panel_count;i++){
        astro_ui_panel_step(&panel_model[i],panel_step);
        if(memcmp(panels[i]+8,&panel_model[i].y,8)){fprintf(stderr,"Panel mismatch frame%d row%d\n",panel_frames,i);exit(1);}
    if(panel_vectors)fprintf(panel_vectors,"%d,%d,%d,%d,%016llx\n",panel_mode,panel_direction,panel_frames,i,*(unsigned long long *)(panels[i]+8));
    }panel_frames++;
}
static void jump_to(unsigned char *at,void *destination){uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
int main(int argc,char **argv){
    if(argc<3)return 2;setvbuf(stdout,NULL,_IONBF,0);
    FILE *vectors=argc>3?fopen(argv[3],"w"):NULL;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*globals=calloc(1,0x1300),*heap=calloc(1,0x10000);uint32_t toc[489]={0};
    for(int i=0;i<484;i++){void *function=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))function=native_resource;descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:(void *)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    *(void **)(globals+0x21c)=literals;*(double *)(globals+0x378)=4503601774854144.;*(uint32_t *)(globals+0x380)=0x43300000;
    *(void **)(globals+0x388)=heap;*(void **)(globals+0x38c)=heap;toc[0]=(uint32_t)(uintptr_t)globals;
    MakeDataExecutable(code,433284);
    unsigned char record[308];unsigned checks=0;
    for(int interval=1;interval<=5;interval++)for(int sprite=899;sprite<=903;sprite++)for(int initial=-2;initial<=62;initial++){
        memset(record,0,sizeof(record));double *xy=(double *)record;
        xy[0]=381.1;xy[1]=-70.3;xy[2]=65.7;xy[3]=380.2;*(int16_t *)(record+38)=sprite;*(int32_t *)(record+296)=initial;
        *(void **)(globals+0xe86)=record;*(int16_t *)(globals+0xa52)=interval;
        AstroUIMotion state={xy[0],xy[1],xy[2],xy[3],initial,sprite};
        for(int frame=0;frame<125;frame++){
            *(void **)(globals+0x38c)=heap;invoke_fb(code+0x45f20,globals,toc,NULL,NULL,NULL);astro_ui_animate(&state,interval);
            const double expected[]={state.x,state.y,state.width,state.height};
            if(memcmp(expected,xy,32)||state.counter!=*(int32_t *)(record+296)){
                fprintf(stderr,"Mismatch interval%d sprite%d initial%d frame%d\n",interval,sprite,initial,frame);
                for(int i=0;i<4;i++)fprintf(stderr,"%016llx/%016llx ",((unsigned long long *)xy)[i],((const unsigned long long *)expected)[i]);return 1;
            }checks++;
            if(vectors&&frame==124)fprintf(vectors,"%d,%d,%d,%016llx,%016llx,%016llx,%016llx,%d\n",interval,sprite,initial,((unsigned long long *)xy)[0],((unsigned long long *)xy)[1],((unsigned long long *)xy)[2],((unsigned long long *)xy)[3],*(int32_t *)(record+296));
        }
    }
    if(vectors)fclose(vectors);
    if(argc>4){
        panel_vectors=argc>5?fopen(argv[5],"w"):NULL;FSRef ref;SInt16 rf;HFSUniStr255 forkName;OSStatus error=FSPathMakeRef((const UInt8 *)argv[4],&ref,NULL);
        if(!error)error=FSGetResourceForkName(&forkName);if(!error)error=FSOpenResourceFile(&ref,forkName.length,forkName.unicode,fsRdPerm,&rf);if(error)return 2;UseResFile(rf);
        /* Isolate panel arithmetic: replace resource-name lookups by matching record order. */
        jump_to(code+0x2ca8,noop);jump_to(code+0x3b260,panel_sprite);
        jump_to(code+0x57afc,panel_render);jump_to(code+0x44898,noop);jump_to(code+0x44e10,noop);jump_to(code+0x43134,noop);jump_to(code+0x35eb8,noop);MakeDataExecutable(code,433284);
        for(int mode=0;mode<2;mode++){
            const char *names[]={"Pause","PauseQuit","PauseContinue","PauseFade","GameOverOK","GameOverFade"};
            panel_mode=mode;panel_count=mode?2:4;panel_expected=mode?60:30;
            for(int i=0;i<panel_count;i++){
                memset(panels[i],0,308);double y=(217.1+i*37.7-380)-70;
                *(double *)(panels[i]+8)=y;panels[i][40]=strlen(names[i+(mode?4:0)]);memcpy(panels[i]+41,names[i+(mode?4:0)],panels[i][40]);
                *(void **)(panels[i]+300)=i+1<panel_count?panels[i+1]:NULL;
                panel_model[i]=(AstroUIMotion){0,y,65,65,0,900};
            }
            *(void **)(globals+0xe86)=panels[0];
            
            for(int direction=1;direction>=-1;direction-=2){
                panel_direction=direction;panel_frames=0;panel_lookup=0;panel_step=(380.0/panel_expected)*direction;
                *(void **)(globals+0x38c)=heap;invoke_fb(code+(mode?0x4cd48:0x4d574),globals,toc,(void *)(intptr_t)direction,NULL,NULL);
                if(panel_frames!=panel_expected)return 1;
            }
        }
        if(panel_vectors)fclose(panel_vectors);CloseResFile(rf);puts("PASS original Pause30/GameOver60 forward/reverse panel raw-double states");
    }
    printf("PASS %u original ANIMATEMENU raw-double/counter states\n",checks);return 0;
}
