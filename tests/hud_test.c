#include "../src/hud.h"
#include <assert.h>
#include <stdio.h>
#include <math.h>
int main(int argc,char **argv){
    AstroHUDCommand commands[32];AstroHUDState state={1,200,30,2,3,4,12345};
    assert(astro_hud_commands(&state,commands,32)==21);
    assert(commands[0].height==70&&commands[1].y==450);
    assert(commands[8].a==1&&commands[9].a==1);
    assert(commands[10].sprite==503);
    assert(commands[11].a==.8&&commands[13].a==.8&&commands[14].a==.3);
    assert(commands[17].a==.8&&commands[18].a==.3);
    assert(commands[19].value==4&&commands[20].value==12345);
    state.hit_points=50;astro_hud_commands(&state,commands,32);
    assert(commands[8].a==.5&&commands[9].a==0);
    state.player_present=0;astro_hud_commands(&state,commands,32);
    assert(commands[8].a==0&&commands[9].a==0);
    assert(astro_hud_commands(&state,NULL,0)==21);
    FILE *fixture=fopen(argc>1?argv[1]:"tests/hud_vectors.csv","r");assert(fixture);
    unsigned rows=0,index;int kind,sprite,value;double x,y,w,h,r,g,b,a;
    while(fscanf(fixture,"%d,%d,%d,%d,%d,%d,%d,%u,%d,%d,%d,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf",
          &state.player_present,&state.hit_points,&state.weapon,&state.upgrades,&state.special_ammo,&state.lives,&state.score,
          &index,&kind,&sprite,&value,&x,&y,&w,&h,&r,&g,&b,&a)==19){
        astro_hud_commands(&state,commands,32);AstroHUDCommand c=commands[index];
        assert((int)c.kind==kind&&c.sprite==sprite&&c.value==value);
        if(c.kind==ASTRO_HUD_SCORE)assert(x==487.5&&c.x==517);
        else assert(fabs(c.x-x)<1e-9);
        assert(fabs(c.y-y)<1e-9&&fabs(c.width-w)<1e-9&&fabs(c.height-h)<1e-9);
        assert(fabs(c.r-r)<1e-9&&fabs(c.g-g)<1e-9&&fabs(c.b-b)<1e-9&&fabs(c.a-a)<1e-9);rows++;
    }
    fclose(fixture);assert(rows==168);
    puts("PASS original HUD geometry, two-stage shield, weapon/upgrades/ammo, lives and score");
}
