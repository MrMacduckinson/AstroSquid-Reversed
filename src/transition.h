#ifndef ASTROSQUID_TRANSITION_H
#define ASTROSQUID_TRANSITION_H
#include "player.h"
#include <stdint.h>
enum { ASTRO_TRANSITION_MID,ASTRO_TRANSITION_END,ASTRO_TRANSITION_RESPAWN,
       ASTRO_TRANSITION_NEW_GAME,ASTRO_TRANSITION_SECTION };
enum { ASTRO_TRANSITION_DONE,ASTRO_TRANSITION_WAIT,ASTRO_TRANSITION_CENTER,
       ASTRO_TRANSITION_EXIT,ASTRO_TRANSITION_EXIT_WAIT,ASTRO_TRANSITION_ACCEL,
       ASTRO_TRANSITION_CRUISE,ASTRO_TRANSITION_TRAIL,ASTRO_TRANSITION_CARD,
       ASTRO_TRANSITION_BLINK };
enum { ASTRO_TRANSITION_BLOW=1,ASTRO_TRANSITION_CLEAR_WORLD=2,
       ASTRO_TRANSITION_MENU_MUSIC=4,ASTRO_TRANSITION_HYPER_SOUND=8,
       ASTRO_TRANSITION_BANG_SOUND=16,ASTRO_TRANSITION_ENGINE_GLOW=32,
       ASTRO_TRANSITION_TRAIL_SPRITE=64,ASTRO_TRANSITION_SPAWN_PLAYER=128,
       ASTRO_TRANSITION_BRIEFING=256,ASTRO_TRANSITION_RESET_WEAPON=512,
       ASTRO_TRANSITION_NEW_SPECIAL=1024 };
typedef struct {
    int mode,phase,ready,started;
    uint32_t deadline,phase_tick,blink_tick,pending;
    unsigned events,controls;
    int allow_input,simulate_world,player_visible,zero_velocity,player_frame;
    double scroll_x,scale,spawn_x,spawn_y,target_x,target_y;
} AstroTransition;
/* Call step once per60Hz tick before physics; it exposes one-shot events and
 * persistent controls/state. Center/exit steering matches original WAITLOOP(1).
 * END begins with HP200 (host), respawn creates kind-1 invulnerable player. */
void astro_transition_begin(AstroTransition *t,int mode,uint32_t tick,double scroll_x);
void astro_transition_step(AstroTransition *t,uint32_t tick,AstroRect player_bounds,
                          double width,double height,AstroRect viewport,double camera_x,double camera_y);
/* END card must wait for a user key; this performs the final cleanup/reset. */
void astro_transition_accept_card(AstroTransition *t);
/* Sprite115EngineGlow tracks player animation; Sprite116 trail is frozen once
 * created. Coordinates are world-space; host supplies normal layer8/4 drawing. */
typedef struct {double x,y,width,height;} AstroTransitionRect;
AstroTransitionRect astro_transition_engine_glow(double player_x,double player_y,double player_height,int frame);
AstroTransitionRect astro_transition_departure_glow(double player_x,double player_y,double width,double height);
AstroTransitionRect astro_transition_departure_trail(AstroTransitionRect glow);
#endif
