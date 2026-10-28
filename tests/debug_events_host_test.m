#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSMutableArray *messages;static BOOL expectMap,expectSprites,expectContext;
@interface DebugEventsView:AstroView
@end
@implementation DebugEventsView
- (BOOL)appendDebugMessage:(NSString *)message {
 [messages addObject:message];
 if([message isEqual:@"Disposing Spritemaps"]){assert(textures.count==2);expectMap=YES;}
 if([message isEqual:@"Disposing SpriteList"]){assert(expectMap&&!textures.count&&visualEffects.count);expectSprites=YES;}
 if([message isEqual:@"Deactivating OpenGL context"]){assert(expectSprites&&!visualEffects.count&&playerVisualDeleted);for(AstroEnemy *e in enemies)assert(e->visualDeleted);expectContext=YES;}
 if([message isEqual:@"---------- End of Shutdown  -----------"]){assert(expectContext&&NSOpenGLContext.currentContext==nil);}
 return YES;
}
@end
@implementation AstroView(DebugEventsCheck)
- (void)checkDebugEvents {
 [timer invalidate];timer=nil;[audio stop];[messages removeAllObjects];[self resetLevelWorld];assert([messages isEqual:@[@"0"]]);
 [[self openGLContext]makeCurrentContext];GLuint names[2];glGenTextures(2,names);textures[@0]=@(names[0]);textures[@1]=@(names[1]);
 LiveEffect effect={{115,10,10,20,20,0},8,1};[visualEffects addObject:[NSData dataWithBytes:&effect length:sizeof effect]];
 [messages removeAllObjects];[self releaseGraphics];
 NSArray *expected=@[@" ",@"---------- Shutdown  -----------",@" ",@"Disposing Spritemaps",@"    Disposed 2 SpriteMaps",@"Disposing SpriteList",@"Deactivating OpenGL context",@" ",@"---------- End of Shutdown  -----------",@" "];
 assert([messages isEqual:expected]);[self releaseGraphics];assert([messages isEqual:expected]);
 puts("PASS native level-load message and ordered shutdown messages at actual map/sprite/context disposal boundaries; repeated release is inert");
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 messages=[NSMutableArray array];DebugEventsView *view=[[DebugEventsView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkDebugEvents];return 0;
}}
