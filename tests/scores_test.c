#include "../src/scores.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
int main(void){
    AstroScore scores[10];AstroScoreEditor editor;
    astro_scores_clear(scores);
    for(size_t i=0;i<10;i++)assert(scores[i].score==0&&!strcmp(scores[i].name,"Space Dust"));
    assert(!astro_scores_qualifies(scores,0));assert(!astro_scores_insert(scores,-1,"negative"));
    assert(astro_scores_insert(scores,100,"First")==1);
    assert(astro_scores_insert(scores,100,"Second")==2);
    assert(astro_scores_insert(scores,200,"")==1);
    assert(!strcmp(scores[0].name,"Paranoid Android"));
    assert(!strcmp(scores[1].name,"First")&&!strcmp(scores[2].name,"Second"));
    assert(astro_scores_insert(scores,50,"  Mixed Case  ")==4);assert(!strcmp(scores[3].name,"  Mixed Case  "));
    for(int i=4;i<10;i++)scores[i].score=50;
    assert(!astro_scores_insert(scores,50,"tied last"));
    char aliased[256];strcpy(aliased,scores[1].name);
    assert(astro_scores_insert(scores,400,scores[1].name)==1&&!strcmp(scores[0].name,aliased));
    astro_score_editor_begin(&editor);assert(astro_score_editor_key(&editor,8)&&editor.cursor==-1);
    astro_score_editor_begin(&editor);
    for(const char *c="MACSPB";*c;c++)assert(astro_score_editor_key(&editor,(unsigned char)*c));
    astro_score_editor_key(&editor,28);astro_score_editor_key(&editor,8);assert(!strcmp(editor.name,"MACSB"));
    astro_score_editor_key(&editor,30);astro_score_editor_key(&editor,127);assert(!strcmp(editor.name,"ACSB"));
    astro_score_editor_key(&editor,31);astro_score_editor_key(&editor,'!');assert(!strcmp(editor.name,"ACSB!"));
    assert(!astro_score_editor_key(&editor,27)&&!editor.submitted);
    astro_score_editor_key(&editor,13);assert(editor.submitted);
    astro_score_editor_begin(&editor);for(int i=0;i<255;i++)assert(astro_score_editor_key(&editor,'A'));
    assert(astro_score_editor_key(&editor,'B')==ASTRO_SCORE_EDIT_ALERT&&editor.alert==150&&editor.cursor==255);
    assert(astro_score_editor_resolve_alert(&editor,1)==ASTRO_SCORE_EDIT_CHANGED&&editor.cursor==256&&strlen(editor.name)==255);
    assert(editor.name[254]=='A');
    editor.cursor=128;
    assert(astro_score_editor_key(&editor,'B')==ASTRO_SCORE_EDIT_ALERT);
    assert(editor.name[128]=='A');
    assert(astro_score_editor_resolve_alert(&editor,1)==ASTRO_SCORE_EDIT_CHANGED&&editor.cursor==129&&editor.name[128]=='B');
    assert(strlen(editor.name)==255);
    assert(astro_scores_insert(scores,500,editor.name)==1&&strlen(scores[0].name)==255);
    astro_score_editor_begin(&editor);strcpy(editor.name,"ABC");editor.cursor=0;
    astro_score_editor_key(&editor,8);assert(editor.cursor==-1&&!strcmp(editor.name,"ABC"));
    astro_score_editor_key(&editor,'X');assert(editor.cursor==0&&!strcmp(editor.name,"XABC"));
    editor.cursor=-1;astro_score_editor_key(&editor,127);assert(editor.cursor==-1&&!strcmp(editor.name,"ABC"));
    editor.cursor=-32768;astro_score_editor_key(&editor,8);assert(editor.cursor==32767&&!strcmp(editor.name,"ABC"));
    astro_score_editor_key(&editor,29);assert(editor.cursor==-32768);
    astro_score_editor_key(&editor,28);assert(editor.cursor==32767);
    editor.cursor=0;astro_score_editor_key(&editor,28);assert(editor.cursor==0);
    memset(editor.name,'A',255);editor.name[255]=0;editor.cursor=255;
    assert(astro_score_editor_key(&editor,'B')==ASTRO_SCORE_EDIT_ALERT);
    assert(astro_score_editor_resolve_alert(&editor,0)==ASTRO_SCORE_EDIT_STOP&&editor.cursor==255);
    puts("PASS original score defaults, stable ties, empty-name fallback, Classic editing and byte bounds");
}
