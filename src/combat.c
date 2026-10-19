#include "combat.h"
#include <stdint.h>

int astro_bullet_hits_enemy(AstroCombatState *b,AstroCombatState *e,int value,int *score) {
    if(b->remove||(b->layer!=3&&b->layer!=1)) return 0;
    e->hit_points=(int16_t)(e->hit_points-b->hit_points);
    b->hit_points=(int16_t)(b->hit_points-value);
    if(value>10000) b->hit_points=0;
    if(e->hit_points<1) {
        *score+=value;e->remove=-1;
        if(b->kind!=999) {
            e->velocity.x+=b->velocity.x;e->velocity.y+=b->velocity.y;
        }
    }
    if(b->hit_points<40) { b->remove=-1;return 0; }
    return 1;
}

void astro_bullet_hits_player(AstroCombatState *b,AstroCombatState *p) {
    if(b->remove||(b->layer!=2&&b->layer!=1)) return;
    int damage=(b->kind==2||b->kind==999)?b->hit_points:40;
    if(b->kind==999) damage*=2;
    p->hit_points=(int16_t)(p->hit_points-damage);
    b->hit_points=(int16_t)(b->hit_points-p->hit_points);
    if(b->hit_points<1) b->remove=-1;
    if(p->hit_points<1) {p->hit_points=0;p->remove=-1;}
}
