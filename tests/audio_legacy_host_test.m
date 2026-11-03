#import "../src/audio.h"
#import <OpenAL/al.h>
#import <objc/runtime.h>
#include <assert.h>
#include <unistd.h>
@interface AstroAudio (LegacyTest)
- (BOOL)channelPlaying:(unsigned)index;
@end
static void waitSeconds(double seconds){[[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];}
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);alarm(20);NSError *error=nil;
    AstroAudio *audio=[[AstroAudio alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] beforeMusic:^(AstroAudio *a){a.soundVolume=0;a.musicVolume=0;} error:&error];if(!audio||error)NSLog(@"Legacy init failed: %@",error);assert(audio&&!error);
    NSDictionary *samples=[audio valueForKey:@"samples"];assert(samples.count==18);
    for(NSString *cue in samples){
        ALuint buffer=[[samples objectForKey:cue]unsignedIntValue];ALint size=0,rate=0,bits=0,channels=0;
        alGetBufferi(buffer,AL_SIZE,&size);alGetBufferi(buffer,AL_FREQUENCY,&rate);alGetBufferi(buffer,AL_BITS,&bits);alGetBufferi(buffer,AL_CHANNELS,&channels);
        assert(size>0&&bits==16&&channels==1&&(rate==11025||rate==22050||rate==44100));
        assert([audio playCue:cue]);assert([audio channelPlaying:0]);[audio stopEffects];
    }
    assert(![audio playCue:@"nonexistent"]);
    for(unsigned i=0;i<6;i++)assert([audio playCue:@"Hyper" position:i/5.]);
    assert(![audio playCue:@"Hyper"]);assert(![audio playCueIfNotPlaying:@"Hyper" position:0]);
    [audio setPaused:YES];waitSeconds(.1);for(unsigned i=0;i<6;i++)assert([audio channelPlaying:i]);
    assert(![audio playCue:@"Click"]);[audio setPaused:NO];[audio stopEffects];
    for(unsigned i=0;i<6;i++)assert(![audio channelPlaying:i]);
    for(unsigned i=0;i<100;i++){assert([audio playCue:@"Pellet"]);[audio setPaused:YES];[audio stopEffects];[audio setPaused:NO];assert(![audio channelPlaying:0]);}
    assert([audio playCue:@"Pellet"]);waitSeconds(.6);assert(![audio channelPlaying:0]);
    [audio setPaused:YES];[audio setPaused:NO];assert(![audio channelPlaying:0]);
    assert([audio playMusic:1]);waitSeconds(.1);assert(audio.music.isPlaying);[audio setPaused:YES];assert(!audio.music.isPlaying);[audio setPaused:NO];assert(audio.music.isPlaying);[audio stop];
    // The compiler's libarclite supplies Lion collection subscripting, no custom swizzling.
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];dictionary[@"key"]=@1;assert([dictionary[@"key"]intValue]==1);dictionary[@"key"]=nil;assert(!dictionary.count);
    NSMutableArray *array=[NSMutableArray arrayWithObject:@1];array[0]=@2;array[1]=@3;assert([array[1]intValue]==3);
    puts("PASS legacy audio:18 buffers,6-channel limit,100 stop/pause cycles,completed sound stays stopped,music pause; muted;collection subscripts");
}}
