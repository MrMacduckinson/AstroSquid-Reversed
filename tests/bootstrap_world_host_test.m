#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static unsigned resets,seedReads,startPhase;static BOOL checkStart;static int oldScore;static NSMutableArray *messages;
@interface BootstrapWorldView:AstroView
@end
@implementation BootstrapWorldView
- (uint32_t)macLocalSeconds {seedReads++;return 123;}

- (void)resetLevelWorld {
 if(checkStart){assert(startPhase++==0&&score==oldScore&&inventory.lives==7&&inventory.weapon==50&&inventory.specials==8);}
 resets++;[super resetLevelWorld];
}
- (void)presentFrame {if(checkStart){assert(startPhase++==1&&!score&&inventory.lives==7&&![world containsObject:[NSNull null]]);}}
- (void)createPlayerAtX:(double)x y:(double)y {
 if(checkStart)assert(startPhase++==2&&!score&&inventory.lives==1&&!gameEndRequested&&inventory.weapon==50&&inventory.specials==8);
 [super createPlayerAtX:x y:y];
}
- (void)setGameCursorHidden:(BOOL)hidden {if(checkStart)assert(hidden&&startPhase==2&&inventory.lives==1&&!gameEndRequested);}
- (void)finishPlayerStart {if(checkStart)assert(startPhase++==3);[super finishPlayerStart];}
- (BOOL)appendDebugMessage:(NSString *)message {[messages addObject:message];return YES;}
@end
@implementation AstroView(BootstrapWorldCheck)
- (void)checkBootstrapWorld:(NSString *)assets {
 [timer invalidate];timer=nil;assert(seedReads==1&&!resets&&!world.count&&!enemies.count&&!mapPlacements.count&&!visualEffects.count&&!backgrounds.count&&!renderClock&&!playerNextActor&&!audio);
 assert(![messages containsObject:@"0"]&&!starsInitialized);uint32_t seeded=123;astro_random(&seeded,1);assert(randomSeed==seeded);[self reloadMainMenu];
 NSError *error=nil;AstroUIRenderer *reference=[[AstroUIRenderer alloc]initWithAssets:assets error:&error];assert(reference);uint32_t expected=123;astro_random(&expected,1);[reference reloadMenuWithRandom:&expected];AstroStar menuStars[3000];astro_stars_init(menuStars,1,&expected);double dx=astro_random(&expected,8)-4,dy=astro_random(&expected,8)-4;
 assert(randomSeed==expected&&menuScroll.x==dx&&menuScroll.y==dy&&!memcmp(stars,menuStars,sizeof menuStars));
 splashVisible=NO;[ui show:@"Play Menu"];oldScore=score=123456;inventory=(AstroInventory){50,3,8,7};gameEndRequested=YES;cheats=(AstroCheats){3,1};cheatNoticeUntil=1e12;checkStart=YES;startPhase=0;[self performMenuAction:@"New Game"];assert(!cheats.weapons&&!cheats.matched&&!cheatNoticeUntil);checkStart=NO;assert(startPhase==4&&inventory.weapon==10&&!inventory.upgrade&&inventory.specials==1&&inventory.lives==1);
 assert(resets==1&&world.count&&enemies.count&&[world containsObject:[NSNull null]]&&campaign.level==1&&campaign.half==1&&gameLoopActive&&!playerVisualDeleted);
 assert([messages isEqual:@[@"0"]]);[self destroyGameWorld];assert(!world.count&&!enemies.count);
 oldScore=score=-1;inventory=(AstroInventory){50,3,8,7};gameEndRequested=YES;ui.unlockedLevel=16;
 cheats=(AstroCheats){3,1};cheatNoticeUntil=1e12;checkStart=YES;startPhase=0;[self performMenuAction:@"Level8"];assert(!cheats.weapons&&!cheats.matched&&!cheatNoticeUntil);checkStart=NO;
 assert(startPhase==4&&resets==2&&campaign.level==4&&campaign.half==2&&inventory.weapon==10&&!inventory.upgrade&&inventory.specials==1&&inventory.lives==1);
 [self destroyGameWorld];puts("PASS NewGame/Continue load old score/inventory, clear score before swap, reset lives/end before player, then initialize equipment");
 puts("PASS bootstrap has no game actors/maps/level-load message; native-proven menu RNG/star/drift composition retained; NewGame creates level/player exactly once");
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];messages=[NSMutableArray array];NSString *assets=[NSString stringWithUTF8String:argv[1]];
 BootstrapWorldView *view=[[BootstrapWorldView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:assets];assert(view);[view checkBootstrapWorld:assets];return 0;
}}
