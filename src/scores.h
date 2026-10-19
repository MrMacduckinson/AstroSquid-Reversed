#ifndef ASTROSQUID_SCORES_H
#define ASTROSQUID_SCORES_H
#include <stddef.h>
#include <stdint.h>
enum {ASTRO_SCORE_COUNT=10,ASTRO_SCORE_NAME_BYTES=255};
typedef struct {int32_t score;char name[ASTRO_SCORE_NAME_BYTES+1];} AstroScore;
typedef struct {char name[ASTRO_SCORE_NAME_BYTES+1];size_t cursor;int submitted;} AstroScoreEditor;
void astro_scores_clear(AstroScore scores[ASTRO_SCORE_COUNT]);
int astro_scores_qualifies(const AstroScore scores[ASTRO_SCORE_COUNT],int32_t score);
/* Returns 1-based inserted rank, or0. Name is original MacRoman bytes. */
int astro_scores_insert(AstroScore scores[ASTRO_SCORE_COUNT],int32_t score,const char *name);
void astro_score_editor_begin(AstroScoreEditor *editor);
/* Classic event character byte, not a hardware keycode. Return nonzero on change. */
int astro_score_editor_key(AstroScoreEditor *editor,unsigned key);
#endif
