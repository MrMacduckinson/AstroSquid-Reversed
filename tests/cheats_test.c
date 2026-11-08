#include "../src/cheats.h"
#include <assert.h>
#include <stdio.h>
static void type(AstroCheats *c,AstroInventory *i,const char *s){while(*s)astro_cheat_key(c,(unsigned char)*s++,i);}
int main(void){
    AstroCheats c={0};AstroInventory i={10,0,1,7};
    assert(!astro_cheat_key(&c,'4',&i)&&i.weapon==10&&i.upgrade==0);
    type(&c,&i,"weapXons");assert(!c.weapons);
    type(&c,&i,"wwWEAPONS");assert(c.weapons);
    const int family[]={10,30,40,50};
    for(unsigned n=0;n<4;n++){
        assert(astro_cheat_key(&c,'1'+n,&i));
        assert(i.weapon==family[n]&&i.upgrade==3&&i.specials==4&&i.lives==7);
    }
    assert(!astro_cheat_key(&c,'5',&i)&&i.weapon==50);
    for(unsigned n=0;n<65536;n++)astro_cheat_key(&c,n,&i);
    puts("PASS weapons activation, overlap, case, selections, upgrades, specials and unchanged lives");
}
