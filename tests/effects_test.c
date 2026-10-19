#include "../src/effects.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static AstroDeathEffect effects[4096];static unsigned count,sounds;
static void capture(void *unused,const AstroDeathEffect *e) {
    (void)unused;if(e->type==ASTRO_EFFECT_SOUND) {sounds++;return;}
    assert(count<4096);effects[count++]=*e;
}
static int values(char *line,double *out) {
    char *p=strtok(line,",");int n=0;assert(p);
    while((p=strtok(NULL,","))) {assert(n<32);out[n++]=strtod(p,NULL);}return n;
}
int main(int argc,char **argv) {
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);
    char line[2048];unsigned cases=0;
    while(fgets(line,sizeof(line),f)) {
        assert(line[0]=='C');double v[32];assert(values(line,v)==25);
        AstroDeathSource s={.kind=v[0],.tag=v[1],.left=v[2],.top=v[3],.right=v[4],.bottom=v[5],
            .width=v[6],.height=v[7],.original_height=v[8],.velocity={v[9],v[10]},
            .explosion_sprite=v[11],.explosion_width=v[12],.explosion_height=v[13],.explosion_delay=v[14],
            .debris_attribute=v[15],.debris_sprite=v[16],.debris_width=v[17],.debris_height=v[18],.debris_count=v[19]};
        uint32_t seed=(uint32_t)v[20],tick=(uint32_t)v[21],expected_seed=(uint32_t)v[22];
        unsigned expected=v[23],expected_sounds=v[24];count=sounds=0;
        assert(astro_death_effects(&s,tick,&seed,capture,NULL));
        assert(count==expected&&seed==expected_seed&&sounds==expected_sounds);
        for(unsigned i=0;i<count;i++) {
            assert(fgets(line,sizeof(line),f)&&line[0]=='E'&&values(line,v)==13);
            AstroDeathEffect *e=&effects[i];
            assert(e->type==v[0]&&e->kind==v[1]&&e->attribute==v[2]&&e->frame==v[4]);
            assert(fabs(e->x-v[5])<1e-9&&fabs(e->y-v[6])<1e-9);
            if(e->type!=ASTRO_EFFECT_PICKUP) assert(e->sprite==v[3]&&fabs(e->width-v[7])<1e-9&&fabs(e->height-v[8])<1e-9);
            if(e->type==ASTRO_EFFECT_DEBRIS) assert(fabs(e->velocity.x-v[9])<1e-9&&fabs(e->velocity.y-v[10])<1e-9&&e->action_tick==(uint32_t)v[12]);
            if(e->type==ASTRO_EFFECT_EXPLOSION) assert(e->animation_tick==(uint32_t)v[11]);
        }
        cases++;
    }
    assert(feof(f)&&cases==15);fclose(f);
    printf("PASS: %u original G5 death traces, %u final-trace effects and exact RNG\n",cases,count);return 0;
}
