#ifndef ASTROSQUID_PLAYER_H
#define ASTROSQUID_PLAYER_H
#include "combat.h"
#include <stdint.h>
typedef struct { double left,top,right,bottom; } AstroViewport;
typedef struct {
    AstroVelocity velocity;
    int frame,tilt,state;
    uint32_t animation_tick,update_tick;
} AstroPlayer;
enum { ASTRO_KEY_UP=1,ASTRO_KEY_DOWN=2,ASTRO_KEY_LEFT=4,ASTRO_KEY_RIGHT=8 };
/* Distinct original animation compare/store clocks; a closed gate ignores store. */
void astro_player_animate(AstroPlayer *p,uint32_t comparison,uint32_t store,unsigned controls);
/* Movement body only. Host stores update_tick after synchronous weapon calls. */
void astro_player_move(AstroPlayer *p,unsigned controls,int speed,AstroRect bounds,
                       double width,double height,AstroViewport viewport,int ending);
/* DOPLAYERSPRITE animation, acceleration and boundary handling; firing is separate. */
void astro_player_step(AstroPlayer *p,uint32_t tick,unsigned controls,int speed,
                       AstroRect bounds,double width,double height,AstroViewport viewport,int ending);
#endif
