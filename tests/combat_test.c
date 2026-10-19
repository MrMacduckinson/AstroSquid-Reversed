#include "../src/combat.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>

int main(int argc,char **argv) {
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);
    int player,n,kind,layer,bhp,ehp,value,want_bhp,want_ehp,want_score,effects,br,er;
    double vx,vy;unsigned checked=0;
    while(fscanf(f,"%d,%d,%d,%d,%d,%d,%d,%d,%d,%lf,%lf,%d,%d,%d,%d",
        &player,&n,&kind,&layer,&bhp,&ehp,&value,&want_bhp,&want_ehp,
        &vx,&vy,&want_score,&effects,&br,&er)==15) {
        AstroCombatState b={.kind=kind,.layer=layer,.hit_points=bhp,
            .remove=n%13==0?-1:0,.velocity={n/10.0,-n/20.0}};
        AstroCombatState e={.hit_points=ehp,.velocity={2,3}};
        int score=1000,actual_effects=0;
        if(player) astro_bullet_hits_player(&b,&e);
        else actual_effects=astro_bullet_hits_enemy(&b,&e,value,&score);
        assert(b.hit_points==want_bhp&&e.hit_points==want_ehp&&b.remove==br&&e.remove==er);
        assert(fabs(e.velocity.x-vx)<1e-10&&fabs(e.velocity.y-vy)<1e-10);
        assert(score==want_score&&effects==actual_effects);checked++;
    }
    assert(feof(f));fclose(f);assert(checked==200);
    printf("PASS: %u original G5 combat captures, health/removal/score/impulse/effects\n",checked);
    return 0;
}
