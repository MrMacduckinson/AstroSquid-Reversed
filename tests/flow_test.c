#include "../src/flow.h"
#include <assert.h>
#include <stdio.h>
static void dismiss(AstroFlow *f) {for(int i=0;i<59;i++)assert(!astro_flow_step(f,1));assert(astro_flow_step(f,1));}
int main(void) {
    AstroFlow f;astro_flow_ready(&f,1,1);assert(astro_flow_picture(&f)==51);
    dismiss(&f);assert(f.phase==ASTRO_FLOW_PLAY);
    for(int stage=1;stage<=8;stage++) {
        astro_flow_stage_end(&f,stage,1,stage,2,0);
        assert(f.phase==ASTRO_FLOW_READY&&astro_flow_picture(&f)==stage+70&&astro_flow_text_list(&f)==401);
        dismiss(&f);
        astro_flow_stage_end(&f,stage,2,stage+1,1,stage==8);
        assert(f.phase==ASTRO_FLOW_END_CARD&&astro_flow_picture(&f)==stage+60&&astro_flow_text_list(&f)==402);
        assert(!astro_flow_step(&f,0));assert(astro_flow_step(&f,1));
        if(stage<8){assert(f.phase==ASTRO_FLOW_READY&&f.stage==stage+1);dismiss(&f);}
    }
    assert(f.phase==ASTRO_FLOW_ENDING);
    for(int page=0;page<4;page++){assert(f.ending_page==page&&astro_flow_picture(&f)==68);dismiss(&f);}
    assert(f.phase==ASTRO_FLOW_FINISHED);
    astro_flow_stage_end(&f,8,2,9,2,0);assert(f.phase==ASTRO_FLOW_PLAY);
    puts("PASS campaign cards, half-stage routing, input delay and all four ending pages");
}
