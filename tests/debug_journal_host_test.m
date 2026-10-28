#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
static NSString *journalPath;static NSData *headerBytes;static int errorCode;static unsigned errorReads;
@interface JournalView:AstroView
@end
@implementation JournalView
- (void)checkAGL {assert(debugAGLLibrary()&&dlsym(debugAGLLibrary(),"aglGetVersion")&&dlsym(debugAGLLibrary(),"aglGetError"));assert([super debugJournalHeader]);assert([super debugAGLError]==0);}
- (NSString *)debugJournalPath {return journalPath;}
- (NSData *)debugJournalHeader {return headerBytes;}
- (int)debugAGLError {errorReads++;return errorCode;}
@end
@implementation AstroView(JournalCheck)
- (void)checkJournal {
 [timer invalidate];timer=nil;[audio stop];fullscreenRequested=NO;
 NSData *old=[@"OLD" dataUsingEncoding:NSASCIIStringEncoding];assert([old writeToFile:journalPath atomically:NO]);
 engineDebug=NO;assert([self initializeDebugJournal]&&[self appendDebugMessage:@"disabled"]);assert(!errorReads&&[[NSData dataWithContentsOfFile:journalPath]isEqual:old]);
 engineDebug=YES;assert(![self startFullscreen]);assert([[NSData dataWithContentsOfFile:journalPath]isEqual:headerBytes]);
 assert([[NSFileManager.defaultManager attributesOfItemAtPath:journalPath error:NULL][NSFileHFSTypeCode]unsignedIntValue]==0x54455854);
 errorCode=0;assert([self appendDebugMessage:@"Hello"]&&errorReads==1);
 errorCode=10000;assert([self appendDebugMessage:@"Hello"]&&errorReads==2);
 NSMutableData *expected=[headerBytes mutableCopy];[expected appendData:[@"Hello\rHello\r   *** AGL Error:  10000\r" dataUsingEncoding:NSASCIIStringEncoding]];
 assert([[NSData dataWithContentsOfFile:journalPath]isEqual:expected]);
 engineDebug=NO;assert([self appendDebugMessage:@"disabled"]&&[self initializeDebugJournal]);assert(errorReads==2&&[[NSData dataWithContentsOfFile:journalPath]isEqual:expected]);
 engineDebug=YES;errorCode=0;NSString *longMessage=[@"" stringByPaddingToLength:300 withString:@"x" startingAtIndex:0];assert([self appendDebugMessage:longMessage]&&errorReads==3);
 [expected appendData:[[[longMessage substringToIndex:255]stringByAppendingString:@"\r"]dataUsingEncoding:NSASCIIStringEncoding]];assert([[NSData dataWithContentsOfFile:journalPath]isEqual:expected]);
 NSString *filePath=journalPath;journalPath=[filePath stringByAppendingPathComponent:@"missing"];
 assert(![self initializeDebugJournal]&&![self appendDebugMessage:@"failed"]&&errorReads==3);
 journalPath=[filePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"directory"];
 assert([NSFileManager.defaultManager createDirectoryAtPath:journalPath withIntermediateDirectories:NO attributes:nil error:NULL]);
 assert(![self initializeDebugJournal]&&![self appendDebugMessage:@"failed"]&&errorReads==3);BOOL directory=NO;assert([NSFileManager.defaultManager fileExistsAtPath:journalPath isDirectory:&directory]&&directory);
 puts("PASS actual journal replacement/TEXT metadata, native header/append/error bytes and CR, disabled gate, Pascal255 limit, independent calls and failed-path/directory preservation");
}
@end
int main(int argc,char **argv){@autoreleasepool{
 assert(argc==3);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
 [[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"sound":@0,@"music":@0}} forName:NSArgumentDomain];
 NSDateComponents *date=[NSDateComponents new];date.year=1904;date.month=date.day=1;date.hour=0;date.minute=2;date.second=3;
 headerBytes=debugHeader(date,1000000000,536870912,0xa411,1,4,YES);NSData *native=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[2]]];assert(native&&[native isEqual:headerBytes]);
 assert(!debugHeader(date,0,0,0,0,0,NO));
 const int32_t clocks[]={100000000,2000000000,-2147483647,100499999,100500000,100500001,98500000};NSArray *fields=@[@" 100",@"2000",@"?147",@" 100",@" 100",@" 101",@"  98"];
 for(unsigned i=0;i<7;i++)assert([debugField(clocks[i]/1000000.0,4)isEqual:fields[i]]);
 assert([debugField(-2147483647/1048576.0,5)isEqual:@"-2048"]);
 NSString *root=[NSTemporaryDirectory()stringByAppendingPathComponent:[@"astrosquid-journal-"stringByAppendingString:NSUUID.UUID.UUIDString]];
 assert([NSFileManager.defaultManager createDirectoryAtPath:root withIntermediateDirectories:NO attributes:nil error:NULL]);journalPath=[root stringByAppendingPathComponent:@"LMEngine Debug file"];
 JournalView *view=[[JournalView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(view);[view checkAGL];[view checkJournal];
 assert([NSFileManager.defaultManager removeItemAtPath:root error:NULL]);return 0;
}}
