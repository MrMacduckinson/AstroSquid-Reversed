#ifndef ASTROSQUID_WEAPONS_H
#define ASTROSQUID_WEAPONS_H
#include <stdint.h>
typedef struct { int type,heading,x,y; } AstroShot;
typedef struct { int pattern; AstroShot shots[6]; } AstroWeapon;
/* Ordinary FIREWEAPON branch only. Lasers and bolts require their own routines. */
int astro_weapon_shots(const AstroWeapon *weapon,int x,int y,int heading,
                       uint32_t *seed,AstroShot out[6]);
int astro_random(uint32_t *seed,int bound);
#endif
