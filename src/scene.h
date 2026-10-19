#ifndef ASTROSQUID_SCENE_H
#define ASTROSQUID_SCENE_H
#include <stddef.h>
#include <stdint.h>
#include "beams.h"
typedef struct { double brightness,x,y,speed; } AstroStar;
typedef struct { double x,y; int depth; } AstroParallax;
typedef struct { double r,g,b,a,width; } AstroLineStyle;
typedef struct {
    int sprite,persistent;
    double xy[8],alpha;
    /* Original CPU sprite/transform command, before GPU matrix rasterization. */
    double rect[4],angle,pivot_x,pivot_y;
} AstroSceneSprite;
typedef struct {
    void *context;
    void (*line)(void *,double,double,double,double,AstroLineStyle);
    void (*sprite)(void *,const AstroSceneSprite *);
    void (*point)(void *,double,double,double);
    void (*star_trail)(void *,double,double,double,double);
} AstroSceneSink;
/* Original FB star array holds3000 entries; game draws the first1000, menu all3000. */
void astro_stars_init(AstroStar stars[3000],int menu,uint32_t *seed);
void astro_stars_move(AstroStar stars[3000],double camera_x,double camera_y,
                      double left,double top,double right,double bottom,
                      double scroll_x,double scroll_y,double input_x,double input_y,
                      int interval,uint32_t *seed,AstroParallax *layers,size_t count,int menu);
void astro_stars_draw(const AstroStar stars[3000],int menu,int stage,double scroll_x,
                      const AstroSceneSink *sink);
/* Generates original screen-space beam vertices and sprite quads. Persistent
 * laser impact sprites are requested only when the endpoint is inside bounds. */
void astro_beam_render(const AstroBeam *beam,double camera_x,double camera_y,
                       double left,double top,double right,double bottom,uint32_t *seed,
                       const AstroSceneSink *sink);
#endif
