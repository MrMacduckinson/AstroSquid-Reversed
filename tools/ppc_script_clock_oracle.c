/* Original DOSCRIPTEDSPRITE with finite clock scripts and resource boundaries. */
#define main legacy_script_oracle_main
#include "ppc_script_oracle.c"
#undef main
static unsigned char *code_base,*current;
static Handle constants,program;
static uint32_t values[8];
static unsigned used,limit;
static void snapshot(void){
    printf(",%d,%u,%u,%u,%d,%d,%d,%d,%016llx,%016llx",
        *(int16_t *)(current+22)-1,*(uint32_t *)(current+8),*(uint32_t *)(current+16),*(uint32_t *)(current+12),
        *(int16_t *)(current+4),*(int16_t *)(current+24),*(int16_t *)(current+26),*(int16_t *)(current+70),
        (unsigned long long)ieee_word(*(double *)(current+72)),(unsigned long long)ieee_word(*(double *)(current+80)));
}
uint32_t script_clock_value(uintptr_t pc){
    if(used>=limit){fputs("Clock script exhausted\n",stderr);exit(3);}
    uint32_t tick=values[used];printf("T,%u,%08x,%u",used++,pc?(unsigned)(pc-(uintptr_t)code_base-4+0x10000000):0,tick);snapshot();puts("");return tick;
}
void script_clock_fire(int weapon,int x,int y,int heading,void *source){
    if(source!=current){fputs("Wrong source\n",stderr);exit(3);}
    printf("F,%d,%d,%d,%d\n",weapon,x,y,heading);script_clock_value(0);
}
extern void script_clock_fb(void),script_fire_fb(void);
/* CFM callers restore r2 from their own linkage area after the patched import. */
__asm__(".text\n.align 2\n.globl _script_clock_fb\n_script_clock_fb:\nstw r2,20(r1)\nmflr r3\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _script_clock_value\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
".align 2\n.globl _script_fire_fb\n_script_fire_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _script_clock_fire\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static Handle scripted_resource(ResType type,short id){if(type!='STR#')exit(3);if(id==25000)return constants;if(id==777)return program;fprintf(stderr,"Unexpected resource%d\n",id);exit(3);}
typedef struct {const char *text;int animated,state;uint32_t update,action,animation;unsigned n;uint32_t clocks[8];} Case;
int main(int argc,char **argv){
    if(argc!=4)return 2;FILE *input=fopen(argv[3],"rb");if(!input)return 2;
    if(fseek(input,0,SEEK_END)||ftell(input)!=6884){fclose(input);fputs("Expected6884-byte STR#25000 payload\n",stderr);return 2;}fclose(input);
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*lit=read_file(argv[2]),*strings=read_file(argv[3]);code_base=code;
    constants=NewHandle(6884);if(!constants)return 2;memcpy(*constants,strings,6884);
    unsigned char *g=calloc(1,0x1300),*heap=calloc(1,65536),*attrs=calloc(441,30),*sprites=calloc(1001,14);uint32_t toc[489]={0};
    for(int i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))fn=scripted_resource;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    set_pointer(g,0x21c,lit);set_double(g,0x368,3.14159265358979323846);set_double(g,0x378,4503601774854144.);*(uint32_t *)(g+0x380)=0x43300000;
    set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);set_pointer(g,0xa94,attrs);set_pointer(g,0xe82,sprites);toc[0]=(uint32_t)(uintptr_t)g;
    set_short(attrs+50*30,4,10);set_short(attrs+50*30,22,1);set_short(sprites+14,6,71);set_short(sprites+14,8,20);
    jump_to(code+0x694e4,script_clock_fb);jump_to(code+0x58f40,script_fire_fb);MakeDataExecutable(code,433284);
    const Case cases[]={
        {"007|Fire|045|Any",1,1,100,100,100,7,{101,105,110,120,130,140,150}},
        {"007|Fire|045|Any",1,1,100,100,100,1,{100}},
        {"007|Fire|045|Any",1,1,100,100,100,4,{101,102,100,106}},
        {"RETURN",1,1,100,100,100,4,{101,105,108,109}},
        {"007|Fire|045|Any",0,1,100,100,100,3,{101,102,100}},
        {"007|Fire|045|Any",1,4,100,100,100,3,{101,102,100}},
        {"007|Stop|000|Any",0,1,100,0x80000000u,100,4,{101,102,100,120}},
        {"007|Stop|000|Any",0,1,100,100,100,3,{101,102,0x80000000u}},
        {"007|Stop|000|Any",0,1,UINT32_MAX,100,100,3,{0,1,100}},
        {"007|Stop|000|Any",0,1,100,100,100,1,{0x80000064u}}
    };
    for(unsigned id=0;id<sizeof(cases)/sizeof(cases[0]);id++){
        const Case *c=&cases[id];used=0;limit=c->n;memcpy(values,c->clocks,sizeof(values));
        unsigned char entity[128]={0},render[312]={0};current=entity;
        set_short(entity,0,5);set_short(entity,4,c->state);set_short(entity,20,777);set_short(entity,22,1);set_short(entity,24,1);set_short(entity,26,1);set_short(entity,68,50);
        *(uint32_t *)(entity+8)=c->update;*(uint32_t *)(entity+16)=c->action;*(uint32_t *)(entity+12)=c->animation;
        set_short(entity,36,7);set_short(entity,38,5);set_short(entity,40,27);set_short(entity,42,76);set_double(entity,44,5);set_double(entity,52,7);set_pointer(entity,62,render);
        set_double(render,16,71);set_double(render,24,20);set_short(render,38,1);set_short(attrs+50*30,20,c->animated);
        program=NewHandleClear(128);if(!program)return 2;unsigned char *p=(unsigned char *)*program;*(uint16_t *)p=2;p[2]=strlen(c->text);memcpy(p+3,c->text,p[2]);p+=3+p[2];p[0]=6;memcpy(p+1,"RETURN",6);
        set_pointer(g,0x38c,heap);printf("CASE,%u,%s,%d,%d,%u,%u,%u,%u\n",id,c->text,c->animated,c->state,c->update,c->action,c->animation,c->n);
        invoke_fb(code+0x61c40,g,toc,entity,NULL,NULL);printf("O");snapshot();puts("");if(used!=limit)return 4;DisposeHandle(program);
    }
    return 0;
}
