/* Native G5 GetDateTime local-epoch comparison; no clock changes. */
#include <Carbon/Carbon.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
int main(void){unsigned long seconds;GetDateTime(&seconds);CFAbsoluteTime t=CFAbsoluteTimeGetCurrent();CFTimeZoneRef z=CFTimeZoneCopySystem();printf("delta_from_CF_1904=%ld timezone_offset=%.0f\n",(long)(seconds-(unsigned long)floor(t+3061152000.0)),CFTimeZoneGetSecondsFromGMT(z,t));long delta=(long)(seconds-(unsigned long)floor(t+3061152000.0));long offset=(long)CFTimeZoneGetSecondsFromGMT(z,t);CFRelease(z);return labs(delta-offset)>1?3:0;}
