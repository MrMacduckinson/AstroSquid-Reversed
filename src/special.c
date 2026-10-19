#include "special.h"
#include <math.h>
#include "ppc_math.h"
#include <string.h>

static void sound(AstroSpecialContext *c,int id,double x) {if(c->sound)c->sound(c->context,id,x);}
static void spawn(AstroSpecialContext *c,const AstroSpecialSpawn *s) {if(c->spawn)c->spawn(c->context,s);}
static void sprite(AstroSpecialContext *c,int id,double x,double y,double size) {
    if(c->sprite)c->sprite(c->context,id,x,y,size,size);
}
static int random_value(AstroSpecialContext *c,int n) {return astro_random(c->seed,n);}
static int valid(const AstroSpecialContext *c) {
    return c&&c->seed&&(!c->target_count||c->targets)&&c->left<c->right&&c->top<c->bottom;
}
static double center_value(const AstroTarget *t,int y) {
    AstroRect r=astro_target_rect(t);
    return (y?t->y:t->x)+(y?r.bottom-r.top:r.right-r.left)/2.0;
}
static int center(const AstroTarget *t,int y) {return astro_ppc_i32(center_value(t,y));}
static int nearest(AstroSpecialContext *c,int x,int y,int distance,int excluded) {
    int found=-1;
    for(size_t i=0;i<c->target_count;i++) {
        AstroTarget *t=c->targets+i;
        if(!(t->kind==1||t->kind==5||(t->kind>19&&t->kind<30))||
            (int)i==excluded||(int)i==c->source_parent||t->remove)continue;
        uint32_t dx=(uint32_t)x-(uint32_t)(int32_t)(int16_t)center(t,0),dy=(uint32_t)y-(uint32_t)(int32_t)(int16_t)center(t,1);
        /* Original PPC low-word multiply/add wraps at32bits. */
        int32_t d=(int32_t)(dx*dx+dy*dy);
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
static void set_action(AstroSpecial *s,AstroSpecialContext *c,uint32_t value) {
    s->action_until=value;
    if(c->action_tick)*c->action_tick=value;
}
int astro_special_start(AstroSpecial *s,int weapon,int x,int y,int heading,uint32_t tick,AstroSpecialContext *c) {
    if(!s||s->active||!valid(c))return 0;
    if(!((weapon>=10&&weapon<=13)||(weapon>=30&&weapon<=33)||
         (weapon>=40&&weapon<=43)||(weapon>=50&&weapon<=53)))return 0;
    *s=(AstroSpecial){.weapon=weapon,.started=tick,.last_tick=tick-1,.last_render_tick=tick-1};
    set_action(s,c,tick+(uint32_t)c->frame_interval+59);
    if(weapon<20){sound(c,299,x);burst(c,x,y);}
    else if(weapon<40){sound(c,299,x);plasma_projectile(c,x,y,heading);}
    else {s->active=1;if(weapon<50)sound(c,296,x);}
    return 1;
}
static int storm_cpu(AstroSpecial *s,AstroSpecialContext *c) {
    int hits=0;
    for(int i=0;i<8;i++) {
        int x=c->gun_x-210+random_value(c,400),y=c->gun_y-199+random_value(c,400);
        int target=nearest(c,x,y,90000,-1);
        if(target<0)continue;
        AstroTarget *t=c->targets+target;
        int ex=center(t,0),ey=center(t,1);
        sound(c,295,center_value(t,0));hits++;
        beam(c,s->weapon,0,c->gun_x,c->gun_y,x,y,-1,0);
        beam(c,s->weapon,(s->weapon-49)*4,x,y,ex,ey,target,0);
        if(s->weapon>50&&!t->remove) {
            int second=nearest(c,ex,ey,6400,target);
            if(second>=0){AstroTarget *u=c->targets+second;
                beam(c,s->weapon-1,s->weapon-49,ex,ey,center(u,0),center(u,1),second,0);}
        }
    }
    return hits;
}
static void storm_render(AstroSpecialContext *c,int hits) {
    for(int i=0;i<hits;i++) {
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
typedef struct {int x,y;double ex,ey;} SpecialRay;
static SpecialRay plasma_ray_cpu(AstroSpecialContext *c) {
    int x=c->gun_x-15,y=c->gun_y+1,target=-1;double ex=x,ey=y;
    while(ex<c->right&&ex>c->left&&ey<c->bottom&&ey>c->top&&target<0) {
        ex+=5;
        for(int offset=1;offset<20&&target<0;offset+=4)target=point(c,(int16_t)astro_ppc_i32(ex),(int16_t)astro_ppc_i32(ey+offset));
    }
    beam(c,40,200,x,y,astro_ppc_i32(ex),astro_ppc_i32(ey),target,1);
    return (SpecialRay){x,y,ex,ey};
}
static void plasma_ray_render(AstroSpecialContext *c,SpecialRay ray) {
    int x=ray.x,y=ray.y;double ex=ray.ex,ey=ray.ey;
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
typedef struct {int hits;SpecialRay ray;} SpecialFrame;
static SpecialFrame special_cpu(AstroSpecial *s,AstroSpecialContext *c) {
    SpecialFrame frame={0};
    if(s->weapon>=50)frame.hits=storm_cpu(s,c);else frame.ray=plasma_ray_cpu(c);
    return frame;
}
static void special_render(AstroSpecial *s,AstroSpecialContext *c,SpecialFrame frame,uint32_t tick) {
    uint32_t *render_tick=c->render_tick?c->render_tick:&s->last_render_tick;
    *render_tick=tick;s->last_render_tick=tick;
    if(c->render_world)c->render_world(c->context);
    if(s->weapon>=50)storm_render(c,frame.hits);else plasma_ray_render(c,frame.ray);
    if(c->present)c->present(c->context);
}
static int apply_tick(AstroSpecial *s,uint32_t tick,AstroSpecialContext *c) {
    set_action(s,c,tick+(uint32_t)c->frame_interval+59);
    if(tick==s->last_tick)return 0;
    s->last_tick=tick;
    SpecialFrame frame=special_cpu(s,c);
    uint32_t *render_tick=c->render_tick?c->render_tick:&s->last_render_tick;
    if((int32_t)(tick-*render_tick)>=c->frame_interval) {
        special_render(s,c,frame,tick);
    }
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
    /* Scalar replay API; production uses the clocked run_nested driver. */
    if(!s||!s->active||!valid(c))return 0;
    if((int32_t)(tick-s->started)<0||tick==s->last_tick)return ASTRO_SPECIAL_WAIT;
    apply_tick(s,tick,c);
    if(tick-s->started>=30){s->active=0;return ASTRO_SPECIAL_EFFECT|ASTRO_SPECIAL_RESUME;}
    return ASTRO_SPECIAL_EFFECT;
}
int astro_special_run_nested(AstroSpecial *s,AstroSpecialContext *c,const AstroSpecialLoop *loop) {
    if(!s||!s->active||!valid(c)||!c->render_tick||!loop||!loop->cpu_tick||
       !loop->read_tick||!loop->prepare||!loop->calculate||!loop->animate||!loop->read_keys)return 0;
    s->started=loop->read_tick(c->context);
    do {
        loop->prepare(c->context,c);
        set_action(s,c,loop->read_tick(c->context)+(uint32_t)c->frame_interval+59);
        uint32_t comparison=loop->read_tick(c->context);
        if((int32_t)(comparison-*loop->cpu_tick)>0){
            *loop->cpu_tick=loop->read_tick(c->context);s->last_tick=*loop->cpu_tick;
            loop->calculate(c->context,c);
            SpecialFrame frame=special_cpu(s,c);
            comparison=loop->read_tick(c->context);
            if((int32_t)(comparison-*c->render_tick)>=c->frame_interval)
                special_render(s,c,frame,loop->read_tick(c->context));
            loop->animate(c->context);loop->read_keys(c->context);
        }
    }while((int32_t)(loop->read_tick(c->context)-s->started)<31);
    s->active=0;return 1;
}
