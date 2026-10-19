#include "script.h"
#include "ppc_math.h"
#include <stdlib.h>
#include <string.h>

int astro_script_gun_coordinate(int edge,int turret,double size,int original_size) {
    return astro_ppc_i32(turret*(size/original_size)+edge);
}

static int number3(const char *s,int *value) {
    int start=s[0]=='-'?1:0,n=0;
    for(int i=start;i<3;i++) {
        if(s[i]<'0'||s[i]>'9') return 0;
        n=n*10+s[i]-'0';
    }
    *value=start?-n:n;
    return 1;
}

static int operand3(const char *s,AstroOperand *kind,int *value) {
    const char *tokens[]={"***","###","Up ","Dwn","Lft","Rgt","Any"};
    for(int i=0;i<7;i++) if(!memcmp(s,tokens[i],3)) {
        *kind=(AstroOperand)(i+1);*value=0;return 1;
    }
    *kind=ASTRO_NUMBER;
    return number3(s,value);
}

int astro_parse_instruction(const char *text,AstroInstruction *out) {
    if(!text||!out) return 0;
    memset(out,0,sizeof(*out));
    if(!strcmp(text,"RETURN")) { out->opcode=ASTRO_RETURN;return 1; }
    if(strlen(text)!=16||text[3]!='|'||text[8]!='|'||text[12]!='|') return 0;
    if(!number3(text,&out->delay)||out->delay<0) return 0;
    const char *commands[]={"Stop","Move","Near","Fire","Turn"};
    int found=0;
    for(int i=0;i<5;i++) if(!memcmp(text+4,commands[i],4)) {
        out->opcode=(AstroOpcode)i;found=1;break;
    }
    if(!found) return 0;
    return operand3(text+9,&out->direction_kind,&out->direction)&&
           operand3(text+13,&out->value_kind,&out->value);
}

static int frame_heading(int frame,AstroOperand side) {
    switch(side) {
        case ASTRO_UP:return frame*-36+210;
        case ASTRO_DOWN:return frame*-36+390;
        case ASTRO_LEFT:return frame*36+120;
        case ASTRO_RIGHT:return (frame*-36+120)%360;
        case ASTRO_ANY:return frame*45+30;
        default:return 0;
    }
}

static int facing(int heading,AstroOperand side) {
    switch(side) {
        case ASTRO_UP:return heading>0&&heading<180;
        case ASTRO_DOWN:return heading>180&&heading<360;
        case ASTRO_LEFT:return heading>90&&heading<270;
        case ASTRO_RIGHT:return (heading>0&&heading<90)||(heading>270&&heading<360);
        default:return 1;
    }
}

static void animate(AstroScriptState *s,uint32_t tick,const AstroScriptContext *c) {
    if(!c->animated||s->state==4||(int32_t)(tick-s->animation_tick)<=6) return;
    s->animation_tick=tick;
    int destination=s->state==2?1:s->state==3?3:2;
    if(s->tilt<destination) { s->tilt++;s->frame++; }
    else if(s->tilt>destination) { s->tilt--;s->frame--; }
}

int astro_script_step(AstroScriptState *s,const AstroInstruction *script,
                      size_t count,uint32_t tick,const AstroScriptContext *c) {
    if(!s||!script||!c||s->line>=count) return 0;
    if((int32_t)(tick-s->update_tick)<1) return 1;
    s->update_tick=tick;
    const AstroInstruction *op=&script[s->line];
    if(op->opcode==ASTRO_RETURN) {
        // Original RETURN skips the initialization line and resumes line two.
        if(count<2) return 0;
        s->line=1;
        animate(s,tick,c);
        return 1;
    }
    if(s->state!=4) s->state=s->velocity.y<-.2?2:s->velocity.y>.2?3:1;
    if((int32_t)(tick-s->action_tick)>0) {
        s->action_tick=tick+(uint32_t)op->delay;
        int direction=op->direction;
        if(op->direction_kind==ASTRO_AIM&&c->player_present) direction=c->target_heading;
        if(op->direction_kind==ASTRO_FRAME) direction=frame_heading(s->frame,op->value_kind);
        switch(op->opcode) {
            case ASTRO_STOP:
                s->velocity.x=0;s->velocity.y=0;
                break;
            case ASTRO_MOVE:
                astro_vector_make(&s->velocity,direction,op->value/10.0);
                if(c->move_children) c->move_children(c->userdata,direction,op->value/10.0);
                break;
            case ASTRO_NEAR: {
                double dx=s->x-c->player_x+30,dy=s->y-c->player_y+15;
                int32_t distance_squared=astro_ppc_i32(dx*dx+dy*dy);
                if(c->player_present&&distance_squared<(int32_t)((uint32_t)direction*(uint32_t)direction)) {
                    if(op->value_kind==ASTRO_AIM) {
                        if(c->hit_player) c->hit_player(c->userdata);
                        s->remove=-1;
                    } else if(op->value_kind==ASTRO_FRAME) {
                        if(c->fire) c->fire(c->userdata,c->weapon,c->gun_x,c->gun_y,direction);
                    } else {
                        s->frame=op->value;s->state=4;
                    }
                }
                break;
            }
            case ASTRO_FIRE:
                if(facing(direction,op->value_kind)&&c->fire)
                    c->fire(c->userdata,c->weapon,c->gun_x,c->gun_y,direction);
                break;
            case ASTRO_TURN:
                if(op->direction_kind!=ASTRO_AIM) {
                    int frame=s->frame+direction;
                    if(frame>0&&frame<5) s->frame=frame;
                } else {
                    int desired=frame_heading(s->frame,op->value_kind);
                    int difference=desired-direction;
                    int delta=abs(difference)<21?0:difference<0?-1:1;
                    int frame=s->frame+delta;
                    int limit=op->value_kind==ASTRO_ANY?9:6;
                    if(facing(direction,op->value_kind)&&frame>0&&frame<limit) s->frame=frame;
                }
                break;
            default:return 0;
        }
        s->line++;
    }
    animate(s,tick,c);
    return 1;
}
