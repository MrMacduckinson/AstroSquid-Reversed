#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AstroAudio : NSObject
@property(nonatomic) float soundVolume;
@property(nonatomic) float musicVolume;
@property(nonatomic) BOOL stereo;
@property(nonatomic, readonly) AVAudioPlayer *music;
- (instancetype)initWithAssets:(NSString *)path error:(NSError **)error;
// Callback runs after cues are ready, before any music file is opened.
- (instancetype)initWithAssets:(NSString *)path beforeMusic:(void (^)(AstroAudio *sound))beforeMusic error:(NSError **)error;
- (BOOL)playCue:(NSString *)name;
- (BOOL)playCue:(NSString *)name position:(double)position;
- (BOOL)playCueIfNotPlaying:(NSString *)name position:(double)position;
- (BOOL)playStringCue:(int)index position:(double)position;
- (BOOL)playMusic:(int)track;
- (void)setPaused:(BOOL)paused;
- (void)stopMusic;
- (void)stopEffects;
- (void)stop;
@end
