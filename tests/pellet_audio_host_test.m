// Short original-player cadence replay plus real AVAudioPlayer timing, Intel only.
#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static uint32_t pelletTick;
static unsigned pelletShots,pelletSounds,pelletInterval;
static FILE *pelletTrace;
@interface PelletAudio : AstroAudio
@end
@implementation PelletAudio
- (BOOL)playStringCue:(int)index position:(double)position {
    assert(index==297&&isfinite(position));pelletSounds++;return YES;
}
@end
@interface PelletView : AstroView
- (void)checkCadence:(NSString *)assets trace:(FILE *)trace;
@end
@implementation PelletView
- (uint32_t)playerClockTick {return pelletTick;}
- (BOOL)controlPressed:(unsigned)index {return index==0;}
- (void)spawnShot:(const AstroShot *)shot source:(int)kind {assert(shot->type==1&&kind==1);}
- (void)fireWeapon:(int)weapon x:(int)x y:(int)y heading:(int)heading source:(int)kind {
    assert(weapon==10);unsigned interval,tick;
    assert(fscanf(pelletTrace,"F,%u,%u\n",&interval,&tick)==2);
    assert(interval==pelletInterval&&tick==pelletTick);pelletShots++;
    [super fireWeapon:weapon x:x y:y heading:heading source:kind];
}
- (void)checkCadence:(NSString *)assets trace:(FILE *)trace {
    game=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[assets stringByAppendingPathComponent:@"game.json"]] options:0 error:NULL];assert(game);
    assert([game[@"weapons"][@"10"][@"rate"] intValue]==7);
    ui=[AstroUIRenderer new];audio=[PelletAudio new];playerWeapon=10;pelletTrace=trace;
    for(pelletInterval=1;pelletInterval<=3;pelletInterval++){
        ui.frameInterval=pelletInterval;uint32_t action=0;pelletShots=pelletSounds=0;
        for(pelletTick=pelletInterval;pelletTick<=180;pelletTick+=pelletInterval)
            [self fireOrdinaryPlayerWeaponFrom:(AstroRect){60,180,131,200} actionTick:&action kind:1];
        unsigned interval,count;assert(fscanf(trace,"N,%u,%u\n",&interval,&count)==2);
        assert(interval==pelletInterval&&count==pelletShots&&pelletSounds==pelletShots);
        printf("PASS interval%u shots%u sound_calls%u\n",interval,count,pelletSounds);
    }
    assert(fgetc(trace)==EOF);audio=nil;
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);alarm(15);setvbuf(stdout,NULL,_IONBF,0);
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSString *assets=[NSString stringWithUTF8String:argv[1]];FILE *trace=fopen(argv[2],"r");assert(trace);
    PelletView *view=[[PelletView alloc]initWithFrame:NSZeroRect];assert(view);[view checkCadence:assets trace:trace];fclose(trace);
    NSError *error=nil;AstroAudio *sound=[[AstroAudio alloc]initWithAssets:assets error:&error];assert(sound&&!error);sound.soundVolume=0;
    NSTimeInterval start=NSProcessInfo.processInfo.systemUptime;double maxCall=0,totalCall=0;
    for(unsigned i=0;i<12;i++){
        while(NSProcessInfo.processInfo.systemUptime<start+i*.15)
            [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
        NSTimeInterval request=NSProcessInfo.processInfo.systemUptime;
        assert([sound playStringCue:297 position:.2]);double callTime=NSProcessInfo.processInfo.systemUptime-request;totalCall+=callTime;
        NSArray *pair=[[sound valueForKey:@"voices"]lastObject];assert(pair.count==2);
        AVAudioPCMBuffer *pcm=[pair[0]valueForKey:@"buffer"];
        assert(pcm.frameLength==1797&&pcm.format.sampleRate==11025&&[pair[0]isPlaying]);
        if(callTime>maxCall)maxCall=callTime;
        printf("P,%u,request_ms=%.3f,call_ms=%.3f,duration_ms=%.3f\n",i,(request-start)*1000,callTime*1000,pcm.frameLength/pcm.format.sampleRate*1000);
    }
    assert(totalCall<.05); // The old per-shot players block for hundreds of milliseconds in this sequence.
    [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.25]];
    for(NSArray *pair in [sound valueForKey:@"voices"])assert(![pair[0]isPlaying]&&![pair[1]isPlaying]);
    for(unsigned i=0;i<4;i++){
        [sound stopEffects];assert([sound playStringCue:297 position:.2]);
        NSArray *pair=[[sound valueForKey:@"voices"]lastObject];
        [sound setPaused:YES];assert(![pair[0]isPlaying]&&![pair[1]isPlaying]);
        [sound setPaused:NO];
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.025]];
        assert([pair[0]isPlaying]&&[pair[1]isPlaying]);
    }
    [sound stop];printf("PASS12 Pellet requests at150ms, none dropped, native rate/duration, total call%.3fms, max call%.3fms\n",totalCall*1000,maxCall*1000);
}}
