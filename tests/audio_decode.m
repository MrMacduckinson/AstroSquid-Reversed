#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "audio.h"
#include <assert.h>
int main(int argc,char **argv) { @autoreleasepool {
    assert(argc==2);NSString *path=[NSString stringWithUTF8String:argv[1]];NSError *error=nil;
    AstroAudio *audio=[[AstroAudio alloc] initWithAssets:path error:&error];
    if (!audio) { NSLog(@"Audio initialization failed: %@",error);return 1; }
    NSDictionary *manifest=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"audio.json"]] options:0 error:NULL];
    audio.soundVolume=0.001;
    NSUInteger cues=0;
    for (NSString *name in manifest[@"sounds"]) {
        [audio stop];assert([audio playCue:name position:0.25]);cues++;
    }
    for (int i=1;i<=3;i++) {
        assert([audio playMusic:i]);audio.musicVolume=0;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.15]];
        assert(audio.music.playing && audio.music.currentTime>0);
    }
    [audio setPaused:YES];assert(!audio.music.playing);
    [audio setPaused:NO];assert(audio.music.playing);
    [audio stop];assert(!audio.music);
    printf("PASS: %lu original sound cues decoded and scheduled; all 3 music tracks advanced; pause/resume verified\n",(unsigned long)cues);
} return 0; }
