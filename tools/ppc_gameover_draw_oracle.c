/* Original whole DRAWGAMEOVEROVERLAY, including real sprite lookup and field.
   Logical menu Y normalized by70; inherited projection is a separate gate. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <OpenGL/gl.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned field_case,command_index,field_outline;
static uint64_t word(double x){uint64_t u;memcpy(&u,&x,8);return u;}
static void colors(void){for(unsigned i=0;i<4;i++)printf(",%016llx",word(color[i]));putchar('\n');}
static uint32_t field_tick(void){return 100;}
static void field_mode(unsigned face,unsigned mode){assert(face==GL_FRONT_AND_BACK);field_outline=mode==GL_LINE;}
void field_box(double *x,double *y,double *r,double *b){
    printf("%u,%u,B,%u,%016llx,%016llx,%016llx,%016llx",field_case,command_index++,field_outline,word(*x),word(*y+70),word(*r),word(*b+70));colors();
}
void field_text(double *x,double *y,unsigned char *text,double *size){
    printf("%u,%u,T,",field_case,command_index++);for(unsigned i=0;i<text[0];i++)printf("%02x",text[i+1]);
    printf(",%016llx,%016llx,%016llx",word(*x),word(*y+70),word(*size));colors();
}
static void field_scissor(int x,int y,int w,int h){printf("%u,%u,S,%d,%d,%d,%d\n",field_case,command_index++,x,y,w,h);}
BRIDGE(field_box) BRIDGE(field_text)
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(30);struct stat input;
    assert(!stat(argv[1],&input)&&input.st_size==455780&&!stat(argv[2],&input)&&input.st_size==11812);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strncmp(import_names[i],"gl",2))fn=noop;
        if(!strcmp(import_names[i],"glColor3d"))fn=color3;if(!strcmp(import_names[i],"glColor4d"))fn=color4;
        if(!strcmp(import_names[i],"glPolygonMode"))fn=field_mode;if(!strcmp(import_names[i],"glScissor"))fn=field_scissor;
        if(!strcmp(import_names[i],"TickCount"))fn=field_tick;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xeb6)=font_widths;
    *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;
    assert(!FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL)&&!FSGetResourceForkName(&fork)&&!FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf));UseResFile(rf);
    Str255 text;for(int i=1;i<=256;i++){GetIndString(text,129,i);text[text[0]+1]=0;font_widths[i]=atof((char *)text+1)/32;}font_widths[32]=.2;GetIndString(text,25000,273);assert(text[0]==5&&!memcmp(text+1,"Name:",5));
    jump_to(code+0x41730,field_box_fb);jump_to(code+0x3572c,field_text_fb);jump_to(code+0x342b4,noop);MakeDataExecutable(code,433284);
    unsigned char button[312]={0};double button_bounds[]={381,222,65,65};memcpy(button,button_bounds,32);
    GetIndString(text,25000,209);memcpy(button+40,text,text[0]+1);*(void **)(g+0xe86)=button;
    for(unsigned closing=0;closing<2;closing++)for(unsigned focus=0;focus<2;focus++)for(unsigned visible=0;visible<2;visible++){
        unsigned char field[600]={0};double bounds[]={223,185,200,22};memcpy(field,bounds,32);
        *(uint32_t *)(field+32)=200;*(int16_t *)(field+36)=2;*(int16_t *)(field+38)=visible?1:-1;
        field[40]=5;memcpy(field+41,"Name:",5);field[296]=4;memcpy(field+297,"TEST",4);
        *(void **)(g+0xa06)=focus?field:NULL;*(int16_t *)(g+0xa68)=closing?0:1;
        command_index=0;invoke_fb(code+0x44e10,g,toc,NULL,NULL,NULL);
        assert(command_index==(focus?(visible?7u:6u):2u)-closing);field_case++;
    }
    CloseResFile(rf);fprintf(stderr,"PASS native8 active/closing GameOver profiles,30 commands; title/OK/field/highscore order andRGBA\n");return 0;
}
