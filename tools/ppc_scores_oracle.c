/* Original score insertion/editing oracle; SAVEHIGHSCORES is disabled in private code only. */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppc_bridge.h"
#include "imports.h"
#include "scores.h"
static uint32_t descriptors[484][2];
static void no_save(void){}
static unsigned native_alerts;
static short controlled_alert(short identifier,void *filter){(void)filter;if(identifier!=150)exit(2);native_alerts++;return 2;}
static void controlled_paramtext(void){}
void missing_import_report(uint32_t *descriptor){int index=(int)(descriptor-&descriptors[0][0])/2;fprintf(stderr,"Unresolved scores oracle import %d\n",index);exit(2);}
extern void missing_import(void);
__asm__(".text\n.align 2\n.globl _missing_import\n_missing_import:\nmr r3,r12\nb _missing_import_report\n");
static unsigned char *read_file(const char *name){FILE *f=fopen(name,"rb");if(!f){perror(name);exit(2);}fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char *p=malloc(n);if(fread(p,1,n,f)!=(size_t)n)exit(2);fclose(f);return p;}
static void jump_to(unsigned char *at,void *destination){uintptr_t p=(uintptr_t)destination;uint32_t *w=(uint32_t *)at;w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);w[2]=0x7d8903a6;w[3]=0x4e800420;}
int main(int argc,char **argv){
    if(argc!=4){fputs("usage: scores_oracle original.pef literals.bin original-app\n",stderr);return 2;}
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]),*globals=calloc(1,0x1300),*heap=calloc(1,0x10000);uint32_t toc[489]={0};
    for(int i=0;i<484;i++){void *function=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"StopAlert"))function=controlled_alert;if(!strcmp(import_names[i],"ParamText"))function=controlled_paramtext;descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:(void *)missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    *(void **)(globals+0x21c)=literals;*(double *)(globals+0x378)=4503601774854144.;*(uint32_t *)(globals+0x380)=0x43300000;
    *(void **)(globals+0x388)=heap;*(void **)(globals+0x38c)=heap;toc[0]=(uint32_t)(uintptr_t)globals;
    FSRef ref;SInt16 resourceFile;HFSUniStr255 forkName;OSStatus error=FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL);
    if(!error)error=FSGetResourceForkName(&forkName);if(!error)error=FSOpenResourceFile(&ref,forkName.length,forkName.unicode,fsRdPerm,&resourceFile);if(error)return 2;UseResFile(resourceFile);
    jump_to(code+0x63dc4,no_save);MakeDataExecutable(code,433284);
    unsigned char names[12][256];int32_t values[12];AstroScore scores[10];
    *(void **)(globals+0xa6e)=names;*(void **)(globals+0xa72)=values;
    memset(names,0,sizeof(names));memset(values,0,sizeof(values));
    invoke_fb(code+0x63cc0,globals,toc,NULL,NULL,NULL);astro_scores_clear(scores);
    for(int i=0;i<10;i++){if(values[i+1]!=scores[i].score||names[i+1][0]!=strlen(scores[i].name)||memcmp(names[i+1]+1,scores[i].name,names[i+1][0])){fputs("Native score defaults mismatch\n",stderr);return 1;}}
    unsigned insertions=0;
    for(int i=0;i<200;i++){
        int32_t score=(i%9)*100;char name[256];snprintf(name,sizeof(name),i%7?"Player%d":"",i);
        if(!astro_scores_qualifies(scores,score))continue;
        globals[0x6da]=(unsigned char)strlen(name);memcpy(globals+0x6db,name,strlen(name));*(int32_t *)(globals+0xa7e)=score;
        *(void **)(globals+0x38c)=heap;invoke_fb(code+0x3ed88,globals,toc,NULL,NULL,NULL);
        int rank=astro_scores_insert(scores,score,name);
        if(rank!=*(int16_t *)(globals+0xa6c)){fputs("Native tie rank mismatch\n",stderr);return 1;}
        for(int j=0;j<10;j++)if(values[j+1]!=scores[j].score||names[j+1][0]!=strlen(scores[j].name)||memcmp(names[j+1]+1,scores[j].name,names[j+1][0])){fprintf(stderr,"Native insertion mismatch case%d row%d\n",i,j);return 1;}
        insertions++;
    }
    unsigned steps=0;uint32_t random=12345;
    for(int episode=0;episode<100;episode++){
        AstroScoreEditor editor;astro_score_editor_begin(&editor);memset(globals+0x5b2,0,0x22a);*(void **)(globals+0xa06)=globals+0x5b2;*(double *)(globals+0x5c2)=200;
        for(int step=0;step<400;step++){
            static const unsigned controls[]={8,127,28,29,30,31,27,9,10,11,12,16,1,4,5};
            random=random*1664525+1013904223;unsigned key=(random&3)?32+(random>>16)%224:controls[(random>>16)%15];
            unsigned before_alerts=native_alerts;
            *(void **)(globals+0x38c)=heap;invoke_fb(code+0x4b9c8,globals,toc,(void *)(uintptr_t)key,NULL,NULL);int edit=astro_score_editor_key(&editor,key);if(edit==ASTRO_SCORE_EDIT_ALERT){if(native_alerts!=before_alerts+1)return 1;astro_score_editor_resolve_alert(&editor,1);}else if(native_alerts!=before_alerts)return 1;
            if(globals[0x6da]!=strlen(editor.name)||memcmp(globals+0x6db,editor.name,globals[0x6da])||*(int16_t *)(globals+0x5d6)!=(int)editor.cursor){fprintf(stderr,"Native editor mismatch episode%d step%d key%u len%u/%lu cursor%d/%lu\n",episode,step,key,globals[0x6da],(unsigned long)strlen(editor.name),*(int16_t *)(globals+0x5d6),(unsigned long)(int)editor.cursor);return 1;}
            steps++;
        }
        invoke_fb(code+0x4b9c8,globals,toc,(void *)13,NULL,NULL);astro_score_editor_key(&editor,13);if(*(int16_t *)(globals+0x7da)!=editor.submitted)return 1;
    }
    CloseResFile(resourceFile);printf("PASS native defaults, %u stable score insertions and %u Classic editing events +100submits, %u controlledoriginaloverflowalerts\n",insertions,steps,native_alerts);return 0;
}
