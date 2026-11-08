#ifndef ASTROSQUID_CHEATS_H
#define ASTROSQUID_CHEATS_H
#include "combat.h"
typedef struct { unsigned matched; int weapons; } AstroCheats;
/* Returns one only when a weapon-selection key is consumed. */
static int astro_cheat_key(AstroCheats *state, unsigned ch, AstroInventory *inventory) {
    static const char word[]="weapons";
    static const int families[]={10,30,40,50};
    if(ch>='A'&&ch<='Z')ch+='a'-'A';
    if(state->weapons&&ch>='1'&&ch<='4') {
        inventory->weapon=families[ch-'1'];inventory->upgrade=3;inventory->specials=4;
        state->matched=0;return 1;
    }
    state->matched=ch==(unsigned)word[state->matched]?state->matched+1:(ch=='w'?1:0);
    if(state->matched==sizeof(word)-1){state->weapons=1;state->matched=0;}
    return 0;
}
#endif
