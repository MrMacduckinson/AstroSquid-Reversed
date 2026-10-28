#import "audio.h"
#include <math.h>

@implementation AstroAudio {
    NSDictionary *manifest;
    NSMutableDictionary *samples;
    NSArray *tracks;
    NSMutableArray *voices;
    NSMapTable *cueNames;
    AVAudioPlayer *_music;
    BOOL paused;
}
@synthesize music = _music;
- (instancetype)initWithAssets:(NSString *)path error:(NSError **)error {
    return [self initWithAssets:path beforeMusic:nil error:error];
}
- (instancetype)initWithAssets:(NSString *)path beforeMusic:(void (^)(AstroAudio *sound))beforeMusic error:(NSError **)error {
    self=[super init]; if (!self) return nil;
    NSData *data=[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"audio.json"] options:0 error:error];
    if (!data) return nil;
    manifest=[NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![manifest isKindOfClass:[NSDictionary class]]) return nil;
    samples=[NSMutableDictionary dictionary]; voices=[NSMutableArray array];
    cueNames=[NSMapTable weakToStrongObjectsMapTable];
    _soundVolume=1; _musicVolume=0.5; _stereo=YES;
    for (NSString *name in manifest[@"sounds"]) {
        NSString *file=manifest[@"sounds"][name][@"file"];
        NSData *sample=[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:file] options:0 error:error];
        if (!sample) return nil;
        // Validate every cue at load time, before a missing decoder can silence combat.
        AVAudioPlayer *probe=[[AVAudioPlayer alloc] initWithData:sample error:error];
        if (!probe || probe.duration<=0) return nil;
        samples[name]=sample;
    }
    if(beforeMusic)beforeMusic(self);
    NSMutableArray *musicTracks=[NSMutableArray array];
    for (int i=1;i<=3;i++) {
        NSString *file=manifest[@"music"][[NSString stringWithFormat:@"%d",i]][@"file"];
        AVAudioPlayer *player=[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:file]] error:error];
        if (!player || player.duration<=0) return nil;
        player.numberOfLoops=-1;player.volume=_musicVolume;
        [player prepareToPlay];[musicTracks addObject:player];
    }
    tracks=[musicTracks copy];return self;
}
- (void)setSoundVolume:(float)value { _soundVolume=fmaxf(0,fminf(1,value)); }
- (void)setMusicVolume:(float)value {
    _musicVolume=fmaxf(0,fminf(1,value));
    for (AVAudioPlayer *player in tracks) player.volume=_musicVolume;
}
- (BOOL)playCue:(NSString *)name { return [self playCue:name position:NAN]; }
- (BOOL)playCue:(NSString *)name position:(double)position {
    if (!samples[name] || paused || _soundVolume<=0) return NO;
    NSIndexSet *finished=[voices indexesOfObjectsPassingTest:^BOOL(NSArray *pair,NSUInteger i,BOOL *stop) {
        return ![pair[0] isPlaying] && ![pair[1] isPlaying];
    }];
    [voices removeObjectsAtIndexes:finished];
    // GETAFREECHANNEL checks channels 1 through 6 and drops a cue when all are busy.
    if (voices.count>=6) return NO;
    AVAudioPlayer *left=[[AVAudioPlayer alloc] initWithData:samples[name] error:NULL];
    AVAudioPlayer *right=[[AVAudioPlayer alloc] initWithData:samples[name] error:NULL];
    if (!left || !right) return NO;
    left.pan=-1;right.pan=1;
    double p=fmax(0,fmin(1,position));
    BOOL pan=_stereo && isfinite(position);
    left.volume=_soundVolume*(pan?floor(sqrt(1-p)*256)/256:1);
    right.volume=_soundVolume*(pan?floor(sqrt(p)*256)/256:1);
    [left prepareToPlay];[right prepareToPlay];
    NSTimeInterval time=left.deviceCurrentTime+0.005;
    BOOL ok=[left playAtTime:time] && [right playAtTime:time];
    if (!ok) { [left stop];[right stop];return NO; }
    [cueNames setObject:name forKey:left];
    [voices addObject:@[left,right]];return YES;
}
- (BOOL)playCueIfNotPlaying:(NSString *)name position:(double)position {
    for (NSArray *pair in voices) {
        if ([[cueNames objectForKey:pair[0]] isEqual:name] &&
            ([pair[0] isPlaying] || [pair[1] isPlaying])) return NO;
    }
    return [self playCue:name position:position];
}
- (BOOL)playStringCue:(int)index position:(double)position {
    NSString *name=manifest[@"string_cues"][[NSString stringWithFormat:@"%d",index]];
    return name && [self playCue:name position:position];
}
- (BOOL)playMusic:(int)track {
    if (track<1 || track>(int)tracks.count) return NO;
    AVAudioPlayer *next=tracks[track-1];
    if (_music==next) return YES;
    [_music stop]; _music=next;_music.currentTime=0;
    return paused || [_music play];
}
- (void)setPaused:(BOOL)value {
    if (paused==value) return;paused=value;
    for (NSArray *pair in voices) for (AVAudioPlayer *player in pair) {
        if (value) [player pause]; else [player play];
    }
    if (value) [_music pause]; else [_music play];
}
- (void)stopMusic {
    [_music stop];_music=nil;
}
- (void)stopEffects {
    for (NSArray *pair in voices) for (AVAudioPlayer *player in pair) [player stop];
    [voices removeAllObjects];
}
- (void)stop {[self stopMusic];[self stopEffects];}
@end
