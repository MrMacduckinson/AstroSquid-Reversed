#include "ieee_exact.h"
#include "../src/debris.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
int main(int argc,char **argv) {
    FILE *f=fopen(argc>1?argv[1]:"tests/debris_vectors.csv","r");assert(f);
    char line[1024];unsigned count=0;
    while(fgets(line,sizeof(line),f)) {
        AstroDebris s,e;uint32_t tick;int right;double left,gravity;
        assert(sscanf(line,"%d,%d,%d,%d,%u,%u,%u,%lf,%lf,%u,%d,%lf,%lf,%d,%d,%d,%d,%u,%u,%u,%lf,%lf",
            &s.kind,&s.state,&s.frame,&s.remove,&s.update_tick,&s.animation_tick,&s.action_tick,&s.velocity.x,&s.velocity.y,
            &tick,&right,&left,&gravity,&e.kind,&e.state,&e.frame,&e.remove,&e.update_tick,&e.animation_tick,&e.action_tick,&e.velocity.x,&e.velocity.y)==22);
        astro_debris_step(&s,tick,right,left,gravity);
        assert(s.kind==e.kind&&s.state==e.state&&s.frame==e.frame&&s.remove==e.remove&&
            s.update_tick==e.update_tick&&s.animation_tick==e.animation_tick&&s.action_tick==e.action_tick);
        assert(ieee_exact(s.velocity.x,e.velocity.x)&&ieee_exact(s.velocity.y,e.velocity.y));
        count++;
    }
    fclose(f);assert(count==450);
    for(int stage=0;stage<11;stage++)assert(astro_debris_gravity(stage)==(stage==6||stage==8?.3:0));
    AstroDebris s={.kind=4,.state=1,.frame=3,.update_tick=0,.animation_tick=0,.action_tick=0};
    astro_debris_step(&s,45,100,100,0);assert(!s.remove&&s.frame==3);
    astro_debris_step(&s,46,100,100,0);assert(s.remove==1);
    s.remove=0;s.action_tick=46;astro_debris_step(&s,46,99,100,0);assert(s.remove==1);
    astro_debris_step(NULL,0,0,0,0);
    printf("PASS: %u original debris/kind20 traces, removal boundaries and campaign gravity\n",count);return 0;
}
