#import "audio.h"
#include <math.h>
#include <stdatomic.h>
#include <assert.h>
#include <mach/mach_time.h>

static float soundGain(float value){return (int)(255*(double)value)/255.0f;}

static float musicGain(float value){return MIN(126,(int)(value*128))/256.0f;}

// Each effect stays on a running mixer; starting AVAudioPlayer per shot blocks the game clock.
@interface AstroCuePlayer : NSObject {
    AVAudioPlayerNode *node;AVAudioPCMBuffer *buffer;
    atomic_uint activeTicket;unsigned nextTicket;
}
@property(nonatomic) float volume,pan;
@property(nonatomic,readonly,getter=isPlaying) BOOL playing;
@property(nonatomic,readonly) double deviceCurrentTime;
@property(nonatomic,readonly) NSTimeInterval outputLatency;
- (instancetype)initWithEngine:(AVAudioEngine *)engine buffer:(AVAudioPCMBuffer *)pcm;
- (BOOL)playAtTime:(NSTimeInterval)time outputLatency:(NSTimeInterval)latency;
- (BOOL)play;
- (void)prepare;
- (void)pause;
- (void)stop;
@end
@implementation AstroCuePlayer
- (instancetype)initWithEngine:(AVAudioEngine *)engine buffer:(AVAudioPCMBuffer *)pcm {
    if((self=[super init])){buffer=pcm;node=[AVAudioPlayerNode new];atomic_init(&activeTicket,0);
        [engine attachNode:node];[engine connect:node to:engine.mainMixerNode format:pcm.format];}
    return self;
}
- (float)volume{return node.volume;}
- (void)setVolume:(float)value{node.volume=value;}
- (float)pan{return node.pan;}
- (void)setPan:(float)value{node.pan=value;}
- (BOOL)isPlaying{return atomic_load(&activeTicket)!=0&&node.isPlaying;}
- (double)deviceCurrentTime{return [AVAudioTime secondsForHostTime:mach_absolute_time()];}
- (NSTimeInterval)outputLatency{return node.outputPresentationLatency;}
- (BOOL)playAtTime:(NSTimeInterval)time outputLatency:(NSTimeInterval)latency {
    unsigned ticket=++nextTicket;assert(ticket);atomic_store(&activeTicket,ticket);
    uint64_t scheduledHost=[AVAudioTime hostTimeForSeconds:time];
    [node scheduleBuffer:buffer atTime:[AVAudioTime timeWithHostTime:scheduledHost] options:0
        // DataPlayedBack deadlocks against stop on 10.13; retain its output-latency wait outside AVFAudio locks.
        completionCallbackType:AVAudioPlayerNodeCompletionDataRendered completionHandler:^(AVAudioPlayerNodeCompletionCallbackType type){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(latency*NSEC_PER_SEC)),dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{
                unsigned expected=ticket;atomic_compare_exchange_strong(&self->activeTicket,&expected,0);
            });
        }];
    if(!node.isPlaying)[node play];return YES;
}
- (BOOL)play{if(!atomic_load(&activeTicket))return NO;[node play];return YES;}
- (void)prepare{[node play];}
- (void)pause{[node pause];}
- (void)stop{atomic_store(&activeTicket,0);[node stop];}
@end
static NSArray *preparedCue(AVAudioPCMBuffer *buffer,AVAudioEngine *engine){
    AstroCuePlayer *left=[[AstroCuePlayer alloc]initWithEngine:engine buffer:buffer];
    AstroCuePlayer *right=[[AstroCuePlayer alloc]initWithEngine:engine buffer:buffer];
    left.pan=-1;right.pan=1;return @[left,right];
}

@implementation AstroAudio {
    NSDictionary *manifest;
    NSMutableDictionary *samples;
    NSArray *tracks;
    NSMutableArray *voices;
    NSMutableDictionary *idleVoices;
    AVAudioEngine *effectEngine;
    NSMapTable *cueNames,*voiceGains;
    AVAudioPlayer *_music;
    BOOL paused;
    BOOL musicStarted;
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
    samples=[NSMutableDictionary dictionary]; voices=[NSMutableArray array];idleVoices=[NSMutableDictionary dictionary];
    cueNames=[NSMapTable weakToStrongObjectsMapTable];voiceGains=[NSMapTable weakToStrongObjectsMapTable];
    _soundVolume=1; _musicVolume=1; _stereo=YES;effectEngine=[AVAudioEngine new];
    for (NSString *name in manifest[@"sounds"]) {
        NSString *file=manifest[@"sounds"][name][@"file"];
        AVAudioFile *fileData=[[AVAudioFile alloc]initForReading:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:file]] error:error];
        if(!fileData||fileData.length<=0||fileData.length>UINT32_MAX)return nil;
        AVAudioPCMBuffer *sample=[[AVAudioPCMBuffer alloc]initWithPCMFormat:fileData.processingFormat frameCapacity:(AVAudioFrameCount)fileData.length];
        if(!sample||![fileData readIntoBuffer:sample error:error])return nil;
        NSMutableArray *idle=[NSMutableArray array];
        // Any of the six logical channels may overlap this cue; never attach nodes during combat.
        for(unsigned i=0;i<6;i++)[idle addObject:preparedCue(sample,effectEngine)];
        idleVoices[name]=idle;samples[name]=sample;
    }
    if(beforeMusic)beforeMusic(self);
    NSMutableArray *musicTracks=[NSMutableArray array];
    for (int i=1;i<=3;i++) {
        NSString *file=manifest[@"music"][[NSString stringWithFormat:@"%d",i]][@"file"];
        AVAudioPlayer *player=[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:file]] error:error];
        if (!player || player.duration<=0) return nil;
        player.numberOfLoops=0;player.volume=i<=2?musicGain(_musicVolume):126/256.0f;
        [player prepareToPlay];[musicTracks addObject:player];
    }
    tracks=[musicTracks copy];[effectEngine prepare];
    if(![effectEngine startAndReturnError:error])return nil;
    for(NSArray *idle in idleVoices.allValues)for(NSArray *pair in idle)for(AstroCuePlayer *player in pair)[player prepare];
    return self;
}
- (void)setSoundVolume:(float)value {
    _soundVolume=fmaxf(0,fminf(1,value));
    for(NSArray *pair in voices)for(AstroCuePlayer *player in pair)
        player.volume=soundGain(_soundVolume)*[[voiceGains objectForKey:player] doubleValue];
}
- (void)setMusicVolume:(float)value {
    _musicVolume=fmaxf(0,fminf(1,value));
    // Original settings update Music1/2; Music3 retains MIDWorld default volume.
    for(NSUInteger i=0;i<MIN((NSUInteger)2,tracks.count);i++)[(AVAudioPlayer *)tracks[i] setVolume:musicGain(_musicVolume)];
}
- (BOOL)playCue:(NSString *)name { return [self playCue:name position:NAN]; }
- (BOOL)playCue:(NSString *)name position:(double)position {
    if (!samples[name] || paused) return NO;
    NSIndexSet *finished=[voices indexesOfObjectsPassingTest:^BOOL(NSArray *pair,NSUInteger i,BOOL *stop) {
        return ![pair[0] isPlaying] && ![pair[1] isPlaying];
    }];
    [finished enumerateIndexesUsingBlock:^(NSUInteger i,BOOL *stop){
        NSArray *pair=voices[i];NSString *cue=[cueNames objectForKey:pair[0]];
        [idleVoices[cue] addObject:pair];
    }];
    [voices removeObjectsAtIndexes:finished];
    // GETAFREECHANNEL checks channels 1 through 6 and drops a cue when all are busy.
    if (voices.count>=6) return NO;
    NSMutableArray *idle=idleVoices[name];NSArray *pair=idle.lastObject;
    if(!pair)return NO;
    [idle removeLastObject];
    AstroCuePlayer *left=pair[0],*right=pair[1];
    double p=fmax(0,fmin(1,position));
    BOOL pan=_stereo && isfinite(position);
    double leftGain=pan?floor(sqrt(1-p)*256)/256:1,rightGain=pan?floor(sqrt(p)*256)/256:1;
    left.volume=soundGain(_soundVolume)*leftGain;right.volume=soundGain(_soundVolume)*rightGain;
    NSTimeInterval latency=left.outputLatency;
    NSTimeInterval time=left.deviceCurrentTime+0.005;
    BOOL ok=[left playAtTime:time outputLatency:latency] && [right playAtTime:time outputLatency:latency];
    if (!ok) { [left stop];[right stop];return NO; }
    [voiceGains setObject:@(leftGain) forKey:left];[voiceGains setObject:@(rightGain) forKey:right];
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
    [_music stop]; _music=next;musicStarted=NO;_music.currentTime=0;
    if(paused)return YES;
    musicStarted=[_music play];return musicStarted;
}
- (void)serviceMusic {
    if(!musicStarted||paused||_music.isPlaying)return;
    // Original infinite repeat rewinds only when SERVICEMUSIC observes completion.
    [_music stop];_music.currentTime=0;musicStarted=[_music play];
}
- (void)setPaused:(BOOL)value {
    if (paused==value) return;paused=value;
    for (NSArray *pair in voices) for (AVAudioPlayer *player in pair) {
        if (value) [player pause]; else [player play];
    }
    if (value) [_music pause]; else musicStarted=[_music play];
}
- (void)stopMusic {
    [_music stop];_music=nil;musicStarted=NO;
}
- (void)stopEffects {
    for (NSArray *pair in voices) {
        for (AVAudioPlayer *player in pair) [player stop];
        [idleVoices[[cueNames objectForKey:pair[0]]] addObject:pair];
    }
    [voices removeAllObjects];
}
- (void)stop {[self stopMusic];[self stopEffects];}
@end
