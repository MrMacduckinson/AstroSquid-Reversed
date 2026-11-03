#ifndef ASTRO_TIGER_COMPAT_H
#define ASTRO_TIGER_COMPAT_H
#import <Cocoa/Cocoa.h>
#import "vendor/BlocksRuntime/Block.h"
#include <stdint.h>
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1050
typedef int NSInteger;
typedef unsigned int NSUInteger;
typedef float CGFloat;
typedef struct {unsigned long state; id *itemsPtr; unsigned long *mutationsPtr; unsigned long extra[5];} NSFastEnumerationState;
@protocol NSApplicationDelegate @end
@protocol NSWindowDelegate @end
#endif
typedef NSUInteger NSEventModifierFlags;
#define NSEventModifierFlagCommand NSCommandKeyMask
#define NSEventModifierFlagOption NSAlternateKeyMask
#define NSEventModifierFlagShift NSShiftKeyMask
#define NSEventModifierFlagControl NSControlKeyMask
#define NSEventModifierFlagCapsLock NSAlphaShiftKeyMask
#define NSEventModifierFlagFunction NSFunctionKeyMask
#define NSEventMaskKeyDown NSKeyDownMask
#define NSBitmapImageFileTypePNG NSPNGFileType
#define NSAlertStyleCritical NSCriticalAlertStyle
#define NSRunLoopCommonModes ((NSString *)kCFRunLoopCommonModes)
#define NSEventTypeKeyDown NSKeyDown
#define NSEventTypeKeyUp NSKeyUp
#define NSEventTypeFlagsChanged NSFlagsChanged
#define NSEventTypeLeftMouseDown NSLeftMouseDown
#define NSEventTypeLeftMouseUp NSLeftMouseUp
#define NSEventMaskAny NSAnyEventMask
#define NSWindowStyleMaskTitled NSTitledWindowMask
#define NSWindowStyleMaskClosable NSClosableWindowMask
#define NSWindowStyleMaskMiniaturizable NSMiniaturizableWindowMask
#define NSCalendarUnitYear NSYearCalendarUnit
#define NSCalendarUnitMonth NSMonthCalendarUnit
#define NSCalendarUnitDay NSDayCalendarUnit
#define NSCalendarUnitHour NSHourCalendarUnit
#define NSCalendarUnitMinute NSMinuteCalendarUnit
#define NSCalendarUnitSecond NSSecondCalendarUnit
#define NSJSONWritingPrettyPrinted 1
#define ASTRO_STORE(slot,...) do {id newObject=(__VA_ARGS__); [newObject retain]; [(slot) release]; (slot)=newObject;} while(0)
@interface AstroTigerSerialization:NSObject
+ (id)JSONObjectWithData:(NSData *)data options:(NSUInteger)options error:(NSError **)error;
+ (NSData *)dataWithJSONObject:(id)object options:(NSUInteger)options error:(NSError **)error;
@end
@interface NSArray (AstroTiger)
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (id)firstObject;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)count;
@end
@interface NSMutableArray (AstroTiger)
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
- (void)sortUsingComparator:(NSComparisonResult (^)(id,id))compare;
@end
@interface NSDictionary (AstroTiger)
- (id)objectForKeyedSubscript:(id)key;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)count;
@end
@interface NSMutableDictionary (AstroTiger)
- (void)setObject:(id)object forKeyedSubscript:(id)key;
@end
@interface NSNumber (AstroTiger)
+ (id)numberWithInteger:(NSInteger)value;
+ (id)numberWithUnsignedInteger:(NSUInteger)value;
- (NSInteger)integerValue;
- (NSUInteger)unsignedIntegerValue;
@end
@interface NSString (AstroTiger)
- (NSInteger)integerValue;
- (NSComparisonResult)localizedStandardCompare:(NSString *)value;
@end
@interface NSData (AstroTiger)
+ (id)dataWithContentsOfFile:(NSString *)path options:(NSUInteger)options error:(NSError **)error;
- (BOOL)writeToFile:(NSString *)path options:(NSUInteger)options error:(NSError **)error;
@end
@interface NSProcessInfo (AstroTiger)
- (NSTimeInterval)systemUptime;
@end
@interface NSView (AstroTiger)
- (NSRect)convertRectToBacking:(NSRect)rect;
- (BOOL)inFullScreenMode;
- (void)exitFullScreenModeWithOptions:(NSDictionary *)options;
@end
@interface NSFileManager (AstroTiger)
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)intermediate attributes:(NSDictionary *)attributes error:(NSError **)error;
- (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error;
@end
@interface NSEvent (AstroTiger)
+ (NSUInteger)pressedMouseButtons;
@end
@interface NSThread (AstroTiger)
+ (void)sleepForTimeInterval:(NSTimeInterval)seconds;
@end
#endif
