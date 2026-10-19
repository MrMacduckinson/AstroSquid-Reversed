#include "../src/combat.h"
#include <assert.h>
#include <stdio.h>
int main(int argc,char **argv) {
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);
    int n,hp,removed,weapon,upgrade,specials,lives;unsigned checked=0;
    while(fscanf(f,"%d,%d,%d,%d,%d,%d,%d",&n,&hp,&removed,&weapon,&upgrade,&specials,&lives)==7) {
        int families[]={10,30,40,50};
        AstroInventory inventory={families[(n/10)%4],(n/40)%4,(n/160)%5,n%7};
        AstroCombatState player={.hit_points=n%201};int consumed=n%17==0?-1:0;
        astro_pickup(&player,n%10,n%101,&consumed,&inventory);
        assert(player.hit_points==hp&&consumed==removed&&inventory.weapon==weapon&&
            inventory.upgrade==upgrade&&inventory.specials==specials&&inventory.lives==lives);
        checked++;
    }
    assert(feof(f));fclose(f);assert(checked==1000);
    printf("PASS: %u original G5 pickup captures, health/weapons/upgrades/specials/lives\n",checked);
    return 0;
}
