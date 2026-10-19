/* Original CPU tick trace replay: shared a4e phase, W→visual RNG→P order.
 * Busy-loop terminal polling is reported separately: this test deliberately
 * replays captured CPU ticks, not an invented fixed31-update lifetime. */
#include "../src/special.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct {
    uint32_t *seed,*deadline,tick,before_seed;
    int inject,due,seen_beam,seen_world,seen_present,flashes,frames;
    int first_id,have_first;uint64_t first[4];
} Probe;
static void beam(void *p,const AstroBeam *b,int temporary){(void)b;(void)temporary;Probe*q=p;assert(!q->seen_world&&!q->seen_present);q->seen_beam=1;}
static void world(void *p){Probe*q=p;assert(q->due&&q->seen_beam&&!q->seen_world);assert(*q->deadline==q->tick&&*q->seed==q->before_seed);q->seen_world=1;q->frames++;if(q->inject)astro_random(q->seed,123);}
static void flash(void*p,int id,double x,double y,double w,double h){Probe*q=p;assert(q->seen_world&&!q->seen_present);q->flashes++;if(q->have_first){double values[4]={x,y,w,h};assert(id==q->first_id);for(int j=0;j<4;j++){uint64_t u;memcpy(&u,values+j,8);assert(u==q->first[j]);}q->have_first=0;}}
static void polygon(void*p,const AstroSpecialVertex*v,size_t n){(void)v;(void)n;Probe*q=p;assert(q->seen_world&&!q->seen_present);}
static void present(void*p){Probe*q=p;assert(q->seen_world&&!q->seen_present);q->seen_present=1;}
int main(int argc,char**argv){
    assert(argc==2);FILE*f=fopen(argv[1],"r");assert(f);char row[512];unsigned cases=0,steps=0;
    while(fgets(row,sizeof(row),f)){
        int id,interval,phase,inject,count,frames,flashes,outer_due;unsigned returned,final_render,final_action,final_seed;
        assert(sscanf(row,"C,%d,%d,%d,%d,%d,%u,%u,%u,%d,%d,%u,%d",&id,&interval,&phase,&inject,&count,&returned,&final_render,&final_action,&frames,&flashes,&final_seed,&outer_due)==12);
        uint32_t seed=123,deadline=100-(uint32_t)phase;AstroSpecial s={0};Probe q={.seed=&seed,.deadline=&deadline,.inject=inject};
        AstroTarget targets[3];AstroSpecialContext c={.context=&q,.seed=&seed,.targets=targets,.target_count=3,.source_parent=-1,.gun_x=102,.gun_y=100,.frame_interval=interval,.left=0,.top=0,.right=640,.bottom=380,.beam=beam,.sprite=flash,.polygon=polygon,.render_tick=&deadline,.render_world=world,.present=present};
        assert(astro_special_start_nested(&s,id,174,112,0,100,&c));
        for(int i=0;i<count;i++){
            unsigned tick,old_render,before,after_render,total_flashes,after_seed;int gunx,guny,due,first_id;unsigned long long words[4];
            assert(fgets(row,sizeof(row),f));assert(sscanf(row,"E,%u,%d,%d,%u,%d,%u,%u,%u,%u,%d,%llx,%llx,%llx,%llx",&tick,&gunx,&guny,&old_render,&due,&before,&after_render,&total_flashes,&after_seed,&first_id,words,words+1,words+2,words+3)==14);
            assert(deadline==old_render);q.tick=tick;q.due=due;q.before_seed=before;q.seen_beam=q.seen_world=q.seen_present=0;q.first_id=first_id;q.have_first=first_id!=0;
            for(int j=0;j<4;j++)q.first[j]=(uint64_t)words[j];
            for(int j=0;j<3;j++){int x=j==0?102+i:j==1?104+i*2:103+i*3;targets[j]=(AstroTarget){.kind=j==1?-1:5,.parent=-1,.x=x,.y=100,.width=20,.height=20,.bounds_valid=1,.bounds={x,100,x+20,120}};}
            c.gun_x=gunx;c.gun_y=guny;int result=astro_special_step_nested(&s,tick,&c);assert(result&ASTRO_SPECIAL_EFFECT);
            assert(q.seen_beam&&q.seen_world==due&&q.seen_present==due&&!q.have_first);
            if(seed!=after_seed){fprintf(stderr,"special FPS case%u id%d interval%d step%d tick%u native seed%u port%u\n",cases,id,interval,i,tick,after_seed,seed);return 1;}
            assert(deadline==after_render&&q.flashes==(int)total_flashes);steps++;
        }
        assert(deadline==final_render&&s.action_until==final_action&&q.frames==frames&&q.flashes==flashes&&seed==final_seed);
        assert(((int32_t)(returned-deadline)>=interval)==outer_due);
        /* At interval3 this native polling schedule exits between CPU updates.
         * The asynchronous host owns that completion boundary, not this replay. */
        if(count==30)assert(s.active);else assert(!s.active);cases++;
    }
    assert(feof(f));fclose(f);assert(cases==40);
    printf("PASS:%u original shared-render phases,%u captured CPU updates, signedintervals/callback order/visual RNG IEEE bits\n",cases,steps);return 0;
}
