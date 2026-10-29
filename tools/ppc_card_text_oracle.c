/* Original GETREADY/ENDDIALOG and bounded startup credits text; semantic GPU/audio/input observers. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
#include <setjmp.h>
static jmp_buf credits_finished;
static int reminder;
static unsigned buttons;
static unsigned char *card_globals;
static unsigned card_case,texts,delays,polls,music_calls,swaps,gameovers,stops,plays;
static uint64_t word(double x){uint64_t u;memcpy(&u,&x,8);return u;}
void card_text(double *x,double *y,unsigned char *text,double *size){
    printf("%u,%u,",card_case,texts++);for(unsigned i=0;i<text[0];i++)printf("%02x",text[i+1]);
    printf(",%016llx,%016llx,%016llx",word(*x),word(*y),word(*size));
    for(unsigned i=0;i<4;i++)printf(",%016llx",word(color[i]));putchar('\n');
}
void card_hud(void){}
void card_picture(void){}
void card_swap(void){swaps++;if(reminder)printf("%u,swap\n",card_case);if(card_case==18)longjmp(credits_finished,1);}
void card_keys(void){polls++;if(reminder){printf("%u,keys\n",card_case);*(int16_t *)(card_globals+0xab2)=card_case<3&&polls>=card_case%3+1;return;}*(int16_t *)(card_globals+0xab6)=polls%(card_case%3+1)==0;}
void card_music(void){music_calls++;if(reminder)printf("%u,music\n",card_case);}
static unsigned char reminder_button(void){buttons++;printf("%u,button\n",card_case);return card_case>=3&&polls>=card_case%3+1;}
void card_stop(void){stops++;}
void card_play(void){plays++;}
void card_gameover(void){gameovers++;}
static void card_delay(unsigned ticks,unsigned *final){assert(ticks==(reminder?300u:60u));*final=ticks*++delays;if(reminder)printf("%u,delay,%u\n",card_case,ticks);}
BRIDGE(card_text) BRIDGE(card_hud) BRIDGE(card_picture) BRIDGE(card_swap) BRIDGE(card_keys)
BRIDGE(card_music) BRIDGE(card_stop) BRIDGE(card_play) BRIDGE(card_gameover)
int main(int argc,char **argv){
    if(argc!=4&&argc!=5)return 2;reminder=argc==5;assert(!reminder||!strcmp(argv[4],"reminder"));alarm(15);struct stat input;
    assert(!stat(argv[1],&input)&&input.st_size==455780&&!stat(argv[2],&input)&&input.st_size==11812);
    unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*g=calloc(1,0x1300),*heap=calloc(1,0x100000);assert(g&&heap);card_globals=g;
    uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strncmp(import_names[i],"gl",2))fn=noop;
        if(!strcmp(import_names[i],"glColor3d"))fn=color3;
        if(!strcmp(import_names[i],"glColor4d"))fn=color4;
        if(!strcmp(import_names[i],"Delay"))fn=card_delay;
        if(reminder&&!strcmp(import_names[i],"Button"))fn=reminder_button;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }toc[0]=(uint32_t)(uintptr_t)g;
    FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;
    assert(!FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL)&&!FSGetResourceForkName(&fork)&&!FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf));UseResFile(rf);
    Str255 text;for(int i=1;i<=256;i++){GetIndString(text,129,i);text[text[0]+1]=0;font_widths[i]=atof((char *)text+1)/32;}font_widths[32]=.2;
    const struct {unsigned at;void *fn;} hooks[]={
        {0x3572c,card_text_fb},{0x43134,card_hud_fb},{0x3bb58,card_picture_fb},{0x35eb8,card_swap_fb},
        {0x33b40,card_picture_fb},{0x4cb28,card_keys_fb},{0x334bc,card_music_fb},{0x31af4,card_stop_fb},{0x31edc,card_play_fb},{0x4cef0,card_gameover_fb}};
    for(unsigned i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++)jump_to(code+hooks[i].at,hooks[i].fn);
    // Keep the real startup frame, skip services, stop at the credits' first swap.
    assert(*(uint32_t *)(code+0x654a0)==0x3be00001);
    *(uint32_t *)(code+0x654a0)=0x48000000|(0x65950-0x654a0);
    MakeDataExecutable(code,433284);
    for(card_case=0;card_case<(reminder?6u:19u);card_case++){
        memset(g,0,0x1300);texts=delays=polls=music_calls=swaps=gameovers=stops=plays=0;
        *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xeb6)=font_widths;
        *(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
        *(int16_t *)(g+0xed6)=640;*(int16_t *)(g+0xed8)=480;
        *(int16_t *)(g+0xa82)=card_case<16?card_case/2+1:8;*(int16_t *)(g+0xa84)=card_case<16?card_case%2+1:2;*(int16_t *)(g+0xa0c)=1;*(int16_t *)(g+0xabc)=card_case%2;
        if(reminder){
            buttons=0;*(int16_t *)(g+0xa68)=7;
            invoke_fb(code+0x3e924,g,toc,NULL,NULL,NULL);
            assert(swaps==1&&delays==1&&polls==card_case%3+1&&music_calls==polls&&buttons==polls&&!*(int16_t *)(g+0xa68)&&*(int16_t *)(g+0x58c)==1);
            printf("%u,return,%u,%u\n",card_case,polls,buttons);continue;
        }
        if(card_case==18){
            if(!setjmp(credits_finished))invoke_fb(code+0x65484,g,toc,NULL,NULL,NULL);
            assert(texts==4&&swaps==1&&!delays&&!polls&&!music_calls&&!gameovers&&!stops&&!plays);continue;
        }
        invoke_fb(code+(card_case<16?0x4e004:0x50388),g,toc,NULL,NULL,NULL);
        unsigned pages=card_case<16?1:4;
        assert(texts==2*pages&&delays==pages&&swaps==pages&&polls==pages*(card_case%3+1)&&music_calls==polls);
        assert(gameovers==(card_case>=16)&&stops==(card_case<16)&&plays==(card_case<16&&card_case%2));
    }
    CloseResFile(rf);fputs(reminder?"PASS6 original registration reminder schedules\n":"PASS19 original cards/credits:52 text commands, Delay60 per page, key/music polling and accepted-key music/GameOver boundary\n",stderr);return 0;
}
