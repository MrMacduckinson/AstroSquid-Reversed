// Separate Lion backend: preloaded OpenAL effects, AVAudioPlayer music (10.7).
#import "audio.h"
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>
#include <math.h>
#include <limits.h>

static float soundGain(float value){return (int)(255*(double)value)/255.0f;}
static float musicGain(float value){return MIN(126,(int)(value*128))/256.0f;}
static BOOL fail(NSError **error,NSInteger code){
    if(error)*error=[NSError errorWithDomain:@"AstroSquidLegacyAudio" code:code userInfo:nil];return NO;
}
static ALuint loadSample(NSString *path,NSError **error){
    ExtAudioFileRef file=NULL;OSStatus status=ExtAudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:path],&file);
    if(status){fail(error,status);return 0;}
    AudioStreamBasicDescription source={0};UInt32 size=sizeof(source);
    status=ExtAudioFileGetProperty(file,kExtAudioFileProperty_FileDataFormat,&size,&source);
    SInt64 frames=0;size=sizeof(frames);
    if(!status)status=ExtAudioFileGetProperty(file,kExtAudioFileProperty_FileLengthFrames,&size,&frames);
    if(status||source.mChannelsPerFrame!=1||frames<=0||frames>INT_MAX/2){ExtAudioFileDispose(file);fail(error,status?status:-1);return 0;}
    AudioStreamBasicDescription format={source.mSampleRate,kAudioFormatLinearPCM,kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked,2,1,2,1,16,0};
    status=ExtAudioFileSetProperty(file,kExtAudioFileProperty_ClientDataFormat,sizeof(format),&format);
    NSMutableData *pcm=[NSMutableData dataWithLength:(NSUInteger)frames*2];
    UInt32 total=0;
    while(!status&&total<(UInt32)frames){
        UInt32 count=(UInt32)frames-total;
        AudioBufferList buffers={1,{{1,count*2,(char *)pcm.mutableBytes+total*2}}};
        status=ExtAudioFileRead(file,&count,&buffers);if(!count)break;total+=count;
    }
    ExtAudioFileDispose(file);
    if(status||total!=frames){fail(error,status?status:-2);return 0;}
    ALuint buffer=0;alGenBuffers(1,&buffer);alBufferData(buffer,AL_FORMAT_MONO16,pcm.bytes,(ALsizei)pcm.length,(ALsizei)source.mSampleRate);
    ALenum result=alGetError();if(result!=AL_NO_ERROR){if(buffer)alDeleteBuffers(1,&buffer);fail(error,result);return 0;}return buffer;
}
@implementation AstroAudio {
    ALCdevice *device;ALCcontext *context;ALuint sources[12];
    NSDictionary *manifest;NSMutableDictionary *samples;
    NSString *cueNames[6];float gains[12];NSArray *tracks;
    AVAudioPlayer *_music;BOOL paused,musicStarted;
}
@synthesize music=_music;
- (instancetype)initWithAssets:(NSString *)path error:(NSError **)error{return [self initWithAssets:path beforeMusic:nil error:error];}
- (instancetype)initWithAssets:(NSString *)path beforeMusic:(void (^)(AstroAudio *))beforeMusic error:(NSError **)error{
    if(!(self=[super init]))return nil;
    NSData *data=[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"audio.json"] options:0 error:error];
    if(!data)return nil;manifest=[NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if(![manifest isKindOfClass:[NSDictionary class]]){fail(error,-3);return nil;}
    device=alcOpenDevice(NULL);if(!device){fail(error,-4);return nil;}
    context=alcCreateContext(device,NULL);if(!context||!alcMakeContextCurrent(context)){fail(error,-5);return nil;}
    _soundVolume=_musicVolume=1;_stereo=YES;samples=[NSMutableDictionary dictionary];
    alDistanceModel(AL_NONE);alGenSources(12,sources);
    if(alGetError()!=AL_NO_ERROR){fail(error,-6);return nil;}
    for(unsigned i=0;i<12;i++){
        alSourcei(sources[i],AL_SOURCE_RELATIVE,AL_TRUE);alSource3f(sources[i],AL_POSITION,i%2?1:-1,0,0);
        alSourcef(sources[i],AL_ROLLOFF_FACTOR,0);
    }
    for(NSString *name in [manifest objectForKey:@"sounds"]){
        NSString *file=[[[manifest objectForKey:@"sounds"]objectForKey:name]objectForKey:@"file"];
        ALuint buffer=loadSample([path stringByAppendingPathComponent:file],error);if(!buffer)return nil;
        [samples setObject:@(buffer) forKey:name];
    }
    if(beforeMusic)beforeMusic(self);
    NSMutableArray *music=[NSMutableArray array];
    for(unsigned i=1;i<=3;i++){
        NSString *file=[[[manifest objectForKey:@"music"]objectForKey:[NSString stringWithFormat:@"%u",i]]objectForKey:@"file"];
        AVAudioPlayer *player=[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:file]] error:error];
        if(!player||player.duration<=0)return nil;
        player.numberOfLoops=0;player.volume=i<=2?musicGain(_musicVolume):126/256.0f;[player prepareToPlay];[music addObject:player];
    }
    tracks=[music copy];return self;
}
- (void)dealloc{
    if(context){alcMakeContextCurrent(context);alSourceStopv(12,sources);alDeleteSources(12,sources);
        for(NSNumber *value in samples.allValues){ALuint buffer=value.unsignedIntValue;alDeleteBuffers(1,&buffer);}
        alcMakeContextCurrent(NULL);alcDestroyContext(context);}
    if(device)alcCloseDevice(device);
}
- (BOOL)channelPlaying:(unsigned)index{
    for(unsigned i=2*index;i<2*index+2;i++){ALint state=0;alGetSourcei(sources[i],AL_SOURCE_STATE,&state);if(state==AL_PLAYING||state==AL_PAUSED)return YES;}return NO;
}
- (void)setSoundVolume:(float)value{
    _soundVolume=fmaxf(0,fminf(1,value));if(!context)return;alcMakeContextCurrent(context);
    for(unsigned i=0;i<12;i++)alSourcef(sources[i],AL_GAIN,soundGain(_soundVolume)*gains[i]);
}
- (void)setMusicVolume:(float)value{
    _musicVolume=fmaxf(0,fminf(1,value));
    for(NSUInteger i=0;i<MIN((NSUInteger)2,tracks.count);i++)[(AVAudioPlayer *)[tracks objectAtIndex:i]setVolume:musicGain(_musicVolume)];
}
- (BOOL)playCue:(NSString *)name{return [self playCue:name position:NAN];}
- (BOOL)playCue:(NSString *)name position:(double)position{
    NSNumber *buffer=[samples objectForKey:name];if(!buffer||paused)return NO;alcMakeContextCurrent(context);
    unsigned slot=0;while(slot<6&&[self channelPlaying:slot])slot++;if(slot==6)return NO;
    double p=fmax(0,fmin(1,position));BOOL pan=_stereo&&isfinite(position);
    gains[2*slot]=pan?floor(sqrt(1-p)*256)/256:1;gains[2*slot+1]=pan?floor(sqrt(p)*256)/256:1;
    alSourceStopv(2,sources+2*slot);
    for(unsigned i=2*slot;i<2*slot+2;i++){
        alSourcei(sources[i],AL_BUFFER,buffer.unsignedIntValue);alSourcef(sources[i],AL_GAIN,soundGain(_soundVolume)*gains[i]);
    }
    alSourcePlayv(2,sources+2*slot);if(alGetError()!=AL_NO_ERROR){alSourceStopv(2,sources+2*slot);return NO;}
    cueNames[slot]=name;return YES;
}
- (BOOL)playCueIfNotPlaying:(NSString *)name position:(double)position{
    alcMakeContextCurrent(context);for(unsigned i=0;i<6;i++)if([cueNames[i]isEqual:name]&&[self channelPlaying:i])return NO;
    return [self playCue:name position:position];
}
- (BOOL)playStringCue:(int)index position:(double)position{
    NSString *name=[[manifest objectForKey:@"string_cues"]objectForKey:[NSString stringWithFormat:@"%d",index]];
    return name&&[self playCue:name position:position];
}
- (BOOL)playMusic:(int)track{
    if(track<1||track>(int)tracks.count)return NO;AVAudioPlayer *next=[tracks objectAtIndex:track-1];if(_music==next)return YES;
    [_music stop];_music=next;musicStarted=NO;_music.currentTime=0;if(paused)return YES;musicStarted=[_music play];return musicStarted;
}
- (void)serviceMusic{
    if(!musicStarted||paused||_music.isPlaying)return;[_music stop];_music.currentTime=0;musicStarted=[_music play];
}
- (void)setPaused:(BOOL)value{
    if(paused==value)return;paused=value;alcMakeContextCurrent(context);
    for(unsigned i=0;i<12;i++){ALint state=0;alGetSourcei(sources[i],AL_SOURCE_STATE,&state);
        if(value&&state==AL_PLAYING)alSourcePause(sources[i]);else if(!value&&state==AL_PAUSED)alSourcePlay(sources[i]);}
    if(value)[_music pause];else musicStarted=[_music play];
}
- (void)stopMusic{[_music stop];_music=nil;musicStarted=NO;}
- (void)stopEffects{alcMakeContextCurrent(context);alSourceStopv(12,sources);for(unsigned i=0;i<6;i++)cueNames[i]=nil;}
- (void)stop{[self stopMusic];[self stopEffects];}
@end
