#include "../src/ui_model.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
int main(int argc,char **argv){
    assert(argc==3);FILE *f=fopen(argv[1],"r");assert(f);unsigned cases=0;
    int interval,sprite,initial,count;unsigned long long expected[4];
    while(fscanf(f,"%d,%d,%d,%llx,%llx,%llx,%llx,%d",&interval,&sprite,&initial,&expected[0],&expected[1],&expected[2],&expected[3],&count)==8){
        AstroUIMotion state={381.1,-70.3,65.7,380.2,initial,(int16_t)sprite};
        for(int step=0;step<125;step++)astro_ui_animate(&state,interval);
        const double actual[]={state.x,state.y,state.width,state.height};
        assert(!memcmp(expected,actual,32)&&state.counter==count);cases++;
    }
    fclose(f);assert(cases==1625);
    f=fopen(argv[2],"r");assert(f);unsigned panel_cases=0;int mode,direction,frame,row;unsigned long long ybits;
    while(fscanf(f,"%d,%d,%d,%d,%llx",&mode,&direction,&frame,&row,&ybits)==5){
        int frames=mode?60:30;double start=(217.1+row*37.7-380)-70;
        AstroUIMotion state={0,start,65,65,0,900};
        if(direction<0)for(int i=0;i<frames;i++)astro_ui_panel_step(&state,380.0/frames);
        for(int i=0;i<=frame;i++)astro_ui_panel_step(&state,(380.0/frames)*direction);
        assert(!memcmp(&ybits,&state.y,8));panel_cases++;
    }
    fclose(f);assert(panel_cases==480);printf("PASS %u original G5 raw-double Pause/GameOver frame vectors\n",panel_cases);
    printf("PASS %u original G5 raw-double ANIMATEMENU vectors\n",cases);return 0;
}
