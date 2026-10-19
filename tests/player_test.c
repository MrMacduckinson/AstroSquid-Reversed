#include "ieee_exact.h"
#include "../src/player.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
int main(int argc,char **argv) {
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);
    int variant,frame,tilt,state,previous=-1;unsigned tick,animation,update,count=0;
    double vx,vy;AstroPlayer p;
    while(fscanf(f,"%d,%u,%lf,%lf,%d,%d,%d,%u,%u",&variant,&tick,&vx,&vy,&frame,&tilt,&state,&animation,&update)==9) {
        if(variant!=previous) {p=(AstroPlayer){{0,0},12,3,1,0,0};previous=variant;}
        unsigned controls=(variant+tick/25)%16;
        int x=tick%4==0?-20:tick%4==1?620:60,y=tick%4==2?-20:tick%4==3?375:180;
        astro_player_step(&p,tick,controls,1,(AstroRect){x,y,x+71,y+20},71,20,(AstroViewport){0,0,640,380},0);
        assert(ieee_exact(p.velocity.x,vx)&&ieee_exact(p.velocity.y,vy)&&p.frame==frame&&
            p.tilt==tilt&&p.state==state&&p.animation_tick==animation&&p.update_tick==update);count++;
    }
    assert(feof(f));fclose(f);assert(count==800);
    AstroPlayer fractional={{-1,0},12,3,1,0,0};
    astro_player_step(&fractional,1,0,1,(AstroRect){101,100,172,120},71,20,(AstroViewport){110.75,0,750.75,380},0);
    assert(ieee_exact(fractional.velocity.x,0)&&ieee_exact(fractional.velocity.y,0));
    printf("PASS: %u original G5 player animation/control/boundary captures\n",count);return 0;
}
