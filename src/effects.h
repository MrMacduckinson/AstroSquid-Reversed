#ifndef ASTROSQUID_EFFECTS_H
#define ASTROSQUID_EFFECTS_H
#include "physics.h"
#include <stdint.h>
typedef struct {
    int kind,tag,left,top,right,bottom;
    double width,height,original_height;
    AstroVelocity velocity;
    int explosion_sprite,explosion_width,explosion_height,explosion_delay;
    int debris_attribute,debris_sprite,debris_width,debris_height,debris_count;
} AstroDeathSource;
enum {ASTRO_EFFECT_SOUND,ASTRO_EFFECT_EXPLOSION,ASTRO_EFFECT_DEBRIS,ASTRO_EFFECT_PICKUP};
typedef struct {
    int type,kind,attribute,sprite,frame,sound_string;
    double x,y,width,height,scale;
    AstroVelocity velocity;
    uint32_t animation_tick,action_tick;
} AstroDeathEffect;
int astro_death_effects(const AstroDeathSource *source,uint32_t tick,uint32_t *seed,
                        void (*emit)(void *,const AstroDeathEffect *),void *context);
/* Create at the original allocation point, then mutate after the remaining RNG calls. */
int astro_death_effects_phased(const AstroDeathSource *source,uint32_t tick,uint32_t *seed,
                               void *(*create)(void *,const AstroDeathEffect *),
                               void (*finish)(void *,void *,const AstroDeathEffect *),void *context);
#endif
