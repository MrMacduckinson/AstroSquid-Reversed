#include "../src/transition.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
static AstroRect view={0,0,640,380},centered={300,170,340,210};
static void step(AstroTransition *t,uint32_t tick,AstroRect p) {astro_transition_step(t,tick,p,40,40,view,0,0);}
/* Every event from the original trail instruction range is replayed in order;
 * the clock/render host remains explicit, with separate compare/store reads. */
static uint64_t word(double value){uint64_t u;memcpy(&u,&value,8);return u;}
static uint32_t native_tick(FILE*f,unsigned*reads){char row[256];unsigned tick;assert(fgets(row,sizeof(row),f));assert(sscanf(row,"T,%u",&tick)==1);(*reads)++;return tick;}
static void native_event(FILE*f,char tag,AstroTransition*t,uint32_t deadline){char row[256];unsigned long long scale,sx,camera;unsigned tick;assert(fgets(row,sizeof(row),f));assert(row[0]==tag);assert(sscanf(row+2,"%llx,%u,%llx,%llx",&scale,&tick,&sx,&camera)==4);assert(word(t->scale)==scale&&deadline==tick&&word(t->scroll_x)==sx&&word(1234.25)==camera);}
static void native_trail(const char*path){
 FILE*f=fopen(path,"r");assert(f);char row[256];unsigned cases=0,total_reads=0,frames=0,polls=0,skipped=0;
 while(fgets(row,sizeof(row),f)){int id,interval;unsigned long long scale;assert(sscanf(row,"CASE,%d,%d,%llx",&id,&interval,&scale)==3);assert(id==(int)cases);uint64_t u=scale;double initial;memcpy(&initial,&u,8);
  AstroTransition t={.mode=ASTRO_TRANSITION_END,.phase=ASTRO_TRANSITION_TRAIL,.scale=initial,.scroll_x=217.79533378093692,.simulate_world=0};uint32_t deadline=100;unsigned reads=0;native_tick(f,&reads);
  do {
   uint64_t before=word(t.scale);step(&t,0,centered);assert(word(t.scale)==before&&t.phase==ASTRO_TRANSITION_TRAIL&&!t.simulate_world);
   uint32_t comparison=native_tick(f,&reads);polls++;
   if((int32_t)(comparison-deadline)>=interval){deadline=native_tick(f,&reads);assert(astro_transition_render_trail(&t));native_event(f,'M',&t,deadline);native_event(f,'W',&t,deadline);native_event(f,'P',&t,deadline);native_event(f,'K',&t,deadline);frames++;}else{assert(word(t.scale)==before);skipped++;}
   native_event(f,'V',&t,deadline);
  }while(!(t.scale<.001));
  assert(t.phase==ASTRO_TRANSITION_CARD&&t.events==ASTRO_TRANSITION_MENU_MUSIC);native_event(f,'E',&t,deadline);assert(fgets(row,sizeof(row),f));unsigned expected;assert(sscanf(row,"FINAL,%u",&expected)==1&&reads==expected);assert(!astro_transition_render_trail(&t));total_reads+=reads;cases++;
 }
 assert(feof(f));fclose(f);assert(cases==24&&skipped);printf("PASS:%u native END trail schedules,%u clock reads,%u polls,%u exact scale/render/M-W-P-K-V frames; no CPU scale advance\n",cases,total_reads,polls,frames);
}
int main(int argc,char**argv) {
    assert(argc<3);native_trail(argc==2?argv[1]:"tests/trail_transition_vectors.csv");
    AstroTransition t;
    astro_transition_begin(&t,ASTRO_TRANSITION_MID,100,0);
    step(&t,100,(AstroRect){0,0,40,40});assert(t.controls==(ASTRO_KEY_RIGHT|ASTRO_KEY_DOWN));
    step(&t,101,centered);assert(!t.ready);
    step(&t,102,centered);assert(t.ready&&t.phase==ASTRO_TRANSITION_CENTER);
    step(&t,104,centered);assert(t.phase==ASTRO_TRANSITION_EXIT&&t.controls==ASTRO_KEY_RIGHT);
    step(&t,106,(AstroRect){691,170,731,210});assert(t.phase==ASTRO_TRANSITION_EXIT&&t.ready);
    step(&t,108,(AstroRect){691,170,731,210});assert(t.phase==ASTRO_TRANSITION_EXIT_WAIT);
    step(&t,128,centered);assert(t.phase!=ASTRO_TRANSITION_DONE);
    step(&t,129,centered);assert(t.phase==ASTRO_TRANSITION_DONE&&t.events==(ASTRO_TRANSITION_MENU_MUSIC|ASTRO_TRANSITION_CLEAR_WORLD));
    astro_transition_begin(&t,ASTRO_TRANSITION_END,0,0);step(&t,0,centered);
    assert(t.events==ASTRO_TRANSITION_BLOW&&t.allow_input);
    step(&t,60,centered);assert(t.phase==ASTRO_TRANSITION_WAIT);
    step(&t,61,centered);assert(t.phase==ASTRO_TRANSITION_CENTER&&t.ready);
    step(&t,63,centered);assert(t.phase==ASTRO_TRANSITION_ACCEL&&t.zero_velocity&&t.scroll_x==1.4);
    assert(t.events==(ASTRO_TRANSITION_ENGINE_GLOW|ASTRO_TRANSITION_HYPER_SOUND));
    int acceleration=0,trail=0;uint32_t tick;
    for(tick=64;tick<1000&&t.phase!=ASTRO_TRANSITION_CARD;tick++) {
        int old=t.phase;step(&t,tick,centered);
        if(t.phase==ASTRO_TRANSITION_TRAIL)assert(astro_transition_render_trail(&t));
        if(old==ASTRO_TRANSITION_ACCEL&&t.deadline==tick+11)acceleration++;
        if(t.events&ASTRO_TRANSITION_TRAIL_SPRITE) {assert(t.player_frame==15&&!t.simulate_world);trail++;}
    }
    assert(t.phase==ASTRO_TRANSITION_CARD&&trail==1&&acceleration==15);
    assert(t.scale<.001&&t.events==ASTRO_TRANSITION_MENU_MUSIC);
    astro_transition_accept_card(&t);step(&t,tick,centered);assert(t.phase==ASTRO_TRANSITION_DONE&&t.scale==1&&t.events==ASTRO_TRANSITION_CLEAR_WORLD);
    astro_transition_begin(&t,ASTRO_TRANSITION_RESPAWN,0,1);step(&t,60,centered);assert(!(t.events&ASTRO_TRANSITION_SPAWN_PLAYER));
    step(&t,61,centered);assert(t.events==ASTRO_TRANSITION_SPAWN_PLAYER&&t.spawn_x==30&&t.spawn_y==190&&!t.player_visible);
    step(&t,66,centered);assert(!t.player_visible);step(&t,67,centered);assert(t.player_visible);
    step(&t,241,centered);assert(t.phase==ASTRO_TRANSITION_BLINK);step(&t,242,centered);assert(t.phase==ASTRO_TRANSITION_DONE&&t.player_visible);
    astro_transition_begin(&t,ASTRO_TRANSITION_NEW_GAME,10,1);step(&t,10,centered);
    assert(t.phase==ASTRO_TRANSITION_DONE&&(t.events&ASTRO_TRANSITION_BRIEFING)&&(t.events&ASTRO_TRANSITION_NEW_SPECIAL));
    AstroTransitionRect g=astro_transition_engine_glow(320,170,40,12);assert(g.x==321&&g.y==169&&g.width==42&&g.height==42);
    g=astro_transition_departure_glow(320,170,40,40);assert(g.x==310&&g.y==165&&g.width==20&&g.height==50);
    g=astro_transition_departure_trail(g);assert(g.x==0&&g.y==182.5&&g.width==360&&g.height==15);
    puts("PASS: original transition strict timers, centering/exit controls, hyper acceleration, blink and geometry");return 0;
}
