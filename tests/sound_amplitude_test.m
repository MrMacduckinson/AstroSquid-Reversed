#import "../src/audio.h"
#include <assert.h>
#include <math.h>
static uint32_t bits(float value){uint32_t b;memcpy(&b,&value,4);return b;}
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==3);int amplitudes[11];for(unsigned i=0;i<11;i++)amplitudes[i]=-1;
 NSString *trace=[NSString stringWithContentsOfFile:[NSString stringWithUTF8String:argv[2]] encoding:NSUTF8StringEncoding error:NULL];assert(trace);
 for(NSString *line in [trace componentsSeparatedByString:@"\n"]){NSArray *f=[line componentsSeparatedByString:@","];if(f.count==7&&[f[0]isEqual:@"C"]&&[f[2]intValue]==2&&[f[3]intValue]==1&&[f[4]intValue]==1){assert([f[5]intValue]==43);amplitudes[[f[1]intValue]]=[f[6]intValue];}}
 for(unsigned i=0;i<11;i++)assert(amplitudes[i]>=0&&amplitudes[i]<=255);
 NSError *error=nil;AstroAudio *audio=[[AstroAudio alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:&error];assert(audio&&!error);audio.soundVolume=0;
 const double pans[]={NAN,0,.25,.5,.75,1};double coefficients[6][2];
 for(unsigned i=0;i<6;i++){assert([audio playCue:@"Laser" position:pans[i]]);coefficients[i][0]=i?floor(sqrt(1-pans[i])*256)/256:1;coefficients[i][1]=i?floor(sqrt(pans[i])*256)/256:1;}
 NSArray *voices=[audio valueForKey:@"voices"];assert(voices.count==6);assert(![audio playCue:@"Laser" position:.5]);
 for(unsigned level=0;level<11;level++){
  audio.soundVolume=level/20.;assert([[audio valueForKey:@"voices"]count]==6);
  for(unsigned i=0;i<6;i++)for(unsigned side=0;side<2;side++){
   AVAudioPlayer *player=voices[i][side];float expected=(amplitudes[level]/255.0f)*coefficients[i][side];assert(bits(player.volume)==bits(expected));assert(player.pan==(side?1:-1));printf("A,%u,%u,%u,%08x\n",level,i,side,bits(player.volume));
  }
 }
 [audio stopEffects];assert(![[audio valueForKey:@"voices"]count]);audio.soundVolume=.35;assert([audio playCue:@"Laser" position:.25]);
 NSArray *pair=[[audio valueForKey:@"voices"]firstObject];for(unsigned side=0;side<2;side++){float expected=(amplitudes[7]/255.0f)*coefficients[2][side];assert(bits([pair[side]volume])==bits(expected));}
 [audio stop];puts("PASS132 actual AV player gains from native amplitudes, live pan retention, muted6channel occupancy and new cues");
}}
