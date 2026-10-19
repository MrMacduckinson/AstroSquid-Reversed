#include "../src/script.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
typedef struct {uint32_t ticks[8];unsigned count,used,fired;AstroScriptState *state;} Clock;
static uint32_t read_tick(void *opaque){Clock *c=opaque;assert(c->used<c->count);return c->ticks[c->used++];}
static void fire(void *opaque,int weapon,int x,int y,int heading){
    Clock *c=opaque;assert(weapon==10&&x==5&&y==7&&heading==45&&c->used==4);
    assert(c->state->update_tick==105&&c->state->action_tick==127);
    assert(read_tick(c)==130);c->fired++;
}
static AstroScriptState initial(void){return (AstroScriptState){.frame=1,.tilt=1,.state=1,.update_tick=100,.action_tick=100,.animation_tick=100};}
int main(void){
    unsigned checked=0;
    AstroInstruction op={.delay=7,.opcode=ASTRO_FIRE,.direction_kind=ASTRO_NUMBER,.direction=45,.value_kind=ASTRO_ANY};
    AstroScriptState s=initial();Clock clock={{101,105,110,120,130,140,150},7,0,0,&s};
    AstroScriptContext context={.animated=1,.weapon=10,.gun_x=5,.gun_y=7,.userdata=&clock,.fire=fire};
    assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));
    assert(clock.used==7&&clock.fired==1&&s.line==1&&s.animation_tick==150&&s.frame==2&&s.tilt==2);checked++;
    s=initial();clock=(Clock){{100},1,0,0,&s};context.userdata=&clock;
    assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));assert(clock.used==1&&s.update_tick==100&&s.line==0);checked++;
    s=initial();clock=(Clock){{101,102,100,106},4,0,0,&s};context.userdata=&clock;
    assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));assert(clock.used==4&&s.update_tick==102&&s.line==0&&s.animation_tick==100);checked++;
    AstroInstruction returning[2]={{.opcode=ASTRO_RETURN},{.opcode=ASTRO_STOP}};
    s=initial();clock=(Clock){{101,105,108,109},4,0,0,&s};
    assert(astro_script_step_clocked(&s,returning,2,read_tick,&clock,&context));assert(clock.used==4&&s.line==1&&s.action_tick==100&&s.animation_tick==109);checked++;
    for(int animated=0;animated<=1;animated++){
        s=initial();if(animated)s.state=4;
        clock=(Clock){{101,102,100},3,0,0,&s};context.animated=animated;
        assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));assert(clock.used==3&&s.animation_tick==100);checked++;
    }
    op.opcode=ASTRO_STOP;context.animated=0;context.fire=NULL;
    s=initial();s.action_tick=0x80000000;clock=(Clock){{101,102,100,120},4,0,0,&s};
    assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));assert(clock.used==4&&s.line==1&&s.action_tick==127);checked++;
    s=initial();clock=(Clock){{101,102,0x80000000},3,0,0,&s};
    assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));assert(clock.used==3&&s.line==0&&s.action_tick==100);checked++;
    s=initial();s.update_tick=UINT32_MAX;clock=(Clock){{0,1,100},3,0,0,&s};
    assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));assert(clock.used==3&&s.update_tick==1);checked++;
    s=initial();clock=(Clock){{0x80000064},1,0,0,&s};
    assert(astro_script_step_clocked(&s,&op,1,read_tick,&clock,&context));assert(clock.used==1&&s.update_tick==100);checked++;
    assert(checked==10);puts("PASS10 SOURCE-DERIVED script clocks: fresh stores, callback ordering, RETURN, inactive animation, signed absolute action and wrapped update gates");return 0;
}
