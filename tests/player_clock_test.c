/* Original full DOPLAYER clock prefix, fire keys false and no named shield/glow.
 * Keep animation compare/store, movement compare and post-body store separate.
 * No approximate float comparisons and no invented constant-time replay. */
#include "../src/player.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef struct {uint32_t values[4];unsigned count,used;} Clock;
static uint32_t next_tick(Clock*c){assert(c->used<c->count);return c->values[c->used++];}
static double from_bits(unsigned long long bits){uint64_t u=(uint64_t)bits;double value;memcpy(&value,&u,8);return value;}
static uint64_t bits(double value){uint64_t u;memcpy(&u,&value,8);return u;}
int main(int argc,char**argv){
 assert(argc==2);FILE*f=fopen(argv[1],"r");assert(f);char row[1024];unsigned cases=0,reads=0,coverage=0,separate_store=0;
 while(fgets(row,sizeof(row),f)){
  if(row[0]=='#')continue;
  int id,frame,tilt,state,after_frame,after_tilt,after_state;unsigned controls,animation,update,after_animation,after_update,action;unsigned long long vx,vy,after_vx,after_vy;Clock clock={{0},0,0};
  assert(sscanf(row,"%d,%u,%u,%u,%u,%u,%u,%u,%u,%llx,%llx,%d,%d,%d,%llx,%llx,%d,%d,%d,%u,%u,%u",&id,&controls,&clock.count,clock.values,clock.values+1,clock.values+2,clock.values+3,&animation,&update,&vx,&vy,&frame,&tilt,&state,&after_vx,&after_vy,&after_frame,&after_tilt,&after_state,&after_animation,&after_update,&action)==22);
  AstroPlayer p={{from_bits(vx),from_bits(vy)},frame,tilt,state,animation,update};
  uint32_t comparison=next_tick(&clock),store=comparison;int animate=(int32_t)(comparison-animation)>10;
  if(animate){store=next_tick(&clock);if(store!=comparison)separate_store++;}
  astro_player_animate(&p,comparison,store,controls);
  int move=(int32_t)(next_tick(&clock)-update)>0;
  if(move){astro_player_move(&p,controls,1,(AstroRect){60,180,131,200},71,20,(AstroViewport){0,0,640,380},0);assert(p.update_tick==update);p.update_tick=next_tick(&clock);}
  coverage|=1u<<((animate?2:0)+(move?1:0));
  if(!(bits(p.velocity.x)==after_vx&&bits(p.velocity.y)==after_vy&&p.frame==after_frame&&p.tilt==after_tilt&&p.state==after_state&&p.animation_tick==after_animation&&p.update_tick==after_update&&clock.used==clock.count)){
   fprintf(stderr,"player clock case%d mismatch: velocity%016llx/%016llx expected%016llx/%016llx; frame%d/%d tilt%d/%d state%d/%d timers%u/%u expected%u/%u reads%u/%u\n",id,(unsigned long long)bits(p.velocity.x),(unsigned long long)bits(p.velocity.y),after_vx,after_vy,p.frame,after_frame,p.tilt,after_tilt,p.state,after_state,p.animation_tick,p.update_tick,after_animation,after_update,clock.used,clock.count);return 1;
  }
  assert(action==777);reads+=clock.used;cases++;
 }
 assert(feof(f));fclose(f);assert(cases==16&&coverage==15&&separate_store);printf("PASS:%u original player clock prefixes,%u separate reads, all animation/movement gate combinations + raw IEEE states\n",cases,reads);return 0;
}
