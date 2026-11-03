#import "compat.h"
#import <Carbon/Carbon.h>
#import <objc/objc-runtime.h>
#include <stdlib.h>
#include <string.h>
#include <mach/mach_time.h>
#include <unistd.h>
#include "vendor/BlocksRuntime/Block_private.h"
static void retainObject(const void *p){[(id)p retain];}
static void releaseObject(const void *p){[(id)p release];}
__attribute__((constructor)) static void prepareBlocks(void){_Block_use_RR(retainObject,releaseObject);}
void objc_enumerationMutation(id collection){[NSException raise:NSGenericException format:@"Collection changed during enumeration"];}
// Never replace a native method: newer Foundation often forwards old APIs to it.
static void installMissingMethods(Class target){
    void *iterator=NULL;struct objc_method_list *methods,*added=NULL;unsigned count=0;
    while((methods=class_nextMethodList(target,&iterator))){
        for(int i=0;i<methods->method_count;i++){
            Method method=&methods->method_list[i];const char *name=sel_getName(method->method_name);
            if(strncmp(name,"astroTiger_",11))continue;
            SEL selector=sel_registerName(name+11);
            if(class_getInstanceMethod(target,selector))continue;
            added=realloc(added,sizeof(*added)+count*sizeof(struct objc_method));
            added->method_list[count]=*method;added->method_list[count++].method_name=selector;
        }
    }
    if(count){added->obsolete=NULL;added->method_count=count;class_addMethods(target,added);}
    // Runtime owns the method list for the process lifetime.
}
__attribute__((constructor)) static void prepareCompatibility(void){
    const char *names[]={"NSArray","NSMutableArray","NSDictionary","NSMutableDictionary","NSNumber","NSString","NSData","NSProcessInfo","NSView","NSFileManager","NSEvent","NSThread"};
    for(unsigned i=0;i<sizeof(names)/sizeof(*names);i++){
        installMissingMethods((Class)objc_getClass(names[i]));
        installMissingMethods((Class)objc_getMetaClass(names[i]));
    }
}
@interface NSArray (AstroTigerFallback) @end
@implementation NSArray (AstroTigerFallback)
- (id)astroTiger_objectAtIndexedSubscript:(NSUInteger)index{return [self objectAtIndex:index];}
- (id)astroTiger_firstObject{return self.count?[self objectAtIndex:0]:nil;}
- (NSUInteger)astroTiger_countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)count{
    NSUInteger n=MIN(count,self.count-state->state);for(NSUInteger i=0;i<n;i++)buffer[i]=[self objectAtIndex:state->state+i];
    state->state+=n;state->itemsPtr=buffer;state->mutationsPtr=&state->extra[0];return n;
}
@end
static int compareObjects(id a,id b,void *context){return (int)((NSComparisonResult (^)(id,id))context)(a,b);}
@interface NSMutableArray (AstroTigerFallback) @end
@implementation NSMutableArray (AstroTigerFallback)
- (void)astroTiger_setObject:(id)object atIndexedSubscript:(NSUInteger)index{if(index==self.count)[self addObject:object];else [self replaceObjectAtIndex:index withObject:object];}
- (void)astroTiger_sortUsingComparator:(NSComparisonResult (^)(id,id))compare{[self sortUsingFunction:compareObjects context:compare];}
@end
@interface NSDictionary (AstroTigerFallback) @end
@implementation NSDictionary (AstroTigerFallback)
- (id)astroTiger_objectForKeyedSubscript:(id)key{return [self objectForKey:key];}
- (NSUInteger)astroTiger_countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)count{
    // Newer Foundation implements allKeys through fast enumeration: use the primitive instead.
    if(!state->state){state->extra[1]=(unsigned long)[self keyEnumerator];state->state=1;}
    NSEnumerator *keys=(NSEnumerator *)state->extra[1];NSUInteger n=0;id key;
    while(n<count&&(key=[keys nextObject]))buffer[n++]=key;
    state->itemsPtr=buffer;state->mutationsPtr=&state->extra[0];return n;
}
@end
@interface NSMutableDictionary (AstroTigerFallback) @end
@implementation NSMutableDictionary (AstroTigerFallback)
- (void)astroTiger_setObject:(id)object forKeyedSubscript:(id)key{if(object)[self setObject:object forKey:key];else [self removeObjectForKey:key];}
@end
@interface NSNumber (AstroTigerFallback) @end
@implementation NSNumber (AstroTigerFallback)
+ (id)astroTiger_numberWithInteger:(NSInteger)value{return [self numberWithInt:value];}
+ (id)astroTiger_numberWithUnsignedInteger:(NSUInteger)value{return [self numberWithUnsignedInt:value];}
- (NSInteger)astroTiger_integerValue{return [self intValue];}
- (NSUInteger)astroTiger_unsignedIntegerValue{return [self unsignedIntValue];}
@end
@interface NSString (AstroTigerFallback) @end
@implementation NSString (AstroTigerFallback)
- (NSInteger)astroTiger_integerValue{return [self intValue];}
- (NSComparisonResult)astroTiger_localizedStandardCompare:(NSString *)value{return [self compare:value options:NSNumericSearch|NSCaseInsensitiveSearch];}
@end
@interface NSData (AstroTigerFallback) @end
@implementation NSData (AstroTigerFallback)
+ (id)astroTiger_dataWithContentsOfFile:(NSString *)path options:(NSUInteger)options error:(NSError **)error{
    id data=[self dataWithContentsOfFile:path];if(!data&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:260 userInfo:nil];return data;
}
- (BOOL)astroTiger_writeToFile:(NSString *)path options:(NSUInteger)options error:(NSError **)error{
    BOOL ok=[self writeToFile:path atomically:options!=0];if(!ok&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:512 userInfo:nil];return ok;
}
@end
@interface NSProcessInfo (AstroTigerFallback) @end
@implementation NSProcessInfo (AstroTigerFallback)
- (NSTimeInterval)astroTiger_systemUptime{mach_timebase_info_data_t scale;mach_timebase_info(&scale);return mach_absolute_time()*((double)scale.numer/scale.denom)/1e9;}
@end
@interface NSView (AstroTigerFallback) @end
@implementation NSView (AstroTigerFallback)
- (NSRect)astroTiger_convertRectToBacking:(NSRect)rect{return rect;}
- (BOOL)astroTiger_inFullScreenMode{return NO;}
- (void)astroTiger_exitFullScreenModeWithOptions:(NSDictionary *)options{}
@end
@interface NSFileManager (AstroTigerFallback) @end
@implementation NSFileManager (AstroTigerFallback)
- (BOOL)astroTiger_createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)intermediate attributes:(NSDictionary *)attributes error:(NSError **)error{
    if(intermediate){NSString *parent=[path stringByDeletingLastPathComponent];BOOL directory=NO;
        if(![self fileExistsAtPath:parent isDirectory:&directory]&&parent.length&&![parent isEqual:path])
            if(![self createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:attributes error:error])return NO;
    }
    BOOL ok=[self createDirectoryAtPath:path attributes:attributes];if(!ok&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:512 userInfo:nil];return ok;
}
- (BOOL)astroTiger_setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error{
    BOOL ok=[self changeFileAttributes:attributes atPath:path];if(!ok&&error)*error=[NSError errorWithDomain:NSCocoaErrorDomain code:512 userInfo:nil];return ok;
}
@end
@interface NSEvent (AstroTigerFallback) @end
@implementation NSEvent (AstroTigerFallback)
+ (NSUInteger)astroTiger_pressedMouseButtons{return Button()?1:0;}
@end
@interface NSThread (AstroTigerFallback) @end
@implementation NSThread (AstroTigerFallback)
+ (void)astroTiger_sleepForTimeInterval:(NSTimeInterval)seconds{[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];}
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
