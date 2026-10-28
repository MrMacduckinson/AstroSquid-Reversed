/* Characterize the open WAITFORKEY gap; replace with coupled parity test when fixed. */
#define main astrosquid_application_main
#include "../../src/preview.m"
#undef main
@interface KeyGapView:AstroView
- (void)checkGap:(const char *)fixture;
@end
@implementation KeyGapView
- (void)checkGap:(const char *)fixture {
    FILE *f=fopen(fixture,"r");assert(f);char line[256];int expected=-1;
    while(fgets(line,sizeof(line),f)){
        unsigned id,reads,polls,frames,stamp;int bit,raw;
        if(sscanf(line,"Z,%u,%d,%d,%u,%u,%u,%u",&id,&bit,&raw,&reads,&polls,&frames,&stamp)==7&&id==128){assert(bit==7&&polls==1&&frames==1);expected=raw;}
    }
    assert(feof(f)&&!ferror(f)&&!fclose(f)&&expected==0);
    [timer invalidate];timer=nil;[audio stop];selftestPath=campaignTestPath=nil;
    menuVisible=YES;splashVisible=paused=gameOver=NO;editingKey=-1;memset(keys,0,sizeof(keys));
    [self keyDown:[self testEvent:NSKeyDown code:7]];[self keyDown:[self testEvent:NSKeyDown code:0]];
    assert(keys[7]&&keys[0]);int previous=controlKeys[0];
    [self performMenuAction:@"SetKeyFire"];
    assert(editingKey==0&&controlKeys[0]==previous);
    [self keyDown:[self testEvent:NSKeyDown code:7]];[self keyDown:[self testEvent:NSKeyDown code:0]];
    assert(editingKey==-1&&controlKeys[0]==7&&controlKeys[0]!=expected);
    puts("CONFIRMED OPEN GAP: native held raw0+7 selects0 immediately; host ignores held state and commits first keyDown7");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}}forName:NSArgumentDomain];
    KeyGapView *view=[[KeyGapView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkGap:argv[2]];
}}
