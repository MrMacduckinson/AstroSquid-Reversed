#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#include <sys/stat.h>
static unsigned char snapshot[16];
static unsigned captures;
static BOOL countOnly=YES;
@interface PictureView:AstroView
@end
@implementation PictureView
- (void)copyKeyMap:(unsigned char *)bytes {memcpy(bytes,snapshot,16);}
- (uint32_t)screenshotSeconds {return 123;}
- (BOOL)saveScreenshot {captures++;return countOnly?YES:[super saveScreenshot];}
@end
@implementation AstroView(PictureCheck)
- (void)checkStartupInactive {[timer invalidate];timer=nil;[audio stop];assert(!engineDebug);}
- (void)checkPicture:(NSString *)base {
 [timer invalidate];timer=nil;[audio stop];assert(engineDebug);
 memset(snapshot,0,16);snapshot[67>>3]=1u<<(67&7);
 for(int i=0;i<3;i++)[self readKeyMap];assert(captures==3);
 engineDebug=NO;[self readKeyMap];assert(captures==3);engineDebug=YES;
 memset(snapshot,0,16);snapshot[68>>3]=1u<<(68&7);[self readKeyMap];assert(captures==3);
 snapshot[67>>3]|=1u<<(67&7);snapshot[55>>3]|=1u<<(55&7);snapshot[12>>3]|=1u<<(12&7);
 [self readKeyMap];assert(quitRequested&&captures==4);quitRequested=NO;
 screenshotBase=base;countOnly=NO;assert([self saveScreenshot]);
 NSString *path=[base stringByAppendingPathComponent:@"Screenshots/Screen 123.pict"];
 NSData *first=[NSData dataWithContentsOfFile:path];assert(first.length==1229448);
 NSDictionary *attrs=[NSFileManager.defaultManager attributesOfItemAtPath:path error:NULL];
 assert([attrs[NSFileHFSTypeCode] unsignedIntValue]==ASTRO_PICTURE_TYPE&&[attrs[NSFileHFSCreatorCode] unsignedIntValue]==ASTRO_PICTURE_CREATOR);
 FILE *extra=fopen(path.fileSystemRepresentation,"ab");assert(extra);assert(fwrite("extra",1,5,extra)==5);assert(!fclose(extra));
 assert([self saveScreenshot]);assert([[NSData dataWithContentsOfFile:path] isEqual:first]);
 assert(!chmod(path.fileSystemRepresentation,0444));assert(![self saveScreenshot]);assert([[NSData dataWithContentsOfFile:path] isEqual:first]);assert(!chmod(path.fileSystemRepresentation,0600));
 screenshotBase=[base stringByAppendingPathComponent:@"blocked"];
 assert([NSFileManager.defaultManager createDirectoryAtPath:screenshotBase withIntermediateDirectories:NO attributes:nil error:NULL]);
 assert([NSFileManager.defaultManager createFileAtPath:[screenshotBase stringByAppendingPathComponent:@"Screenshots"] contents:[NSData data] attributes:nil]);
 assert(![self saveScreenshot]);
 puts("PASS actual host startup Command, held multiply polls, debug gate, quit coexistence, PICT bytes/metadata, same-name truncation, readonly and folder failures");
}
@end
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults] setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 int inactiveKeys[]={54,-1};for(unsigned i=0;i<2;i++){int key=inactiveKeys[i];memset(snapshot,0,16);if(key>=0)snapshot[key>>3]=1u<<(key&7);AstroView *inactive=[[PictureView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(inactive);[inactive checkStartupInactive];}
 memset(snapshot,0,16);snapshot[55>>3]=1u<<(55&7);
 AstroView *view=[[PictureView alloc] initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];
 assert(view);[view checkPicture:[NSString stringWithUTF8String:argv[2]]];
}}
