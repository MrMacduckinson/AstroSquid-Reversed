/* Actual cleanup/death/LOADLEVEL/scene/spawn; FB file boundary reads original files. */
#define ASTRO_WORLD_ORACLE_LIBRARY
#include "ppc_world_oracle.c"
#include <assert.h>
#include <unistd.h>
static FILE *input_file;static long input_size;static const char *data_directory;
static unsigned clock_reads,opens,records,map_records,scene_records;
static int advancing;
static uint32_t arena_tick(void){unsigned index=clock_reads++;return tick+(advancing&&phase&&strcmp(phase,"before")?index:0);}
int arena_system(int selector){assert(selector==1);return 123;}
int arena_folder(int volume){
    assert(volume==123);unsigned char *p=*(unsigned char **)(world_globals+0x38c)-256;
    *(void **)(world_globals+0x38c)=p;assert(p[0]==4&&!memcmp(p+1,"Data",4));return 123;
}
void arena_open(int mode,int number,int kind,unsigned char *name,int zero,int folder,int unused){
    assert(!input_file&&number==1&&kind==1&&!zero&&folder==123&&!unused);
    assert((mode==0x49&&name[0]==7&&!memcmp(name+1,"Data 9B",7))||
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
void arena_play(unsigned handle){assert(handle==0x1234);puts("A\tplay2");}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(arena_system) WRAP(arena_folder) WRAP(arena_open) WRAP(arena_read) WRAP(arena_readfile)
WRAP(arena_eof) WRAP(arena_length) WRAP(arena_close) WRAP(arena_stop) WRAP(arena_play)
int main(int argc,char **argv){
    if(argc<6||argc>8)return 2;alarm(30);data_directory=argv[5];advancing=argc>=7;if(advancing)assert(!strcmp(argv[6],"advancing"));
    unsigned char *code=read_file(argv[1])+128,*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);world_globals=g;
    uint32_t toc[489]={0};for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"TickCount"))fn=arena_tick;
        if(!strcmp(import_names[i],"NewPtrClear"))fn=world_alloc;
        if(!strcmp(import_names[i],"DisposePtr"))fn=world_dispose;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    char path[2048];const struct {const char *name;int offset;} tables[]={{"Attr.bin",0xa94},{"sprt.bin",0xe82},{"Wpns.bin",0xa98}};
    for(unsigned i=0;i<3;i++){snprintf(path,sizeof(path),"%s/%s",argv[4],tables[i].name);set_pointer(g,tables[i].offset,read_file(path));}
    set_pointer(g,0x21c,read_file(argv[2]));set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);
    set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.0);*(uint32_t *)(g+0x380)=0x43300000;
    set_short(g,0xed6,640);set_short(g,0xed8,480);set_short(g,0xa52,1);set_short(g,0xa82,8);set_short(g,0xa84,2);
    set_pointer(g,0xa54,calloc(3001*4,sizeof(double)));*(uint32_t *)(g+0x244)=123;set_short(g,0xabc,1);*(unsigned *)(g+0xa42)=0x1234;
    const struct {unsigned at;void *fn;} hooks[]={
        {0x24450,arena_system_fb},{0xce40,arena_folder_fb},{0xf064,arena_open_fb},{0x7160,arena_read_fb},
        {0xfd04,arena_readfile_fb},{0x10f44,arena_eof_fb},{0x109bc,arena_length_fb},{0xf8d4,arena_close_fb},
        {0x31af4,arena_stop_fb},{0x31edc,arena_play_fb},{0x3ce84,world_sound_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].at,hooks[i].fn);MakeDataExecutable(code,433284);
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;assert(!FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL));assert(!FSGetResourceForkName(&fork));assert(!FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf));UseResFile(rf);
    tick=100;phase="before";unsigned char *player=spawn(code,toc,1,1,1400,180);set_pointer(g,0xa7a,player);set_short(player,88,73);
    unsigned char *boss=spawn(code,toc,7,3,1500,180);set_short(boss,96,-2);set_short(boss,70,-1);
    unsigned char *survivor=spawn(code,toc,7,3,1600,100);set_short(survivor,88,71);
    set_double(g,0xea2,-1234.25);set_double(g,0xa1e,1234.25);set_double(g,0xa26,1874.25);set_double(g,0xa2e,-0.0);set_double(g,0xa36,380);
    set_double(g,0xaa0,.3);snapshot();clock_reads=0;
    if(argc==8&&!strcmp(argv[7],"outer")){
        phase="outer";invoke_fb(code+0x539b8,g,toc,NULL,NULL,NULL);invoke_fb(code+0x54c64,g,toc,NULL,NULL,NULL);snapshot();
        assert(opens==2&&map_records==247&&scene_records==3);
        assert(clock_reads==211&&-*(double *)(g+0xea2)==1&&*(unsigned *)(g+0x244)==0xf8ce7428&&entity_birth==33&&render_birth==52);
        fprintf(stderr,"NATIVE outerbody camera%.17g clocks%u RNG%08x entities%u images%u\n",-*(double *)(g+0xea2),clock_reads,*(unsigned *)(g+0x244),entity_birth,render_birth);return 0;
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
