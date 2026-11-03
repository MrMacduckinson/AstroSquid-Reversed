#import "compat.h"
#import <Foundation/Foundation.h>
#import "compat.h"
#import "music.h"

#import <OpenAL/al.h>
#import <OpenAL/alc.h>
@interface AstroAudio : NSObject {

    ALCdevice *device;ALCcontext *context;ALuint sources[12];
    NSDictionary *manifest;NSMutableDictionary *samples;
    NSString *cueNames[6];float gains[12];NSArray *tracks;
    AstroTigerMusic *_music;BOOL paused,musicStarted;
float _soundVolume;
float _musicVolume;
BOOL _stereo;
}
@property(nonatomic) float soundVolume;
@property(nonatomic) float musicVolume;
@property(nonatomic) BOOL stereo;
@property(nonatomic, readonly) AstroTigerMusic *music;
- (instancetype)initWithAssets:(NSString *)path error:(NSError **)error;
// Callback runs after cues are ready, before any music file is opened.
- (instancetype)initWithAssets:(NSString *)path beforeMusic:(void (^)(AstroAudio *sound))beforeMusic error:(NSError **)error;
- (BOOL)playCue:(NSString *)name;
- (BOOL)playCue:(NSString *)name position:(double)position;
- (BOOL)playCueIfNotPlaying:(NSString *)name position:(double)position;
- (BOOL)playStringCue:(int)index position:(double)position;
- (BOOL)playMusic:(int)track;
- (void)serviceMusic;
- (void)setPaused:(BOOL)paused;
- (void)stopMusic;
- (void)stopEffects;
- (void)stop;
@end
