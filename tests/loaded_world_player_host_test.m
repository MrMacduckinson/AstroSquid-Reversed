// Actual host player handler against original DOPLAYERSPRITE with loaded70..450 bounds.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include "ieee_exact.h"
static uint32_t playerTick;
@interface LoadedPlayerView:AstroView
@end
@implementation LoadedPlayerView
- (uint32_t)playerClockTick {return playerTick;}
@end
@implementation AstroView(LoadedPlayerCheck)
- (void)checkLoadedPlayer:(const char *)path {
    [timer invalidate];timer=nil;[self resetLevelWorld];assert(worldTop==70&&worldBottom==450);
    inventory.specials=0;playerWeapon=0;engineGlow=NO;changingStage=NO;
    FILE *f=fopen(path,"r");assert(f);int variant,previous=-1,frame,tilt,state;unsigned count=0,animation,update;
    double vx,vy;AstroEnemy *actor=nil;
    while(fscanf(f,"%d,%u,%lf,%lf,%d,%d,%d,%u,%u",&variant,&playerTick,&vx,&vy,&frame,&tilt,&state,&animation,&update)==9){
        if(previous!=variant){actor=[AstroEnemy new];actor->kind=1;actor->state=(AstroScriptState){.frame=12,.tilt=3,.state=1};actor->visual.width=71;actor->visual.height=20;previous=variant;}
        unsigned controls=(variant+playerTick/25)%16;memset(keys,0,sizeof(keys));
        keys[controlKeys[4]]=!!(controls&ASTRO_KEY_LEFT);keys[controlKeys[5]]=!!(controls&ASTRO_KEY_RIGHT);
        keys[controlKeys[2]]=!!(controls&ASTRO_KEY_UP);keys[controlKeys[3]]=!!(controls&ASTRO_KEY_DOWN);
        int x=playerTick%4==0?-20:playerTick%4==1?620:60,y=playerTick%4==2?50:playerTick%4==3?445:180;
        actor->bounds=(AstroRect){x,y,x+71,y+20};[self updateOtherPlayer:actor];
        if(!ieee_exact(actor->state.velocity.x,vx)||!ieee_exact(actor->state.velocity.y,vy)){
            fprintf(stderr,"player variant%d tick%u actual%.17g,%.17g expected%.17g,%.17g bounds%.17g..%.17g\n",variant,playerTick,actor->state.velocity.x,actor->state.velocity.y,vx,vy,worldTop,worldBottom);abort();
        }
        assert(actor->state.frame==frame&&actor->state.tilt==tilt&&actor->state.state==state&&actor->state.animation_tick==animation&&actor->state.update_tick==update);count++;
    }
    assert(feof(f)&&count==3200);fclose(f);
    simulationTick=1000;astro_transition_begin(&transition,ASTRO_TRANSITION_MID,1000,0);[self stepStageTransition];
    assert(transition.target_x==320&&transition.target_y==260);
    changingStage=NO;[world removeAllObjects];[enemies removeAllObjects];
    AstroStar expected[3000];memcpy(expected,stars,sizeof(expected));uint32_t seed=randomSeed;
    NSMutableData *positions=[parallaxData mutableCopy];
    astro_stars_move(expected,-camera,0,camera,70,camera+640,450,tickedScroll,0,0,0,ui.frameInterval,&seed,positions.mutableBytes,backgrounds.count,0);
    [self calculateActors];assert(!memcmp(stars,expected,sizeof(expected))&&randomSeed==seed&&[parallaxData isEqual:positions]);
    assert(worldTop==0&&signbit(worldTop)&&worldBottom==380);
    puts("PASS3200 original loaded-world player IEEE/control/clamp states through actual host handler, including top50 andbottom445 cases");
}
@end
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0,@"keys":@[@55,@58,@126,@125,@123,@124]}} forName:NSArgumentDomain];
    LoadedPlayerView *view=[[LoadedPlayerView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkLoadedPlayer:argv[2]];
}}
