#ifndef ASTROSQUID_CHEATS_H
#define ASTROSQUID_CHEATS_H
#include "combat.h"
typedef struct { unsigned matched; int weapons; } AstroCheats;
/* Mac virtual key positions are independent of layout, Shift and Caps Lock. */
static unsigned astro_cheat_character(unsigned key) {
    switch(key) {
        case 13:return 'w';case 14:return 'e';case 0:return 'a';case 35:return 'p';
        case 31:return 'o';case 45:return 'n';case 1:return 's';
        case 18:return '1';case 19:return '2';case 20:return '3';case 21:return '4';
        default:return 0;
    }
}
/* 0: ordinary input, 1: weapon selected, 2: cheat activated. */
static int astro_cheat_key(AstroCheats *state, unsigned ch, AstroInventory *inventory) {
    static const char word[]="weapons";
    static const int families[]={10,30,40,50};
    if(ch>='A'&&ch<='Z')ch+='a'-'A';
    if(state->weapons&&ch>='1'&&ch<='4') {
        inventory->weapon=families[ch-'1'];inventory->upgrade=3;inventory->specials=4;
        state->matched=0;return 1;
    }
    state->matched=ch==(unsigned)word[state->matched]?state->matched+1:(ch=='w'?1:0);
    if(state->matched==sizeof(word)-1){state->weapons=1;state->matched=0;return 2;}
    return 0;
}
#endif
