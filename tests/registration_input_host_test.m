#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <objc/runtime.h>
static uint32_t serviceTick=1000;static unsigned serviceClockReads,serviceTickStep,commandBeeps;
static NSMutableString *events;static BOOL observing,checkRegisterFocus,autoTest,autoHeld;
static BOOL observeIdleWait;static NSTimeInterval idleWait;
@interface MainWaitApplication:NSApplication @end
@implementation MainWaitApplication
- (NSEvent *)nextEventMatchingMask:(NSEventMask)mask untilDate:(NSDate *)expiration inMode:(NSRunLoopMode)mode dequeue:(BOOL)dequeue {
    if(observeIdleWait){assert(mask==NSEventMaskAny&&dequeue&&[mode isEqual:NSDefaultRunLoopMode]);idleWait=[expiration timeIntervalSinceNow];return nil;}
    return [super nextEventMatchingMask:mask untilDate:expiration inMode:mode dequeue:dequeue];
}
@end
static unsigned commandMenuCalls;
@interface CommandProbeMenu:NSMenu @end
@implementation CommandProbeMenu
- (BOOL)performKeyEquivalent:(NSEvent *)event {assert(event.modifierFlags&NSEventModifierFlagCommand);commandMenuCalls++;return YES;}
@end
static BOOL commandChecking;static unsigned commandDialogs,commandExits,commandSaves;static NSModalResponse commandChoice;static NSString *commandReason;static AstroView *commandView;
@interface AstroView (CommandModalProbe)
- (void)checkCommandModalFreeze;
@end
static NSModalResponse commandModal(NSAlert *alert,SEL selector){
    assert(commandChecking&&[alert.messageText isEqual:@"Stop"]&&[alert.informativeText isEqual:commandReason]);
    assert(alert.buttons.count==2&&[alert.buttons[0].title isEqual:@"Stop"]&&[alert.buttons[1].title isEqual:@"Continue"]);
    commandDialogs++;[commandView checkCommandModalFreeze];return commandChoice;
}
@interface RegistrationInputUI:AstroUIRenderer @end
@implementation RegistrationInputUI
- (void)setButton:(NSString *)name pressed:(BOOL)pressed {if(checkRegisterFocus&&pressed&&[name isEqual:@"Register"])assert(self.activeRegistrationField==-1);[super setButton:name pressed:pressed];}
- (void)show:(NSString *)anchor {if(checkRegisterFocus&&[anchor isEqual:@"Register Menu"])assert(self.activeRegistrationField==0);[super show:anchor];}
- (int)editRegistrationByte:(unsigned)byte {if(observing)[events appendString:@"E"];return [super editRegistrationByte:byte];}
@end
@interface RegistrationInputAudio:AstroAudio @end
@implementation RegistrationInputAudio
- (BOOL)playCue:(NSString *)name position:(double)position {if(observing&&autoTest){assert([name isEqual:@"Click"]);[events appendString:@"C"];}return YES;}
- (void)serviceMusic {if(observing)[events appendString:@"S"];}
@end
@interface RegistrationInputView:AstroView @end
@implementation RegistrationInputView
- (uint32_t)currentGameTick {return 1000;}
- (void)signalUnhandledCommand {commandBeeps++;}
- (void)checkCommandModalFreeze {
    assert(stringOverflowActive);unsigned clocks=serviceClockReads;
    [self tick:nil];[self tickWallClock];[self drawRect:NSZeroRect];assert(serviceClockReads==clocks);
}
- (void)saveSettings {if(commandChecking){commandSaves++;return;}[super saveSettings];}
- (void)terminateApplication {
    if(commandChecking){assert(terminationAllowed);commandExits++;@throw [NSException exceptionWithName:@"CommandStopped" reason:nil userInfo:nil];}
    [super terminateApplication];
}
- (uint32_t)cardDelayClockTick {serviceClockReads++;uint32_t tick=serviceTick;serviceTick+=serviceTickStep;return tick;}
- (void)copyKeyMap:(unsigned char *)map {memset(map,0,16);}
- (BOOL)menuMouseButtonPressed {return autoTest?autoHeld:NO;}
- (NSPoint)currentMenuMousePoint {return NSMakePoint(-30000,-30000);}
- (void)readKeyMap {if(observing)[events appendString:@"K"];}
- (void)display {if(observing)[events appendString:@"D"];if(autoTest){if(menuFrameActive){[self pollMenuMouse];menuFrameActive=NO;}else [self presentFrame];}}
- (void)delayGameTicks:(uint32_t)ticks {assert(autoTest&&ticks==6);[events appendString:@"L"];}
- (void)presentFrame {if(observing)[events appendString:@"W"];}
- (BOOL)continueScoreOverflow:(NSData *)left right:(NSData *)right {assert(left.length==255&&right.length==1);[events appendString:@"C"];return YES;}
- (void)queueCharacter:(NSString *)text code:(unsigned)code repeat:(BOOL)repeat {
    [self keyDown:[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:text charactersIgnoringModifiers:text isARepeat:repeat keyCode:code]];
}
- (void)frameExpect:(NSString *)expected {
    [events setString:@""];observedWallTick=999;[self pollMenu];if(![events isEqual:expected]){fprintf(stderr,"expected %s got %s\n",expected.UTF8String,events.UTF8String);abort();}
}
- (void)checkLoadedRegistration:(BOOL)active name:(NSString *)name serial:(NSString *)serial {
    [timer invalidate];timer=nil;assert(ui.registered==active&&[ui.registeredName isEqual:name]&&[registeredSerial isEqual:serial]);[self releaseGraphics];
}
- (void)checkInput {
    NSData *initialName=[ui.registeredName dataUsingEncoding:NSMacOSRomanStringEncoding],*initialCode=[registeredSerial dataUsingEncoding:NSMacOSRomanStringEncoding];assert(astro_registration_valid(initialName.bytes,initialName.length,initialCode.bytes,initialCode.length));
    [timer invalidate];timer=nil;[audio stop];audio=[RegistrationInputAudio new];object_setClass(ui,[RegistrationInputUI class]);
    menuVisible=YES;splashVisible=paused=gameOver=NO;editingKey=-1;
    [ui show:@"Register Menu"];while(ui.transitioning)[ui advanceMenuCamera];ui.activeRegistrationField=0;
    observing=YES;AstroScoreEditor *fields=[ui registrationFields];
    [self queueCharacter:@"A" code:0 repeat:NO];[self queueCharacter:@"\t" code:48 repeat:NO];[self queueCharacter:@"B" code:11 repeat:NO];
    assert(!fields[0].name[0]&&!fields[1].name[0]&&queuedKeyEvents.count==3);
    [events setString:@""];observedWallTick=1000;[self pollMenu];assert(!events.length&&queuedKeyEvents.count==3);
    [self frameExpect:@"DWSKE"];assert(!strcmp(fields[0].name,"A")&&queuedKeyEvents.count==2);
    [self frameExpect:@"DWSKE"];assert(ui.activeRegistrationField==1&&queuedKeyEvents.count==1);
    [self frameExpect:@"DWSKE"];assert(!strcmp(fields[1].name,"B")&&!queuedKeyEvents.count);
    [self queueCharacter:@"C" code:8 repeat:YES];[self frameExpect:@"DWSKE"];assert(!strcmp(fields[1].name,"BC"));
    ui.activeRegistrationField=-1;[self queueCharacter:@"D" code:2 repeat:NO];[self frameExpect:@"DWSK"];assert(queuedKeyEvents.count==1);
    ui.activeRegistrationField=1;[ui show:@"Main Menu"];[self frameExpect:@"DWSK"];assert(queuedKeyEvents.count==1);
    while(ui.transitioning)[ui advanceMenuCamera];[self frameExpect:@"DWSKE"];assert(!strcmp(fields[1].name,"BCD"));
    memset(fields[1].name,'A',255);fields[1].name[255]=0;fields[1].cursor=255;
    [self queueCharacter:@"B" code:11 repeat:NO];[self frameExpect:@"DWSKEC"];assert(strlen(fields[1].name)==255&&fields[1].cursor==256&&!fields[1].alert);
    [self queueCharacter:@"\r" code:36 repeat:NO];assert(!fields[1].submitted);[self frameExpect:@"DWSKE"];assert(fields[1].submitted);
    const unsigned codes[]={115,119,116,121,114,71,126,125};const unsigned bytes[]={1,4,11,12,5,27,30,31};
    for(unsigned i=0;i<8;i++){NSEvent *event=[self testEvent:NSKeyDown code:codes[i]];NSData *mapped=[self fieldCharacters:event];assert(mapped.length==1&&*(const unsigned char *)mapped.bytes==bytes[i]);}
    fields[1].submitted=0;fields[1].cursor=2;[self queueCharacter:@"" code:115 repeat:NO];[self queueCharacter:@"" code:119 repeat:NO];
    [self frameExpect:@"DWSKE"];assert(fields[1].cursor==2&&queuedKeyEvents.count==1);[self frameExpect:@"DWSKE"];assert(fields[1].cursor==2);
    [self queueCharacter:[NSString stringWithFormat:@"%C",(unichar)NSF1FunctionKey] code:122 repeat:NO];[self frameExpect:@"DWSKE"];assert(fields[1].cursor==2);
    [ui resetRegistrationFields];ui.activeRegistrationField=0;
    NSEvent *compound=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:123 windowNumber:0 context:nil characters:@"YZ" charactersIgnoringModifiers:@"yz" isARepeat:YES keyCode:16];
    [self keyDown:compound];assert(queuedKeyEvents.count==1&&queuedKeyEvents[0]==compound);
    assert(queuedKeyEvents[0].isARepeat&&queuedKeyEvents[0].modifierFlags==NSEventModifierFlagCommand&&queuedKeyEvents[0].timestamp==123);
    [self frameExpect:@"DWSKE"];assert(!strcmp(fields[0].name,"Y")&&!queuedKeyEvents.count);
    [ui resetRegistrationFields];ui.activeRegistrationField=-1;queuedKeyEvents=nil;
    [NSApp discardEventsMatchingMask:NSEventMaskAny beforeEvent:nil];
    for(unsigned i=0;i<2;i++)[NSApp postEvent:[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:i windowNumber:0 context:nil characters:i?@"B":@"A" charactersIgnoringModifiers:i?@"B":@"A" isARepeat:i!=0 keyCode:i?11:0] atStart:NO];
    [self frameExpect:@"DWSK"];assert([NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO].keyCode==0);
    ui.activeRegistrationField=0;[events setString:@""];observedWallTick=1000;[self pollMenu];assert(!events.length);
    [self queueCharacter:@"X" code:7 repeat:NO];[self frameExpect:@"DWSKE"];assert(!strcmp(fields[0].name,"X"));
    assert([NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO].keyCode==0);
    [self frameExpect:@"DWSKE"];assert(!strcmp(fields[0].name,"XA"));
    assert([NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO].keyCode==11);
    [self frameExpect:@"DWSKE"];assert(!strcmp(fields[0].name,"XAB"));
    assert(![NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO]);
    puts("PASS pending Cocoa key events retained while unfocused/closed gate and consumed one per eligible field frame, including repeat");
    [ui resetRegistrationFields];ui.activeRegistrationField=0;[self flushGameEvents];lastMainEventTick=0;
    for(NSString *ch in @[@"A",@"B",@"C"])[self queueCharacter:ch code:0 repeat:NO];
    observedWallTick=999;serviceTick=1000;serviceClockReads=0;[self pollMainMenu];
    assert(!strcmp(fields[0].name,"A")&&queuedKeyEvents.count==1&&lastMainEventTick==1000&&serviceClockReads==3);
    observedWallTick=999;serviceTick=1059;serviceClockReads=0;[self pollMainMenu];
    assert(!strcmp(fields[0].name,"AC")&&!queuedKeyEvents.count&&lastMainEventTick==1000&&serviceClockReads==1);
    [self queueCharacter:@"D" code:2 repeat:NO];observedWallTick=1000;serviceTick=1060;serviceClockReads=0;[self pollMainMenu];
    assert(!strcmp(fields[0].name,"AC")&&!queuedKeyEvents.count&&lastMainEventTick==1060&&serviceClockReads==3);
    [self queueCharacter:@"E" code:14 repeat:NO];serviceTick=2000;serviceClockReads=0;[self pollMenu];
    assert(queuedKeyEvents.count==1&&lastMainEventTick==1060&&!serviceClockReads);
    paused=YES;[self pollMainMenu];paused=NO;assert(queuedKeyEvents.count==1&&!serviceClockReads);
    [self flushGameEvents];ui.activeRegistrationField=-1;serviceTick=2000;serviceClockReads=0;serviceTickStep=1;
    NSEvent *pending=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:@"P" charactersIgnoringModifiers:@"P" isARepeat:YES keyCode:35];
    [NSApp postEvent:pending atStart:YES];[self pollMainMenu];
    assert(lastMainEventTick==2002&&serviceClockReads==3&&!queuedKeyEvents.count);
    assert(![NSApp nextEventMatchingMask:NSEventMaskKeyDown untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO]);
    serviceTickStep=0;serviceTick=3000;
    Class appClass=object_setClass(NSApp,[MainWaitApplication class]);observeIdleWait=YES;
    [self pollMainMenu];observeIdleWait=NO;object_setClass(NSApp,appClass);
    assert(idleWait>0.02&&idleWait<=2.0/60.0&&lastMainEventTick==3000);
    NSMenu *savedMenu=NSApp.mainMenu;NSApp.mainMenu=nil;[self flushGameEvents];
    for(unsigned i=0;i<2;i++){
        NSString *text=i?[NSString stringWithFormat:@"%C",(unichar)NSF1FunctionKey]:@"x";
        NSEvent *command=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:0 windowNumber:0 context:nil characters:text charactersIgnoringModifiers:text isARepeat:i!=0 keyCode:i?122:7];
        [self keyDown:command];serviceTick+=60;[self pollMainMenu];assert(commandBeeps==1&&!queuedKeyEvents.count);
    }
    NSApp.mainMenu=[CommandProbeMenu new];
    NSEvent *matched=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:0 windowNumber:0 context:nil characters:@"x" charactersIgnoringModifiers:@"x" isARepeat:NO keyCode:7];
    [self keyDown:matched];serviceTick+=60;[self pollMainMenu];assert(commandMenuCalls==1&&commandBeeps==1);
    NSApp.mainMenu=nil;commandView=self;commandChecking=YES;
    Method modal=class_getInstanceMethod([NSAlert class],@selector(runModal));IMP previousModal=method_setImplementation(modal,(IMP)commandModal);
    for(unsigned repeat=0;repeat<2;repeat++)for(unsigned choice=0;choice<2;choice++)for(unsigned i=0;i<3;i++){
        NSString *ch=@[@".",@"q",@"Q"][i];commandReason=i?@"User Break (3)":@"User Break (2)";
        commandChoice=choice?NSAlertSecondButtonReturn:NSAlertFirstButtonReturn;unsigned beforeExits=commandExits,beforeBeeps=commandBeeps,beforeDialogs=commandDialogs;
        AstroScoreEditor beforeFields[2];memcpy(beforeFields,fields,sizeof(beforeFields));
        NSEvent *command=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:NSEventModifierFlagCommand timestamp:0 windowNumber:0 context:nil characters:ch charactersIgnoringModifiers:ch isARepeat:repeat keyCode:i?12:47];
        [self keyDown:command];serviceTick+=60;terminationAllowed=NO;quitRequested=NO;
        @try {[self pollMainMenu];assert(choice);}
        @catch(NSException *exception){assert(!choice&&[exception.name isEqual:@"CommandStopped"]);}
        assert(commandDialogs==beforeDialogs+1&&commandExits==beforeExits+!choice&&commandBeeps==beforeBeeps+(choice&&i!=0));
        assert(!commandSaves&&!quitRequested&&!stringOverflowActive&&!queuedKeyEvents.count&&!memcmp(beforeFields,fields,sizeof(beforeFields)));
    }
    method_setImplementation(modal,previousModal);commandChecking=NO;terminationAllowed=NO;
    puts("PASS 12 actual Root Stop/Continue command routes, no settings save, unchanged fields, and modal timer/draw freeze");
    NSApp.mainMenu=savedMenu;
    [self flushGameEvents];puts("PASS outer Main field/periodic shared consumption AC,59/60 boundary,closed frame gate,and nested/pause exclusion");
    observing=NO;
    for(NSString *button in @[@"Back3",@"Back4",@"Back5",@"Back6",@"Back7"]){
        ui.activeRegistrationField=0;[self performMenuAction:button];assert(ui.activeRegistrationField==-1);
        while(ui.transitioning)[ui advanceMenuCamera];[self finishMenuNavigation];
    }
    ui.activeRegistrationField=-1;checkRegisterFocus=YES;[self performMenuAction:@"Register"];checkRegisterFocus=NO;assert(ui.activeRegistrationField==0);
    while(ui.transitioning)[ui advanceMenuCamera];[self finishMenuNavigation];
    selftestPath=@"registration-input";[self testCaptureKey:14];assert(ui.activeRegistrationField==-1);selftestPath=nil;
    [ui resetRegistrationFields];ui.activeRegistrationField=0;ui.registered=NO;ui.registeredName=@"OLDN";registeredSerial=@"OLDC";
    fields=[ui registrationFields];strcpy(fields[0].name,"TEST");strcpy(fields[1].name,"INVALID");
    autoTest=autoHeld=observing=YES;menuMouseLatched=YES;[self queueCharacter:@"\r" code:36 repeat:NO];
    [self frameExpect:@"DWSKE"];assert(fields[0].submitted);
    [self frameExpect:@"DWSK"];assert(fields[0].submitted&&[ui.registeredName isEqual:@"OLDN"]);
    autoHeld=NO;[self frameExpect:@"DWSCDWLK"];assert(!fields[0].submitted&&!fields[1].submitted&&menuMouseLatched&&!ui.registered&&[ui.registeredName isEqual:@"Unregistered"]&&[registeredSerial isEqual:@"OLDC"]);
    autoTest=observing=NO;[self releaseGraphics];
    puts("PASS actual Root field input: one event after swap/music/keymap, closed gate, Tab, repeat, retained focus/queue, transition exclusion, overflow and deferred submit flag");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
    events=[NSMutableString string];RegistrationInputView *view=[[RegistrationInputView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkInput];
    for(unsigned valid=0;valid<2;valid++){
        [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0},@"AstroSquidRegistration":@{@"name":valid?@"":@"TEST",@"serial":valid?@"AAAAAAAA":@"INVALID"}} forName:NSArgumentDomain];
        RegistrationInputView *loaded=[[RegistrationInputView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(loaded);
        [loaded checkLoadedRegistration:valid name:valid?@"":@"Unregistered" serial:valid?@"AAAAAAAA":@"INVALID"];
    }
    puts("PASS automatic Enter waits for the next eligible released-latch frame; valid/invalid stored tuples revalidated on construction");
}}
