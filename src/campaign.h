#ifndef ASTROSQUID_CAMPAIGN_H
#define ASTROSQUID_CAMPAIGN_H
typedef struct {int level,half,arena,complete;} AstroCampaign;
enum {ASTRO_CAMPAIGN_NONE,ASTRO_CAMPAIGN_LOAD,ASTRO_CAMPAIGN_COMPLETE};
/* Map marker activation and tagged entity death, from CALCSPRITES/death/game loop. */
int astro_campaign_event(AstroCampaign *campaign,int tag,int marker);
#endif
