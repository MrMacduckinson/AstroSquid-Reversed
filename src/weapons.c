#include "weapons.h"
#include <stdlib.h>

int astro_random(uint32_t *seed,int bound) {
    *seed=*seed*UINT32_C(1664525)+UINT32_C(1013904223);
    uint32_t product=(uint32_t)bound*(*seed>>16);
    int32_t signed_product=(int32_t)product;
    /* PPC arithmetic shift rounds negative products down. */
    int result=signed_product>=0?signed_product/65536:
        (int)(-((-(int64_t)signed_product+65535)/65536));
    return result+1;
}

int astro_weapon_shots(const AstroWeapon *weapon,int x,int y,int heading,
                       uint32_t *seed,AstroShot out[6]) {
    if(!weapon||!out||weapon->pattern<0||weapon->pattern>12) return -1;
    int random=weapon->pattern>6,count=weapon->pattern-(random?6:0);
    if(random&&!seed) return -1;
    for(int i=0;i<count;i++) {
        out[i]=weapon->shots[i];
        int dx=out[i].x,dy=out[i].y;
        if(random) {
            dx=astro_random(seed,dx);
            dy=astro_random(seed,abs(dy))*(dy<0?-1:dy>0?1:0);
        }
        out[i].x=x+dx;out[i].y=y+dy;out[i].heading+=heading;
    }
    return count;
}
