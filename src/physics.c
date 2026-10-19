#include "physics.h"
#include "ppc_math.h"
#include <math.h>
#include <float.h>
#include <stdint.h>
#include <string.h>

int16_t astro_frame_interval(int16_t fps) {
    uint16_t low = (uint16_t)astro_ppc_i32(60.0 / (double)fps);
    return (int16_t)(low <= INT16_MAX ? (int32_t)low : (int32_t)low - 65536);
}

static double fb_single(double value) {
    /* FB emits STFS without FRSP: retain high significand bits, not a C
       round-to-nearest cast. Normal finite values are the game's input range. */
    if (fabs(value) >= FLT_MIN && fabs(value) <= FLT_MAX) {
        uint64_t bits;
        memcpy(&bits,&value,sizeof(bits));
        bits &= ~((UINT64_C(1)<<29)-1);
        memcpy(&value,&bits,sizeof(value));
        return (double)(float)value;
    }
    float single = (float)value;
    if (isfinite(value) && fabs((double)single)>fabs(value))
        single=nextafterf(single,0.0f);
    return (double)single;
}

void astro_vector_make(AstroVelocity *velocity, double degrees, double amount) {
    const double pi = 3.14159265358979323846;
    if (degrees > 360.0) degrees -= 360.0;
    if (degrees < 0.0) degrees += 360.0;
    double radians = pi * degrees / 180.0;
    if (radians < 0.0) radians += pi * 2.0;
    velocity->x += amount * astro_ppc_cos(radians);
    velocity->y -= amount * astro_ppc_sin(radians);
}

void astro_vector_slow(AstroVelocity *velocity, double friction) {
    double retain = fb_single(1.0-fb_single(friction));
    velocity->x *= retain;
    velocity->y *= retain;
    if (velocity->x < 0.1 && velocity->x > -0.1 &&
        velocity->y < 0.1 && velocity->y > -0.1) {
        velocity->x = 0.0;
        velocity->y = 0.0;
    }
}

int astro_heading(double x,double y,double width,double height,
                  double target_x,double target_y,double target_width,double target_height) {
    double dx=(double)astro_ppc_i32(astro_ppc_i32(target_x)+target_width/2)-astro_ppc_i32(astro_ppc_i32(x)+width/2);
    double dy=(double)astro_ppc_i32(astro_ppc_i32(target_y)+target_height/2)-astro_ppc_i32(astro_ppc_i32(y)+height/2);
    /* Original ATN2 uses this rounded literal, not 180/pi. */
    double angle=astro_ppc_atan(-dy/dx)*57.29578;
    if(dx<0) angle+=180;
    if(angle<0) angle+=360;
    return astro_ppc_i32(angle);
}
