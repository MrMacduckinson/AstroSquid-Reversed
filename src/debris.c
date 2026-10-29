#include "debris.h"
void astro_debris_step_clocked(AstroDebris *s,int right,double left,double gravity,
                               uint32_t (*read_tick)(void *),void *context) {
    if(!s||!read_tick)return;
    if(s->kind==20) {
        if((int32_t)(read_tick(context)-s->update_tick)>0) {
            s->update_tick=read_tick(context);astro_vector_slow(&s->velocity,.02);
        }
        return;
    }
    if(s->kind!=4||s->state!=1)return;
    if((int32_t)(read_tick(context)-s->animation_tick)>6)s->animation_tick=read_tick(context);
    if((int32_t)(read_tick(context)-s->update_tick)>0) {
        s->update_tick=read_tick(context);astro_vector_slow(&s->velocity,.02);
        astro_vector_make(&s->velocity,270,gravity);
    }
    if((int32_t)(read_tick(context)-s->action_tick)>45||right<left)s->remove=1;
}
static uint32_t constant_tick(void *context){return *(const uint32_t *)context;}
void astro_debris_step(AstroDebris *s,uint32_t tick,int right,double left,double gravity) {
    astro_debris_step_clocked(s,right,left,gravity,constant_tick,&tick);
}
double astro_debris_gravity(int stage) {return stage==6||stage==8?.3:0;}
