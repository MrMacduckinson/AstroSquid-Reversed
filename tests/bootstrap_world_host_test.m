#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned resets,seedReads;static NSMutableArray *messages;
@interface BootstrapWorldView:AstroView
@end
@implementation BootstrapWorldView
- (uint32_t)macLocalSeconds {seedReads++;return 123;}

- (void)resetEnemies {resets++;[super resetEnemies];}
- (BOOL)appendDebugMessage:(NSString *)message {[messages addObject:message];return YES;}
@end
@implementation AstroView(BootstrapWorldCheck)
- (void)checkBootstrapWorld:(NSString *)assets {
 [timer invalidate];timer=nil;assert(seedReads==1&&!resets&&!world.count&&!enemies.count&&!mapPlacements.count&&!visualEffects.count&&!backgrounds.count&&!renderClock&&!playerNextActor&&!audio);
 assert(![messages containsObject:@"0"]);
 NSError *error=nil;AstroUIRenderer *reference=[[AstroUIRenderer alloc]initWithAssets:assets error:&error];assert(reference);uint32_t expected=123;astro_random(&expected,1);[reference reloadMenuWithRandom:&expected];AstroStar menuStars[3000];astro_stars_init(menuStars,1,&expected);double dx=astro_random(&expected,8)-4,dy=astro_random(&expected,8)-4;
 assert(randomSeed==expected&&menuScroll.x==dx&&menuScroll.y==dy&&!memcmp(stars,menuStars,sizeof menuStars));
 splashVisible=NO;[ui show:@"Play Menu"];[self performMenuAction:@"New Game"];
 assert(resets==1&&world.count&&enemies.count&&[world containsObject:[NSNull null]]&&campaign.level==1&&campaign.half==1&&gameLoopActive&&!playerVisualDeleted);
 assert([messages isEqual:@[@"0"]]);[self destroyGameWorld];assert(!world.count&&!enemies.count);
 puts("PASS bootstrap has no game actors/maps/level-load message; native-proven menu RNG/star/drift composition retained; NewGame creates level/player exactly once");
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];messages=[NSMutableArray array];NSString *assets=[NSString stringWithUTF8String:argv[1]];
 BootstrapWorldView *view=[[BootstrapWorldView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(view);[view checkBootstrapWorld:assets];return 0;
}}
