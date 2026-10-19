#ifndef ASTROSQUID_HIT_VISUAL_H
#define ASTROSQUID_HIT_VISUAL_H
#include "combat.h"
#include "visual.h"
enum {ASTRO_PLAYER_HIT_LAYER=7,ASTRO_PLAYER_SCENERY_HIT_LAYER=8,ASTRO_PLAYER_HIT_SOUND=301};
typedef struct {AstroVisual visual;int active;} AstroPlayerHitVisual;
/* Call after a valid BULLETHITSPLAYER hit only when playerHP remains positive.
 * Returns1=newsprite71,2=existing sprite reset72,0=invalid data. Both emitHit301;
 * a reset retains the original rendercreation order. */
int astro_player_hit_visual(AstroPlayerHitVisual *effect,AstroRect bounds,
                           const AstroSpriteInfo *sprites,size_t count,uint32_t tick);
/* Scenery hits use the same named effect, but force its size/position to current
 * bounds on every reset. New scenery effect useslayer8; retain its old layer
 * and birth when this returns2, including mixed projectile/scenery hits. */
int astro_player_scenery_hit_visual(AstroPlayerHitVisual *effect,AstroRect bounds,
                                   const AstroSpriteInfo *sprites,size_t count,uint32_t tick);
void astro_player_hit_follow(AstroPlayerHitVisual *effect,AstroRect player_bounds);
/* LMHANDLESPRITES phase, after render:1alive,0removed,-1invalid. */
int astro_player_hit_step(AstroPlayerHitVisual *effect,const AstroSpriteInfo *sprites,size_t count,uint32_t tick);
#endif
