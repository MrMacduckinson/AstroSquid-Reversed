#include "special.h"
#include <math.h>
#include <string.h>

static void sound(AstroSpecialContext *c,int id,int x) {if(c->sound)c->sound(c->context,id,x);}
static void spawn(AstroSpecialContext *c,const AstroSpecialSpawn *s) {if(c->spawn)c->spawn(c->context,s);}
static void sprite(AstroSpecialContext *c,int id,double x,double y,double size) {
    if(c->sprite)c->sprite(c->context,id,x,y,size,size);
}
static int random_value(AstroSpecialContext *c,int n) {return astro_random(c->seed,n);}
static int valid(const AstroSpecialContext *c) {
    return c&&c->seed&&(!c->target_count||c->targets)&&c->frame_interval>0&&c->left<c->right&&c->top<c->bottom;
}
static int center(const AstroTarget *t,int y) {
    AstroRect r=astro_target_rect(t);
    return (int)((y?t->y:t->x)+(y?r.bottom-r.top:r.right-r.left)/2.0);
}
static int nearest(AstroSpecialContext *c,int x,int y,int distance,int excluded) {
    int found=-1;
    for(size_t i=0;i<c->target_count;i++) {
        AstroTarget *t=c->targets+i;
        if(!(t->kind==1||t->kind==5||(t->kind>19&&t->kind<30))||
            (int)i==excluded||(int)i==c->source_parent||t->remove)continue;
        int dx=x-(int16_t)center(t,0),dy=y-(int16_t)center(t,1);
        int d=dx*dx+dy*dy;
        if(d<distance){distance=d;found=(int)i;}
    }
    return found;
}
static void beam(AstroSpecialContext *c,int weapon,int damage,int x,int y,int ex,int ey,int target,int temporary) {
    AstroBeam b={weapon,damage,x,y,ex,ey,target};if(c->beam)c->beam(c->context,&b,temporary);
}
static void burst(AstroSpecialContext *c,int x,int y) {
    for(int group=0;group<2;group++)for(int i=0;i<(group?40:50);i++) {
        int dx=random_value(c,10),dy=random_value(c,10);
        AstroSpecialSpawn s={.kind=2,.subtype=group?1:5,.x=x-5+dx,.y=y-5+dy,
            .hit_points=group?30:60,.layer=3,.frame=1,.scale=1};
        int heading=random_value(c,360),r=random_value(c,4);
        astro_vector_make(&s.velocity,heading,(group?6:9)*(6.0+r)/10.0);
        s.velocity.x+=6;spawn(c,&s);
    }
}
static void plasma_projectile(AstroSpecialContext *c,int x,int y,int heading) {
    AstroSpecialSpawn s={.kind=2,.subtype=6,.x=x-80,.y=y-44,.hit_points=2000,
        .layer=3,.frame=1,.scale=1,.width=144,.height=82};
    astro_vector_make(&s.velocity,heading,7);spawn(c,&s);
    double speed=s.velocity.x;
    for(int i=0;i<6;i++) {
        int dx=random_value(c,60),dy=random_value(c,50);
        AstroShot shot={4,0,x+dx-50,y+dy-25};if(c->bullet)c->bullet(c->context,&shot);
    }
    for(int group=0;group<2;group++)for(int i=0;i<(group?10:24);i++) {
        int dx=random_value(c,20),dy=random_value(c,50);
        AstroSpecialSpawn p={.kind=4,.subtype=2,.x=x+dx-40,.y=y+dy-30,.frame=1,.scale=1};
        int angle=random_value(c,360),r=random_value(c,20);
        astro_vector_make(&p.velocity,angle,(10.0+r)*.1);
        if(!group){p.velocity.x+=speed;p.velocity.y=0;}
        p.frame=random_value(c,3);p.action_offset=random_value(c,60)-30;
        p.scale=(5.0+random_value(c,8))/10.0;spawn(c,&p);
    }
}
int astro_special_start(AstroSpecial *s,int weapon,int x,int y,int heading,uint32_t tick,AstroSpecialContext *c) {
    if(!s||s->active||!valid(c))return 0;
    if(!((weapon>=10&&weapon<=13)||(weapon>=30&&weapon<=33)||
         (weapon>=40&&weapon<=43)||(weapon>=50&&weapon<=53)))return 0;
    *s=(AstroSpecial){.weapon=weapon,.started=tick,.last_tick=tick-1,.last_render_tick=tick-1,.action_until=tick+(uint32_t)c->frame_interval+59};
    if(weapon<20){sound(c,299,x);burst(c,x,y);}
    else if(weapon<40){sound(c,299,x);plasma_projectile(c,x,y,heading);}
    else {s->active=1;if(weapon<50)sound(c,296,x);}
    return 1;
}
static void storm(AstroSpecial *s,AstroSpecialContext *c,int render) {
    int hits=0;
    for(int i=0;i<8;i++) {
        int x=c->gun_x-210+random_value(c,400),y=c->gun_y-199+random_value(c,400);
        int target=nearest(c,x,y,90000,-1);
        if(target<0)continue;
        AstroTarget *t=c->targets+target;
        int ex=center(t,0),ey=center(t,1);
        sound(c,295,ex);hits++;
        beam(c,s->weapon,0,c->gun_x,c->gun_y,x,y,-1,0);
        beam(c,s->weapon,(s->weapon-49)*4,x,y,ex,ey,target,0);
        if(s->weapon>50&&!t->remove) {
            int second=nearest(c,ex,ey,6400,target);
            if(second>=0){AstroTarget *u=c->targets+second;
                beam(c,s->weapon-1,s->weapon-49,ex,ey,center(u,0),center(u,1),second,0);}
        }
    }
    if(render)for(int i=0;i<hits;i++) {
        double size=30+random_value(c,70);
        int dx=random_value(c,60),dy=random_value(c,60);
        sprite(c,115,c->gun_x-40+dx-size/2,c->gun_y-29+dy-size/2,size);
    }
}
static int point(AstroSpecialContext *c,int x,int y) {
    int result=-1;
    for(size_t i=0;i<c->target_count;i++) {
        AstroTarget *t=c->targets+i;
        if(t->kind==2||t->kind==999||t->kind==4)continue;
        AstroRect r=astro_target_rect(t);
        if(x>=r.left&&x<r.right&&y>=r.top&&y<r.bottom)result=(int)i;
    }
    if(result>=0&&(c->targets[result].kind==40||c->targets[result].kind==-1||result==c->source_parent))return -1;
    return result;
}
static void plasma_ray(AstroSpecialContext *c,int render) {
    int x=c->gun_x-15,y=c->gun_y+1,target=-1;double ex=x,ey=y;
    while(ex<c->right&&ex>c->left&&ey<c->bottom&&ey>c->top&&target<0) {
        ex+=5;
        for(int offset=1;offset<20&&target<0;offset+=4)target=point(c,(int16_t)(int)ex,(int16_t)(int)(ey+offset));
    }
    beam(c,40,200,x,y,(int)ex,(int)ey,target,1);
    if(!render)return;
    for(int sign=1;sign>=-1;sign-=2) {
        AstroSpecialVertex v[]={
            {x,y+sign*45,1,0,0,0},{x+15,y+sign*85,1,0,0,0},
            {x+40,y+sign*40,1,0,0,0},{ex,y+sign*40,1,0,0,0},
            {ex,y,1,0,0,.8},{x+15,y,1,.4,.4,.8},{x,y,1,0,0,0}};
        if(c->polygon)c->polygon(c->context,v,7);
    }
    double size=50+random_value(c,120);sprite(c,88,x-size/2,y-size/2,size);
    for(int i=0;i<4;i++) {
        size=50+random_value(c,50);int dx=random_value(c,40),dy=random_value(c,30);
        sprite(c,90,ex+dx-size/2,ey-15+dy-size/2,size);
    }
}
static int apply_tick(AstroSpecial *s,uint32_t tick,AstroSpecialContext *c) {
    s->action_until=tick+(uint32_t)c->frame_interval+59;
    if(tick==s->last_tick)return 0;
    s->last_tick=tick;
    int render=tick-s->last_render_tick>=(uint32_t)c->frame_interval;
    if(render)s->last_render_tick=tick;
    if(s->weapon>=50)storm(s,c,render);else plasma_ray(c,render);
    return 1;
}
int astro_special_step(AstroSpecial *s,uint32_t tick,AstroSpecialContext *c) {
    if(!s||!s->active||!valid(c))return 0;
    if(tick-s->started>=31){s->active=0;return 0;}
    apply_tick(s,tick,c);return 1;
}
int astro_special_start_nested(AstroSpecial *s,int weapon,int x,int y,int heading,
                               uint32_t tick,AstroSpecialContext *c) {
    if(!astro_special_start(s,weapon,x,y,heading,tick,c))return 0;
    if(s->active){s->started=tick+1;s->last_tick=tick;}
    return 1;
}
int astro_special_step_nested(AstroSpecial *s,uint32_t tick,AstroSpecialContext *c) {
    if(!s||!s->active||!valid(c))return 0;
    if((int32_t)(tick-s->started)<0||tick==s->last_tick)return ASTRO_SPECIAL_WAIT;
    apply_tick(s,tick,c);
    if(tick-s->started>=30){s->active=0;return ASTRO_SPECIAL_EFFECT|ASTRO_SPECIAL_RESUME;}
    return ASTRO_SPECIAL_EFFECT;
}
