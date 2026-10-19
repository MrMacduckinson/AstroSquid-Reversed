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
static int16_t word(int value){
    int bits=(int)((uint32_t)value&65535u);
    return (int16_t)(bits>=32768?bits-65536:bits);
}
/* FBLEFT/FBRIGHT clamp substring lengths; the original cursor itself can wrap. */
static size_t slice_length(int requested,size_t length){
    return requested<1?0:(size_t)requested>length?length:(size_t)requested;
}
void astro_score_editor_begin(AstroScoreEditor *editor){memset(editor,0,sizeof(*editor));}
int astro_score_editor_key(AstroScoreEditor *editor,unsigned key){
    size_t length=strlen(editor->name);
    if(!key||key>255||editor->alert)return 0;
    if(key==28){editor->cursor=word(editor->cursor-1);if(editor->cursor<0)editor->cursor=0;return 1;}
    if(key==29){editor->cursor=word(editor->cursor+1);if(editor->cursor>(int)length)editor->cursor=(int16_t)length;return 1;}
    if(key==30){editor->cursor=0;return 1;}
    if(key==31){editor->cursor=(int16_t)length;return 1;}
    if(key==3||key==13){editor->submitted=1;return 1;}
    if(key==1||key==4||key==5||key==9||key==10||key==11||key==12||key==16||key==27)return 0;
    size_t left=slice_length(editor->cursor,length),right=slice_length((int)length-editor->cursor,length);
    int16_t next=editor->cursor;
    char combined[ASTRO_SCORE_NAME_BYTES+2];size_t count=0;
    if(key==8){
        left=slice_length((int)left-1,left);next=word(next-1);
    }else if(key==127){
        right=slice_length((int)right-1,right);
    }
    memcpy(combined,editor->name,left);count=left;
    if(key!=8&&key!=127){combined[count++]=(char)key;next=word(next+1);}
    memcpy(combined+count,editor->name+length-right,right);count+=right;
    if(count>ASTRO_SCORE_NAME_BYTES){
        memcpy(editor->pending_name,combined,ASTRO_SCORE_NAME_BYTES);editor->pending_name[ASTRO_SCORE_NAME_BYTES]=0;
        editor->pending_cursor=next;editor->alert=150;return ASTRO_SCORE_EDIT_ALERT;
    }
    combined[count]=0;memcpy(editor->name,combined,count+1);editor->cursor=next;return ASTRO_SCORE_EDIT_CHANGED;
}
int astro_score_editor_resolve_alert(AstroScoreEditor *editor,int continue_editing){
    if(!editor->alert)return 0;
    editor->alert=0;
    if(!continue_editing)return ASTRO_SCORE_EDIT_STOP;
    memcpy(editor->name,editor->pending_name,sizeof(editor->name));editor->cursor=editor->pending_cursor;
    return ASTRO_SCORE_EDIT_CHANGED;
}
