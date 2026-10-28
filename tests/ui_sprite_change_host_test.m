#import "../src/ui_renderer.h"
#include "../src/ui_model.h"
#include <assert.h>
static unsigned sample,step,reads;
@interface AstroUIRenderer (SpriteChangeProbe)
- (void)changeSprite:(int16_t)sprite object:(NSDictionary *)object;
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);AstroUIRenderer *ui=[[AstroUIRenderer alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:NULL];assert(ui);
    const double bounds[][4]={{381,222,65,65},{-.125,1.25,65.125,64.875},{1e16,-1e16,222,222},{-83.25,5.5,.125,1000.5}};const int16_t ids[]={902,900,901,900,901};
    for(sample=0;sample<4;sample++){
        ui.readTick=nil;[ui show:@"GameOver"];
        NSDictionary *object=[[ui valueForKey:@"objects"] firstObject];assert([object[@"name"]isEqual:@"GameOverOK"]);
        AstroUIMotion *state=[[[ui valueForKey:@"orbStates"]objectForKey:@"GameOverOK"]mutableBytes];memcpy(state,bounds[sample],32);state->sprite=900;reads=0;
        ui.readTick=^uint32_t{uint32_t n=(sample==3?UINT32_MAX-2:1000)+reads++;printf("T,%u,%u,%u\n",sample,step,n);return n;};
        for(step=0;step<5;step++){
            if(step==4)[ui beginGameOverExit];else [ui changeSprite:ids[step] object:object];
            uint32_t deadline=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"GameOverOK"]unsignedIntValue];
            printf("N,%u,%u,%d,%u",sample,step,state->sprite,deadline);
            double values[]={state->x,state->y,state->width,state->height};for(unsigned i=0;i<4;i++){uint64_t bits;memcpy(&bits,&values[i],8);printf(",%016llx",bits);}putchar('\n');
        }assert(reads==5);
    }
}}
