/* Q fixture rows losslessly repeat a three-site TickCount pattern; the test
 * expands and verifies every read (no digest/sampling).
 * Replay every original TickCount read and observable phase, with independent
 * compare/store values and an explicitly clock-consuming CALC test double.
 * Native actor internals/OS clock scheduling are outside this bounded fixture. */
#include "../src/special.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct {FILE*f;char row[512];uint32_t seed,cpu,render,tick;unsigned calls,passes,frames,flashes;int weapon,extra,first_beam,first_flash,role,in_calc,interval;AstroSpecial*s;AstroTarget targets[3];unsigned repeat,repeat_phase,index,sites[3],value;int kind;} Probe;
static void row(Probe*q,char tag){assert(fgets(q->row,sizeof(q->row),q->f));if(q->row[0]!=tag){fprintf(stderr,"expected %c got %s",tag,q->row);abort();}}
static uint32_t clock_read(void*p){Probe*q=p;unsigned index,site,value;int kind;
 if(!q->repeat){assert(fgets(q->row,sizeof(q->row),q->f));if(q->row[0]=='Q'){unsigned cycles;assert(sscanf(q->row,"Q,%u,%u,%x,%x,%x,%u,%d",&cycles,&q->index,q->sites,q->sites+1,q->sites+2,&q->value,&q->kind)==7);q->repeat=cycles*3;q->repeat_phase=0;}}
 if(q->repeat){index=q->index++;site=q->sites[q->repeat_phase++%3];value=q->value;kind=q->kind;q->repeat--;}else assert(sscanf(q->row,"T,%u,%x,%u,%d",&index,&site,&value,&kind)==4);
 static const unsigned sites[2][7]={{0x1005c7d8,0x1005c80c,0x1005c8e8,0x1005c910,0x1005cc8c,0x1005ccb4,0x1005dce8},{0x1005bdac,0x1005bdec,0x1005bec8,0x1005bef0,0x1005c4a0,0x1005c4c8,0x1005c6b0}};
 assert(site==(q->in_calc?0:sites[q->weapon==50][q->role]));assert(kind==(q->role==0&&q->weapon==50?1:-1));
 if(!q->in_calc)switch(q->role){case 0:q->role=1;break;case 1:q->role=2;break;case 2:q->role=(int32_t)(value-q->cpu)>0?3:6;break;case 3:q->role=4;break;case 4:q->role=(int32_t)(value-q->render)>=q->interval?5:6;break;case 5:q->role=6;break;case 6:q->role=1;break;}
 assert(index==q->calls++);q->tick=value;return value;}
static void prepare(void*p,AstroSpecialContext*c){Probe*q=p;c->gun_x=100+(int)q->passes*2;c->gun_y=100;}
static void calculate(void*p,AstroSpecialContext*c){Probe*q=p;q->passes++;q->first_beam=q->first_flash=1;if(q->extra){q->in_calc=1;clock_read(q);q->in_calc=0;}unsigned tick,cpu,action;row(q,'C');assert(sscanf(q->row,"C,%u,%u,%u",&tick,&cpu,&action)==3);assert(tick==q->tick&&cpu==q->cpu&&action==q->s->action_until);
 for(int j=0;j<3;j++){int x=100+(int)q->passes*(j==0?1:j==1?2:3);q->targets[j]=(AstroTarget){.kind=j==1?-1:5,.parent=-1,.x=0,.y=0,.width=20,.height=20,.bounds_valid=1,.bounds={x,100,x+20,120}};}c->targets=q->targets;c->target_count=3;}
static void beam(void*p,const AstroBeam*b,int temporary){(void)temporary;Probe*q=p;if(!q->first_beam)return;q->first_beam=0;unsigned tick,render;int x,y,left,top;row(q,'B');assert(sscanf(q->row,"B,%u,%d,%d,%d,%d,%u",&tick,&x,&y,&left,&top,&render)==6);assert(tick==q->tick&&render==q->render&&x==b->x&&y==b->y&&left==100+(int)q->passes*2&&top==100);}
static void world(void*p){Probe*q=p;unsigned tick,render,seed;row(q,'W');assert(sscanf(q->row,"W,%u,%u,%u",&tick,&render,&seed)==3);assert(tick==q->tick&&render==q->render&&seed==q->seed);q->frames++;}
static void sprite(void*p,int id,double x,double y,double w,double h){Probe*q=p;q->flashes++;if(!q->first_flash)return;q->first_flash=0;unsigned tick,seed;int native_id;unsigned long long bits[4];row(q,'F');assert(sscanf(q->row,"F,%u,%d,%llx,%llx,%llx,%llx,%u",&tick,&native_id,bits,bits+1,bits+2,bits+3,&seed)==7);assert(tick==q->tick&&native_id==id&&seed==q->seed);double a[]={x,y,w,h};for(int j=0;j<4;j++){uint64_t u;memcpy(&u,a+j,8);assert(u==(uint64_t)bits[j]);}}
static void animate(void*p){Probe*q=p;unsigned tick,render,flashes,seed;row(q,'L');assert(sscanf(q->row,"L,%u,%u,%u,%u",&tick,&render,&flashes,&seed)==4);if(!(tick==q->tick&&render==q->render&&flashes==q->flashes&&seed==q->seed)){fprintf(stderr,"id%d L expected %u,%u,%u,%u got %u,%u,%u,%u\n",q->weapon,tick,render,flashes,seed,q->tick,q->render,q->flashes,q->seed);abort();}}
static void nothing(void*p){(void)p;}
int main(int argc,char**argv){assert(argc==2);FILE*f=fopen(argv[1],"r");assert(f);char line[512];unsigned cases=0,reads=0;
 while(fgets(line,sizeof(line),f)){int id,schedule,interval,extra;assert(sscanf(line,"CASE,%d,%d,%d,%d",&id,&schedule,&interval,&extra)==4);AstroSpecial s={0};Probe q={.f=f,.seed=123,.cpu=100,.render=100,.weapon=id,.extra=extra,.s=&s,.interval=interval};AstroSpecialContext c={.context=&q,.seed=&q.seed,.source_parent=-1,.frame_interval=interval,.left=0,.top=0,.right=640,.bottom=380,.beam=beam,.sprite=sprite,.render_tick=&q.render,.render_world=world};
 assert(astro_special_start_nested(&s,id,174,112,0,100,&c));AstroSpecialLoop loop={.cpu_tick=&q.cpu,.read_tick=clock_read,.prepare=prepare,.calculate=calculate,.animate=animate,.read_keys=nothing};assert(astro_special_run_nested(&s,&c,&loop));assert(!s.active);row(&q,'F');unsigned calls,passes,tick,cpu,render,action,frames,flashes,seed;int kind;assert(sscanf(q.row,"FINAL,%u,%u,%u,%u,%u,%u,%u,%u,%u,%d",&calls,&passes,&tick,&cpu,&render,&action,&frames,&flashes,&seed,&kind)==10);assert(calls==q.calls&&passes==q.passes&&tick==q.tick&&cpu==q.cpu&&render==q.render&&action==s.action_until&&frames==q.frames&&flashes==q.flashes&&seed==q.seed&&kind==1);reads+=q.calls;cases++;
 }assert(feof(f));fclose(f);assert(cases==12);printf("PASS:%u original polling schedules,%u exact clock reads + ordered CPU/render/RNG/terminal states\n",cases,reads);return 0;}
