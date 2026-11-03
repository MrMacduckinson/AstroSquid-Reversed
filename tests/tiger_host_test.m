// Traversal lifetime regression; runtime only on remote Intel reference host.
// Instrument only actor callbacks. Production calculateActors/cleanupWorld run.
#define main astrosquid_application_main
#include "../src/tiger/preview.m"
#undef main
static NSMutableString *visits;
static AstroEnemy *survivor,*removedTail,*insertedHead;
static int scenario;
static BOOL runningStages;
@interface AstroLifetimeView : AstroView
@end
@implementation AstroLifetimeView
- (void)readGameKeys {}
- (void)display {} // Traversal test never needs a presented frame.
- (void)stepActor:(id)object {
    if(runningStages){[super stepActor:object];return;}
    [visits appendString:object==[NSNull null]?@"A":object==survivor?@"B":object==removedTail?@"C":@"D"];
    if(object!=[NSNull null])return;
    if(scenario==1){removedTail->state.remove=1;[self cleanupWorld];}
    else if(scenario==2)[self prependEnemy:insertedHead];
    else if(scenario==3){survivor->state.remove=1;[self cleanupWorld];}
    else if(scenario==4){playerCombat.remove=1;[self cleanupWorld];}
    else if(scenario==5){survivor->state.remove=removedTail->state.remove=1;[self cleanupWorld];}
    else if(scenario==6){survivor->state.remove=1;[self cleanupWorld];[self prependEnemy:insertedHead];}
    else if(scenario==7)survivor->state.remove=1;
}
@end
@interface AstroView (LifetimeCheck)
- (int)checkTraversalLifetime;
@end
@implementation AstroView (LifetimeCheck)
- (int)checkTraversalLifetime {
    [timer invalidate];ASTRO_STORE(timer,nil);[audio stop];audio.soundVolume=audio.musicVolume=0;
    ASTRO_STORE(selftestPath,@"world-lifetime");ASTRO_STORE(campaignTestPath,selftestPath);
    changingStage=NO;camera=tickedScroll=0;simulationTick=100;
    ASTRO_STORE(backgrounds,@[]);ASTRO_STORE(parallaxData,[NSMutableData data]);memset(stars,0,sizeof stars);
    ASTRO_STORE(specialPolygons,[NSMutableArray array]);ASTRO_STORE(specialFlashes,[NSMutableArray array]);
    playerCombat=(AstroCombatState){.kind=1,.hit_points=200};ui.frameInterval=1;
    int failures=0;
    for(scenario=1;scenario<=7;scenario++){
        playerCombat=(AstroCombatState){.kind=1,.hit_points=200};
        survivor=[AstroEnemy new];removedTail=[AstroEnemy new];insertedHead=[AstroEnemy new];
        survivor->active=removedTail->active=insertedHead->active=YES;
        survivor->kind=removedTail->kind=insertedHead->kind=2;
        ASTRO_STORE(enemies,[NSMutableArray arrayWithObjects:survivor,removedTail,nil]);
        ASTRO_STORE(world,[NSMutableArray arrayWithObjects:[NSNull null],survivor,removedTail,nil]);
        [survivor release];[removedTail release];[insertedHead autorelease];
        visits=[NSMutableString string];[self calculateActors];
        // Defined traversal skips retired identities, even if new actors are inserted.
        NSString *expected=scenario==1?@"AB":scenario==3||scenario==6?@"AC":scenario==5?@"A":@"ABC";
        BOOL equal=[visits isEqualToString:expected];
        fprintf(equal?stdout:stderr,"%s scenario%d expected=%s host=%s\n",equal?"PASS":"FAIL",scenario,expected.UTF8String,visits.UTF8String);
        if(!equal)failures++;
        if(scenario==1)assert(world.count==2&&world[1]==survivor&&![world containsObject:removedTail]);
        else if(scenario==2)assert(world.count==4&&world[0]==insertedHead);
        else if(scenario==3)assert(world.count==2&&world[1]==removedTail);
        else if(scenario==4)assert(world.count==2&&world[0]==survivor&&playerNextActor==nil&&actorTraversalDepth==0);
        else if(scenario==5)assert(world.count==1&&world[0]==[NSNull null]);
        else if(scenario==6)assert(world.count==3&&world[0]==insertedHead&&world[2]==removedTail);
        else assert(world.count==3&&world[1]==survivor&&survivor->state.remove==1);
    }
    survivor=removedTail=insertedHead=nil;visits=nil;
    runningStages=YES;
    for(selectedLevel=0;selectedLevel<levels.count;selectedLevel++){
        NSAutoreleasePool *pool=[NSAutoreleasePool new];
        [self resetEnemies];[pool drain];
        for(unsigned tick=0;tick<20;tick++){
            pool=[NSAutoreleasePool new];simulationTick++;playerCombat.hit_points=200;
            [self makeNewSprites];[self calculateActors];[self updateVisualEffects];[pool drain];
        }
    }
    printf("PASS %u stage resources survive pool drains\n",(unsigned)levels.count);
    return failures?1:0;
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    if(argc!=2)return 2;
    [NSApplication sharedApplication];
    [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"smooth":@(YES),@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    AstroView *view=[[AstroLifetimeView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);
    int result=[view checkTraversalLifetime];[view release];return result;
}}
