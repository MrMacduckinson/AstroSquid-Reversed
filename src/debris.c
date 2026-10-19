#include "debris.h"
void astro_debris_step(AstroDebris *s,uint32_t tick,int right,double left,double gravity) {
    if(!s)return;
    if(s->kind==20) {
        if((int32_t)(tick-s->update_tick)>0) {
            s->update_tick=tick;astro_vector_slow(&s->velocity,.02);
        }
        return;
    }
    if(s->kind!=4||s->state!=1)return;
    if((int32_t)(tick-s->animation_tick)>6)s->animation_tick=tick;
    if((int32_t)(tick-s->update_tick)>0) {
        s->update_tick=tick;astro_vector_slow(&s->velocity,.02);
        astro_vector_make(&s->velocity,270,gravity);
    }
    if((int32_t)(tick-s->action_tick)>45||right<left)s->remove=1;
}
double astro_debris_gravity(int stage) {return stage==6||stage==8?.3:stage==9?-.2:0;}
