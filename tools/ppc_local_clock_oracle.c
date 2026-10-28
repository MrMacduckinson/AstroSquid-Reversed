/* Compare the port's Mac-local-seconds formula with actual classic GetDateTime. */
#include <Carbon/Carbon.h>
#include <stdint.h>
#include <math.h>
#include <stdio.h>
int main(void){
 for(unsigned i=0;i<12;i++){
  UInt32 before,after;GetDateTime(&before);CFAbsoluteTime now=CFAbsoluteTimeGetCurrent();CFTimeZoneRef zone=CFTimeZoneCopySystem();if(!zone)return 2;
  double local=now+kCFAbsoluteTimeIntervalSince1904+CFTimeZoneGetSecondsFromGMT(zone,now);CFRelease(zone);
  uint32_t value=(uint32_t)(uint64_t)floor(local);GetDateTime(&after);if(value!=before&&value!=after)return 3;
 }
 puts("PASS12 actual GetDateTime comparisons: CF absolute time +1904 epoch +system timezone seconds matches Mac local seconds");return 0;
}
