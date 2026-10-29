#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#include "scores.h"

typedef void (^AstroUISpriteDrawer)(NSInteger sprite,double x,double y,double width,double height);
typedef GLuint (^AstroUITextureLoader)(NSInteger texture);

@interface AstroUIRenderer : NSObject
@property(nonatomic,readonly) NSString *anchor;
@property(nonatomic,readonly) BOOL transitioning;
/* Original signed16 global+a52; default corresponds to FPS60. */
@property(nonatomic) int16_t frameInterval;
@property(nonatomic,readonly) double panelOffset;
@property(nonatomic,readonly) double cameraX,cameraY,cameraStepX,cameraStepY;
- (void)advanceMenuCamera;
- (void)animateMenuObjects;
- (void)handleSpritesAtTick:(uint32_t)tick;
- (void)beginPauseExit;
@property(nonatomic) BOOL gameOverClosing;
- (void)beginGameOverExit;
- (void)finishGameOverExit;
@property(nonatomic) BOOL registered;
@property(nonatomic,copy) NSString *registeredName;
/* Root owns the original Pascal overflow and Stop/Continue policy. */
@property(nonatomic,copy) NSString *(^registrationFooterText)(NSString *prefix,NSString *name);
@property(nonatomic) NSInteger activeRegistrationField;
- (AstroScoreEditor *)registrationFields;
- (NSRect)registrationFieldBounds:(unsigned)index;
- (BOOL)selectRegistrationFieldX:(double)x y:(double)y;
- (int)editRegistrationByte:(unsigned)byte;
- (void)resetRegistrationFields;
/* 1-based row, zero disables new-score entry. Root handles text input. */
@property(nonatomic) NSInteger editingHighscore;
@property(nonatomic,copy) NSString *editingName;
@property(nonatomic) NSInteger editingCursor;
@property(nonatomic,copy) uint32_t (^readTick)(void);
@property(nonatomic,readonly) BOOL editingCaretVisible;
@property(nonatomic,readonly) NSRect scoreField;
- (void)prepareScoreField;
- (BOOL)scoreFieldContainsX:(double)x y:(double)y;
- (void)beginScoreClock:(uint32_t)tick;
@property(nonatomic) NSInteger unlockedLevel;
@property(nonatomic) BOOL smooth;
@property(nonatomic) double soundVolume,musicVolume;
@property(nonatomic,copy) NSArray<NSString *> *keyLabels;
@property(nonatomic,copy) NSArray<NSDictionary *> *highscores;
- (instancetype)initWithAssets:(NSString *)assets error:(NSError **)error;
/* Main Menu / Play Menu / Settings Menu / Continue Menu / Keys Menu /
   Highscores Menu / Register Menu / Reg Thanks / Pause / GameOver. */
- (void)show:(NSString *)anchor;
/* Original PUTCONTROLS: source-order random phase for orb records only. */
- (void)reloadMenuWithRandom:(uint32_t *)seed;
/* Initialize stars/drift between orb RNG and the original unrendered camera move. */
- (void)reloadMenuWithRandom:(uint32_t *)seed afterRandomization:(void (^)(void))initializeBackground;
- (void)moveMouseX:(double)x y:(double)y;
- (void)pollMouseX:(double)x y:(double)y;
/* Return the action; the root owns its navigation transaction. */
- (NSString *)mouseDownX:(double)x y:(double)y;
/* Release pointer state; activation is handled on mouse down. */
- (NSString *)mouseUpX:(double)x y:(double)y;
- (void)animateTicks:(unsigned)ticks;
- (void)drawSprites:(AstroUISpriteDrawer)sprites texture:(AstroUITextureLoader)texture;
- (NSInteger)scoreCursorAtX:(double)x;
- (void)setButton:(NSString *)name pressed:(BOOL)pressed;
- (double)clickPosition:(NSString *)name;
- (NSString *)nameForKeyCode:(NSInteger)code;
- (double)textWidth:(NSString *)text size:(double)size;
- (void)drawText:(NSString *)text x:(double)x baseline:(double)y size:(double)size
        texture:(AstroUITextureLoader)texture;
/* Original LMDRAWPICTURE: zero width/height uses original image dimensions;
   zero x/y centers that axis in 640x480. */
- (void)drawPicture:(NSInteger)identifier x:(double)x y:(double)y width:(double)width
             height:(double)height texture:(AstroUITextureLoader)texture;
/* list 400 = stage introduction, 401 = midpoint, 402 = end card. */
- (NSString *)briefingForStage:(NSInteger)stage list:(NSInteger)list;
- (void)drawBriefingForStage:(NSInteger)stage list:(NSInteger)list texture:(AstroUITextureLoader)texture;
- (void)drawSplashWithTexture:(AstroUITextureLoader)texture;
- (void)drawEndingPage:(NSInteger)page texture:(AstroUITextureLoader)texture;
@end
