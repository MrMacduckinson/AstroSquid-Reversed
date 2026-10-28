/* Actual LMPOINTSPRITE edges in animated Data B2; no event dispatch or GUI. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static uint64_t bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
int main(int argc,char **argv){
    if(argc!=4)return 2;
    alarm(60);struct stat st;
    assert(!stat(argv[1],&st)&&st.st_size==455780);
    assert(!stat(argv[2],&st)&&st.st_size==11812);
    assert(!stat(argv[3],&st)&&st.st_size==52*308);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*scene=read_file(argv[3]);
    unsigned char *g=calloc(1,0x1400),*heap=calloc(1,0x100000),*nodes[52];assert(g&&heap);
    for(unsigned i=0;i<52;i++){nodes[i]=calloc(1,308);assert(nodes[i]);}
    uint32_t toc[489]={0};
    for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}
    toc[0]=(uint32_t)(uintptr_t)g;MakeDataExecutable(code,433284);
    const double cameras[][2]={{0,0},{-599.5,-344},{-.75,.75}};
    unsigned queries=0;
    for(unsigned profile=0;profile<9;profile++){
        memset(g,0,0x1400);*(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;
        *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
        *(void **)(g+0xe86)=nodes[0];*(short *)(g+0xa52)=profile%3+1;
        double cx=cameras[profile/3][0],cy=cameras[profile/3][1];*(double *)(g+0xea2)=cx;*(double *)(g+0xeaa)=cy;
        for(unsigned i=0;i<52;i++){memcpy(nodes[i],scene+i*308,308);*(void **)(nodes[i]+300)=i<51?nodes[i+1]:NULL;*(void **)(nodes[i]+304)=i?nodes[i-1]:NULL;}
        printf("P,%u,%u,%016llx,%016llx\n",profile,profile%3+1,bits(cx),bits(cy));
        for(unsigned frame=0;frame<=60;frame++){
            for(unsigned i=0;i<52;i++){
                unsigned char *n=nodes[i];
                printf("N,%u,%u,%u,%d,%d",profile,frame,i,*(short *)(n+38),*(int *)(n+296));
                for(unsigned a=0;a<4;a++)printf(",%016llx",bits(*(double *)(n+a*8)));putchar('\n');
                int l=(int)(cx+*(double *)n),t=(int)(cy+*(double *)(n+8));
                int r=l+(int)*(double *)(n+16),b=t+(int)*(double *)(n+24);
                const int points[][2]={{l,t},{r-1,b-1},{l-1,t},{r,t},{l,t-1},{l,b},{(l+r)/2,(t+b)/2},{r-1,t},{l,b-1},{r,b},{l-1,b-1},{r-1,t-1}};
                for(unsigned p=0;p<12;p++){
                    short x=points[p][0],y=points[p][1];uint32_t point=((uint32_t)(uint16_t)y<<16)|(uint16_t)x;
                    uintptr_t hit=invoke_fb(code+0x3b378,g,toc,(void *)(uintptr_t)point,NULL,NULL);int index=-1;
                    for(unsigned j=0;j<52;j++)if(hit==(uintptr_t)nodes[j])index=j;
                    assert(!hit||index>=0);printf("Q,%u,%u,%u,%u,%d,%d,%d\n",profile,frame,i,p,x,y,index);queries++;
                }
            }
            if(frame<60)invoke_fb(code+0x45f20,g,toc,NULL,NULL,NULL);
        }
    }
    assert(queries==342576);fputs("PASS342576 actual LMPOINTSPRITE edge queries and28548 animated node states\n",stderr);return 0;
}
