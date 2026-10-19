#include "player.h"
void astro_player_step(AstroPlayer *p,uint32_t tick,unsigned keys,int speed,
                       AstroRect b,double width,double height,AstroViewport viewport,int ending) {
    if((int32_t)(tick-p->animation_tick)>10) {
        p->animation_tick=tick;
        if(keys&ASTRO_KEY_RIGHT) p->animation_tick-=5;
        if(p->state==1) {
            if(p->tilt<3) {p->tilt++;p->frame+=5;}
            if(p->tilt>3) {p->tilt--;p->frame-=5;}
        } else if(p->state==3&&p->tilt<5) {p->tilt++;p->frame+=5;}
        else if(p->state==2&&p->tilt>1) {p->tilt--;p->frame-=5;}
        if(!(keys&ASTRO_KEY_LEFT)||p->frame-(p->tilt-1)*5<5) p->frame++;
        if(p->frame>p->tilt*5) p->frame-=5;
    }
    if((int32_t)(tick-p->update_tick)<1) return;
    double amount=speed/2.0;
    if(keys&ASTRO_KEY_UP) {astro_vector_make(&p->velocity,90,amount);p->state=2;}
    if(keys&ASTRO_KEY_DOWN) {astro_vector_make(&p->velocity,270,amount);p->state=3;}
    if(!(keys&(ASTRO_KEY_UP|ASTRO_KEY_DOWN))) p->state=1;
    if(keys&ASTRO_KEY_LEFT) astro_vector_make(&p->velocity,180,amount);
    if(keys&ASTRO_KEY_RIGHT) astro_vector_make(&p->velocity,0,amount);
    int margin=(int)(-height/2);
    if(!ending) {
        if(b.left+p->velocity.x<viewport.left+margin&&p->velocity.x<0) p->velocity.x=0;
        if(b.right+p->velocity.x>viewport.right-(int)(-width/2)&&p->velocity.x>0) p->velocity.x=0;
        if(b.top+p->velocity.y<viewport.top+margin&&p->velocity.y<0) p->velocity.y=0;
        if(b.bottom+p->velocity.y>viewport.bottom-margin&&p->velocity.y>0) p->velocity.y=0;
    }
    astro_vector_slow(&p->velocity,.1);p->update_tick=tick;
}
