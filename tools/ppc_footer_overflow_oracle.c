/* Actual FBAddStrings used by DRAWGLMENU for resource223 + registered name. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <setjmp.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g,*code,*heap,*lit;static uint32_t toc[489];static unsigned length,pattern,choice,params,alerts,cases;
static unsigned char prefix[256],message[256],left_line[256],right_line[256];static jmp_buf stopped;
static void hex(const unsigned char *p,unsigned n){for(unsigned i=0;i<n;i++)printf("%02x",p[i]);}
static void footer_params(const unsigned char *a,const unsigned char *b,const unsigned char *c,const unsigned char *d){
    (void)d;char anchor;assert(a>=lit&&a+256<=lit+11812);assert((uintptr_t)b>(uintptr_t)&anchor&&(uintptr_t)b<(uintptr_t)&anchor+65536);assert((uintptr_t)c>(uintptr_t)&anchor&&(uintptr_t)c<(uintptr_t)&anchor+65536);
    memcpy(message,a,a[0]+1);memcpy(left_line,b,b[0]+1);memcpy(right_line,c,c[0]+1);params++;
}
static short footer_alert(short id,void *filter){
    assert(id==150&&!filter&&params==2);alerts++;
    printf("A,%u,%u,%u,",length,pattern,choice);hex(message+1,message[0]);putchar(',');hex(left_line+1,left_line[0]);putchar(',');hex(right_line+1,right_line[0]);putchar('\n');return choice;
}
void footer_end(void){printf("E,%u,%u,%u\n",length,pattern,choice);longjmp(stopped,1);}
BRIDGE(footer_end)
static void footer_case(unsigned n,unsigned p,unsigned answer,const unsigned char *name){
    length=n;pattern=p;choice=answer;params=alerts=0;memset(heap,0,2048);memcpy(heap,prefix,prefix[0]+1);heap[256]=n;memcpy(heap+257,name,n);*(void **)(g+0x38c)=heap+256;
    if(!setjmp(stopped)){
        unsigned char *result=(void *)(uintptr_t)invoke_fb(code+0x2ef4,g,toc,NULL,NULL,NULL);assert(result==heap&&*(void **)(g+0x38c)==heap);
        printf("D,%u,%u,%u,",length,pattern,choice);hex(result+1,result[0]);putchar('\n');
    }
    assert(alerts==(n>240));cases++;
}
#include "../tests/footer_overflow_cases.h"
int main(int argc,char **argv){
    if(argc!=4)return 2;alarm(30);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884);
    code=read_file(argv[1])+128;lit=read_file(argv[2]);g=calloc(1,0x1400);heap=calloc(1,0x100000);assert(g&&heap);
    unsigned char *raw=read_file(argv[3]),*p=raw+2;for(unsigned i=1;i<223;i++)p+=p[0]+1;assert(p[0]==15);memcpy(prefix,p,p[0]+1);
    for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"ParamText"))fn=footer_params;if(!strcmp(import_names[i],"StopAlert"))fn=footer_alert;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;toc[1]=(uint32_t)(uintptr_t)lit;
    *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
    jump_to(code+0x1b2cc,footer_end_fb);MakeDataExecutable(code,433284);run_footer_overflow_cases();fprintf(stderr,"PASS %u original footer concatenations / Stop / Continue\n",cases);return 0;
}
