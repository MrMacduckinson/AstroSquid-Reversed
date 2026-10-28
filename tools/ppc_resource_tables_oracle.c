/* Execute original resource loaders against a read-only original resource fork. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
int main(int argc,char **argv){
    if(argc!=5)return 2;alarm(15);
    FSRef ref;ResFileRefNum file;HFSUniStr255 fork;
    assert(!FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL));assert(!FSGetResourceForkName(&fork));
    assert(!FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&file));UseResFile(file);
    unsigned char *code=read_file(argv[1])+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);assert(g&&heap);
    *(void **)(g+0x21c)=read_file(argv[2]);*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;
    uint32_t toc[489]={0};
    for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    toc[0]=(uint32_t)(uintptr_t)g;
    const struct {const char *name;ResType type;unsigned global,entry,size,count;} tables[]={
        {"lm-sprt",'sprt',0xe82,0x34fa4,14,1001},{"Attr",'Attr',0xa94,0x65094,30,441},
        {"Wpns",'Wpns',0xa98,0x65334,52,241},{"game-SPRT",'SPRT',0xa9c,0x651e4,14,501}};
    MakeDataExecutable(code,433284);
    for(unsigned i=0;i<4;i++){
        unsigned size=tables[i].size*tables[i].count;void *data=calloc(1,size);assert(data);
        *(void **)(g+tables[i].global)=data;*(void **)(g+0x38c)=heap;
        short count=CountResources(tables[i].type);
        invoke_fb(code+tables[i].entry,g,toc,NULL,NULL,NULL);
        char path[1024];assert(snprintf(path,sizeof(path),"%s/%s.bin",argv[4],tables[i].name)<(int)sizeof(path));
        FILE *out=fopen(path,"wb");assert(out&&fwrite(data,1,size,out)==size&&!fclose(out));
        printf("%s resources%d bytes%u\n",tables[i].name,count,size);free(data);
    }
    CloseResFile(file);puts("PASS original four resource loader calls and indexed table dumps; compare complete bytes separately");return 0;
}
