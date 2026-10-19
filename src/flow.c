#include "flow.h"
void astro_flow_ready(AstroFlow *f,int stage,int half) {
    *f=(AstroFlow){.phase=ASTRO_FLOW_READY,.stage=stage,.half=half};
}
void astro_flow_stage_end(AstroFlow *f,int stage,int half,int next,int next_half,int complete) {
    if(next==9&&!complete){*f=(AstroFlow){.phase=ASTRO_FLOW_PLAY,.stage=next,.half=next_half};return;}
    if(half==1){astro_flow_ready(f,next,next_half);return;}
    *f=(AstroFlow){.phase=ASTRO_FLOW_END_CARD,.stage=stage,.half=half,
        .next_stage=next,.next_half=next_half,.complete=complete};
}
int astro_flow_step(AstroFlow *f,int key) {
    f->ticks++;
    if(!key||f->phase==ASTRO_FLOW_PLAY||f->phase==ASTRO_FLOW_FINISHED)return 0;
    if(f->phase!=ASTRO_FLOW_END_CARD&&f->ticks<60)return 0;
    if(f->phase==ASTRO_FLOW_READY)f->phase=ASTRO_FLOW_PLAY;
    else if(f->phase==ASTRO_FLOW_END_CARD) {
        if(f->complete){f->phase=ASTRO_FLOW_ENDING;f->ending_page=0;}
        else {astro_flow_ready(f,f->next_stage,f->next_half);return 1;}
    } else if(++f->ending_page==4)f->phase=ASTRO_FLOW_FINISHED;
    f->ticks=0;return 1;
}
int astro_flow_picture(const AstroFlow *f) {
    if(f->phase==ASTRO_FLOW_READY)return f->stage+(f->half==1?50:70);
    if(f->phase==ASTRO_FLOW_END_CARD)return f->stage+60;
    if(f->phase==ASTRO_FLOW_ENDING)return 68;
    return 0;
}
int astro_flow_text_list(const AstroFlow *f) {
    return f->phase==ASTRO_FLOW_END_CARD?402:f->half==1?400:401;
}
