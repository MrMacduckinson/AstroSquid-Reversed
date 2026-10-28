/* Execute original SERVICEMUSIC with scripted QuickTime boundaries, no playback. */
#define main existing_keymap_main
#include "ppc_keymap_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>

static char events[32];static unsigned used;static Boolean done;
static void event(char c){assert(used+1<sizeof(events));events[used++]=c;events[used]=0;}
static void task(void *movie,long limit){assert(movie==(void *)0x1234&&limit==0);event('T');}
static Boolean is_done(void *movie){assert(movie==(void *)0x1234);event('D');return done;}
static void beginning(void *movie){assert(movie==(void *)0x1234);event('B');}
static void stop_movie(void *movie){assert(movie==(void *)0x1234);event('S');}
static uint32_t unexpected_tick(void){assert(!"SERVICEMUSIC read a clock without fading");return 0;}

int main(int argc,char **argv){
    if(argc!=3)return 2;alarm(15);
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*g=calloc(1,0x1300),*heap=calloc(1,65536);
    assert(g&&heap);*(void **)(g+0x21c)=read_file(argv[2]);
    *(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;
    uint32_t toc[489]={0};
    for(int i=0;i<484;i++){
        void *fn=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"MoviesTask"))fn=task;
        if(!strcmp(import_names[i],"IsMovieDone"))fn=is_done;
        if(!strcmp(import_names[i],"GoToBeginningOfMovie"))fn=beginning;
        if(!strcmp(import_names[i],"StopMovie"))fn=stop_movie;
        if(!strcmp(import_names[i],"TickCount"))fn=unexpected_tick;
        descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing);toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    toc[0]=(uint32_t)(uintptr_t)g;MakeDataExecutable(code,433284);
    Handle state=NewHandleClear(24),track=NewHandleClear(82);assert(state&&track);
    for(int test=0;test<12;test++){
        memset(*state,0,24);memset(*track,0,82);used=0;events[0]=0;
        *(Handle *)(g+0xfe8)=test==0?NULL:state;
        *(Handle *)*state=test==1?NULL:track;
        *(uint32_t *)(*track+2)=test==2?0:0x1234;
        done=test>=4;
        short loop=test<6?1:test==6?-1:0;
        short count=test<8?1:test==8?2:test==9?0:test==10?-1:32767;
        *(short *)(*track+10)=loop;*(short *)(*track+12)=count;
        invoke_fb(code+0x334bc,g,toc,NULL,NULL,NULL);
        short after=*(short *)(*track+12);
        const char *expected=test<3?"":!done?"TD":loop?"TDB":count<=1?"TDS":"TDB";
        assert(!strcmp(events,expected));
        assert(after==(done&&!loop?(short)(count-1):count));
        assert(*(Handle *)*state==((done&&!loop&&count<=1)?NULL:test==1?NULL:track));
        printf("case%d loop%d count%d after%d calls%s\n",test,loop,count,after,events);
    }
    DisposeHandle(track);DisposeHandle(state);
    puts("PASS original music service: 12 guarded/completed/infinite/finite cases, exact QT call order and count, no fade clock");
    return 0;
}
