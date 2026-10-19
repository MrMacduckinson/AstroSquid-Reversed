#include "combat.h"
#include <stdint.h>
#include <math.h>

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

void astro_pickup(AstroCombatState *player,int type,int health,int *removed,AstroInventory *inventory) {
    if(!*removed) {
        if(type==1) {
            player->hit_points=(int16_t)(player->hit_points+health);
            if(player->hit_points>200) player->hit_points=200;
        } else if(type>=2&&type<=5) {
            const int families[]={40,30,10,50};int weapon=families[type-2];
            if(inventory->weapon==weapon) {
                if(inventory->upgrade==3&&inventory->specials<4) inventory->specials++;
                if(inventory->upgrade<3) inventory->upgrade++;
            } else {inventory->weapon=weapon;inventory->upgrade=0;}
        } else if(type==9) inventory->lives++;
    }
    *removed=1;
}

void astro_player_hits_scenery(AstroCombatState *p,AstroRect a,AstroCombatState *s,AstroRect b) {
    if(s->remove) return;
    /* The original subtracts right-right for X; preserve that asymmetric push. */
    double dx=b.left-a.left,dy=(b.bottom-b.top)/2.0+b.top-((a.bottom-a.top)/2.0+a.top);
    double length=sqrt(dx*dx+dy*dy);dx/=length;dy/=length;
    if(b.right-b.left+b.bottom-b.top<60) {
        s->velocity.x+=dx;s->velocity.y+=dy;
        p->velocity.x-=dx;p->velocity.y-=dy;
    } else {p->velocity.x-=dx*2;p->velocity.y-=dy*2;}
    s->hit_points=(int16_t)(s->hit_points-10);
    p->hit_points=(int16_t)(p->hit_points-10);
    if(p->hit_points<1) {p->hit_points=0;p->remove=-1;}
}
