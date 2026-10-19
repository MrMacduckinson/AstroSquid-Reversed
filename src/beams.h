#ifndef ASTROSQUID_BEAMS_H
#define ASTROSQUID_BEAMS_H
#include <stddef.h>
#include <stdint.h>
#include "combat.h"
typedef struct {
    int kind,parent,remove;
    /* x/y are entity coordinates, not a render sprite's recentered position.
     * Zero bounds_valid keeps legacy derived bounds for existing callers. */
    double x,y,width,height;
    int bounds_valid;
    AstroRect bounds;
} AstroTarget;
static inline AstroRect astro_target_rect(const AstroTarget *t) {
    return t->bounds_valid?t->bounds:(AstroRect){(int)t->x,(int)t->y,
        (int)(t->x+t->width),(int)(t->y+t->height)};
}
typedef struct {int weapon,damage,x,y,end_x,end_y,target;} AstroBeam;
/* Returns 0..2 beams or -1 for an invalid request. World order is significant. */
int astro_beam_shots(int weapon,int x,int y,int heading,int frame_interval,
                    int source_kind,int source_parent,const AstroTarget *targets,size_t count,
                    double left,double top,double right,double bottom,uint32_t *seed,AstroBeam out[2],
                    void (*hit)(void *,const AstroBeam *),void *context);
#endif
