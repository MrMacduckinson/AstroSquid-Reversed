#include "../src/special.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
static FILE *trace;
static uint32_t now;
static int positions[3]={100,100,100},effects;
static void event(char code,int actor) {
    char line[128],expected[128];assert(fgets(line,sizeof(line),trace));
    snprintf(expected,sizeof(expected),"%c,%d,%u\n",code,actor,now);
    if(strcmp(line,expected)){fprintf(stderr,"native %s port %s",line,expected);assert(0);}
}
static void actor(int id){positions[id-1]+=id;event('A',id);}
static void beam(void *unused,const AstroBeam *b,int temporary){(void)unused;assert(temporary&&b->weapon==40&&b->damage==200);effects++;event('E',0);}
int main(int argc,char **argv) {
    trace=fopen(argc>1?argv[1]:"tests/nested_special_trace.csv","r");assert(trace);
    uint32_t seed=0;AstroSpecial s={0};
    AstroSpecialContext c={.seed=&seed,.source_parent=-1,.gun_x=102,.gun_y=100,
        .frame_interval=1,.left=0,.top=0,.right=640,.bottom=380,.beam=beam};
    now=100;actor(1);actor(2);event('S',0);
    assert(astro_special_start_nested(&s,40,174,112,0,now,&c));
    assert(s.active&&s.started==101&&s.action_until==160);
    assert(astro_special_step_nested(&s,now,&c)==ASTRO_SPECIAL_WAIT);
    int player_kind=-1;
    for(now=101;now<=131;now++) {
        actor(1);actor(2);actor(3);
        int flags=astro_special_step_nested(&s,now,&c);
        assert(flags&ASTRO_SPECIAL_EFFECT);
        uint32_t saved=seed;
        if(flags&ASTRO_SPECIAL_RESUME){player_kind=1;event('R',0);actor(3);break;}
        assert(astro_special_step_nested(&s,now,&c)==ASTRO_SPECIAL_WAIT&&seed==saved);
    }
    char line[128];int x,y,z,kind;unsigned tick,expected_seed;
    assert(fgets(line,sizeof(line),trace));assert(sscanf(line,"F,%d,%d,%d,%u,%d,%u",&x,&y,&z,&tick,&kind,&expected_seed)==6);
    assert(!fgets(line,sizeof(line),trace));fclose(trace);
    assert(now==tick&&kind==player_kind&&positions[0]==x&&positions[1]==y&&positions[2]==z&&seed==expected_seed);
    assert(effects==31&&!s.active&&s.action_until==191);
    assert(astro_special_step_nested(&s,132,&c)==0);
    c.beam=NULL;s=(AstroSpecial){0};
    assert(astro_special_start_nested(&s,13,100,100,0,200,&c)&&!s.active);
    assert(astro_special_step_nested(&s,201,&c)==0);
    assert(astro_special_start_nested(&s,40,100,100,0,300,&c));
    assert(astro_special_step_nested(&s,340,&c)==(ASTRO_SPECIAL_EFFECT|ASTRO_SPECIAL_RESUME));
    assert(!s.active&&s.action_until==400);
    assert(astro_special_start_nested(&s,50,100,100,0,UINT32_MAX,&c));
    assert(astro_special_step_nested(&s,UINT32_MAX,&c)==ASTRO_SPECIAL_WAIT);
    assert(astro_special_step_nested(&s,0,&c)==ASTRO_SPECIAL_EFFECT);
    assert(astro_special_step_nested(&s,30,&c)==(ASTRO_SPECIAL_EFFECT|ASTRO_SPECIAL_RESUME));
    puts("PASS native nested-special actor trace,31effects at101..131,terminal same-tick resume,clock jump/wrap and instant-family checks");return 0;
}
