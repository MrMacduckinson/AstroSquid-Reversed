/* Actual DOMOUSE/LMPOINTSPRITE against all three DataB1 nodes, settled panel. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned mouse_case;
static Point point;
static Handle strings;
static const short points[][2]={{381,292},{445,356},{380,292},{446,292},{381,291},{381,357},{400,320},{0,69},{639,448},{0,449},{0,68},{640,100},{-1,100},{225,260}};
static void get_mouse(Point *out){*out=point;}
static int zero(void){return 0;}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
void mouse_sound(unsigned char *name,double *pan){uint64_t bits;assert(name[0]==5&&!memcmp(name+1,"Click",5));memcpy(&bits,pan,8);printf("%u,S,%016llx\n",mouse_case,bits);}
BRIDGE(mouse_sound)
int main(int argc,char **argv){
    setvbuf(stdout,NULL,_IONBF,0);if(argc!=4)return 2;alarm(15);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000),*raw=read_file(argv[3]);assert(g&&heap);strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetMouse"))fn=get_mouse;if(!strcmp(import_names[i],"GetResource"))fn=resource;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x24248,zero);jump_to(code+0x57afc,noop);jump_to(code+0x44e10,noop);jump_to(code+0x43134,noop);jump_to(code+0x35eb8,noop);jump_to(code+0x3ce84,mouse_sound_fb);MakeDataExecutable(code,433284);
    for(unsigned focus=0;focus<2;focus++)for(unsigned p=0;p<sizeof(points)/sizeof(points[0]);p++,mouse_case++){
        if(!focus&&p==13){mouse_case--;continue;}
        memset(g,0,0x1300);*(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(int16_t *)(g+0xed6)=640;*(int16_t *)(g+0xa68)=1;
        unsigned char node[312] __attribute__((aligned(8)))={0},empty[256]={0};double bounds[]={381,-158,65,65};memcpy(node,bounds,32);*(int16_t *)(node+32)=10;*(int16_t *)(node+38)=900;node[40]=10;memcpy(node+41,"GameOverOK",10);unsigned char fade[312] __attribute__((aligned(8)))={0},unnamed[312] __attribute__((aligned(8)))={0};
        double fade_bounds[]={0,-381,640,380},other_bounds[]={-328.5,-237.5,83,31};memcpy(fade,fade_bounds,32);memcpy(unnamed,other_bounds,32);
        *(int16_t *)(fade+32)=8;*(int16_t *)(fade+38)=998;fade[40]=12;memcpy(fade+41,"GameOverFade",12);
        *(int16_t *)(unnamed+32)=2;*(int16_t *)(unnamed+38)=1;unnamed[40]=7;memcpy(unnamed+41,"Unnamed",7);
        *(void **)(node+300)=fade;*(void **)(fade+300)=unnamed;*(void **)(g+0xe86)=node;
        double field[]={223,185,200,22};memcpy(g+0x5b2,field,32);*(int16_t *)(g+0x5d6)=77;*(void **)(g+0xeb6)=font_widths;*(void **)(g+0xa06)=focus?g+0x5b2:NULL;point.h=points[p][0];point.v=points[p][1];
        invoke_fb(code+0x4cd48,g,toc,(void *)1,NULL,NULL);
        invoke_fb(code+0x3f178,g,toc,empty,NULL,NULL);
        printf("%u,Z,%d,%d,%d,%d\n",mouse_case,*(int16_t *)(g+0xa68),*(int16_t *)(g+0x58c),*(void **)(g+0xa06)!=NULL,*(int16_t *)(g+0x5d6));
    }
    DisposeHandle(strings);fputs("PASS27 actual DOMOUSE fullDataB1 button/fade/field routes and click pan\n",stderr);return 0;
}
