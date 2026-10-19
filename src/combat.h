#ifndef ASTROSQUID_COMBAT_H
#define ASTROSQUID_COMBAT_H
#include "physics.h"
typedef struct {
    int kind,layer,hit_points,remove;
    AstroVelocity velocity;
} AstroCombatState;
/* Returns one when the original requests an additional projectile death effect. */
int astro_bullet_hits_enemy(AstroCombatState *bullet,AstroCombatState *enemy,
                           int kill_score,int *score);
void astro_bullet_hits_player(AstroCombatState *bullet,AstroCombatState *player);
typedef struct { int weapon,upgrade,specials,lives; } AstroInventory;
void astro_pickup(AstroCombatState *player,int type,int health,int *removed,AstroInventory *inventory);
typedef struct { int left,top,right,bottom; } AstroRect;
void astro_player_hits_scenery(AstroCombatState *player,AstroRect player_rect,
                               AstroCombatState *scenery,AstroRect scenery_rect);
#endif
