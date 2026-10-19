#include "visual.h"
int astro_visual_change(AstroVisual *v,int sprite,const AstroSpriteInfo *info,size_t count,uint32_t tick) {
    if(!v||!info||v->sprite<0||(size_t)v->sprite>=count||sprite<0||(size_t)sprite>=count||
        info[v->sprite].width<=0||info[v->sprite].height<=0||info[sprite].width<=0||info[sprite].height<=0) return 0;
    double width=v->width,height=v->height;
    v->x+=v->width/2;v->y+=v->height/2;
    v->width=width/info[v->sprite].width*info[sprite].width;
    v->height=height/info[v->sprite].height*info[sprite].height;
    v->sprite=sprite;v->next_tick=tick+(uint32_t)info[sprite].delay;
    v->x-=v->width/2;v->y-=v->height/2;
    return 1;
}
int astro_visual_step_clocked(AstroVisual *v,const AstroSpriteInfo *info,size_t count,
                              uint32_t comparison,uint32_t store) {
    if(!v||!info||v->sprite<0||(size_t)v->sprite>=count) return -1;
    int next=info[v->sprite].next_frame;
    if(!next||(int32_t)v->next_tick>=(int32_t)comparison) return 1;
    if(next<0) return 0;
    return astro_visual_change(v,next,info,count,store)?1:-1;
}

int astro_visual_step(AstroVisual *v,const AstroSpriteInfo *info,size_t count,uint32_t tick) {
    return astro_visual_step_clocked(v,info,count,tick,tick);
}
