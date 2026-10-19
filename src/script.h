#ifndef ASTROSQUID_SCRIPT_H
#define ASTROSQUID_SCRIPT_H
#include <stddef.h>
#include <stdint.h>
#include "physics.h"

typedef enum { ASTRO_STOP, ASTRO_MOVE, ASTRO_NEAR, ASTRO_FIRE, ASTRO_TURN, ASTRO_RETURN } AstroOpcode;
typedef enum { ASTRO_NUMBER, ASTRO_AIM, ASTRO_FRAME, ASTRO_UP, ASTRO_DOWN,
               ASTRO_LEFT, ASTRO_RIGHT, ASTRO_ANY } AstroOperand;
typedef struct {
    int delay;
    AstroOpcode opcode;
    AstroOperand direction_kind, value_kind;
    int direction, value;
} AstroInstruction;

typedef struct {
    size_t line;
    uint32_t update_tick, action_tick, animation_tick;
    int frame, tilt, state, remove;
    double x,y;
    AstroVelocity velocity;
} AstroScriptState;

typedef struct {
    int player_present, target_heading, animated, weapon;
    double player_x,player_y;
    int gun_x,gun_y;
    void *userdata;
    void (*fire)(void *userdata,int weapon,int x,int y,int heading);
    void (*move_children)(void *userdata,int heading,double amount);
    void (*hit_player)(void *userdata);
} AstroScriptContext;

int astro_script_gun_coordinate(int edge,int turret,double size,int original_size);

int astro_parse_instruction(const char *text,AstroInstruction *out);
/* Original DOSCRIPTEDSPRITE scheduling and instruction semantics. */
int astro_script_step(AstroScriptState *state,const AstroInstruction *script,
                      size_t count,uint32_t tick,const AstroScriptContext *context);
#endif
