#include "../src/campaign.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    AstroCampaign c={1,1,0,0};
    for(int level=1;level<=8;level++) {
        assert(c.level==level&&c.half==1);
        assert(astro_campaign_event(&c,-1,1)==ASTRO_CAMPAIGN_LOAD&&c.half==2);
        assert(astro_campaign_event(&c,0,1)==ASTRO_CAMPAIGN_NONE&&c.arena);
        assert(astro_campaign_event(&c,0,0)==ASTRO_CAMPAIGN_NONE&&c.arena);
        assert(astro_campaign_event(&c,1,0)==ASTRO_CAMPAIGN_NONE&&c.arena);
        if(level<8) assert(astro_campaign_event(&c,-1,0)==ASTRO_CAMPAIGN_LOAD);
    }
    assert(astro_campaign_event(&c,-2,0)==ASTRO_CAMPAIGN_NONE&&c.level==8&&c.half==2&&!c.arena);
    assert(astro_campaign_event(&c,-1,0)==ASTRO_CAMPAIGN_COMPLETE&&c.complete);
    assert(astro_campaign_event(&c,-2,0)==ASTRO_CAMPAIGN_NONE);
    puts("PASS: complete campaign marker/boss/final-stage path and unrelated death events");return 0;
}
