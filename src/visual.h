#ifndef ASTROSQUID_VISUAL_H
#define ASTROSQUID_VISUAL_H
#include <stddef.h>
#include <stdint.h>
typedef struct {int width,height,next_frame,delay;} AstroSpriteInfo;
typedef struct {int sprite;double x,y,width,height;uint32_t next_tick;} AstroVisual;
int astro_visual_change(AstroVisual *,int sprite,const AstroSpriteInfo *,size_t count,uint32_t tick);
/* 1 alive, 0 animation completed, -1 invalid sprite data. */
int astro_visual_step(AstroVisual *,const AstroSpriteInfo *,size_t count,uint32_t tick);
#endif
