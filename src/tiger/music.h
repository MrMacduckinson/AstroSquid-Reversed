#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
@interface AstroTigerMusic:NSObject { QTMovie *movie; }
@property float volume;
@property NSInteger numberOfLoops;
@property NSTimeInterval currentTime;
@property(readonly) NSTimeInterval duration;
@property(readonly,getter=isPlaying) BOOL playing;
- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)error;
- (void)prepareToPlay;
- (BOOL)play;
- (void)pause;
- (void)stop;
@end
