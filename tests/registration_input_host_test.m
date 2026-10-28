#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <objc/runtime.h>
static NSMutableString *events;static BOOL observing;
@interface RegistrationInputUI:AstroUIRenderer @end
@implementation RegistrationInputUI
- (int)editRegistrationByte:(unsigned)byte {if(observing)[events appendString:@"E"];return [super editRegistrationByte:byte];}
@end
@interface RegistrationInputAudio:AstroAudio @end
@implementation RegistrationInputAudio
- (void)serviceMusic {if(observing)[events appendString:@"S"];}
@end
@interface RegistrationInputView:AstroView @end
@implementation RegistrationInputView
- (uint32_t)currentGameTick {return 1000;}
- (void)copyKeyMap:(unsigned char *)map {memset(map,0,16);}
- (BOOL)menuMouseButtonPressed {return NO;}
- (void)readKeyMap {if(observing)[events appendString:@"K"];}
- (void)display {if(observing)[events appendString:@"D"];}
- (void)presentFrame {if(observing)[events appendString:@"W"];}
- (BOOL)continueScoreOverflow:(NSData *)left right:(NSData *)right {assert(left.length==255&&right.length==1);[events appendString:@"C"];return YES;}
- (void)queueCharacter:(NSString *)text code:(unsigned)code repeat:(BOOL)repeat {
    [self keyDown:[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:text charactersIgnoringModifiers:text isARepeat:repeat keyCode:code]];
}
- (void)frameExpect:(NSString *)expected {
    [events setString:@""];observedWallTick=999;[self pollMenu];assert([events isEqual:expected]);
}
- (void)checkInput {
    [timer invalidate];timer=nil;[audio stop];audio=[RegistrationInputAudio new];object_setClass(ui,[RegistrationInputUI class]);
    menuVisible=YES;splashVisible=paused=gameOver=NO;editingKey=-1;
    [ui show:@"Register Menu"];while(ui.transitioning)[ui advanceMenuCamera];ui.activeRegistrationField=0;
    observing=YES;AstroScoreEditor *fields=[ui registrationFields];
    [self queueCharacter:@"A" code:0 repeat:NO];[self queueCharacter:@"\t" code:48 repeat:NO];[self queueCharacter:@"B" code:11 repeat:NO];
    assert(!fields[0].name[0]&&!fields[1].name[0]&&registrationKeyEvents.length==3);
    [events setString:@""];observedWallTick=1000;[self pollMenu];assert(!events.length&&registrationKeyEvents.length==3);
    [self frameExpect:@"DWSKE"];assert(!strcmp(fields[0].name,"A")&&registrationKeyEvents.length==2);
    [self frameExpect:@"DWSKE"];assert(ui.activeRegistrationField==1&&registrationKeyEvents.length==1);
    [self frameExpect:@"DWSKE"];assert(!strcmp(fields[1].name,"B")&&!registrationKeyEvents.length);
    [self queueCharacter:@"C" code:8 repeat:YES];[self frameExpect:@"DWSKE"];assert(!strcmp(fields[1].name,"BC"));
    [self queueCharacter:@"D" code:2 repeat:NO];ui.activeRegistrationField=-1;[self frameExpect:@"DWSK"];assert(registrationKeyEvents.length==1);
    ui.activeRegistrationField=1;[ui show:@"Main Menu"];[self frameExpect:@"DWSK"];assert(registrationKeyEvents.length==1);
    while(ui.transitioning)[ui advanceMenuCamera];[self frameExpect:@"DWSKE"];assert(!strcmp(fields[1].name,"BCD"));
    memset(fields[1].name,'A',255);fields[1].name[255]=0;fields[1].cursor=255;
    [self queueCharacter:@"B" code:11 repeat:NO];[self frameExpect:@"DWSKEC"];assert(strlen(fields[1].name)==255&&fields[1].cursor==256&&!fields[1].alert);
    [self queueCharacter:@"\r" code:36 repeat:NO];assert(!fields[1].submitted);[self frameExpect:@"DWSKE"];assert(fields[1].submitted);
    const unsigned codes[]={115,119,116,121,114,71,126,125};const unsigned bytes[]={1,4,11,12,5,27,30,31};
    for(unsigned i=0;i<8;i++){NSEvent *event=[self testEvent:NSKeyDown code:codes[i]];NSData *mapped=[self fieldCharacters:event];assert(mapped.length==1&&*(const unsigned char *)mapped.bytes==bytes[i]);}
    fields[1].submitted=0;fields[1].cursor=2;[self queueCharacter:@"" code:115 repeat:NO];[self queueCharacter:@"" code:119 repeat:NO];
    [self frameExpect:@"DWSKE"];assert(fields[1].cursor==2&&registrationKeyEvents.length==1);[self frameExpect:@"DWSKE"];assert(fields[1].cursor==2);
    [self queueCharacter:[NSString stringWithFormat:@"%C",(unichar)NSF1FunctionKey] code:122 repeat:NO];[self frameExpect:@"DWSKE"];assert(fields[1].cursor==2);
    observing=NO;
    for(NSString *button in @[@"Back3",@"Back4",@"Back5",@"Back6",@"Back7"]){
        ui.activeRegistrationField=0;[self performMenuAction:button];assert(ui.activeRegistrationField==-1);
        while(ui.transitioning)[ui advanceMenuCamera];[self finishMenuNavigation];
    }
    ui.activeRegistrationField=-1;[self performMenuAction:@"Register"];assert(ui.activeRegistrationField==0);
    while(ui.transitioning)[ui advanceMenuCamera];[self finishMenuNavigation];
    selftestPath=@"registration-input";[self testCaptureKey:14];assert(ui.activeRegistrationField==-1);selftestPath=nil;
    [self releaseGraphics];
    puts("PASS actual Root field input: one event after swap/music/keymap, closed gate, Tab, repeat, retained focus/queue, transition exclusion, overflow and deferred submit flag");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    events=[NSMutableString string];RegistrationInputView *view=[[RegistrationInputView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkInput];
}}
