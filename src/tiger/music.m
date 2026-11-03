#import "compat.h"
#import "music.h"
@implementation AstroTigerMusic
- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)error {if((self=[super init])){movie=[[QTMovie alloc]initWithURL:url error:error];if(!movie){[self release];return nil;}}return self;}
- (void)dealloc{[movie release];[super dealloc];}
- (float)volume{return movie.volume;}
- (void)setVolume:(float)value{movie.volume=value;}
- (NSInteger)numberOfLoops{return 0;}
- (void)setNumberOfLoops:(NSInteger)value{[movie setAttribute:[NSNumber numberWithBool:value!=0] forKey:QTMovieLoopsAttribute];}
- (NSTimeInterval)duration{NSTimeInterval value=0;QTGetTimeInterval(movie.duration,&value);return value;}
- (NSTimeInterval)currentTime{NSTimeInterval value=0;QTGetTimeInterval(movie.currentTime,&value);return value;}
- (void)setCurrentTime:(NSTimeInterval)value{movie.currentTime=QTMakeTimeWithTimeInterval(value);}
- (BOOL)isPlaying{return movie.rate!=0;}
- (void)prepareToPlay{}
- (BOOL)play{[movie play];return YES;}
- (void)pause{[movie stop];}
- (void)stop{[movie stop];}
@end
