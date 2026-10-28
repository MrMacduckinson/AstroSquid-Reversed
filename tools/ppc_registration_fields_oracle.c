/* Real HANDLEFIELDKEYS for two registration fields; only alert UI is observed/continued. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g,*code,*heap;static uint32_t toc[489];static unsigned count,alerts;
static short field_alert(short id,void *filter){assert(id==150&&!filter);alerts++;return 2;}
static void registration_reset(unsigned length,int cursor,int focus,double width){
    memset(g+0x5b2,0,0x454);alerts=0;*(void **)(g+0xa06)=focus<0?NULL:g+0x5b2+focus*0x22a;
    for(unsigned f=0;f<2;f++){unsigned char *p=g+0x5b2+f*0x22a;*(double *)(p+16)=width;*(short *)(p+36)=cursor;p[296]=length;for(unsigned i=0;i<length;i++)p[297+i]=32+(i*17+f*3)%224;}
}
static void registration_key(unsigned key){*(void **)(g+0x38c)=heap;invoke_fb(code+0x4b9c8,g,toc,(void *)(uintptr_t)key,NULL,NULL);}
static void registration_snapshot(void){
    void *p=*(void **)(g+0xa06);int focus=p==g+0x5b2?0:p==g+0x7dc?1:-1;assert(!p||focus>=0);
    printf("%u,%d,%u",count++,focus,alerts);
    for(unsigned f=0;f<2;f++){unsigned char *field=g+0x5b2+f*0x22a;printf(",%d,%d,",*(short *)(field+36),*(short *)(field+552));for(unsigned i=0;i<field[296];i++)printf("%02x",field[297+i]);}putchar('\n');
}
#include "../tests/registration_field_cases.h"
int main(int argc,char **argv){
    if(argc!=3)return 2;alarm(60);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
    code=read_file(argv[1])+128;unsigned char *lit=read_file(argv[2]);g=calloc(1,0x1400);heap=calloc(1,0x100000);assert(g&&heap);
    for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"StopAlert"))fn=field_alert;if(!strcmp(import_names[i],"ParamText"))fn=noop;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;MakeDataExecutable(code,433284);
    run_registration_field_cases();fprintf(stderr,"PASS %u original two-field input states\n",count);return 0;
}
