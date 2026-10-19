#include "../src/scores.h"
#include <assert.h>
#include <stdio.h>
int main(int argc,char **argv){
    assert(argc==2);FILE*f=fopen(argv[1],"r");assert(f);unsigned start,tick,reset,deadline,reads,count=0;int visible;
    while(fscanf(f,"%u,%u,%u,%u,%d,%u",&start,&tick,&reset,&deadline,&visible,&reads)==6){
        AstroScoreCaret caret;astro_score_caret_begin(&caret,start);
        unsigned actualReads=(int32_t)caret.deadline<(int32_t)tick?2:1;
        astro_score_caret_draw(&caret,tick,reset);
        assert(caret.deadline==deadline&&caret.visible==visible&&actualReads==reads);count++;
    }
    fclose(f);assert(count==4225);
    puts("PASS4225 original caret deadline, visibility and conditional TickCount reads");
}
