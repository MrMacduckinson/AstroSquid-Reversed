#import "../src/tiger/compat.h"
#include <assert.h>
#import <objc/objc-runtime.h>
@interface NSDictionary (TestFallback)
- (NSUInteger)astroTiger_countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)objects count:(NSUInteger)count;
@end
@interface NSArray (InstallProbe)
- (NSString *)astroTiger_installProbe;
- (NSString *)astroTiger_description;
@end
@implementation NSArray (InstallProbe)
- (NSString *)astroTiger_installProbe{return @"installed";}
- (NSString *)astroTiger_description{return @"must not replace native description";}
@end
@interface NSArray (InstalledProbe)
- (NSString *)installProbe;
@end
// A dictionary implemented using only Foundation's required primitives exercises
// inherited allKeys, unlike concrete dictionaries that override that method.
@interface PrimitiveDictionary : NSDictionary { NSArray *keys; }
- (id)initWithCount:(NSUInteger)count;
@end
@implementation PrimitiveDictionary
- (id)initWithCount:(NSUInteger)count {
    self=[super init];if(self){NSMutableArray *values=[NSMutableArray array];
        for(NSUInteger i=0;i<count;i++)[values addObject:[NSNumber numberWithUnsignedInt:i]];
        keys=[values copy];}return self;
}
- (void)dealloc{[keys release];[super dealloc];}
- (NSUInteger)count{return [keys count];}
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)objects count:(NSUInteger)count{return [self astroTiger_countByEnumeratingWithState:state objects:objects count:count];}
- (NSEnumerator *)keyEnumerator{return [keys objectEnumerator];}
- (id)objectForKey:(id)key{return [keys containsObject:key]?key:nil;}
@end
int main(void){NSAutoreleasePool *pool=[NSAutoreleasePool new];
    NSArray *array=[NSArray arrayWithObject:@"native"];
    assert([[array installProbe]isEqual:@"installed"]);
    assert(![[array description]isEqual:@"must not replace native description"]);
    puts("PASS Tiger installs missing methods and preserves existing selectors");
    for(NSUInteger size=0;size<=40;size+=20){
        NSDictionary *dict=[[[PrimitiveDictionary alloc]initWithCount:size]autorelease];
        assert([[dict allKeys]count]==size);
        NSUInteger count=0;unsigned sum=0;
        for(NSNumber *key in dict){count++;sum+=[key unsignedIntValue];}
        assert(count==size&&sum==size*(size-1)/2);
        count=0;for(id outer in dict){for(id inner in dict){assert([dict objectForKey:inner]);count++;}break;}
        assert(count==size);
    }
    NSString *folder=[NSTemporaryDirectory()stringByAppendingPathComponent:[[NSProcessInfo processInfo]globallyUniqueString]];
    NSFileManager *manager=[NSFileManager defaultManager];NSError *error=nil;
    assert([manager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error]);
    assert([manager setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0700] forKey:NSFilePosixPermissions] ofItemAtPath:folder error:&error]);
    assert([manager removeFileAtPath:folder handler:nil]);
    puts("PASS Tiger compatible file operations preserve native implementations");
    puts("PASS Tiger dictionary inherited allKeys, empty/multiple batches and nested enumeration");
    [pool drain];return 0;
}
