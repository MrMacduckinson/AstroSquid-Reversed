#include "../src/script.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
typedef struct {FILE *file;AstroScriptState *state;AstroOpcode opcode;unsigned used,limit,role,fired;} Probe;
static unsigned long long bits(double v){unsigned long long u;memcpy(&u,&v,8);return u;}
static void check_state(const AstroScriptState *s,const char *text){
    unsigned line,update,action,animation;int state,frame,tilt,remove;unsigned long long vx,vy;
    assert(sscanf(text,"%u,%u,%u,%u,%d,%d,%d,%d,%llx,%llx",&line,&update,&action,&animation,&state,&frame,&tilt,&remove,&vx,&vy)==10);
    assert(s->line==line&&s->update_tick==update&&s->action_tick==action&&s->animation_tick==animation);
    assert(s->state==state&&s->frame==frame&&s->tilt==tilt&&s->remove==remove&&bits(s->velocity.x)==vx&&bits(s->velocity.y)==vy);
}
static uint32_t clock_read(void *opaque){
    Probe *p=opaque;char line[512];unsigned index,site,tick;int offset=0;
    assert(p->used<p->limit&&fgets(line,sizeof(line),p->file));
    assert(sscanf(line,"T,%u,%x,%u,%n",&index,&site,&tick,&offset)==3&&offset>0&&index==p->used++);
    const unsigned sites[]={0x10061c78,0x10061cbc,0x10061e6c,0x10061ed4,0x10063354,0x10063398,0};
    assert(p->role<7&&site==sites[p->role]);check_state(p->state,line+offset);
    switch(p->role){
        case 0:p->role=(int32_t)(tick-p->state->update_tick)>0?1:7;break;
        case 1:p->role=p->opcode==ASTRO_RETURN?4:2;break;
        case 2:p->role=(int32_t)tick>(int32_t)p->state->action_tick?3:4;break;
        case 3:p->role=p->opcode==ASTRO_FIRE?6:4;break;
        case 4:p->role=(int32_t)(tick-p->state->animation_tick)>6?5:7;break;
        case 5:p->role=7;break;
        case 6:p->role=4;break;
    }
    return tick;
}
static void fire(void *opaque,int weapon,int x,int y,int heading){
    Probe *p=opaque;char line[128];int w,fx,fy,h;
    assert(fgets(line,sizeof(line),p->file)&&sscanf(line,"F,%d,%d,%d,%d",&w,&fx,&fy,&h)==4);
    assert(w==weapon&&fx==x&&fy==y&&h==heading);p->fired++;(void)clock_read(p);
}
int main(int argc,char **argv){
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);char line[512];unsigned cases=0,reads=0,fires=0;
    while(fgets(line,sizeof(line),f)){
        unsigned id,update,action,animation,limit;int animated,state;char text[32];
        assert(sscanf(line,"CASE,%u,%31[^,],%d,%d,%u,%u,%u,%u",&id,text,&animated,&state,&update,&action,&animation,&limit)==8&&id==cases);
        AstroInstruction ops[2];assert(astro_parse_instruction(text,&ops[0]));ops[1]=(AstroInstruction){.opcode=ASTRO_RETURN};
        AstroScriptState s={.update_tick=update,.action_tick=action,.animation_tick=animation,.state=state,.frame=1,.tilt=1,.x=5,.y=7};
        Probe p={f,&s,ops[0].opcode,0,limit,0,0};AstroScriptContext context={.animated=animated,.weapon=10,.gun_x=5,.gun_y=7,.userdata=&p,.fire=fire};
        assert(astro_script_step_clocked(&s,ops,2,clock_read,&p,&context));
        assert(p.used==limit&&(p.role==7||(p.role==4&&(!animated||s.state==4))));
        assert(fgets(line,sizeof(line),f)&&line[0]=='O'&&line[1]==',');check_state(&s,line+2);
        reads+=p.used;fires+=p.fired;cases++;
    }
    assert(feof(f)&&!ferror(f));fclose(f);assert(cases==10&&reads==33&&fires==1);
    puts("PASS10 original script clock cases,33 exact reads/roles/pre-read states and one clock-consuming fire callback");
    return 0;
}
