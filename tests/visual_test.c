#include "ieee_exact.h"
#include "../src/visual.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include "visual_metrics.h"
int main(int argc,char **argv) {
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);
    int from,to;unsigned tick,next,count=0;double x,y,w,h,ex,ey,ew,eh;
    while(fscanf(f,"%d,%d,%lf,%lf,%lf,%lf,%u,%lf,%lf,%lf,%lf,%u",&from,&to,&x,&y,&w,&h,&tick,&ex,&ey,&ew,&eh,&next)==12) {
        AstroVisual v={from,x,y,w,h,0};
        assert(astro_visual_change(&v,to,metrics,sizeof(metrics)/sizeof(metrics[0]),tick));
        assert(v.sprite==to&&v.next_tick==next&&ieee_exact(v.x,ex)&&ieee_exact(v.y,ey)&&ieee_exact(v.width,ew)&&ieee_exact(v.height,eh));count++;
    }
    assert(feof(f)&&count==100);fclose(f);
    AstroSpriteInfo animation[]={{10,20,1,3},{20,10,-1,2}};
    AstroVisual v={0,0,0,10,20,3};
    assert(astro_visual_step(&v,animation,2,3)==1&&v.sprite==0);
    assert(astro_visual_step(&v,animation,2,4)==1&&v.sprite==1&&v.next_tick==6);
    assert(astro_visual_step(&v,animation,2,7)==0);
    assert(!astro_visual_change(&v,99,animation,2,8));
    printf("PASS: %u original G5 sprite geometry/deadline captures and frame-chain completion\n",count);return 0;
}
