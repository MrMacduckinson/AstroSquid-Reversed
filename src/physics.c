#include "physics.h"
#include <math.h>
#include <float.h>
#include <stdint.h>
#include <string.h>

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
    velocity->x += amount * cos(radians);
    velocity->y -= amount * sin(radians);
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
    double dx=(int)((int)target_x+target_width/2)-(int)((int)x+width/2);
    double dy=(int)((int)target_y+target_height/2)-(int)((int)y+height/2);
    /* Original ATN2 uses this rounded literal, not 180/pi. */
    double angle=atan(-dy/dx)*57.29578;
    if(dx<0) angle+=180;
    if(angle<0) angle+=360;
    return isfinite(angle)?(int)angle:INT32_MIN;
}
