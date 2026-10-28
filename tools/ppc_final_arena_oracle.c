/* Original tag-2 death tail; observe map/music/load boundaries, retain field moves. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
static unsigned char *globals,*images,*actors;static char calls[16];static unsigned used;
static void event(char c){assert(used+1<sizeof(calls));calls[used++]=c;calls[used]=0;}
void kill_image(void *image){assert(image==images+308);event('K');}
void kill_map(void){event('M');}
void stop_track(void){event('S');}
void play_track(unsigned handle){assert(handle==0x1234);event('P');}
void load_level(int level){
    assert(level==9&&*(short *)(globals+0xa82)==8&&*(short *)(globals+0xa84)==2);
    for(int i=0;i<3;i++)assert(*(double *)(images+i*308)==10+i+*(double *)(globals+0xea2));
    for(int i=0;i<3;i++)assert(*(double *)(actors+i*106+44)==20+i+*(double *)(globals+0xea2));
    event('L');
}
#define WRAP(name) extern void name##_fb(void); __asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\nmflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\nbl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
WRAP(kill_image) WRAP(kill_map) WRAP(stop_track) WRAP(play_track) WRAP(load_level)
int main(int argc,char **argv){
    if(argc!=3)return 2;alarm(15);
    unsigned char *code=read_file(argv[1])+128,*g=calloc(1,0x1300);assert(g);globals=g;
    images=calloc(3,308);actors=calloc(3,106);assert(images&&actors);
    *(void **)(g+0x21c)=read_file(argv[2]);*(void **)(g+0xe86)=images;*(void **)(g+0xa76)=actors;
    *(short *)(g+0xa82)=8;*(short *)(g+0xa84)=2;*(unsigned *)(g+0xa42)=0x1234;
    uint32_t toc[489]={0};for(int i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
    jump_to(code+0x34dd8,kill_image_fb);jump_to(code+0x3e66c,kill_map_fb);jump_to(code+0x31af4,stop_track_fb);jump_to(code+0x31edc,play_track_fb);jump_to(code+0x510c8,load_level_fb);
    uint32_t *entry=(uint32_t *)(code+0x53754),*tail=(uint32_t *)(code+0x538ec);
    entry[0]=0x7c0802a6;entry[1]=0x90010010;entry[2]=0x90410014;entry[3]=0x39ae1100;
    tail[0]=0x80010010;tail[1]=0x7c0803a6;tail[2]=0x4e800020;MakeDataExecutable(code,433284);
    const double offsets[]={0,-1234.25,42.5};
    for(int camera=0;camera<3;camera++)for(int music=0;music<3;music++){
        memset(images,0,3*308);memset(actors,0x5a,3*106);calls[0]=0;used=0;
        for(int i=0;i<3;i++){
            *(double *)(images+i*308)=10+i;*(short *)(images+i*308+32)=i+1;
            *(void **)(images+i*308+300)=i<2?images+(i+1)*308:NULL;
            *(double *)(actors+i*106+44)=20+i;*(short *)(actors+i*106+32)=77+i;
            *(void **)(actors+i*106+102)=i<2?actors+(i+1)*106:NULL;
        }
        *(double *)(g+0xea2)=offsets[camera];*(short *)(g+0xabc)=music;*(double *)(g+0xaa0)=.3;
        unsigned char expected[3*106];memcpy(expected,actors,sizeof(expected));
        for(int i=0;i<3;i++)*(double *)(expected+i*106+44)+=offsets[camera];
        invoke_fb(code+0x53754,g,toc,NULL,NULL,NULL);
        assert(!strcmp(calls,music?"KMSPL":"KMSL")&&*(double *)(g+0xaa0)==-.2);
        assert(!memcmp(actors,expected,sizeof(expected)));
        for(int i=0;i<3;i++)assert(*(short *)(actors+i*106+32)==77+i);
        printf("offset%.17g music%d calls%s level%d half%d gravity%.17g\n",offsets[camera],music,calls,*(short *)(g+0xa82),*(short *)(g+0xa84),*(double *)(g+0xaa0));
    }
    puts("PASS9 native final-arena tails: preserve actors/global stage, rebase image/entityX, remove layer2 images only, map/stop/play2/load9 order, gravity override");return 0;
}
