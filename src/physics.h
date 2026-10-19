#ifndef ASTROSQUID_PHYSICS_H
#define ASTROSQUID_PHYSICS_H

typedef struct { double x, y; } AstroVelocity;

/* Recovered from original VECTORMAKE and VECTORSLOW. Units are per 60 Hz tick. */
void astro_vector_make(AstroVelocity *velocity, double degrees, double amount);
void astro_vector_slow(AstroVelocity *velocity, double friction);

int astro_heading(double x,double y,double width,double height,
                  double target_x,double target_y,double target_width,double target_height);
#endif
