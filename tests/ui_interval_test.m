#import "../src/ui_renderer.h"
#include "../src/ui_model.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
static void same(double value,unsigned long long expected){assert(!memcmp(&value,&expected,8));}
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);AstroUIRenderer *ui=[[AstroUIRenderer alloc] initWithAssets:[NSString stringWithUTF8String:argv[1]] error:NULL];assert(ui&&ui.frameInterval==1);
    FILE *f=fopen(argv[2],"r");assert(f);int interval,frame,done,last=0;unsigned cases=0;unsigned long long bits[4];
    while(fscanf(f,"%d,%d,%llx,%llx,%llx,%llx,%d",&interval,&frame,&bits[0],&bits[1],&bits[2],&bits[3],&done)==7){
        if(interval!=last){last=interval;ui.frameInterval=(int16_t)interval;
            [ui setValue:@0.0 forKey:@"cameraX"];[ui setValue:@0.0 forKey:@"cameraY"];
            [ui setValue:@(-599.5) forKey:@"targetX"];[ui setValue:@(-344.0) forKey:@"targetY"];
            [ui setValue:@YES forKey:@"transitioning"];
        }
        [ui advanceMenuCamera];same(ui.cameraX,bits[0]);same(ui.cameraY,bits[1]);same(ui.cameraStepX,bits[2]);same(ui.cameraStepY,bits[3]);assert(ui.transitioning==!done);cases++;
        if(done){uint32_t seed=12345;[ui reloadMenuWithRandom:&seed];same(ui.cameraX,bits[0]);same(ui.cameraY,bits[1]);
            NSDictionary *states=[ui valueForKey:@"orbStates"];NSMutableDictionary *expected=[NSMutableDictionary dictionary];
            for(NSString *name in states){AstroUIMotion state;memcpy(&state,[states[name] bytes],sizeof(state));astro_ui_animate(&state,interval);expected[name]=[NSData dataWithBytes:&state length:sizeof(state)];}
            [ui animateMenuObjects];for(NSString *name in states){const AstroUIMotion *actual=[states[name] bytes],*want=[expected[name] bytes];assert(!memcmp(actual,want,32)&&actual->counter==want->counter);}
            [ui show:@"Pause"];[ui animateTicks:29];assert(ui.transitioning);[ui animateTicks:1];assert(!ui.transitioning);
            [ui beginPauseExit];[ui animateTicks:29];assert(ui.transitioning);[ui animateTicks:1];assert(!ui.transitioning);
            [ui show:@"GameOver"];[ui animateTicks:59];assert(ui.transitioning);[ui animateTicks:1];assert(!ui.transitioning);
        }
    }
    fclose(f);assert(cases==39);ui.frameInterval=-1;assert(ui.frameInterval==-1);ui.frameInterval=0;assert(ui.frameInterval==0);
    printf("PASS %u G5 original interval2/3 camera double states, initial residual, orb interval and sync panels\n",cases);
}}
