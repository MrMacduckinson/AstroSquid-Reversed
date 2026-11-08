// Capture actual engine output before a muted sink; no microphone, window or device changes.
#import "../src/audio.h"
#include <assert.h>
#include <math.h>
#include <unistd.h>
static NSArray *envelope(NSData *data,double rate){
    const float *v=data.bytes;NSUInteger n=data.length/sizeof(float);NSMutableArray *r=[NSMutableArray array];
    for(NSUInteger bin=0;bin*rate*.01<n;bin++){
        NSUInteger a=(NSUInteger)(bin*rate*.01),b=MIN(n,(NSUInteger)((bin+1)*rate*.01));double e=0;
        for(NSUInteger j=a;j<b;j++)e+=(double)v[j]*v[j];
        [r addObject:@(sqrt(e/MAX((NSUInteger)1,b-a)))];
    }return r;
}
static double similarity(NSArray *reference,NSArray *actual){
    double best=0;
    for(NSUInteger offset=0;offset+reference.count<=actual.count;offset++){
        double dot=0,a=0,b=0;
        for(NSUInteger i=0;i<reference.count;i++){double x=[reference[i]doubleValue],y=[actual[offset+i]doubleValue];dot+=x*y;a+=x*x;b+=y*y;}
        if(a>0&&b>0)best=MAX(best,dot/sqrt(a*b));
    }return best;
}
int main(int argc,char **argv){@autoreleasepool{
    assert(argc==2);alarm(30);NSString *assets=[NSString stringWithUTF8String:argv[1]];NSError *error=nil;
    __block AVAudioEngine *engine;__block AVAudioMixerNode *source,*silent;__block AVAudioFormat *format;
    NSMutableData *left=[NSMutableData data],*right=[NSMutableData data];
    AVAudioNodeTapBlock capture=^(AVAudioPCMBuffer *pcm,AVAudioTime *time){
        assert(!pcm.format.interleaved&&pcm.format.commonFormat==AVAudioPCMFormatFloat32);
        @synchronized(left){[left appendBytes:pcm.floatChannelData[0] length:pcm.frameLength*sizeof(float)];[right appendBytes:pcm.floatChannelData[1] length:pcm.frameLength*sizeof(float)];}
    };
    AstroAudio *audio=[[AstroAudio alloc]initWithAssets:assets beforeMusic:^(AstroAudio *sound){
        engine=[sound valueForKey:@"effectEngine"];source=engine.mainMixerNode;
        silent=[AVAudioMixerNode new];[engine attachNode:silent];
        format=[source outputFormatForBus:0];assert(format.channelCount==2);
        [engine disconnectNodeOutput:source];[engine connect:source to:silent format:format];[engine connect:silent to:engine.outputNode format:format];silent.outputVolume=0;
        [source installTapOnBus:0 bufferSize:1024 format:format block:capture];
    } error:&error];assert(audio&&!error&&engine.running);audio.soundVolume=.3;
    for(unsigned recovery=0;recovery<2;recovery++){
    if(recovery){
        [engine stop];[source removeTapOnBus:0];
        // Reproduce a route format change without changing the actual hardware device.
        [engine disconnectNodeOutput:source];[engine disconnectNodeOutput:silent];
        format=[[AVAudioFormat alloc]initStandardFormatWithSampleRate:format.sampleRate==44100?48000:44100 channels:2];
        [engine connect:source to:silent format:format];[engine connect:silent to:engine.outputNode format:format];
        [source installTapOnBus:0 bufferSize:1024 format:format block:capture];
        [[NSNotificationCenter defaultCenter]postNotificationName:AVAudioEngineConfigurationChangeNotification object:engine];
        NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:2];
        while(!engine.running&&deadline.timeIntervalSinceNow>0)[[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
        assert(engine.running);
    }
    for(NSString *cue in (recovery ? @[@"Click",@"Pellet",@"Laser",@"Bang1",@"Hyper"] : @[@"Pellet",@"Laser",@"Bang1",@"Hyper"])){
        [audio stopEffects];[[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.3]];
        AVAudioFile *file=[[AVAudioFile alloc]initForReading:[NSURL fileURLWithPath:[[assets stringByAppendingPathComponent:@"sounds"]stringByAppendingPathComponent:[cue stringByAppendingString:@".wav"]]] error:&error];assert(file);
        AVAudioPCMBuffer *original=[[AVAudioPCMBuffer alloc]initWithPCMFormat:file.processingFormat frameCapacity:(AVAudioFrameCount)file.length];assert([file readIntoBuffer:original error:&error]);
        NSData *pcm=[NSData dataWithBytes:original.floatChannelData[0] length:original.frameLength*sizeof(float)];NSArray *expected=envelope(pcm,original.format.sampleRate);
        double duration=original.frameLength/original.format.sampleRate;
        @synchronized(left){left.length=right.length=0;}
        assert([audio playCue:cue]);[[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration+.7]];
        NSData *l,*r;@synchronized(left){l=[left copy];r=[right copy];}
        double peak=0;
        for(NSData *channel in @[l,r]) {
            const float *values=channel.bytes;
            for(NSUInteger i=0;i<channel.length/sizeof(float);i++) {
                assert(isfinite(values[i]));peak=MAX(peak,fabs(values[i]));
            }
        }
        // A single full-scale transient can hide inside an otherwise matching envelope.
        double sourcePeak=0;const float *raw=pcm.bytes;for(NSUInteger i=0;i<pcm.length/sizeof(float);i++)sourcePeak=MAX(sourcePeak,fabs(raw[i]));
        printf("%s captured peak %.5f source peak %.5f\n",cue.UTF8String,peak,sourcePeak);fflush(stdout);
        // The two mono voices can sum at the mixer; allow resampling overshoot,
        // but not a first-use burst at the nodes' default unity volume.
        assert(peak<=sourcePeak*2*(76.0/255)*1.2+.01);
        double matchL=similarity(expected,envelope(l,format.sampleRate)),matchR=similarity(expected,envelope(r,format.sampleRate));
        printf("recovery%u %s duration%.3fs envelope L%.5f R%.5f\n",recovery,cue.UTF8String,duration,matchL,matchR);fflush(stdout);
        assert(matchL>.9&&matchR>.9);
    }
    }
    [audio stop];[source removeTapOnBus:0];[engine stop];
    puts("PASS full original sound envelopes at11025/22050/44100Hz reach both output channels (hardware sink muted)");
}}
