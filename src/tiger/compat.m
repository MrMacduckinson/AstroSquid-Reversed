#import "compat.h"
#import <Carbon/Carbon.h>
#include <mach/mach_time.h>
#include <unistd.h>
#include "vendor/BlocksRuntime/Block_private.h"
static void retainObject(const void *p){[(id)p retain];}
static void releaseObject(const void *p){[(id)p release];}
__attribute__((constructor)) static void prepareBlocks(void){_Block_use_RR(retainObject,releaseObject);}
void objc_enumerationMutation(id collection){[NSException raise:NSGenericException format:@"Collection changed during enumeration"];}
@implementation NSArray (AstroTiger)
- (id)objectAtIndexedSubscript:(NSUInteger)index{return [self objectAtIndex:index];}
- (id)firstObject{return self.count?[self objectAtIndex:0]:nil;}
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)count{
    NSUInteger n=MIN(count,self.count-state->state);for(NSUInteger i=0;i<n;i++)buffer[i]=[self objectAtIndex:state->state+i];
    state->state+=n;state->itemsPtr=buffer;state->mutationsPtr=&state->extra[0];return n;
}
@end
static int compareObjects(id a,id b,void *context){return (int)((NSComparisonResult (^)(id,id))context)(a,b);}
@implementation NSMutableArray (AstroTiger)
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index{if(index==self.count)[self addObject:object];else [self replaceObjectAtIndex:index withObject:object];}
- (void)sortUsingComparator:(NSComparisonResult (^)(id,id))compare{[self sortUsingFunction:compareObjects context:compare];}
@end
@implementation NSDictionary (AstroTiger)
- (id)objectForKeyedSubscript:(id)key{return [self objectForKey:key];}
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)count{
    if(!state->state)state->extra[1]=(unsigned long)[self allKeys];
    return [(NSArray *)state->extra[1] countByEnumeratingWithState:state objects:buffer count:count];
}
@end
@implementation NSMutableDictionary (AstroTiger)
- (void)setObject:(id)object forKeyedSubscript:(id)key{if(object)[self setObject:object forKey:key];else [self removeObjectForKey:key];}
@end
@implementation NSNumber (AstroTiger)
+ (id)numberWithInteger:(NSInteger)value{return [self numberWithInt:value];}
+ (id)numberWithUnsignedInteger:(NSUInteger)value{return [self numberWithUnsignedInt:value];}
- (NSInteger)integerValue{return [self intValue];}
- (NSUInteger)unsignedIntegerValue{return [self unsignedIntValue];}
@end
@implementation NSString (AstroTiger)
- (NSInteger)integerValue{return [self intValue];}
- (NSComparisonResult)localizedStandardCompare:(NSString *)value{return [self compare:value options:NSNumericSearch|NSCaseInsensitiveSearch];}
@end
@implementation NSData (AstroTiger)
+ (id)dataWithContentsOfFile:(NSString *)path options:(NSUInteger)options error:(NSError **)error{
    id data=[self dataWithContentsOfFile:path];if(!data&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:260 userInfo:nil];return data;
}
- (BOOL)writeToFile:(NSString *)path options:(NSUInteger)options error:(NSError **)error{
    BOOL ok=[self writeToFile:path atomically:options!=0];if(!ok&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:512 userInfo:nil];return ok;
}
@end
@implementation NSProcessInfo (AstroTiger)
- (NSTimeInterval)systemUptime{mach_timebase_info_data_t scale;mach_timebase_info(&scale);return mach_absolute_time()*((double)scale.numer/scale.denom)/1e9;}
@end
@implementation NSView (AstroTiger)
- (NSRect)convertRectToBacking:(NSRect)rect{return rect;}
- (BOOL)inFullScreenMode{return NO;}
- (void)exitFullScreenModeWithOptions:(NSDictionary *)options{}
@end
@implementation NSFileManager (AstroTiger)
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)intermediate attributes:(NSDictionary *)attributes error:(NSError **)error{
    if(intermediate){NSString *parent=[path stringByDeletingLastPathComponent];BOOL directory=NO;
        if(![self fileExistsAtPath:parent isDirectory:&directory]&&parent.length&&![parent isEqual:path])
            if(![self createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:attributes error:error])return NO;
    }
    BOOL ok=[self createDirectoryAtPath:path attributes:attributes];if(!ok&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:512 userInfo:nil];return ok;
}
- (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error{
    BOOL ok=[self changeFileAttributes:attributes atPath:path];if(!ok&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:512 userInfo:nil];return ok;
}
@end
@implementation NSEvent (AstroTiger)
+ (NSUInteger)pressedMouseButtons{return Button()?1:0;}
@end
@implementation NSThread (AstroTiger)
+ (void)sleepForTimeInterval:(NSTimeInterval)seconds{[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];}
@end
static NSString *jsonString(id object){
    if(object==[NSNull null])return @"null";
    if(CFGetTypeID((CFTypeRef)object)==CFBooleanGetTypeID())return [object boolValue]?@"true":@"false";
    if([object isKindOfClass:[NSNumber class]])return [object description];
    if([object isKindOfClass:[NSString class]]){
        NSMutableString *s=[NSMutableString stringWithString:@"\""];
        for(NSUInteger i=0;i<[object length];i++){unichar c=[object characterAtIndex:i];
            if(c=='"'||c=='\\')[s appendFormat:@"\\%C",c];else if(c<32)[s appendFormat:@"\\u%04x",c];else [s appendFormat:@"%C",c];}
        [s appendString:@"\""];return s;
    }
    NSMutableArray *values=[NSMutableArray array];
    if([object isKindOfClass:[NSArray class]]){
        for(id value in object)[values addObject:jsonString(value)];return [NSString stringWithFormat:@"[%@]",[values componentsJoinedByString:@","]];
    }
    if([object isKindOfClass:[NSDictionary class]]){
        for(id key in object)[values addObject:[NSString stringWithFormat:@"%@: %@",jsonString(key),jsonString([object objectForKey:key])]];
        return [NSString stringWithFormat:@"{%@}",[values componentsJoinedByString:@","]];
    }
    [NSException raise:NSInvalidArgumentException format:@"Unsupported report object"];return nil;
}
static id decodeResource(id value){
    if([value isKindOfClass:[NSDictionary class]]){
        if([value count]==1&&[[value objectForKey:@"__AstroSquidNull__"]boolValue])return [NSNull null];
        NSMutableDictionary *result=[NSMutableDictionary dictionary];for(id key in value)[result setObject:decodeResource([value objectForKey:key]) forKey:key];return result;
    }
    if([value isKindOfClass:[NSArray class]]){NSMutableArray *result=[NSMutableArray array];for(id item in value)[result addObject:decodeResource(item)];return result;}
    return value;
}
@implementation AstroTigerSerialization
+ (id)JSONObjectWithData:(NSData *)data options:(NSUInteger)options error:(NSError **)error{
    NSString *message=nil;id value=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&message];
    if(!value&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:3840 userInfo:nil];[message release];return value?decodeResource(value):nil;
}
+ (NSData *)dataWithJSONObject:(id)object options:(NSUInteger)options error:(NSError **)error{return [jsonString(object) dataUsingEncoding:NSUTF8StringEncoding];}
@end
