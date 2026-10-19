#include "transition.h"
#include <math.h>
#include <string.h>

static int due(uint32_t now,uint32_t deadline) {return (int32_t)(now-deadline)>=0;}
static void center(AstroTransition *t,uint32_t tick,AstroRect p,double w,double h,AstroRect view) {
    if(!t->started) {t->target_x=(view.left+view.right)/2;t->target_y=(view.top+view.bottom)/2;}
    double x=p.left+w/2,y=p.top+h/2,tx=t->target_x,ty=t->target_y;
    t->controls=(x<tx?ASTRO_KEY_RIGHT:0)|(x>tx?ASTRO_KEY_LEFT:0)|
                (y<ty?ASTRO_KEY_DOWN:0)|(y>ty?ASTRO_KEY_UP:0);
    t->ready=fabs(x-tx)<20&&fabs(y-ty)<20;t->deadline=tick+2;t->started=1;
}
void astro_transition_begin(AstroTransition *t,int mode,uint32_t tick,double scroll_x) {
    memset(t,0,sizeof(*t));t->mode=mode;t->scale=1;t->scroll_x=scroll_x;
    t->player_visible=1;t->simulate_world=1;t->player_frame=-1;
    if(mode==ASTRO_TRANSITION_MID)t->phase=ASTRO_TRANSITION_CENTER;
    else if(mode==ASTRO_TRANSITION_END) {
        t->phase=ASTRO_TRANSITION_WAIT;t->deadline=tick+61;t->allow_input=1;t->pending=ASTRO_TRANSITION_BLOW;
    } else if(mode==ASTRO_TRANSITION_RESPAWN) {
        t->phase=ASTRO_TRANSITION_WAIT;t->deadline=tick+61;t->allow_input=1;
    } else {t->phase=ASTRO_TRANSITION_WAIT;t->deadline=tick;}
}
void astro_transition_step(AstroTransition *t,uint32_t tick,AstroRect p,double w,double h,
                          AstroRect view,double cx,double cy) {
    t->events=t->pending;t->pending=0;t->zero_velocity=0;
    if(t->phase==ASTRO_TRANSITION_DONE||t->phase==ASTRO_TRANSITION_CARD)return;
    if(t->phase==ASTRO_TRANSITION_WAIT) {
        if(!due(tick,t->deadline))return;t->allow_input=0;
        if(t->mode==ASTRO_TRANSITION_END) {t->phase=ASTRO_TRANSITION_CENTER;t->started=0;}
        else {
            t->events|=ASTRO_TRANSITION_SPAWN_PLAYER;t->spawn_x=(int)(30-cx);t->spawn_y=(int)((view.bottom-view.top)/2-cy);
            t->player_frame=12;t->phase_tick=t->blink_tick=tick;t->player_visible=0;
            if(t->mode==ASTRO_TRANSITION_RESPAWN)t->phase=ASTRO_TRANSITION_BLINK;
            else {
                t->events|=ASTRO_TRANSITION_RESET_WEAPON;t->player_visible=1;t->phase=ASTRO_TRANSITION_DONE;
                if(t->mode==ASTRO_TRANSITION_NEW_GAME)t->events|=ASTRO_TRANSITION_BRIEFING|ASTRO_TRANSITION_NEW_SPECIAL;
            }
            return;
        }
    }
    if(t->phase==ASTRO_TRANSITION_BLINK) {
        if((int32_t)(tick-t->blink_tick)>5) {t->player_visible=!t->player_visible;t->blink_tick=tick;}
        if((int32_t)(tick-t->phase_tick)>180) {t->player_visible=1;t->phase=ASTRO_TRANSITION_DONE;}
        return;
    }
    if(t->phase==ASTRO_TRANSITION_CENTER) {
        if(!t->started) {center(t,tick,p,w,h,view);return;}
        if(!due(tick,t->deadline))return;
        if(!t->ready) {center(t,tick,p,w,h,view);return;}
        if(t->mode==ASTRO_TRANSITION_MID) {
            t->phase=ASTRO_TRANSITION_EXIT;t->controls=ASTRO_KEY_RIGHT;
            t->ready=p.left>view.right+50;t->deadline=tick+2;return;
        }
        t->controls=0;t->zero_velocity=1;t->phase=ASTRO_TRANSITION_ACCEL;
        t->events|=ASTRO_TRANSITION_ENGINE_GLOW|ASTRO_TRANSITION_HYPER_SOUND;
        t->scroll_x=1.4;t->scale=1;t->deadline=tick+11;return;
    }
    if(t->phase==ASTRO_TRANSITION_EXIT) {
        if(!due(tick,t->deadline))return;
        if(!t->ready) {t->ready=p.left>view.right+50;t->deadline=tick+2;return;}
        t->phase=ASTRO_TRANSITION_EXIT_WAIT;t->deadline=tick+21;return;
    }
    if(t->phase==ASTRO_TRANSITION_EXIT_WAIT) {
        if(due(tick,t->deadline)) {t->events|=ASTRO_TRANSITION_MENU_MUSIC|ASTRO_TRANSITION_CLEAR_WORLD;t->phase=ASTRO_TRANSITION_DONE;}return;
    }
    if(t->phase==ASTRO_TRANSITION_ACCEL) {
        if(!due(tick,t->deadline))return;
        t->scale-=.005;
        if(t->scroll_x>200) {t->phase=ASTRO_TRANSITION_CRUISE;t->deadline=tick+21;}
        else {t->scroll_x*=1.4;t->deadline=tick+11;}
        return;
    }
    if(t->phase==ASTRO_TRANSITION_CRUISE) {
        if(!due(tick,t->deadline))return;
        t->phase=ASTRO_TRANSITION_TRAIL;t->simulate_world=0;t->player_frame=15;
        t->events|=ASTRO_TRANSITION_TRAIL_SPRITE|ASTRO_TRANSITION_BANG_SOUND;
    }
    if(t->phase==ASTRO_TRANSITION_TRAIL) {
        // Original renders only MOVESTARS here: player/world freeze until the card.
        t->scale-=.005;
        if(t->scale<.001) {t->phase=ASTRO_TRANSITION_CARD;t->events|=ASTRO_TRANSITION_MENU_MUSIC;}
    }
}
void astro_transition_accept_card(AstroTransition *t) {
    if(t->phase!=ASTRO_TRANSITION_CARD)return;
    t->scale=1;t->pending|=ASTRO_TRANSITION_CLEAR_WORLD;t->phase=ASTRO_TRANSITION_DONE;
}
AstroTransitionRect astro_transition_engine_glow(double x,double y,double h,int frame) {
    double size=30+(frame%5)*6,l=x+22-size/2,t=y+h/2-size/2;
    return (AstroTransitionRect){l,t,size,size};
}
AstroTransitionRect astro_transition_departure_glow(double x,double y,double w,double h) {
    return (AstroTransitionRect){x-10,y-5,w-20,h+10};
}
AstroTransitionRect astro_transition_departure_trail(AstroTransitionRect g) {
    double height=15,top=g.height/2+g.y-height/2;
    return (AstroTransitionRect){0,top,50+g.x,height};
}
