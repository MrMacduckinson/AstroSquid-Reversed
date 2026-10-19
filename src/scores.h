#ifndef ASTROSQUID_SCORES_H
#define ASTROSQUID_SCORES_H
#include <stddef.h>
#include <stdint.h>
enum {ASTRO_SCORE_COUNT=10,ASTRO_SCORE_NAME_BYTES=255};
typedef struct {int32_t score;char name[ASTRO_SCORE_NAME_BYTES+1];} AstroScore;
enum {ASTRO_SCORE_EDIT_CHANGED=1,ASTRO_SCORE_EDIT_ALERT=2,ASTRO_SCORE_EDIT_STOP=3};
typedef struct {
    char name[ASTRO_SCORE_NAME_BYTES+1];int16_t cursor;int submitted;
    int alert;char pending_name[ASTRO_SCORE_NAME_BYTES+1];int16_t pending_cursor;
} AstroScoreEditor;
void astro_scores_clear(AstroScore scores[ASTRO_SCORE_COUNT]);
int astro_scores_qualifies(const AstroScore scores[ASTRO_SCORE_COUNT],int32_t score);
/* Returns 1-based inserted rank, or0. Name is original MacRoman bytes. */
int astro_scores_insert(AstroScore scores[ASTRO_SCORE_COUNT],int32_t score,const char *name);
void astro_score_editor_begin(AstroScoreEditor *editor);
/* Classic event character byte, not a hardware keycode. Return nonzero on change. */
int astro_score_editor_key(AstroScoreEditor *editor,unsigned key);
/* Original StopAlert150: Stop terminates the app; Continue keeps first255bytes.
   The host presents that choice before refreshing or accepting another key. */
int astro_score_editor_resolve_alert(AstroScoreEditor *editor,int continue_editing);
typedef struct {uint32_t deadline;int16_t visible;} AstroScoreCaret;
void astro_score_caret_begin(AstroScoreCaret *caret,uint32_t tick);
void astro_score_caret_draw(AstroScoreCaret *caret,uint32_t comparison_tick,uint32_t reset_tick);
#endif
