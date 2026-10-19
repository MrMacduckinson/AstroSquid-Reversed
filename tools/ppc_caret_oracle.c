/* Original DRAWMYEDITFIELD clock logic. Private draw-only no-ops, no GL/audio. */
#define main ui_motion_oracle_main
#include "ppc_ui_motion_oracle.c"
#undef main
#include "scores.h"
static uint32_t clock_values[2];static unsigned clock_reads;
static uint32_t caret_tick(void){if(clock_reads>=2)exit(2);return clock_values[clock_reads++];}
static int zero_width(void){return 0;}
int main(int argc,char **argv){
    if(argc!=3)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x10000);
    unsigned char field[560]={0};uint32_t toc[489]={0};
    for(int i=0;i<484;i++){void*f=dlsym(RTLD_DEFAULT,import_names[i]);if(!strncmp(import_names[i],"gl",2))f=noop;if(!strcmp(import_names[i],"TickCount"))f=caret_tick;descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:(void*)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    *(void**)(g+0x21c)=literals;*(double*)(g+0x378)=4503601774854144.;*(uint32_t*)(g+0x380)=0x43300000;
    *(void**)(g+0x388)=heap;*(void**)(g+0xa06)=field;toc[0]=(uint32_t)(uintptr_t)g;
    ((double*)field)[2]=200;((double*)field)[3]=22;
    jump_to(code+0x342b4,noop);jump_to(code+0x41730,noop);jump_to(code+0x3572c,noop);jump_to(code+0x419ec,zero_width);MakeDataExecutable(code,433284);
    const uint32_t edges[]={0,1,19,20,21,40,41,1000,0x7fffffeb,0x7fffffff,0x80000000,0xffffffeb,0xffffffff};
    uint32_t random=0x12345678;unsigned cases=0;
    for(unsigned i=0;i<4225;i++){
        uint32_t start,tick,reset;if(i<169){start=edges[i/13];tick=edges[i%13];reset=tick+1;}else{random=random*1664525u+1013904223u;start=random;random=random*1664525u+1013904223u;tick=random;reset=tick+(i%3);}
        AstroScoreCaret model;astro_score_caret_begin(&model,start);
        *(uint32_t*)(field+0x20)=start+20u;*(int16_t*)(field+0x26)=1;
        uint32_t before=*(uint32_t*)(field+0x20);clock_values[0]=tick;clock_values[1]=reset;clock_reads=0;*(void**)(g+0x38c)=heap;
        invoke_fb(code+0x41b70,g,toc,field,NULL,NULL);astro_score_caret_draw(&model,tick,reset);
        if(model.deadline!=*(uint32_t*)(field+0x20)||model.visible!=*(int16_t*)(field+0x26)||clock_reads!=((int32_t)before<(int32_t)tick?2u:1u)){fprintf(stderr,"Caret mismatch case%u\n",i);return 1;}
        printf("%u,%u,%u,%u,%d,%u\n",start,tick,reset,model.deadline,model.visible,clock_reads);cases++;
    }
    fprintf(stderr,"PASS %u original caret deadline/visibility/clock-read cases\n",cases);return 0;
}
