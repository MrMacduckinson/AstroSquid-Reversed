#import "../src/audio.h"
#include <assert.h>
#include <math.h>
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);NSError *error=nil;AstroAudio *audio=[[AstroAudio alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:&error];assert(audio);
 NSArray *tracks=[audio valueForKey:@"tracks"];assert(tracks.count==3&&audio.musicVolume==1);
 for(AVAudioPlayer *track in tracks)assert(track.volume==126/256.0f);
 const int native[]={0,12,25,38,51,64,76,89,102,115,126};
 for(int level=0;level<=10;level++){audio.musicVolume=level/10.0f;assert(fabsf(audio.musicVolume-level/10.0f)<1e-6);assert([(AVAudioPlayer *)tracks[0]volume]==native[level]/256.0f&&[(AVAudioPlayer *)tracks[1]volume]==native[level]/256.0f&&[(AVAudioPlayer *)tracks[2]volume]==126/256.0f);}
 audio.musicVolume=0;assert([(AVAudioPlayer *)tracks[2]volume]==126/256.0f);audio.musicVolume=-1;assert(audio.musicVolume==0);audio.musicVolume=2;assert(audio.musicVolume==1&&[(AVAudioPlayer *)tracks[0]volume]==126/256.0f);
 puts("PASS actual AVAudioPlayer volumes: native11 slider levels quantized/clamped for Music1/2, Music3 default126/256 unchanged; logical setting clamps0..1");return 0;
}}
