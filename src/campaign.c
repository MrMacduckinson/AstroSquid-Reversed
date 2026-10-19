#include "campaign.h"
int astro_campaign_event(AstroCampaign *c,int tag,int marker) {
    if(c->complete) return ASTRO_CAMPAIGN_NONE;
    if(marker&&tag!=-1) {c->arena=1;return ASTRO_CAMPAIGN_NONE;}
    if(!marker&&tag==-2) {
        c->level=9;c->half=2;c->arena=0;return ASTRO_CAMPAIGN_LOAD;
    }
    if(tag!=-1) return ASTRO_CAMPAIGN_NONE;
    c->arena=0;
    if(c->half==1) {c->half=2;return ASTRO_CAMPAIGN_LOAD;}
    if(c->level>=8) {c->complete=1;return ASTRO_CAMPAIGN_COMPLETE;}
    c->level++;c->half=1;return ASTRO_CAMPAIGN_LOAD;
}
