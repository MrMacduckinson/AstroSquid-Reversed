#include "scores.h"
#include <string.h>
void astro_scores_clear(AstroScore scores[ASTRO_SCORE_COUNT]){
    for(size_t i=0;i<ASTRO_SCORE_COUNT;i++){scores[i].score=0;strcpy(scores[i].name,"Space Dust");}
}
int astro_scores_qualifies(const AstroScore scores[ASTRO_SCORE_COUNT],int32_t score){
    return score>scores[ASTRO_SCORE_COUNT-1].score;
}
int astro_scores_insert(AstroScore scores[ASTRO_SCORE_COUNT],int32_t score,const char *name){
    if(!astro_scores_qualifies(scores,score))return 0;
    size_t rank=0;while(rank<ASTRO_SCORE_COUNT&&score<=scores[rank].score)rank++;
    if(rank==ASTRO_SCORE_COUNT)return 0;
    char copy[ASTRO_SCORE_NAME_BYTES+1];
    if(!name||!*name)name="Paranoid Android";
    size_t length=0;while(length<ASTRO_SCORE_NAME_BYTES&&name[length])length++;
    memcpy(copy,name,length);copy[length]=0;
    memmove(scores+rank+1,scores+rank,(ASTRO_SCORE_COUNT-rank-1)*sizeof(*scores));
    scores[rank].score=score;memcpy(scores[rank].name,copy,length+1);
    return (int)rank+1;
}
void astro_score_editor_begin(AstroScoreEditor *editor){memset(editor,0,sizeof(*editor));}
int astro_score_editor_key(AstroScoreEditor *editor,unsigned key){
    size_t length=strlen(editor->name);if(editor->cursor>length)editor->cursor=length;
    if(!key||key>255||editor->submitted)return 0;
    if(key==8){if(!editor->cursor)return 0;memmove(editor->name+editor->cursor-1,editor->name+editor->cursor,length-editor->cursor+1);editor->cursor--;return 1;}
    if(key==127){if(editor->cursor==length)return 0;memmove(editor->name+editor->cursor,editor->name+editor->cursor+1,length-editor->cursor);return 1;}
    if(key==28){if(!editor->cursor)return 0;editor->cursor--;return 1;}
    if(key==29){if(editor->cursor==length)return 0;editor->cursor++;return 1;}
    if(key==30){editor->cursor=0;return 1;}
    if(key==31){editor->cursor=length;return 1;}
    if(key==3||key==13){editor->submitted=1;return 1;}
    if(key==1||key==4||key==5||key==9||key==10||key==11||key==12||key==16||key==27)return 0;
    if(length==ASTRO_SCORE_NAME_BYTES)return 0;
    memmove(editor->name+editor->cursor+1,editor->name+editor->cursor,length-editor->cursor+1);
    editor->name[editor->cursor++]=(char)key;return 1;
}
