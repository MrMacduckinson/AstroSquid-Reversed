/* Actual cleanup/death/LOADLEVEL/scene/spawn; FB file boundary reads original files. */
#define ASTRO_WORLD_ORACLE_LIBRARY
#include "ppc_world_oracle.c"
#include <assert.h>
#include <unistd.h>
#include <setjmp.h>
static FILE *input_file;static long input_size;static const char *data_directory;
static unsigned clock_reads,opens,records,map_records,scene_records;
static int advancing,load_mode,start_mode,run_mode,chain_mode,loop_mode,resume_mode,mid_mode,mid_full,end_mode,end_full,resume_long,gameover_entry,gameover_reached,warm_mode;
static unsigned warm_frames,panel_world_birth;
static int real_hud,panel_mode,input_mode,panel_active,cleanup_mode,tail_mode,cleanup_done;
static unsigned input_index;
static const unsigned char panel_input[]={65,66,28,67,13};
static Boolean panel_event(EventMask mask,EventRecord *event){assert(panel_active&&mask==0x28&&input_index<sizeof(panel_input));memset(event,0,sizeof(*event));event->what=keyDown;event->message=panel_input[input_index++];return true;}
static int panel_button(void){return 0;}
static double hud_font_widths[257];
static jmp_buf loop_done;static unsigned loop_step;static char loop_label[32];
void loop_noop(void){}
static void warm_delay(unsigned ticks,unsigned *final){
 static const unsigned expected[]={0,1,1,2,3,3,4,4,5,6};assert(warm_frames<10&&ticks==expected[warm_frames]);
 snprintf(loop_label,sizeof loop_label,"warm%u",warm_frames);phase=loop_label;snapshot();
 printf("D\t%u\t%u\t%u\n",warm_frames++,ticks,clock_reads);clock_reads+=ticks;*final=100+clock_reads;
}
static void warm_cursor(void){assert(warm_frames==10);if(panel_mode){panel_world_birth=render_birth;puts("W\twarm-complete");return;}gameover_reached=1;puts("W\tcomplete");longjmp(loop_done,1);}

void panel_ready(void){
 assert(panel_mode&&warm_frames==10);unsigned char *g=world_globals;phase="panel-ready";snapshot();unsigned count=0;
 for(unsigned char *node=*(void **)(g+0xe86);node;node=*(void **)(node+300))if(identity(node)>panel_world_birth){
  printf("U\t%u\t",count++);hex(node+41,node[40]);printf("\t%d\t%d\t%u\t%d",*(short *)(node+32),*(short *)(node+38),*(unsigned *)(node+34),*(int *)(node+296));
  for(unsigned i=0;i<4;i++){double v=*(double *)(node+i*8);if(i<2&&node[40]>=8&&!memcmp(node+41,"GameOver",8))v+=*(double *)(g+0xea2+i*8);printf("\t%016llx",(unsigned long long)ieee_word(v));}putchar('\n');
 }assert(count==3);
 printf("F");for(unsigned i=0;i<4;i++){double v=*(double *)(g+0x5b2+i*8);if(i<2)v+=*(double *)(g+0xea2+i*8);printf("\t%016llx",(unsigned long long)ieee_word(v));}printf("\t%u\n",*(unsigned *)(g+0x5d2));
 printf("K\tpanel\t%u\t%u\t%u\n",clock_reads,*(unsigned *)(g+0xa4a),*(unsigned *)(g+0xa4e));gameover_reached=1;puts("W\tpanel-complete");if(input_mode){panel_active=1;return;}longjmp(loop_done,1);
}
void panel_save(void){assert(input_mode&&input_index==5);phase="panel-submit";snapshot();printf("V\t%u\t%u\t",clock_reads,*(unsigned *)(world_globals+0xa4a));hex(world_globals+0x6db,world_globals[0x6da]);putchar('\n');printf("Q\t%d\n",*(short *)(world_globals+0xa6c));for(unsigned i=1;i<=10;i++){unsigned char *name=*(unsigned char **)(world_globals+0xa6e)+i*256;printf("H\t%u\t%d\t",i,(*(int **)(world_globals+0xa72))[i]);hex(name+1,name[0]);putchar('\n');}puts("W\tinput-complete");if(cleanup_mode)return;longjmp(loop_done,1);}
static void panel_dispose(void *pointer){unsigned char *node=pointer;int done=cleanup_mode&&panel_active&&allocation(pointer)&&allocation(pointer)->size==308&&node[40]==12&&!memcmp(node+41,"GameOverFade",12);world_dispose(pointer);if(done){phase="panel-cleanup";snapshot();printf("Z\t%u\t%u\n",clock_reads,*(unsigned *)(world_globals+0xa4a));puts("W\tcleanup-complete");cleanup_done=1;if(tail_mode)return;longjmp(loop_done,1);}}
void gameover_enter(void){gameover_reached=1;phase="gameover-entry";snapshot();printf("K\tentry\t%u\t%u\t%u\n",clock_reads,*(unsigned *)(world_globals+0xa4a),*(unsigned *)(world_globals+0xa4e));longjmp(loop_done,1);}
void end_sound(unsigned char *name){double pan=NAN;world_sound(name,&pan);}
void loop_keys(void){unsigned k=(loop_step/8)%16;unsigned char *g=world_globals;set_short(g,0xaac,k&1?-1:0);set_short(g,0xaae,k&2?-1:0);set_short(g,0xaa8,k&4?-1:0);set_short(g,0xaaa,k&8?-1:0);set_short(g,0xab2,loop_step%7==0?-1:0);}
void loop_misc(void){if(tail_mode&&cleanup_done){phase="gameover-tail";snapshot();printf("Y\t%u\t%u\t%u\n",clock_reads,*(unsigned *)(world_globals+0xa4a),*(unsigned *)(world_globals+0xa4e));puts("W\ttail-complete");longjmp(loop_done,1);}snapshot();printf("K\t%u\t%u\t%u\t%u\n",loop_step,clock_reads,*(unsigned *)(world_globals+0xa4a),*(unsigned *)(world_globals+0xa4e));if((*(short *)(world_globals+0x58c)&&(!resume_mode||(resume_long&&!gameover_entry&&*(int32_t *)(world_globals+0xa86)==0)))||*(short *)(world_globals+0x5ac)){printf("B\t%u\t%d\t%d\n",loop_step,*(short *)(world_globals+0x58c),*(short *)(world_globals+0x5ac));longjmp(loop_done,1);}if(++loop_step==(resume_long?1024:256))longjmp(loop_done,1);snprintf(loop_label,sizeof loop_label,"loop%u",loop_step);phase=loop_label;}
void mid_observe(void){snapshot();printf("K\t%u\t%u\t%u\t%u\n",loop_step,clock_reads,*(unsigned *)(world_globals+0xa4a),*(unsigned *)(world_globals+0xa4e));if(++loop_step==(end_mode?256:16)&&!mid_full&&!end_full)longjmp(loop_done,1);assert(loop_step<10000);snprintf(loop_label,sizeof loop_label,"mid%u",loop_step);phase=loop_label;}
void arena_ready(void){}
static uint32_t arena_tick(void){unsigned index=clock_reads++;return tick+(advancing&&phase&&strcmp(phase,"before")?index:0);}
int arena_system(int selector){assert(selector==1);return 123;}
int arena_folder(int volume){
    assert(volume==123);unsigned char *p=*(unsigned char **)(world_globals+0x38c)-256;
    *(void **)(world_globals+0x38c)=p;assert(p[0]==4&&!memcmp(p+1,"Data",4));return 123;
}
void arena_open(int mode,int number,int kind,unsigned char *name,int zero,int folder,int unused){
    assert(!input_file&&number==1&&kind==1&&!zero&&folder==123&&!unused);
    assert((load_mode&&(mode==0x49||mode==0x52)&&name[0]>=6&&name[0]<=8&&!memcmp(name+1,"Data ",5))||(mode==0x49&&name[0]==7&&!memcmp(name+1,"Data 9B",7))||
           (mode==0x52&&name[0]==7&&!memcmp(name+1,"Data 19",7)));
    char path[2048];assert(snprintf(path,sizeof(path),"%s/%.*s",data_directory,name[0],name+1)<(int)sizeof(path));
    input_file=fopen(path,"rb");assert(input_file);assert(!fseek(input_file,0,SEEK_END));input_size=ftell(input_file);rewind(input_file);opens++;
}
void arena_read(void *out,int type,int bytes){
    assert(input_file&&bytes>0&&((type==3&&bytes==2)||(type==14&&bytes<256)));
    if(type==14){*(unsigned char *)out=(unsigned char)bytes;out=(unsigned char *)out+1;}
    assert(fread(out,1,bytes,input_file)==(size_t)bytes);
}
int arena_readfile(int number,void *out,int bytes){
    assert(number==1&&input_file&&(bytes==50||bytes==308));
    assert(fread(out,1,bytes,input_file)==(size_t)bytes);records++;
    if(bytes==50)map_records++;else scene_records++;return 0;
}
int arena_eof(int number){assert(number==1&&input_file);return ftell(input_file)>=input_size?-1:0;}
long arena_length(int number){assert(number==1&&input_file);return input_size;}
void arena_close(int number){assert(number==1&&input_file&&!fclose(input_file));input_file=NULL;}
void arena_stop(void){puts("A\tstop");}
void arena_play(unsigned handle){if((mid_full||end_full)&&handle==0x4321)puts("A\tplay1");else {assert(handle==0x1234);puts("A\tplay2");}if(end_full&&handle==0x4321){phase="end-pre-card";snapshot();printf("K\tend\t%u\t%u\t%u\n",clock_reads,*(unsigned *)(world_globals+0xa4a),*(unsigned *)(world_globals+0xa4e));longjmp(loop_done,1);}}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(panel_save) WRAP(panel_ready) WRAP(gameover_enter) WRAP(end_sound) WRAP(mid_observe) WRAP(loop_noop) WRAP(loop_keys) WRAP(loop_misc)
WRAP(arena_ready) WRAP(arena_system) WRAP(arena_folder) WRAP(arena_open) WRAP(arena_read) WRAP(arena_readfile)
WRAP(arena_eof) WRAP(arena_length) WRAP(arena_close) WRAP(arena_stop) WRAP(arena_play)
int main(int argc,char **argv){
    real_hud=getenv("ASTRO_WORLD_REAL_HUD")!=NULL;panel_mode=getenv("ASTRO_WORLD_PANEL")!=NULL;input_mode=getenv("ASTRO_WORLD_PANEL_INPUT")!=NULL;cleanup_mode=getenv("ASTRO_WORLD_PANEL_CLEANUP")!=NULL;tail_mode=getenv("ASTRO_WORLD_PANEL_TAIL")!=NULL;assert(!tail_mode||cleanup_mode);assert(!cleanup_mode||input_mode);assert(!input_mode||panel_mode);assert(!panel_mode||real_hud);
    if(argc<6||argc>9)return 2;alarm(30);data_directory=argv[5];advancing=argc>=7;if(advancing)assert(!strcmp(argv[6],"advancing"));
    warm_mode=argc>=8&&!strncmp(argv[7],"resumewarm",10);gameover_entry=warm_mode||(argc>=8&&!strncmp(argv[7],"resumegameover",14));resume_long=gameover_entry||(argc>=8&&!strncmp(argv[7],"resumelong",10));end_full=argc>=8&&!strncmp(argv[7],"endfull",7);end_mode=argc>=8&&!strncmp(argv[7],"end",3);mid_full=argc>=8&&!strncmp(argv[7],"midfull",7);mid_mode=end_mode||(argc>=8&&!strncmp(argv[7],"mid",3));resume_mode=argc>=8&&!strncmp(argv[7],"resume",6);loop_mode=resume_mode||(argc>=8&&!strncmp(argv[7],"loop",4));chain_mode=argc>=8&&!strcmp(argv[7],"chain");run_mode=argc>=8&&!strncmp(argv[7],"run",3);start_mode=mid_mode||loop_mode||chain_mode||run_mode||(argc>=8&&!strncmp(argv[7],"start",5));load_mode=argc>=8&&(!strncmp(argv[7],"load",4)||start_mode);
    if(resume_long)alarm(180);if(panel_mode)assert(warm_mode);
    int inputs=argc==8&&!strcmp(argv[7],"outer-input256");
    unsigned char *code=read_file(argv[1])+128,*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);world_globals=g;
    uint32_t toc[489]={0};for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        if(input_mode&&!strcmp(import_names[i],"GetNextEvent"))fn=panel_event;if(input_mode&&!strcmp(import_names[i],"Button"))fn=panel_button;
        if(real_hud&&!strncmp(import_names[i],"gl",2))fn=loop_noop;
        if(!strcmp(import_names[i],"TickCount"))fn=arena_tick;
        if(warm_mode&&!strcmp(import_names[i],"Delay"))fn=warm_delay;
        if(warm_mode&&!strcmp(import_names[i],"ShowCursor"))fn=warm_cursor;
        if(!strcmp(import_names[i],"NewPtrClear"))fn=world_alloc;
        if(!strcmp(import_names[i],"DisposePtr"))fn=cleanup_mode?panel_dispose:world_dispose;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    char path[2048];const struct {const char *name;int offset;} tables[]={{"Attr.bin",0xa94},{"sprt.bin",0xe82},{"Wpns.bin",0xa98}};
    for(unsigned i=0;i<3;i++){snprintf(path,sizeof(path),"%s/%s",argv[4],tables[i].name);set_pointer(g,tables[i].offset,read_file(path));}
    set_pointer(g,0x21c,read_file(argv[2]));set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);
    set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.0);*(uint32_t *)(g+0x380)=0x43300000;
    set_short(g,0xed6,640);set_short(g,0xed8,480);set_short(g,0xa52,1);set_short(g,0xa82,8);set_short(g,0xa84,2);
    set_pointer(g,0x1004,calloc(7,0x108)); /* FIREWEAPON scans six idle sound-channel names. */
    set_pointer(g,0xa54,calloc(3001*4,sizeof(double)));*(uint32_t *)(g+0x244)=123;set_short(g,0xabc,1);*(unsigned *)(g+0xa42)=0x1234;
    const struct {unsigned at;void *fn;} hooks[]={
        {0x24450,arena_system_fb},{0xce40,arena_folder_fb},{0xf064,arena_open_fb},{0x7160,arena_read_fb},
        {0xfd04,arena_readfile_fb},{0x10f44,arena_eof_fb},{0x109bc,arena_length_fb},{0xf8d4,arena_close_fb},
        {0x31af4,arena_stop_fb},{0x31edc,arena_play_fb},{0x3ce84,world_sound_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    if(panel_mode){set_pointer(g,0xa72,calloc(12,sizeof(int)));jump_to(code+0x2b290,panel_ready_fb);jump_to(code+0x44e10,loop_noop_fb);MakeDataExecutable(code,433284);}
    if(input_mode){set_pointer(g,0xa6e,calloc(12,256));jump_to(code+0x63dc4,panel_save_fb);jump_to(code+0x41448,loop_noop_fb);MakeDataExecutable(code,433284);}
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;assert(!FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL));assert(!FSGetResourceForkName(&fork));assert(!FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf));UseResFile(rf);
    if(real_hud){Str255 text;for(int i=1;i<=256;i++){GetIndString(text,129,i);text[text[0]+1]=0;hud_font_widths[i]=atof((char *)text+1)/32;}hud_font_widths[32]=.2;set_pointer(g,0xeb6,hud_font_widths);
        unsigned drawing[]={0x3a278,0x41730,0x3572c,0x342b4};for(unsigned i=0;i<4;i++)jump_to(code+drawing[i],loop_noop_fb);MakeDataExecutable(code,433284);}
    if(load_mode){for(unsigned chain=0;chain<(chain_mode?17u:1u);chain++){
        if(chain){invoke_fb(code+0x529f8,g,toc,NULL,NULL,NULL);invoke_fb(code+0x3e66c,g,toc,NULL,NULL,NULL);invoke_fb(code+0x34edc,g,toc,NULL,NULL,NULL);entity_birth=render_birth=0;}
        unsigned level=0;char half=0,extra=0;if(chain_mode){level=chain/2+1;half=chain==16?'B':chain%2?'B':'A';}else assert(sscanf(argv[7]+((mid_full||end_full)?7:mid_mode?3:warm_mode?10:gameover_entry?14:resume_long?10:resume_mode?6:loop_mode?4:run_mode?3:start_mode?5:4),"%u%c%c",&level,&half,&extra)==2&&level>=1&&level<=9&&(half=='A'||half=='B'));
        if(argc==9&&!chain){FILE *in=fopen(argv[8],"rb");assert(in);assert(fread(*(unsigned char **)(g+0xa54)+32,1,96000,in)==96000);assert(fread(g+0x244,1,4,in)==4&&fgetc(in)==EOF&&!fclose(in));}
        set_short(g,0xa82,level);set_short(g,0xa84,half=='A'?1:2);tick=100;char load_label[24];snprintf(load_label,sizeof load_label,"load%u%c",level,half);phase=chain_mode?load_label:"load";
        invoke_fb(code+0x510c8,g,toc,(void *)(uintptr_t)level,NULL,NULL);
        if(start_mode){jump_to(code+0x4e004,arena_ready_fb);MakeDataExecutable(code+0x4e004,16);*(int32_t *)(g+0xa86)=1;invoke_fb(code+0x50bfc,g,toc,(void *)(uintptr_t)(chain?2:1),NULL,NULL);}
        if(getenv("ASTRO_WORLD_FRACTIONAL_CAMERA")){set_double(g,0xea2,-.25);set_double(g,0xa1e,.25);set_double(g,0xa26,640.25);}
        snapshot();
        unsigned index=0;for(unsigned char *m=*(void **)(g+0x5ae);m;m=*(void **)(m+42)){
            assert(index<10000);printf("P\t%u\t",index++);hex(m,34);hex(m+38,4);putchar('\n');
        }
        unsigned char *stars=*(unsigned char **)(g+0xa54)+32;
        for(index=0;index<3000;index++){printf("T\t%u\t",index);hex(stars+index*32,32);putchar('\n');}
        if(mid_mode){
            const struct {unsigned at;void *fn;} mh[]={{0x57afc,loop_noop_fb},{0x35eb8,loop_noop_fb},{0x43134,loop_noop_fb},{0x334bc,mid_observe_fb},{0x4cb28,loop_noop_fb},{0x4de74,loop_noop_fb}};
            for(unsigned j=0;j<sizeof(mh)/sizeof(mh[0]);j++)if(!real_hud||mh[j].at!=0x43134)jump_to(code+mh[j].at,mh[j].fn);MakeDataExecutable(code,433284);
            if(end_mode){jump_to(code+0x3ccd8,end_sound_fb);MakeDataExecutable(code+0x3ccd8,16);}
            strcpy(loop_label,"mid0");phase=loop_label;(void)arena_tick();*(unsigned *)(g+0xa4a)=arena_tick();*(unsigned *)(g+0xa4e)=arena_tick();set_double(g,0xa58,0);set_short(g,0x5ac,1);*(unsigned *)(g+0xa3e)=0x4321;
            if(!setjmp(loop_done))invoke_fb(code+(end_mode?0x4eda0:0x4e9c4),g,toc,NULL,NULL,NULL);
            if(mid_full){set_short(g,0xa84,2);phase="mid-end";snapshot();printf("K\tend\t%u\t%u\t%u\n",clock_reads,*(unsigned *)(g+0xa4a),*(unsigned *)(g+0xa4e));}
        }
        if(loop_mode){
            const struct {unsigned at;void *fn;} lh[]={{0x57afc,loop_noop_fb},{0x35eb8,loop_noop_fb},{0x43134,loop_noop_fb},{0x334bc,loop_noop_fb},{0x4cb28,loop_keys_fb},{0x4de74,loop_misc_fb}};
            for(unsigned j=0;j<sizeof(lh)/sizeof(lh[0]);j++)if(!real_hud||lh[j].at!=0x43134)jump_to(code+lh[j].at,lh[j].fn);MakeDataExecutable(code,433284);
            if(gameover_entry&&!warm_mode){jump_to(code+0x4cef0,gameover_enter_fb);MakeDataExecutable(code+0x4cef0,16);}
            strcpy(loop_label,"loop0");phase=loop_label;if(!setjmp(loop_done))invoke_fb(code+0x51a68,g,toc,NULL,NULL,NULL);if(gameover_entry)assert(gameover_reached);
        }
        if(run_mode)for(unsigned step=0;step<256;step++){
            char label[32];snprintf(label,sizeof label,"run%u",step);phase=label;
            unsigned keys=(step/8)%16;set_short(g,0xaac,keys&1?-1:0);set_short(g,0xaae,keys&2?-1:0);set_short(g,0xaa8,keys&4?-1:0);set_short(g,0xaaa,keys&8?-1:0);set_short(g,0xab2,step%7==0?-1:0);
            invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);
            invoke_fb(code+0x3b55c,g,toc,NULL,NULL,NULL);invoke_fb(code+0x4c854,g,toc,NULL,NULL,NULL);snapshot();
        }
        fprintf(stderr,"LOAD %u%c maps%u scenes%u clocks%u RNG%08x\n",level,half,map_records,scene_records,clock_reads,*(unsigned *)(g+0x244));}return 0;
    }
    tick=100;phase="before";unsigned char *player=spawn(code,toc,1,1,1400,180);set_pointer(g,0xa7a,player);set_short(player,88,73);
    unsigned char *boss=spawn(code,toc,7,3,1500,180);set_short(boss,96,-2);set_short(boss,70,-1);
    unsigned char *survivor=spawn(code,toc,7,3,1600,100);set_short(survivor,88,71);
    set_double(g,0xea2,-1234.25);set_double(g,0xa1e,1234.25);set_double(g,0xa26,1874.25);set_double(g,0xa2e,-0.0);set_double(g,0xa36,380);
    set_double(g,0xaa0,.3);snapshot();clock_reads=0;
    if(argc==8&&(!strcmp(argv[7],"outer")||!strcmp(argv[7],"outer64")||!strcmp(argv[7],"outer-map256")||inputs)){
        phase="outer";invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);snapshot();
        assert(opens==2&&map_records==247&&scene_records==3);
        assert(clock_reads==211&&-*(double *)(g+0xea2)==1&&*(unsigned *)(g+0x244)==0xf8ce7428&&entity_birth==33&&render_birth==52);
        fprintf(stderr,"NATIVE outerbody camera%.17g clocks%u RNG%08x entities%u images%u\n",-*(double *)(g+0xea2),clock_reads,*(unsigned *)(g+0x244),entity_birth,render_birth);if(strcmp(argv[7],"outer"))for(unsigned step=1;step<((!strcmp(argv[7],"outer-map256")||inputs)?256u:64u);step++){
            char label[32];snprintf(label,sizeof label,"follow%u",step);phase=label;
            if(inputs){unsigned keys=(step/8)%16;set_short(g,0xa8a,10);set_short(g,0xaac,keys&1?-1:0);set_short(g,0xaae,keys&2?-1:0);set_short(g,0xaa8,keys&4?-1:0);set_short(g,0xaaa,keys&8?-1:0);set_short(g,0xab2,step%7==0?-1:0);}
            invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);
            invoke_fb(code+0x3b55c,g,toc,NULL,NULL,NULL);
            if(!strcmp(argv[7],"outer-map256")||inputs)invoke_fb(code+0x4c854,g,toc,NULL,NULL,NULL);
            snapshot();
        }
        return 0;
    }
    phase="cleanup";invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);snapshot();
    assert(opens==2&&map_records==247&&scene_records&&records==map_records+scene_records&&!input_file);
    assert(*(short *)(player+88)==73&&*(short *)(survivor+88)==71&&*(short *)(g+0xa82)==8&&*(short *)(g+0xa84)==2&&*(double *)(g+0xaa0)==-.2);
    fprintf(stderr,"PASS native finalarena composite:247 map records,%u scene records,%u clocks, RNG%08x entities%u images%u\n",scene_records,clock_reads,*(unsigned *)(g+0x244),entity_birth,render_birth);
    if(argc==8){
        set_pointer(g,0xa76,NULL);set_pointer(g,0xa7a,NULL);phase="stars";
        invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);
        assert(ieee_word(*(double *)(g+0xa2e))==0x8000000000000000ULL&&*(double *)(g+0xa36)==380);
        FILE *out=fopen(argv[7],"wb");assert(out);assert(fwrite(*(unsigned char **)(g+0xa54)+32,1,3000*32,out)==3000*32);
        unsigned backgrounds=0;for(unsigned char *r=*(void **)(g+0xe86);r;r=*(void **)(r+300))if(*(short *)(r+32)==2){assert(fwrite(r,1,16,out)==16&&fwrite(r+296,1,4,out)==4);backgrounds++;}
        assert(backgrounds==3&&!fclose(out));
        fprintf(stderr,"PASS native first CALC star phase: load70..450 consumed before reset-0..380 RNG%08x\n",*(unsigned *)(g+0x244));
    }return 0;
}
