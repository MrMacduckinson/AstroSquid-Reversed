/* Actual original GETSTRINGWIDTH and SETCURSORPOS; original MacRoman font. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include "../tests/text_cursor_cases.h"
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static int mouse_x,mouse_y;
void cursor_get_mouse(Point *p){p->h=mouse_x;p->v=mouse_y;}
int cursor_zero(void){return 0;}
BRIDGE(cursor_get_mouse) BRIDGE(cursor_zero)
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(60);struct stat input;
    assert(!stat(argv[1],&input)&&input.st_size==455780&&!stat(argv[2],&input)&&input.st_size==11812);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
        void *fn=!strcmp(import_names[i],"GetMouse")?cursor_get_mouse_fb:dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xeb6)=font_widths;
    *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;
    assert(!FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL)&&!FSGetResourceForkName(&fork)&&!FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf));UseResFile(rf);
    Str255 text;for(int i=1;i<=256;i++){GetIndString(text,129,i);text[text[0]+1]=0;font_widths[i]=atof((char *)text+1)/32;}font_widths[32]=.2;
    jump_to(code+0x24248,cursor_zero_fb);jump_to(code+0x3b378,cursor_zero_fb);
    MakeDataExecutable(code,433284);unsigned widths=0,positions=0,mouse_probes=0;
    for(unsigned n=0;n<sizeof(text_cursor_names)/sizeof(text_cursor_names[0]);n++){
        const char *name=text_cursor_names[n];unsigned length=strlen(name);assert(length<256);
        unsigned char field[600]={0};field[0x128]=length;memcpy(field+0x129,name,length);
        for(unsigned s=0;s<sizeof(text_cursor_sizes)/sizeof(text_cursor_sizes[0]);s++)for(unsigned prefix=0;prefix<=length;prefix++){
            unsigned char string[256]={0};string[0]=prefix;memcpy(string+1,name,prefix);double size=text_cursor_sizes[s];
            int width=(int32_t)invoke_fb(code+0x419ec,g,toc,string,&size,NULL);
            printf("W,%u,%u,%d,%d\n",n,prefix,text_cursor_sizes[s],width);widths++;
        }
        for(int x=-4;x<=260;x++){
            invoke_fb(code+0x3f030,g,toc,field,(void *)(intptr_t)x,NULL);
            printf("C,%u,%d,%d\n",n,x,*(int16_t *)(field+0x24));positions++;
        }
    }
    for(unsigned n=0;n<sizeof(text_cursor_names)/sizeof(text_cursor_names[0]);n++){
        unsigned char *field=g+0x5b2;memset(field,0,600);*(double *)field=223;*(double *)(field+8)=185;*(double *)(field+16)=200;*(double *)(field+24)=22;
        unsigned length=strlen(text_cursor_names[n]);field[0x128]=length;memcpy(field+0x129,text_cursor_names[n],length);*(int16_t *)(g+0xa68)=1;
        for(unsigned ix=0;ix<sizeof(text_cursor_mouse_x)/sizeof(text_cursor_mouse_x[0]);ix++)for(unsigned iy=0;iy<sizeof(text_cursor_mouse_y)/sizeof(text_cursor_mouse_y[0]);iy++){
            mouse_x=223+text_cursor_mouse_x[ix];mouse_y=text_cursor_mouse_y[iy];*(int16_t *)(field+0x24)=77;*(void **)(g+0xa06)=NULL;
            unsigned char empty[256]={0};invoke_fb(code+0x3f178,g,toc,empty,NULL,NULL);
            printf("M,%u,%d,%d,%d,%d\n",n,text_cursor_mouse_x[ix],mouse_y,*(void **)(g+0xa06)==field,*(int16_t *)(field+0x24));mouse_probes++;
        }
    }
    CloseResFile(rf);fprintf(stderr,"PASS native%u integer widths,%u cursor positions,%u DOMOUSE routes\n",widths,positions,mouse_probes);return 0;
}
