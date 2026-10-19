#ifndef ASTRO_FLOW_H
#define ASTRO_FLOW_H
#include <stdint.h>
typedef enum {ASTRO_FLOW_PLAY,ASTRO_FLOW_READY,ASTRO_FLOW_END_CARD,ASTRO_FLOW_ENDING,ASTRO_FLOW_FINISHED} AstroFlowPhase;
typedef struct {AstroFlowPhase phase;int stage,half,ending_page,next_stage,next_half,complete;uint32_t ticks;} AstroFlow;
void astro_flow_ready(AstroFlow *flow,int stage,int half);
void astro_flow_stage_end(AstroFlow *flow,int old_stage,int old_half,int next_stage,int next_half,int complete);
/* Original cards wait for any key; GETREADY and each ending page delay one second. */
int astro_flow_step(AstroFlow *flow,int any_key);
int astro_flow_picture(const AstroFlow *flow);
int astro_flow_text_list(const AstroFlow *flow);
#endif
