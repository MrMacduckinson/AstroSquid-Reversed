#ifndef ASTROSQUID_PHYSICS_H
#define ASTROSQUID_PHYSICS_H
#include <stdint.h>

/* Original INITSAGAIA: PPC Float2Int followed by a signed 16-bit store. */
int16_t astro_frame_interval(int16_t fps);
/* CALC advances the negated camera offset, then derives viewport left. */
double astro_camera_advance(double left,double scroll);

typedef struct { double x, y; } AstroVelocity;

/* Recovered from original VECTORMAKE and VECTORSLOW. Units are per 60 Hz tick. */
void astro_vector_make(AstroVelocity *velocity, double degrees, double amount);
void astro_vector_slow(AstroVelocity *velocity, double friction);

int astro_heading(double x,double y,double width,double height,
                  double target_x,double target_y,double target_width,double target_height);
#endif
