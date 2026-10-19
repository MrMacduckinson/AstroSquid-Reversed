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
    astro_score_editor_begin(&editor);assert(!astro_score_editor_key(&editor,8));
    for(const char *c="MACSPB";*c;c++)assert(astro_score_editor_key(&editor,(unsigned char)*c));
    astro_score_editor_key(&editor,28);astro_score_editor_key(&editor,8);assert(!strcmp(editor.name,"MACSB"));
    astro_score_editor_key(&editor,30);astro_score_editor_key(&editor,127);assert(!strcmp(editor.name,"ACSB"));
    astro_score_editor_key(&editor,31);astro_score_editor_key(&editor,'!');assert(!strcmp(editor.name,"ACSB!"));
    assert(!astro_score_editor_key(&editor,27)&&!editor.submitted);
    astro_score_editor_key(&editor,13);assert(editor.submitted&&!astro_score_editor_key(&editor,'X'));
    astro_score_editor_begin(&editor);for(int i=0;i<255;i++)assert(astro_score_editor_key(&editor,'A'));
    assert(!astro_score_editor_key(&editor,'B')&&editor.cursor==255&&strlen(editor.name)==255);
    assert(astro_scores_insert(scores,500,editor.name)==1&&strlen(scores[0].name)==255);
    puts("PASS original score defaults, stable ties, empty-name fallback, Classic editing and byte bounds");
}
