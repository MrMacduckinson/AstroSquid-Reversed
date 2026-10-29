#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
@interface PackedPreferencesView:AstroView
- (void)checkPacked;
- (void)checkLegacy;
- (void)checkConstructedPacked:(BOOL)full;
- (void)finish;
@end
@implementation PackedPreferencesView
- (void)finish {[timer invalidate];timer=nil;[self releaseGraphics];}
- (void)checkLegacy {
    assert(controlKeys[0]==14&&preferenceFPS==20&&ui.frameInterval==3&&!ui.smooth);
    assert(ui.unlockedLevel==7&&fabs(ui.soundVolume-.7)<1e-12&&ui.musicVolume==0);
    [self updatePackedPreferences];uint8_t disk[542];astro_preferences_save(preferenceBytes,disk);
    assert(preferenceWord(disk+534)==107&&preferenceWord(disk+522)==(14^7));
}
- (void)checkConstructedPacked:(BOOL)full {
    assert(preferenceFPS==(full?30:60)&&ui.frameInterval==(full?2:1));
    assert(ui.unlockedLevel==(full?9:1)&&ui.smooth==!full);
    assert(ui.registered==full&&[ui.registeredName isEqual:full?@"":@"Unregistered"]);
    if(full)assert(controlKeys[0]==14&&controlKeys[4]==123&&controlKeys[5]==124);
}
- (void)checkPacked {
    for(unsigned v=0;v<65536;v++){
        uint8_t disk[542],before[542];for(unsigned i=0;i<542;i++)disk[i]=(i*29+v)&255;
        disk[10]=0;disk[266]=8;memcpy(disk+267,"AAAAAAAA",8);
        for(unsigned offset=2;offset<=6;offset+=2)preferencePut(disk+offset,v);
        for(unsigned i=0;i<6;i++)preferencePut(disk+522+i*2,v);
        preferencePut(disk+534,v);preferencePut(disk+536,v);
        assert(astro_preferences_load(preferenceBytes,preferenceDefaults,preferenceDefaults+256,disk,542));
        memcpy(before,preferenceBytes,542);memcpy(before+12,preferenceDefaults+2,2*(preferenceDefaults[0]/2));[self applyPackedPreferences];
        assert(!memcmp(before,preferenceBytes,542));
        assert(ui.registered&&ui.registeredName.length==0&&[registeredSerial isEqual:@"AAAAAAAA"]);
        assert(preferenceFPS==preferenceWord(before+2)&&ui.frameInterval==astro_frame_interval(preferenceFPS));
        assert(ui.smooth==(preferenceWord(before+536)==1));
        assert(ui.unlockedLevel==preferenceWord(before+534));
        const unsigned order[]={0,1,2,3,5,4};
        for(unsigned i=0;i<6;i++){assert(controlKeys[order[i]]==(preferenceWord(before+522+i*2)^7));assert(![self controlPressed:i]);}
        [self updatePackedPreferences];assert(!memcmp(before,preferenceBytes,542));
    }
    /* A changed field updates its own bytes; all spare string/padding bytes survive. */
    uint8_t before[542];memcpy(before,preferenceBytes,542);controlKeys[4]=14;ui.smooth=YES;
    [self updatePackedPreferences];preferencePut(before+532,14^7);preferencePut(before+536,1);assert(!memcmp(before,preferenceBytes,542));
    puts("PASS65536 actual Root packed preference mappings and unchanged whole-byte roundtrips; control ordering, raw signed words/filter and padding preserved");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    NSUserDefaults *prefs=[NSUserDefaults standardUserDefaults];
    NSDictionary *legacy=@{@"AstroSquidSettings":@{@"sound":@.7,@"music":@0,@"smooth":@NO,@"fps":@20,@"keys":@[@14,@58,@126,@125,@123,@124]},@"AstroSquidUnlockedLevel":@7};
    [prefs setVolatileDomain:legacy forName:NSArgumentDomain];
    PackedPreferencesView *view=[[PackedPreferencesView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkLegacy];[view checkPacked];[view finish];
    NSMutableDictionary *arguments=[legacy mutableCopy];arguments[@"AstroSquidPackedPreferences"]=[NSData data];[prefs setVolatileDomain:arguments forName:NSArgumentDomain];
    view=[[PackedPreferencesView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkConstructedPacked:NO];[view finish];
    uint8_t disk[542]={0},live[542],slots[512];NSData *defaults=[NSData dataWithContentsOfFile:[[NSString stringWithUTF8String:argv[1]]stringByAppendingPathComponent:@"preferences-defaults.bin"]];assert(defaults.length==512);memcpy(slots,defaults.bytes,512);
    assert(astro_preferences_load(live,slots,slots+256,NULL,0));live[10]=0;live[266]=8;memcpy(live+267,"AAAAAAAA",8);
    preferencePut(live+2,30);preferencePut(live+534,9);preferencePut(live+536,0);preferencePut(live+522,14^7);astro_preferences_save(live,disk);
    arguments[@"AstroSquidPackedPreferences"]=[NSData dataWithBytes:disk length:542];[prefs setVolatileDomain:arguments forName:NSArgumentDomain];
    view=[[PackedPreferencesView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkConstructedPacked:YES];[view finish];
    arguments[@"AstroSquidPackedPreferences"]=[NSMutableData dataWithLength:543];[prefs setVolatileDomain:arguments forName:NSArgumentDomain];
    view=[[PackedPreferencesView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkLegacy];[view finish];
    puts("PASS actual Root legacy migration and empty partial preference construction");
}}
