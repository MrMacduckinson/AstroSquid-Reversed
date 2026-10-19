#ifndef ASTROSQUID_VISUAL_H
#define ASTROSQUID_VISUAL_H
#include <stddef.h>
#include <stdint.h>
typedef struct {int width,height,next_frame,delay;} AstroSpriteInfo;
typedef struct {int sprite;double x,y,width,height;uint32_t next_tick;} AstroVisual;
int astro_visual_change(AstroVisual *,int sprite,const AstroSpriteInfo *,size_t count,uint32_t tick);
/* One shared LM comparison clock; a positive frame change uses its own fresh
 * store clock. Host consumes that clock only when next>0 and signed next_tick
 * is strictly less than signed comparison. 1 alive,0 completed,-1 invalid. */
int astro_visual_step_clocked(AstroVisual *,const AstroSpriteInfo *,size_t count,
                              uint32_t comparison,uint32_t store);
/* Constant-clock compatibility wrapper. */
int astro_visual_step(AstroVisual *,const AstroSpriteInfo *,size_t count,uint32_t tick);
#endif
