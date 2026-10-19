#ifndef ASTROSQUID_SPECIAL_H
#define ASTROSQUID_SPECIAL_H
#include "physics.h"
#include "beams.h"
#include "weapons.h"

typedef struct {
    int kind,subtype,x,y,hit_points,layer,frame,action_offset;
    AstroVelocity velocity;
    double scale,width,height;
} AstroSpecialSpawn;
typedef struct { double x,y,r,g,b,a; } AstroSpecialVertex;
typedef struct {
    void *context;
    uint32_t *seed;
    AstroTarget *targets;
    size_t target_count;
    /* source_parent is the source entity parent index, or-1; gun is bounds+turret. */
    int source_parent,gun_x,gun_y,frame_interval;
    double left,top,right,bottom;
    void (*spawn)(void *,const AstroSpecialSpawn *);
    void (*bullet)(void *,const AstroShot *);
    /* Hit immediately; temporary beams are damage carriers, never drawn. */
    void (*beam)(void *,const AstroBeam *,int temporary);
    void (*sprite)(void *,int sprite,double x,double y,double width,double height);
    void (*polygon)(void *,const AstroSpecialVertex *,size_t count);
    void (*sound)(void *,int string_index,int x);
} AstroSpecialContext;
typedef struct {
    int weapon,active;
    uint32_t started,last_tick,last_render_tick,action_until;
} AstroSpecial;
/* 10..13 and30..33 create their full burst immediately;40..43 and50..53 run31 ticks.
 * While active, keep player movement/input but treat player kind as-1 and suppress
 * firing until action_until. Advance the world
 * once before each step; refresh gun position/targets after that world update. */
int astro_special_start(AstroSpecial *,int weapon,int x,int y,int heading,uint32_t tick,
                        AstroSpecialContext *);
int astro_special_step(AstroSpecial *,uint32_t tick,AstroSpecialContext *);
#endif
