#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AstroAudio : NSObject
@property(nonatomic) float soundVolume;
@property(nonatomic) float musicVolume;
@property(nonatomic) BOOL stereo;
@property(nonatomic, readonly) AVAudioPlayer *music;
- (instancetype)initWithAssets:(NSString *)path error:(NSError **)error;
- (BOOL)playCue:(NSString *)name;
- (BOOL)playCue:(NSString *)name position:(double)position;
- (BOOL)playStringCue:(int)index position:(double)position;
- (BOOL)playMusic:(int)track;
- (void)setPaused:(BOOL)paused;
- (void)stop;
@end
