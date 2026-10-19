#include "effects.h"
#include "weapons.h"
#include <math.h>

int astro_death_effects(const AstroDeathSource *s,uint32_t tick,uint32_t *seed,
                        void (*emit)(void *,const AstroDeathEffect *),void *context) {
    if(!s||!seed||!emit||!isfinite(s->width)||!isfinite(s->height)||
       s->width<0||s->height<0||s->width>32767||s->height>32767||
       s->original_height<=0||s->debris_count<0) return 0;
    int width=(int)s->width,height=(int)s->height;
    /* Original consumes two RND calls before initializing its width registers.
       Their values are overwritten by every tagged enemy's explosion pass. */
    int x=(int16_t)(s->left+astro_random(seed,width));
    int y=(int16_t)(s->top+astro_random(seed,height));
    double scale=s->height/s->original_height;
    if(s->kind!=2) {
        int choice=astro_random(seed,width<60?3:2);
        const int small[]={0x122,0x123,0x124},large[]={0x11a,0x125};
        AstroDeathEffect sound={.type=ASTRO_EFFECT_SOUND,
            .sound_string=width<60?small[choice-1]:large[choice-1],.x=s->left};
        emit(context,&sound);
    }
    int count=(int)((int)(2+s->height*s->width/100)*scale);
    if(s->kind==2) count=(int)scale;
    if(count>65536) return 0;
    if(s->explosion_sprite) for(int i=0;i<(count>0?count:1);i++) {
        x=(int16_t)(s->left+astro_random(seed,width));
        y=(int16_t)(s->top+astro_random(seed,height));
        if(s->kind==2) x=s->right;
        double factor=scale/3+(5+astro_random(seed,10))/10.0;
        AstroDeathEffect effect={.type=ASTRO_EFFECT_EXPLOSION,.kind=8,
            .sprite=s->explosion_sprite,.frame=1,
            .x=x-factor*s->explosion_width/2,.y=y-factor*s->explosion_height/2,
            .width=factor*s->explosion_width,.height=factor*s->explosion_height,
            .animation_tick=tick+(uint32_t)s->explosion_delay};
        if(s->kind!=2) effect.animation_tick+=(uint32_t)(-5+astro_random(seed,10));
        emit(context,&effect);
    }
    count=(int)(s->debris_count*scale);
    if(count>65536) return 0;
    if(s->debris_attribute) for(int i=0;i<(count>0?count:1);i++) {
        AstroDeathEffect debris={.type=ASTRO_EFFECT_DEBRIS,
            .kind=s->debris_attribute-40>10?20:4,.attribute=s->debris_attribute,
            .sprite=s->debris_sprite,.width=s->debris_width,.height=s->debris_height,
            .x=s->left+astro_random(seed,width),.y=s->top+astro_random(seed,height)};
        int heading=astro_random(seed,360);
        double amount=(20+astro_random(seed,40))*.1;
        astro_vector_make(&debris.velocity,heading,amount);
        debris.velocity.x+=s->velocity.x/2;debris.velocity.y+=s->velocity.y/2;
        debris.frame=astro_random(seed,3);
        debris.animation_tick=tick;debris.action_tick=tick+(uint32_t)astro_random(seed,10);
        double factor=(5+astro_random(seed,8))/10.0;
        debris.width*=factor;debris.height*=factor;
        emit(context,&debris);
    }
    if(s->tag==1||s->tag==2) {
        AstroDeathEffect pickup={.type=ASTRO_EFFECT_PICKUP,.kind=40,
            .attribute=s->tag==1?401:404,.frame=1,.x=x,.y=y};
        emit(context,&pickup);
    }
    return 1;
}
