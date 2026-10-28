#import "../src/audio.h"
#include <assert.h>
#include <stdint.h>

@interface ServicePlayer : NSObject
@property NSTimeInterval currentTime;
@property unsigned starts;
@property(getter=isPlaying) BOOL playing;
@property BOOL fail;
- (BOOL)play;
- (void)stop;
- (void)pause;
@end
@implementation ServicePlayer
- (BOOL)play {self.starts++;self.playing=!self.fail;return self.playing;}
- (void)stop {self.playing=NO;}
- (void)pause {self.playing=NO;}
@end

int main(void){@autoreleasepool{
    AstroAudio *audio=[AstroAudio new];ServicePlayer *one=[ServicePlayer new],*two=[ServicePlayer new];
    [audio setValue:@[one,two] forKey:@"tracks"];
    [audio serviceMusic];assert([audio playMusic:1]);one.currentTime=7;
    [audio serviceMusic];assert(one.starts==1&&one.currentTime==7);
    one.playing=NO;assert([audio playMusic:1]&&one.starts==1&&one.currentTime==7);
    [audio serviceMusic];assert(one.starts==2&&one.currentTime==0);
    [audio serviceMusic];assert(one.starts==2);
    one.playing=NO;[audio playMusic:2];[audio serviceMusic];assert(two.starts==1);
    [audio stopMusic];[audio serviceMusic];assert(two.starts==1&&audio.music==nil);
    one.fail=YES;assert(![audio playMusic:1]);unsigned starts=one.starts;
    [audio serviceMusic];assert(one.starts==starts);[audio stopMusic];one.fail=NO;
    [audio playMusic:1];[audio setPaused:YES];starts=one.starts;[audio serviceMusic];assert(one.starts==starts);
    [audio setPaused:NO];assert(one.starts==starts+1);[audio serviceMusic];assert(one.starts==starts+1);
    one.playing=NO;one.fail=YES;[audio serviceMusic];starts=one.starts;
    [audio serviceMusic];assert(one.starts==starts);[audio stopMusic];

    // A real silent decoder must finish once and remain stopped until serviced.
    NSMutableData *wav=[NSMutableData dataWithLength:44+4410*2];unsigned char *b=wav.mutableBytes;
    memcpy(b,"RIFF",4);uint32_t size=(uint32_t)wav.length-8;memcpy(b+4,&size,4);
    memcpy(b+8,"WAVEfmt ",8);uint32_t fmt=16,rate=44100,bytes=88200,data=8820;
    uint16_t pcm=1,channels=1,align=2,bits=16;
    memcpy(b+16,&fmt,4);memcpy(b+20,&pcm,2);memcpy(b+22,&channels,2);memcpy(b+24,&rate,4);
    memcpy(b+28,&bytes,4);memcpy(b+32,&align,2);memcpy(b+34,&bits,2);memcpy(b+36,"data",4);memcpy(b+40,&data,4);
    AVAudioPlayer *real=[[AVAudioPlayer alloc]initWithData:wav error:NULL];assert(real);
    real.numberOfLoops=0;real.volume=0;[audio setValue:@[real] forKey:@"tracks"];
    assert([audio playMusic:1]);NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:3];
    while(real.playing&&deadline.timeIntervalSinceNow>0)[NSThread sleepForTimeInterval:.01];
    assert(!real.playing&&audio.music==real);
    [NSThread sleepForTimeInterval:.2];assert(!real.playing);
    [audio serviceMusic];assert(real.playing);
    [audio stop];puts("PASS serviced music completion: deferred single repeat, selected identity, switch/stop/pause and failed start, real silent decoder completion/restart without run-loop callbacks");
}}
