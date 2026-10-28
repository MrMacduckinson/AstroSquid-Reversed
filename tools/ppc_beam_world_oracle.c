/* Original FIREWEAPON→NEWBEAM→actual hit→RENDERBEAM/cleanup, private copy only. */
#define ASTRO_WORLD_ORACLE_LIBRARY
#include "ppc_world_oracle.c"
static FILE *clock_events;
static unsigned clock_count;
static Handle strings,script215;
static void no_draw(void){}
static Handle constant_resource(ResType type,short id){if(type=='STR#'&&id==215&&script215)return script215;if(type!='STR#'||id!=25000){fprintf(stderr,"Unexpected resource%d\n",id);exit(3);}return strings;}
static uint32_t beam_clock(void){
    uint32_t value=1000+clock_count++;
    if(!strcmp(phase,"fire")||!strcmp(phase,"render")||!strcmp(phase,"calc")){
        unsigned char *e=*(void **)(world_globals+0xa76);
        fprintf(clock_events,"Q\t%s\t%u\t%u\t%08x\t%u\t%d\t%u\t%u\t%u\t%u\n",phase,clock_count-1,value,
            *(uint32_t *)(world_globals+0x244),identity(e),*(int16_t *)e,
            *(uint32_t *)(e+8),*(uint32_t *)(e+12),*(uint32_t *)(e+16),render_birth);
    }
    return value;
}
static void render_beams(unsigned char *code,uint32_t *toc){
    for(unsigned char *e=*(void **)(world_globals+0xa76);e;e=*(void **)(e+102))
        if(*(int16_t *)e==999)invoke_fb(code+0x559e8,world_globals,toc,e,NULL,NULL);
}
int main(int argc,char **argv){
    setvbuf(stdout,NULL,_IONBF,0);
    if(argc!=8&&argc!=9)return 2;int chain=argc==9&&!strcmp(argv[8],"chain"),kill=argc==9&&!strcmp(argv[8],"kill");int calc=argc==9&&!strcmp(argv[8],"calc");if(argc==9&&!chain&&!kill&&!calc)return 2;int weapon=atoi(argv[5]),cleanup_first=atoi(argv[6]);if(!((weapon>=40&&weapon<=43)||(weapon>=50&&weapon<=53))||(cleanup_first!=0&&cleanup_first!=1))return 2;
    clock_events=fopen(argv[7],"w");if(!clock_events)return 2;setvbuf(clock_events,NULL,_IONBF,0);
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);world_globals=g;phase="setup";
    unsigned char *raw=read_file(argv[4]);strings=NewHandle(6884);if(!strings)return 2;memcpy(*strings,raw,6884);
    if(calc){char scriptpath[2048];snprintf(scriptpath,sizeof(scriptpath),"%s.215",argv[4]);unsigned char *rawscript=read_file(scriptpath);script215=NewHandle(77);if(!script215)return 2;memcpy(*script215,rawscript,77);}
    uint32_t toc[489]={0};for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strncmp(import_names[i],"gl",2))fn=no_draw;
        if(!strcmp(import_names[i],"TickCount"))fn=beam_clock;
        if(!strcmp(import_names[i],"GetResource"))fn=constant_resource;
        if(!strcmp(import_names[i],"NewPtrClear"))fn=world_alloc;
        if(!strcmp(import_names[i],"DisposePtr"))fn=world_dispose;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    char path[2048];snprintf(path,sizeof(path),"%s/Attr.bin",argv[3]);set_pointer(g,0xa94,read_file(path));snprintf(path,sizeof(path),"%s/sprt.bin",argv[3]);set_pointer(g,0xe82,read_file(path));snprintf(path,sizeof(path),"%s/Wpns.bin",argv[3]);set_pointer(g,0xa98,read_file(path));
    set_pointer(g,0x21c,lit);set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.);*(uint32_t *)(g+0x380)=0x43300000;set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);
    set_short(g,0xed6,640);set_short(g,0xed8,480);set_double(g,0xa1e,calc?-0.0:0);set_double(g,0xa26,640);set_double(g,0xa2e,-0.0);set_double(g,0xa36,380);
    set_pointer(g,0xa54,calloc(3001*4,sizeof(double)));
    set_pointer(g,0x1004,calloc(7,0x108)); /* Native FIREWEAPON scans six idle sound channels. */
    set_pointer(g,0xcd6,calloc(1,8)); /* Already-loaded texture 0; GL calls are observation-only. */
    set_short(g,0xa52,1);set_short(g,0xa8a,weapon);set_short(g,0xa8e,2);*(uint32_t *)(g+0x244)=0x12345678;
    jump_to(code+0x3ce84,world_sound_fb);jump_to(code+0x3a278,no_draw);MakeDataExecutable(code,433284);
    unsigned char *player=spawn(code,toc,1,1,30,190);set_pointer(g,0xa7a,player);set_short(player,24,12);set_short(player,26,1);set_short(player,88,100);
    unsigned char *target=spawn(code,toc,7,3,weapon==40?300:180,190);set_short(target,88,kill?1:100);
    if(chain||kill){unsigned char *second=spawn(code,toc,7,3,225,200);set_short(second,88,kill?1:100);}
    tick=0;snapshot();
    phase="fire";world_invoke5(code+0x58f40,g,toc,(void *)(intptr_t)weapon,(void *)104,(void *)202,0,player);snapshot();
    if(calc){phase="calc";invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);snapshot();}
    if(cleanup_first){phase="cleanup";invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);snapshot();}
    phase="render";render_beams(code,toc);snapshot();
    if(!cleanup_first){phase="cleanup";invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);snapshot();}
    phase="after";world_invoke5(code+0x54248,g,toc,(void *)1,(void *)50,(void *)90,0,player);snapshot();
    fclose(clock_events);return 0;
}
