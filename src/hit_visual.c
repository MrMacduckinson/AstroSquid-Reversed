#include "hit_visual.h"
int astro_player_hit_visual(AstroPlayerHitVisual *effect,AstroRect bounds,
                           const AstroSpriteInfo *sprites,size_t count,uint32_t tick) {
    if(!effect||!sprites||count<=72||sprites[71].width<=0||sprites[71].height<=0||sprites[72].width<=0||sprites[72].height<=0)return 0;
    if(effect->active)return astro_visual_change(&effect->visual,72,sprites,count,tick)?2:0;
    effect->visual=(AstroVisual){71,bounds.left-5,bounds.top-5,
        bounds.right-bounds.left+10,bounds.bottom-bounds.top+10,tick+(uint32_t)sprites[71].delay};
    effect->active=1;return 1;
}
int astro_player_scenery_hit_visual(AstroPlayerHitVisual *effect,AstroRect bounds,
                                   const AstroSpriteInfo *sprites,size_t count,uint32_t tick) {
    int result=astro_player_hit_visual(effect,bounds,sprites,count,tick);
    if(result==2)effect->visual=(AstroVisual){72,bounds.left-5,bounds.top-5,
        bounds.right-bounds.left+10,bounds.bottom-bounds.top+10,tick+(uint32_t)sprites[72].delay};
    return result;
}
void astro_player_hit_follow(AstroPlayerHitVisual *effect,AstroRect bounds) {
    if(effect&&effect->active){effect->visual.x=bounds.left-5;effect->visual.y=bounds.top-5;}
}
int astro_player_hit_step(AstroPlayerHitVisual *effect,const AstroSpriteInfo *sprites,size_t count,uint32_t tick) {
    if(!effect)return -1;if(!effect->active)return 0;
    int alive=astro_visual_step(&effect->visual,sprites,count,tick);
    if(!alive)effect->active=0;return alive;
}
