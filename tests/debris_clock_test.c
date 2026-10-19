/* Original kind4 and CALC kind20 finite clock scripts, including shared field
 * visibility BEFORE each native TickCount and raw final velocity/state. */
#include "../src/debris.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef struct {FILE*f;AstroDebris*s;unsigned reads,limit;int role;} Probe;
static uint64_t word(double v){uint64_t u;memcpy(&u,&v,8);return u;}
static double value(unsigned long long x){uint64_t u=x;double d;memcpy(&d,&u,8);return d;}
static uint32_t read_tick(void*p){Probe*q=p;assert(q->reads<q->limit);char line[256];unsigned index,site,tick,update,animation;int remove;assert(fgets(line,sizeof(line),q->f));assert(sscanf(line,"T,%u,%x,%u,%u,%u,%d",&index,&site,&tick,&update,&animation,&remove)==6);assert(index==q->reads++&&update==q->s->update_tick&&animation==q->s->animation_tick&&remove==q->s->remove);
 static const unsigned sites[]={0x100636f4,0x10063738,0x1006377c,0x100637c0,0x10063864};assert(q->role<5);unsigned expected=q->s->kind==20?(q->role==2?0x100555b4:0x100555f8):sites[q->role];assert(site==expected);
 switch(q->role){case 0:q->role=(int32_t)(tick-q->s->animation_tick)>6?1:2;break;case 1:q->role=2;break;case 2:q->role=(int32_t)(tick-q->s->update_tick)>0?3:q->s->kind==20?5:4;break;case 3:q->role=q->s->kind==20?5:4;break;case 4:q->role=5;break;}
 return tick;
}
/* Source-derived boundary checks, explicitly NOT native fixture evidence.
 * Use when the completed remote oracle CSV cannot be exported. */
typedef struct {AstroDebris*s;const uint32_t*values,*updates,*animations;unsigned count,used;} SourceProbe;
static uint32_t source_tick(void*p){SourceProbe*q=p;assert(q->used<q->count);unsigned i=q->used++;assert(q->s->update_tick==q->updates[i]&&q->s->animation_tick==q->animations[i]);return q->values[i];}
static void source_cases(void){
 const uint32_t both[]={107,200,101,202,146},updates[]={100,100,100,100,202},animations[]={100,100,200,200,200};
 AstroDebris s={.kind=4,.state=1,.frame=2,.update_tick=100,.animation_tick=100,.action_tick=100,.velocity={1,0}};
 SourceProbe p={&s,both,updates,animations,5,0};astro_debris_step_clocked(&s,101,100,0,source_tick,&p);assert(p.used==5&&s.update_tick==202&&s.animation_tick==200&&s.action_tick==100&&s.remove==1&&s.frame==2&&word(s.velocity.x)==word(0x1.f5c28ep-1)&&word(s.velocity.y)==word(0));
 s=(AstroDebris){.kind=4,.state=2,.update_tick=100,.animation_tick=100,.action_tick=100,.velocity={1,0}};p=(SourceProbe){&s,NULL,NULL,NULL,0,0};astro_debris_step_clocked(&s,99,100,0,source_tick,&p);assert(!p.used&&!s.remove&&s.update_tick==100&&s.animation_tick==100&&s.velocity.x==1);
 const uint32_t drift[]={101,205},same[]={100,100};s.kind=20;p=(SourceProbe){&s,drift,same,same,2,0};astro_debris_step_clocked(&s,101,100,.3,source_tick,&p);assert(p.used==2&&s.update_tick==205&&s.animation_tick==100&&word(s.velocity.x)==word(0x1.f5c28ep-1)&&word(s.velocity.y)==word(0));
 const uint32_t closed[]={106,100,145},unchanged[]={100,100,100};s=(AstroDebris){.kind=4,.state=1,.update_tick=100,.animation_tick=100,.action_tick=100,.velocity={1,0}};p=(SourceProbe){&s,closed,unchanged,unchanged,3,0};astro_debris_step_clocked(&s,99,100,0,source_tick,&p);assert(p.used==3&&s.remove==1&&s.update_tick==100&&s.animation_tick==100&&s.velocity.x==1);
 const uint32_t flat[]={100};s.kind=20;s.remove=0;p=(SourceProbe){&s,flat,unchanged,unchanged,1,0};astro_debris_step_clocked(&s,101,100,0,source_tick,&p);assert(p.used==1&&!s.remove&&s.update_tick==100&&s.velocity.x==1);
 puts("PASS:5 SOURCE-DERIVED debris clock cases,11 reads; not native fixture evidence");
}
int main(int argc,char**argv){if(argc==1||(argc==2&&!strcmp(argv[1],"--synthetic"))){source_cases();return 0;}assert(argc==2);FILE*f=fopen(argv[1],"r");assert(f);char line[512];unsigned cases=0,reads=0;
 while(fgets(line,sizeof(line),f)){
  int id,right;AstroDebris s;unsigned long long vx,vy,left_bits,gravity_bits;unsigned limit;
  assert(sscanf(line,"CASE,%d,%d,%d,%d,%d,%u,%u,%u,%llx,%llx,%d,%llx,%llx,%u",&id,&s.kind,&s.state,&s.frame,&s.remove,&s.update_tick,&s.animation_tick,&s.action_tick,&vx,&vy,&right,&left_bits,&gravity_bits,&limit)==14);assert(id==(int)cases);s.velocity=(AstroVelocity){value(vx),value(vy)};Probe q={f,&s,0,limit,s.kind==20?2:0};
  astro_debris_step_clocked(&s,right,value(left_bits),value(gravity_bits),read_tick,&q);assert(q.reads==limit);if(limit)assert(q.role==5);
  AstroDebris expected;unsigned long long ex,ey;assert(fgets(line,sizeof(line),f));assert(sscanf(line,"O,%d,%d,%d,%d,%u,%u,%u,%llx,%llx",&expected.kind,&expected.state,&expected.frame,&expected.remove,&expected.update_tick,&expected.animation_tick,&expected.action_tick,&ex,&ey)==9);
  assert(s.kind==expected.kind&&s.state==expected.state&&s.frame==expected.frame&&s.remove==expected.remove&&s.update_tick==expected.update_tick&&s.animation_tick==expected.animation_tick&&s.action_tick==expected.action_tick&&word(s.velocity.x)==ex&&word(s.velocity.y)==ey);reads+=q.reads;cases++;
 }
 assert(feof(f));fclose(f);assert(cases==12&&reads==32);printf("PASS:%u original debris clock scripts,%u exact clockroles/timer visibility/rawIEEE states, kind4 +kind20\n",cases,reads);return 0;}
