#include "hud.h"
size_t astro_hud_commands(const AstroHUDState *state,AstroHUDCommand *out,size_t capacity){
    AstroHUDCommand commands[32];size_t count=0;double hp=state->player_present?state->hit_points:0;
#define ADD(K,S,V,X,Y,W,H,R,G,B,A) commands[count++]=(AstroHUDCommand){K,S,V,X,Y,W,H,R,G,B,A}
    ADD(ASTRO_HUD_BOX,0,0,0,0,640,70,0,0,0,1);
    ADD(ASTRO_HUD_BOX,0,0,0,450,640,30,0,0,0,1);
    ADD(ASTRO_HUD_SPRITE,401,0,0,8,255,62,1,1,1,1);
    ADD(ASTRO_HUD_SPRITE,402,0,255,24,121,46,1,1,1,1);
    ADD(ASTRO_HUD_SPRITE,403,0,376,65,264,5,1,1,1,1);
    ADD(ASTRO_HUD_SPRITE,405,0,394,450,246,33,1,1,1,1);
    ADD(ASTRO_HUD_SPRITE,404,0,0,449,394,7,1,1,1,1);
    ADD(ASTRO_HUD_SPRITE,410,0,29,11,108,60,1,1,1,1);
    ADD(ASTRO_HUD_SPRITE,411,0,29,11,108,60,1,1,1,hp>100?1:hp/100);
    ADD(ASTRO_HUD_SPRITE,412,0,31,11,108,60,1,1,1,hp>100?(hp-100)/100:0);
    ADD(ASTRO_HUD_SPRITE,500+state->weapon/10,0,196,36,30,30,1,1,1,1);
    for(int i=1;i<=4;i++){
        ADD(ASTRO_HUD_SPRITE,506,0,226+6*i,39,4,24,1,1,1,i<=state->upgrades+1?.8:.3);
    }
    for(int i=7;i<=10;i++){
        ADD(ASTRO_HUD_SPRITE,506,0,226+6*i,48.6,4,14.4,1,1,1,i-6<=state->special_ammo?.8:.3);
    }
    ADD(ASTRO_HUD_LIVES,0,state->lives,143,61,0,13,12./255,231./255,238./255,1);
    ADD(ASTRO_HUD_SCORE,0,state->score,517,475,0,18,12./255,231./255,238./255,1);
#undef ADD
    for(size_t i=0;i<count&&i<capacity;i++)out[i]=commands[i];
    return count;
}
