#include "../src/combat.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
int main(int argc,char **argv) {
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);
    int n,hp,shp,removed,sremoved;double px,py,sx,sy;unsigned checked=0;
    while(fscanf(f,"%d,%d,%d,%d,%d,%lf,%lf,%lf,%lf",&n,&hp,&shp,&removed,&sremoved,&px,&py,&sx,&sy)==9) {
        AstroCombatState p={.hit_points=n%201,.velocity={1,2}};
        AstroCombatState s={.hit_points=n%77,.remove=n%17==0?1:0,.velocity={3,4}};
        AstroRect a={n%11,n%13,71+n%11,20+n%13};
        AstroRect b={10+n%27,5+n%17,12+n%27+n%60,7+n%17+n%45};
        astro_player_hits_scenery(&p,a,&s,b);
        assert(p.hit_points==hp&&s.hit_points==shp&&p.remove==removed&&s.remove==sremoved);
        assert(fabs(p.velocity.x-px)<1e-10&&fabs(p.velocity.y-py)<1e-10&&
            fabs(s.velocity.x-sx)<1e-10&&fabs(s.velocity.y-sy)<1e-10);checked++;
    }
    assert(feof(f));fclose(f);assert(checked==200);
    printf("PASS: %u original G5 scenery captures, health and collision impulse\n",checked);return 0;
}
