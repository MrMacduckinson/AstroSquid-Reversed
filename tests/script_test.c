#include "../src/script.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

static int shots;
static void fire(void *unused,int weapon,int x,int y,int angle) {
    (void)unused;(void)x;(void)y;
    assert(weapon==11&&angle==180);shots++;
}

int main(void) {
    assert(astro_script_gun_coordinate(700,33,125,78)==752);
    assert(astro_script_gun_coordinate(200,55,186,123)==283);
    assert(astro_script_gun_coordinate(-700,33,125,78)==-647);
    AstroInstruction p[6],op;
    const char *commands[]={"000|Move|180|012","120|Move|270|010","010|Move|090|010",
        "120|Move|090|010","010|Move|270|010","RETURN"};
    for(int i=0;i<6;i++) assert(astro_parse_instruction(commands[i],&p[i]));
    assert(p[1].delay==120&&p[1].opcode==ASTRO_MOVE&&p[1].direction==270&&p[1].value==10);
    const char *bad[]={"","000|Move|180|012x","000:Move|180|012","00x|Move|180|012",
        "000|Nope|180|012","000|Move|zzz|012","000|Move|180|xyz","-01|Move|180|012"};
    for(unsigned i=0;i<sizeof(bad)/sizeof(bad[0]);i++) assert(!astro_parse_instruction(bad[i],&op));
    assert(!astro_parse_instruction(NULL,&op));
    assert(!astro_parse_instruction("RETURN",NULL));
    AstroScriptState s;memset(&s,0,sizeof(s));
    AstroScriptContext c;memset(&c,0,sizeof(c));
    assert(astro_script_step(&s,p,6,1,&c));
    assert(s.line==1&&fabs(s.velocity.x+1.2)<1e-12&&fabs(s.velocity.y)<1e-12);
    assert(astro_script_step(&s,p,6,2,&c));
    assert(s.line==2&&s.action_tick==122&&fabs(s.velocity.y-1)<1e-12);
    assert(astro_script_step(&s,p,6,122,&c)&&s.line==2);
    assert(astro_script_step(&s,p,6,123,&c)&&s.line==3&&fabs(s.velocity.y)<1e-12);
    assert(astro_script_step(&s,p,6,134,&c)&&s.line==4&&fabs(s.velocity.y+1)<1e-12);
    assert(astro_script_step(&s,p,6,255,&c)&&s.line==5&&fabs(s.velocity.y)<1e-12);
    assert(astro_script_step(&s,p,6,256,&c)&&s.line==1&&s.action_tick==265);
    assert(astro_script_step(&s,p,6,265,&c)&&s.line==1);
    assert(astro_script_step(&s,p,6,266,&c)&&s.line==2&&fabs(s.velocity.y-1)<1e-12);
    assert(astro_parse_instruction("000|Turn|***|Up ",&op));
    memset(&s,0,sizeof(s));s.frame=3;c.player_present=1;c.target_heading=170;
    assert(astro_script_step(&s,&op,1,1,&c)&&s.frame==2);
    assert(astro_parse_instruction("000|Fire|180|Any",&op));
    memset(&s,0,sizeof(s));c.fire=fire;c.weapon=11;
    assert(astro_script_step(&s,&op,1,1,&c)&&shots==1);
    assert(!astro_script_step(&s,&op,1,2,&c));
    puts("PASS: script parser rejects malformed records; scheduling, RETURN, movement, aiming and fire cases pass");
    return 0;
}
