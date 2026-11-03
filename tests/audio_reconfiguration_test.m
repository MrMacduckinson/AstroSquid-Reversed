#import "../src/audio.h"
#include <assert.h>
#include <unistd.h>
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);alarm(25);NSError *error=nil;
    AstroAudio *audio=[[AstroAudio alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:&error];assert(audio&&!error);
    audio.soundVolume=0;AVAudioEngine *engine=[audio valueForKey:@"effectEngine"];engine.mainMixerNode.outputVolume=0;
    for(unsigned paused=0;paused<2;paused++){
        assert([audio playCue:@"Pellet"]);[audio setPaused:paused];
        // Simulate the documented hardware-change boundary without switching the user's device.
        [engine stop];
        assert(![audio playCue:@"Pellet"]);
        [audio setPaused:!paused];[audio setPaused:paused];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{
            [[NSNotificationCenter defaultCenter]postNotificationName:AVAudioEngineConfigurationChangeNotification object:engine];
        });
        NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:2];
        while(!engine.running&&deadline.timeIntervalSinceNow>0)[[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
        assert(engine.running);assert(![[audio valueForKey:@"voices"]count]);
        if(paused)assert(![audio playCue:@"Pellet"]);
        [audio setPaused:NO];assert([audio playCue:@"Pellet"]);[audio stopEffects];
    }
    [audio stop];puts("PASS background engine-configuration recovery, cleared old voices, preserved pause and subsequent playback (muted)");
}}
