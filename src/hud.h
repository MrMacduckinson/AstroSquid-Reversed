#ifndef ASTROSQUID_HUD_H
#define ASTROSQUID_HUD_H
#include <stddef.h>
typedef struct {int player_present,hit_points,weapon,upgrades,special_ammo,lives,score;} AstroHUDState;
typedef enum {ASTRO_HUD_BOX,ASTRO_HUD_SPRITE,ASTRO_HUD_LIVES,ASTRO_HUD_SCORE} AstroHUDKind;
typedef struct {
    AstroHUDKind kind;int sprite,value;
    double x,y,width,height,r,g,b,a;
} AstroHUDCommand;
/* DRAWOVERLAY10043134. Returns command count; never writes beyond capacity. */
size_t astro_hud_commands(const AstroHUDState *state,AstroHUDCommand *commands,size_t capacity);
#endif
