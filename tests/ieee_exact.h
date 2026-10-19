#ifndef ASTRO_TEST_IEEE_EXACT_H
#define ASTRO_TEST_IEEE_EXACT_H
#include <stdint.h>
#include <string.h>
static int ieee_exact(double a,double b){uint64_t x,y;memcpy(&x,&a,8);memcpy(&y,&b,8);return x==y;}
#endif
