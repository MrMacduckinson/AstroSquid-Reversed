// Source-backed PLAYTRACK10031edc identity gate; fake decoder, no sound output.
#import "../src/audio.h"
#include <assert.h>

@interface MusicProbe : NSObject
@property NSTimeInterval currentTime;
@property(getter=isPlaying) BOOL playing;
@property unsigned starts,stops,pauses;
- (BOOL)play;
- (void)stop;
- (void)pause;
@end
@implementation MusicProbe
- (BOOL)play {self.starts++;self.playing=YES;return YES;}
- (void)stop {self.stops++;self.playing=NO;}
- (void)pause {self.pauses++;self.playing=NO;}
@end

int main(void) {@autoreleasepool {
    AstroAudio *audio=[[AstroAudio alloc] init];
    MusicProbe *first=[MusicProbe new],*second=[MusicProbe new];
    [audio setValue:@[first,second] forKey:@"tracks"];
    assert([audio playMusic:1]&&first.starts==1&&first.currentTime==0);
    first.currentTime=7;
    assert([audio playMusic:1]&&first.starts==1&&first.currentTime==7);
    first.playing=NO;
    assert([audio playMusic:1]&&first.starts==1&&first.stops==0&&first.currentTime==7);
    assert(![audio playMusic:0]&&![audio playMusic:3]&&first.starts==1&&first.currentTime==7);
    [audio setPaused:YES];
    assert(first.pauses==1&&[audio playMusic:1]&&first.starts==1&&first.currentTime==7);
    assert([audio playMusic:2]&&first.stops==1&&second.starts==0&&second.currentTime==0);
    [audio setPaused:NO];assert(second.starts==1);
    second.currentTime=9;
    [audio stop];assert(second.stops==1&&audio.music==nil);
    assert([audio playMusic:2]&&second.starts==2&&second.currentTime==0);
    assert([audio playMusic:1]&&second.stops==2&&first.starts==2&&first.currentTime==0);
    MusicProbe *effect=[MusicProbe new];effect.playing=YES;
    [audio setValue:[NSMutableArray arrayWithObject:@[effect,effect]] forKey:@"voices"];
    [audio stopMusic];assert(audio.music==nil&&first.stops==2&&effect.stops==0&&effect.playing);
    [audio stop];assert(effect.stops==2&&!effect.playing);
    puts("PASS PLAYTRACK selected-track identity: playing/stopped/paused no-op, invalid IDs, switch and explicit stop/restart");
}}
