#include "../src/hit_visual.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    AstroSpriteInfo info[76]={0};for(int i=71;i<=75;i++)info[i]=(AstroSpriteInfo){50,50,i==75?-1:i+1,2};
    AstroPlayerHitVisual effect={0};AstroRect b={100,120,171,140};
    assert(astro_player_hit_visual(&effect,b,info,76,10)==1);
    assert(effect.active&&effect.visual.sprite==71&&effect.visual.x==95&&effect.visual.y==115&&effect.visual.width==81&&effect.visual.height==30&&effect.visual.next_tick==12);
    assert(astro_player_hit_step(&effect,info,76,12)==1&&effect.visual.sprite==71);
    assert(astro_player_hit_step(&effect,info,76,13)==1&&effect.visual.sprite==72);
    assert(astro_player_hit_visual(&effect,b,info,76,14)==2&&effect.visual.sprite==72&&effect.visual.next_tick==16);
    astro_player_hit_follow(&effect,(AstroRect){110,150,181,170});assert(effect.visual.x==105&&effect.visual.y==145);
    for(uint32_t tick=15;tick<=25;tick++)assert(astro_player_hit_step(&effect,info,76,tick)==1);
    assert(effect.visual.sprite==75);assert(astro_player_hit_step(&effect,info,76,26)==0&&!effect.active);
    assert(astro_player_hit_visual(&effect,b,info,76,30)==1&&effect.visual.sprite==71);
    assert(astro_player_scenery_hit_visual(&effect,(AstroRect){200,200,250,250},info,76,31)==2);
    assert(effect.visual.sprite==72&&effect.visual.x==195&&effect.visual.y==195&&effect.visual.width==60&&effect.visual.height==60);
    assert(astro_player_hit_visual(&effect,(AstroRect){200,200,300,300},info,76,32)==2);
    assert(effect.visual.width==60&&effect.visual.height==60);
    assert(astro_player_scenery_hit_visual(&effect,(AstroRect){200,200,300,300},info,76,33)==2);
    assert(effect.visual.width==110&&effect.visual.height==110&&effect.visual.next_tick==35);
    effect.active=0;assert(astro_player_scenery_hit_visual(&effect,b,info,76,40)==1&&effect.visual.sprite==71);
    assert(ASTRO_PLAYER_HIT_LAYER==7&&ASTRO_PLAYER_SCENERY_HIT_LAYER==8);
    puts("PASS: playerhit creation71,repeat72,size,follow,strict animation expiry and recreation");return 0;
}
