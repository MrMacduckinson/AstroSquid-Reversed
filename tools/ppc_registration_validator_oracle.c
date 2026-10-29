/* Actual CHECKREGCODE, its computed operand, binary comparison and linked Register removal. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g,*code,*comparison_code,*literals,*heap,*register_node;static uint32_t toc[489];static Handle strings;
static unsigned char computed[256];static unsigned comparisons,kills,cases;
static Handle registration_resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static void registration_dispose(void *node){assert(node==register_node);free(node);register_node=NULL;kills++;}
uint32_t registration_compare(unsigned mode){
    assert(mode==1);if(!comparisons){unsigned char *operand=*(void **)(g+0x38c);assert(operand[0]==8);memcpy(computed,operand,9);}comparisons++;
    return invoke_fb(comparison_code+0x33a4,g,toc,(void *)(uintptr_t)mode,NULL,NULL);
}
BRIDGE(registration_compare)
static void registration_validator_case(unsigned length,unsigned pattern,unsigned variant,unsigned prior,const unsigned char *name,unsigned name_length,const unsigned char *serial,unsigned serial_length,const unsigned char expected[8]){
    (void)expected;assert(!register_node);memset(g,0,0x1400);comparisons=kills=0;
    *(void **)(g+0x21c)=literals;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
    register_node=calloc(1,308);assert(register_node);register_node[40]=8;memcpy(register_node+41,"Register",8);*(short *)(register_node+32)=9;*(short *)(register_node+38)=900;*(void **)(g+0xe86)=register_node;
    *(short *)(g+0xa0c)=prior;g[0xac2]=4;memcpy(g+0xac3,"OLDN",4);g[0xbc2]=4;memcpy(g+0xbc3,"OLDC",4);
    unsigned char n[256]={0},s[256]={0};n[0]=name_length;memcpy(n+1,name,name_length);s[0]=serial_length;memcpy(s+1,serial,serial_length);
    unsigned valid=invoke_fb(code+0x3d844,g,toc,n,s,NULL)!=0;assert(comparisons==1+valid&&kills==valid);
    printf("%u,%u,%u,%u,%u,%d,%u,%u,",length,pattern,variant,prior,valid,*(short *)(g+0xa0c),*(void **)(g+0xe86)!=NULL,kills);
    for(unsigned i=0;i<8;i++)printf("%02x",computed[i+1]);putchar(',');
    for(unsigned i=0;i<g[0xac2];i++)printf("%02x",g[0xac3+i]);putchar(',');
    for(unsigned i=0;i<g[0xbc2];i++)printf("%02x",g[0xbc3+i]);putchar('\n');
    free(register_node);register_node=NULL;cases++;
}
#include "../tests/registration_validator_cases.h"
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(60);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884);
    code=read_file(argv[1])+128;comparison_code=read_file(argv[1])+128;literals=read_file(argv[2]);unsigned char *raw=read_file(argv[3]);g=calloc(1,0x1400);heap=calloc(1,0x100000);assert(g&&heap);
    strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))fn=registration_resource;if(!strcmp(import_names[i],"DisposePtr"))fn=registration_dispose;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x33a4,registration_compare_fb);MakeDataExecutable(code,433284);MakeDataExecutable(comparison_code,433284);
    run_registration_validator_cases();DisposeHandle(strings);fprintf(stderr,"PASS %u actual registration validation/state/removal cases\n",cases);return 0;
}
