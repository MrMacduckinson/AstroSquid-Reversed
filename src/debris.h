#ifndef ASTROSQUID_DEBRIS_H
#define ASTROSQUID_DEBRIS_H
#include "physics.h"
#include <stdint.h>
typedef struct {
    int kind,state,frame,remove;
    uint32_t update_tick,animation_tick,action_tick;
    AstroVelocity velocity;
} AstroDebris;
/* Position/collision bounds are updated by the world before this routine.
 * Kind4 is DOSHRAPNELSPRITE; kind20 is CALCSPRITES' inert scenery drift. */
/* Consumes original independent compare/store/lifetime clocks. Kind4 state!=1
 * reads none; kind20 reads its update gate regardless of state. */
void astro_debris_step_clocked(AstroDebris *,int bounds_right,double viewport_left,
                               double gravity,uint32_t (*read_tick)(void *),void *context);
void astro_debris_step(AstroDebris *,uint32_t tick,int bounds_right,
                        double viewport_left,double gravity);
/* Stage9 is the ending loaded by the boss-death branch. */
double astro_debris_gravity(int stage);
#endif
