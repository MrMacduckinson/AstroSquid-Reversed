#ifndef ASTRO_PPC_MATH_H
#define ASTRO_PPC_MATH_H
#include <stdint.h>
/* Original Apple PowerPC MathLib algorithms, explicit IEEE fused operations. */
double astro_ppc_sin(double x);
double astro_ppc_cos(double x);
double astro_ppc_asin(double x);
double astro_ppc_atan(double x);
int32_t astro_ppc_i32(double x);
#endif
