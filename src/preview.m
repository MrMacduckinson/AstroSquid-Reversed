// Native reconstruction; validation scope and platform support are in README.md.
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <IOKit/hidsystem/IOLLEvent.h>
#import <OpenGL/gl.h>
#import <AVFoundation/AVFoundation.h>
#include <dlfcn.h>
#include <unistd.h>
#include <errno.h>
#include "physics.h"
#include "picture.h"
static void *debugAGLLibrary(void){
    static void *library;static dispatch_once_t once;
    dispatch_once(&once,^{library=dlopen("/System/Library/Frameworks/AGL.framework/AGL",RTLD_LAZY|RTLD_LOCAL);});return library;
}
static NSString *debugField(double value,int width){
    NSString *text=[NSString stringWithFormat:@"%*.0f",width,value];
    return text.length>(NSUInteger)width?[@"?" stringByAppendingString:[text substringFromIndex:text.length-width+1]]:text;
}
static NSData *debugHeader(NSDateComponents *date,int32_t clock,int32_t memory,uint32_t version,int major,int minor,BOOL fullscreen){
    unsigned packed=((version>>12)&15)*1000+((version>>8)&15)*100+((version>>4)&15)*10+(version&15);
    if(packed<100)return nil;
    NSString *system=[NSString stringWithFormat:@" %u",packed];system=[system substringFromIndex:system.length-4];
    NSString *text=[NSString stringWithFormat:
        @"---------- Lost Minds Sprite Engine Debug File -----------\r"
         "If you are having problems, send this file to bugs@lostminds.com\r"
         "File created %02ld/%02ld/%02ld    at %02ld:%02ld:%02ld\r\r"
         "---------- System Info -----------\rProcessor: %@ MHz\rMemory:%@ MB\r"
         "MacOS version: %@.%@.%@\rAGL version: % d.%d\r\r"
         "---------- LM Engine Info -----------\rBuild # 22\r\r"
         "LMSettings.ScreenWidth =  640\rLMSettings.ScreenHeight =  480\r"
         "LMSettings.SpriteCullingFlag = TRUE\rLMSettings.ClearBackgroundFlag = FALSE\r"
         "LMSettings.DebugFlag= TRUE\rLMSettings.FullscreenFlag= %@\r"
         "LMSettings.WindowTitle$ = 'AstroSquid'\rLMSettings.SmoothScalingFlag = TRUE\r"
         "LMSettings.ClassicFlag = FALSE\r\r\r---------- Startup -----------\r",
        (long)date.month,(long)date.day,(long)(date.year%100),(long)date.hour,(long)date.minute,(long)date.second,
        debugField(clock/1000000.0,4),debugField(memory/1048576.0,5),[system substringToIndex:2],
        [system substringWithRange:NSMakeRange(2,1)],[system substringFromIndex:3],major,minor,fullscreen?@"TRUE":@"FALSE"];
    return [text dataUsingEncoding:NSMacOSRomanStringEncoding];
}
static __weak NSView *fullscreenView;
static void restoreFullscreen(void){
    @autoreleasepool {NSView *view=fullscreenView;if(view.inFullScreenMode){[view setHidden:YES];[view exitFullScreenModeWithOptions:nil];}fullscreenView=nil;}
}
#include "ppc_math.h"
#include "script.h"
#include "weapons.h"
#include "combat.h"
#include "beams.h"
#include "player.h"
#include "campaign.h"
#include "flow.h"
#include "scores.h"
#include "transition.h"
#include "hit_visual.h"
#include "visual.h"
#include "effects.h"
#include "debris.h"
#include "special.h"
#include "scene.h"
#import "audio.h"
#import "ui_renderer.h"
#import "hud_renderer.h"
#include "ui_model.h"
#include <assert.h>

@class AstroView;
typedef struct { __unsafe_unretained AstroView *view; __unsafe_unretained NSArray *objects; AstroTarget *targets; int soundCue,soundX,soundPlayed; } BeamContext;
typedef struct { __unsafe_unretained AstroView *view; __unsafe_unretained id enemy; } EnemyContext;
typedef struct {AstroVisual visual;int layer;uint64_t birth;} LiveEffect;
typedef struct {AstroVisual *visual;uint64_t birth;__unsafe_unretained id owner;int kind;} VisualUpdate;
static int visualOrder(const void *a,const void *b){uint64_t x=((const VisualUpdate *)a)->birth,y=((const VisualUpdate *)b)->birth;return (x>y)-(x<y);}

@interface AstroEnemy : NSObject {
@public
    AstroScriptState state;
    NSDictionary *placement, *definition;
    NSData *program;
    int kind,subtype,layer,renderLayer,hitPoints,baseSprite;
    AstroVisual visual;
    AstroRect bounds,previousBounds;
    BOOL active,visualDeleted;
    __unsafe_unretained AstroEnemy *parent;
    // Keep the traversal link alive when nested cleanup retires a cached node.
    id nextActor;
    uint64_t renderBirth;
}
@end
@implementation AstroEnemy
@end

@interface AstroView : NSOpenGLView {
    NSDictionary *game;
    NSMutableDictionary *textures;
    NSArray *levels;
    NSMutableArray *enemies,*world,*mapPlacements;
    id playerNextActor;
    unsigned actorTraversalDepth;
    AstroCombatState playerCombat;
    uint32_t randomSeed,lastPlayerShot;
    AstroVelocity menuScroll;
    int score;
    NSUInteger emittedShots,damageHits,emittedBeams;
    int playerWeapon;
    int16_t preferenceFPS;
    AstroInventory inventory;
    AstroCampaign campaign;
    AstroFlow flow;
    AstroTransition transition;
    AstroCampaign pendingCampaign;
    BOOL changingStage,engineGlow,departureTrail,finalArena;
    uint64_t engineGlowBirth;
    uint32_t playerSpawnTick;
    AstroTransitionRect departureGlow,trailRect,engineGlowRect;
    AstroScore highscores[10];
    AstroScoreEditor scoreEditor;
    NSMutableData *scoreKeyEvents;
    int campaignAction;
    uint32_t respawnTick,invulnerableUntil; // Active markers, not deadlines: elapsed comparisons must survive wrap.
    uint32_t respawnWaitStartTick;
    BOOL respawnPending;
    uint32_t respawnStartTick,respawnBlinkTick;
    double respawnBlinkWidth;
    BOOL paused,gameOver,gameOverPending,pauseLoopRunning;
    BOOL menuMouseLatched;
    BOOL quitRequested,gameLoopActive,gameEndRequested,gameEndHighscores,terminationAllowed;
    NSArray *presentedBeams;
    uint32_t presentedBeamSeed;
    BOOL simulationRender,deferPresent,menuFrameActive;
    uint32_t worldRenderTick,visualRateTick;
    int16_t visualFrames,hudRedraws;
    BOOL panelTransitionRender;
    int32_t visualSprites;
    double visualRate;
    BOOL visualDebug,wallClockPoll,nestedWorldRender;
    BOOL engineDebug,fullscreenRequested,graphicsReleased,spriteMapsPreloaded;
    NSString *screenshotBase;
    uint32_t simulationTick,lastSpawnTick;
    NSUInteger scriptSteps;
    uint32_t actorVisits;
    NSString *assetPath;
    NSTimer *timer;
    AstroAudio *audio;
    AstroUIRenderer *ui;
    NSString *navigationButton;
    NSMutableData *registrationKeyEvents;
    AstroHUDRenderer *hud;
    BOOL menuVisible,splashVisible;
    uint64_t renderClock,playerRenderBirth;
    NSData *keyCaptureTestMap;
    int controlKeys[6],editingKey;
    AstroSpriteInfo spriteInfo[1001];
    NSMutableArray *visualEffects;
    AstroVisual playerVisual;
    BOOL playerVisualDeleted;
    AstroStar stars[3000];
    BOOL starsInitialized;
    NSArray *backgrounds;
    NSMutableData *parallaxData;
    double tickedScroll;
    AstroRect playerBounds,previousPlayerBounds;
    NSUInteger emittedEffects,emittedSpecials;
    AstroSpecial special;
    BOOL specialLoopRunning,specialEntered,specialReturnPending;
    AstroEnemy *specialSourceActor;
    uint32_t specialRealOrigin,specialSimulationOrigin;
    NSArray *specialTargetObjects;
    NSMutableData *specialTargetData;
    NSMutableArray *specialPolygons,*specialFlashes;
    BOOL keys[128];
    NSInteger selectedLevel;
    double camera,worldTop,worldBottom;
    double playerX,playerY,playerEntityX,playerEntityY;
    double previousTime,clockOrigin;
    uint32_t observedWallTick;
    BOOL initialReadyCard,readyLoadPending;
    BOOL cardClockStarted;
    uint32_t cardDelayStartTick;
    double tickRemainder;
    AstroVelocity playerVelocity;
    AstroPlayer playerState;
    AstroPlayerHitVisual playerHitVisual;
    uint64_t playerHitBirth;
    int playerHitLayer;
    BOOL automatic;
    NSString *selftestPath,*campaignTestPath;
    NSMutableArray *campaignVisits;
    NSUInteger campaignTestTicks,campaignLastChange;
    int campaignLastBossHP;
    double campaignLastCamera;
    NSInteger selftestTicks;
    double selftestStartX;
    BOOL selftestStageSwitched,selftestMoved,selftestWaitingSpecial;
    NSUInteger selftestExpectedSpecial;
}
- (instancetype)initWithFrame:(NSRect)frame assets:(NSString *)path;
- (NSPoint)currentMenuMousePoint;
- (void)beginSelfTest:(NSString *)path;
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context;
- (AstroEnemy *)createBeam:(const AstroBeam *)beam;
- (void)deleteActor:(id)object;
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context actor:(AstroEnemy *)actor;
- (void)renderBeams:(const AstroSceneSink *)sink;
- (void)hitPlayerWithEnemy:(AstroEnemy *)enemy;
- (void *)emitDeathEffect:(const AstroDeathEffect *)effect;
- (void)finishDeathEffect:(const AstroDeathEffect *)effect object:(void *)object baseTick:(uint32_t)tick;
- (void)spawnSpecial:(const AstroSpecialSpawn *)spawn;
- (AstroEnemy *)createSpecial:(const AstroSpecialSpawn *)spawn;
- (void)finishSpecial:(const AstroSpecialSpawn *)spawn object:(AstroEnemy *)enemy;
- (void)spawnShot:(const AstroShot *)shot source:(int)kind;
- (void)addSpecialBeam:(const AstroBeam *)beam temporary:(int)temporary context:(BeamContext *)context;
- (void)addSpecialSprite:(int)sprite x:(double)x y:(double)y width:(double)width height:(double)height;
- (void)addSpecialPolygon:(const AstroSpecialVertex *)vertices count:(size_t)count;
- (uint32_t)currentGameTick;
- (void)playSound:(int)index x:(double)x;
- (void)playBeamSound:(int)index x:(int)x;
- (void)drawSceneSprite:(const AstroSceneSprite *)sprite;
- (void)createSceneSprite:(const AstroSceneSprite *)sprite;
- (void)fireWeapon:(int)weapon x:(int)x y:(int)y heading:(int)heading source:(int)kind;
- (void)moveChildren:(AstroEnemy *)parent heading:(int)heading amount:(double)amount;
- (void)renderSpecialWorld;
- (void)presentSpecialFrame;
- (void)drawSpecialOverlays;
- (uint32_t)specialClockTick;
- (uint32_t)playerClockTick;
- (void)prepareSpecialContext:(AstroSpecialContext *)context;
- (void)calculateSpecialContext:(AstroSpecialContext *)context world:(BeamContext *)worldContext;
- (void)animateSpecialWorld;
- (void)readSpecialKeys;
- (void)finishPlayerUpdateAtTick:(uint32_t)tick;
- (void)handleVisualEffects;
- (void)readVisualKeys;
- (void)presentFrame;
- (void)beginGameLoop;
- (void)requestQuit;
- (BOOL)canTerminateApplication;
- (void)pollGame;
- (void)pollMapSpawns;
@end

static double number(NSDictionary *d, NSString *key) { return [d[key] doubleValue]; }

static void enemyFire(void *context,int weapon,int x,int y,int heading) {
    EnemyContext *source=context;
    [source->view fireWeapon:weapon x:x y:y heading:heading source:5];
}

static void enemyMoveChildren(void *context,int heading,double amount) {
    EnemyContext *source=context;[source->view moveChildren:source->enemy heading:heading amount:amount];
}

static void enemyHit(void *context) {
    EnemyContext *source=context;[source->view hitPlayerWithEnemy:source->enemy];
}

static void beamHit(void *context,const AstroBeam *beam) {
    BeamContext *world=context;
    if(world->soundCue&&!world->soundPlayed){[world->view playBeamSound:world->soundCue x:world->soundX];world->soundPlayed=1;}
    [world->view applyBeam:beam context:world actor:[world->view createBeam:beam]];
}

typedef struct {__unsafe_unretained AstroView *view;uint32_t tick;} DeathContext;
static void *createDeathEffect(void *context,const AstroDeathEffect *effect){DeathContext *c=context;return [c->view emitDeathEffect:effect];}
static void finishDeathEffect(void *context,void *object,const AstroDeathEffect *effect){DeathContext *c=context;[c->view finishDeathEffect:effect object:object baseTick:c->tick];}

static void specialSpawn(void *c,const AstroSpecialSpawn *s) {BeamContext *w=c;[w->view spawnSpecial:s];}
static void *specialCreate(void *c,const AstroSpecialSpawn *s){BeamContext *w=c;return (__bridge void *)[w->view createSpecial:s];}
static void specialFinish(void *c,void *object,const AstroSpecialSpawn *s){BeamContext *w=c;[w->view finishSpecial:s object:(__bridge AstroEnemy *)object];}
static void specialBullet(void *c,const AstroShot *s) {BeamContext *w=c;[w->view spawnShot:s source:1];}
static void specialBeam(void *c,const AstroBeam *b,int temporary) {BeamContext *w=c;[w->view addSpecialBeam:b temporary:temporary context:w];}
static void specialSprite(void *c,int sprite,double x,double y,double width,double height) {
    BeamContext *w=c;[w->view addSpecialSprite:sprite x:x y:y width:width height:height];
}
static void specialPolygon(void *c,const AstroSpecialVertex *v,size_t n) {BeamContext *w=c;[w->view addSpecialPolygon:v count:n];}
static void specialSound(void *c,int index,double x) {BeamContext *w=c;[w->view playSound:index x:x];}
static void specialRenderWorld(void *c) {BeamContext *w=c;[w->view renderSpecialWorld];}
static void specialPresent(void *c) {BeamContext *w=c;[w->view presentSpecialFrame];}
static uint32_t actorReadTick(void *c){return [(__bridge AstroView *)c playerClockTick];}
static uint32_t specialReadTick(void *c) {BeamContext *w=c;return [w->view specialClockTick];}
static void specialPrepare(void *c,AstroSpecialContext *s) {BeamContext *w=c;[w->view prepareSpecialContext:s];}
static void specialCalculate(void *c,AstroSpecialContext *s) {BeamContext *w=c;[w->view calculateSpecialContext:s world:w];}
static void specialAnimate(void *c) {BeamContext *w=c;[w->view animateSpecialWorld];}
static void specialKeys(void *c) {BeamContext *w=c;[w->view readSpecialKeys];}

static void sceneLine(void *context,double x,double y,double ex,double ey,AstroLineStyle style) {
    (void)context;glDisable(GL_TEXTURE_2D);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glLineWidth(style.width);glColor4d(style.r,style.g,style.b,style.a);
    glBegin(GL_LINES);glVertex2d(x,y);glVertex2d(ex,ey);glEnd();
}
static void sceneSprite(void *context,const AstroSceneSprite *sprite) {[(__bridge AstroView *)context drawSceneSprite:sprite];}
static void scenePoint(void *context,double x,double y,double gray) {
    (void)context;glDisable(GL_TEXTURE_2D);glPointSize(1);glColor4d(gray,gray,gray,1);
    glBegin(GL_POINTS);glVertex2d(x,y);glEnd();
}
static void sceneTrail(void *context,double x,double y,double ex,double gray) {
    (void)context;glDisable(GL_TEXTURE_2D);glShadeModel(GL_SMOOTH);glLineWidth(1);
    glBegin(GL_LINES);glColor4d(gray,gray,gray,1);glVertex2d(x,y);glColor4d(0,0,0,1);glVertex2d(ex,y);glEnd();
}

@implementation AstroView
- (instancetype)initWithFrame:(NSRect)frame assets:(NSString *)path {
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADoubleBuffer, NSOpenGLPFAAccelerated,
        NSOpenGLPFAColorSize, 24, NSOpenGLPFAAlphaSize, 8, 0
    };
    NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    self = [super initWithFrame:frame pixelFormat:format];
    if (!self) return nil;
    unsigned char startupKeys[16];[self copyKeyMap:startupKeys];engineDebug=(startupKeys[55>>3]>>(55&7))&1;
    fullscreenRequested=!((startupKeys[58>>3]>>(58&7))&1);
    screenshotBase=[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
    clockOrigin=NSProcessInfo.processInfo.systemUptime;
    randomSeed=[self macLocalSeconds];astro_random(&randomSeed,1);
    assetPath = [path copy];
    NSData *data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"game.json"]];
    NSError *error = nil;
    game = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!game) {
        NSLog(@"Cannot read game data: %@", error);
        return nil;
    }
    levels = [[game[@"levels"] allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    if (!levels.count) return nil;
    for(NSString *key in game[@"sprites"]) {
        int index=key.intValue;if(index<0||index>=1001) {NSLog(@"Invalid sprite ID");return nil;}
        NSDictionary *entry=game[@"sprites"][key];
        spriteInfo[index]=(AstroSpriteInfo){[entry[@"width"] intValue],[entry[@"height"] intValue],
            [entry[@"next_frame"] intValue],[entry[@"delay"] intValue]};
    }
    textures = [NSMutableDictionary dictionary];
    enemies=[NSMutableArray array];world=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    visualEffects=[NSMutableArray array];specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    backgrounds=@[];parallaxData=[NSMutableData data];
    playerX = 30; playerY = 190;automatic=YES;worldBottom=380;
    previousTime = [NSDate timeIntervalSinceReferenceDate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self
                                           selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    ui=[[AstroUIRenderer alloc] initWithAssets:path error:&error];
    if(!ui) {NSLog(@"Cannot load original interface: %@",error);return nil;}
    __weak AstroView *weakView=self;ui.readTick=^{return [weakView currentGameTick];};
    ui.registered=YES;ui.registeredName=@"MACSPB";editingKey=-1;
    ui.unlockedLevel=MAX(1,MIN(16,[[NSUserDefaults standardUserDefaults] integerForKey:@"AstroSquidUnlockedLevel"]));
    int defaults[6]={55,58,126,125,123,124};memcpy(controlKeys,defaults,sizeof(defaults));
    NSUserDefaults *preferences=[NSUserDefaults standardUserDefaults];
    NSDictionary *settings=[preferences dictionaryForKey:@"AstroSquidSettings"];
    preferenceFPS=settings[@"fps"]?[settings[@"fps"] shortValue]:60;
    ui.frameInterval=astro_frame_interval(preferenceFPS);
    if(settings) {
        ui.smooth=[settings[@"smooth"] boolValue];
        ui.soundVolume=fmax(0,fmin(1,[settings[@"sound"] doubleValue]));
        ui.musicVolume=fmax(0,fmin(1,[settings[@"music"] doubleValue]));
        NSArray *stored=settings[@"keys"];
        if(stored.count==6)for(int i=0;i<6;i++)if([stored[i] intValue]>=0&&[stored[i] intValue]<128)controlKeys[i]=[stored[i] intValue];
    }
    [self refreshKeyLabels];
    [self loadScores];
    hud=[[AstroHUDRenderer alloc] initWithGame:game ui:ui];
    hud.didDrawSprite=^(NSInteger sprite,double x,double y,double w,double h){[weakView countSpriteX:x y:y width:w height:h];};
    menuVisible=YES;splashVisible=YES;
    return self;
}
- (BOOL)acceptsFirstResponder { return YES; }
- (void)prepareOpenGL {
    [super prepareOpenGL];
    GLint interval = 1;
    [[self openGLContext] setValues:&interval forParameter:NSOpenGLCPSwapInterval];
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0,0,0,0);
}
- (BOOL)initializeAudio {
    if(audio)return YES;
    [self appendDebugMessage:@"Loading Sound..."];
    NSError *error=nil;
    audio=[[AstroAudio alloc] initWithAssets:assetPath beforeMusic:^(AstroAudio *sound){
        sound.soundVolume=ui.soundVolume/2;[self appendDebugMessage:@"Loading Music..."];
    } error:&error];
    if(!audio){NSLog(@"Cannot load original audio: %@",error);return NO;}
    audio.musicVolume=ui.musicVolume;[audio playMusic:1];return YES;
}
- (void)preloadSpriteMaps {
    if(spriteMapsPreloaded)return;
    [self appendDebugMessage:@"Loading SpriteMaps..."];
    for(int identifier=0;identifier<107;identifier++)[self texture:identifier];
    spriteMapsPreloaded=YES;
}
- (void)killSpriteMap:(NSInteger)identifier {
    NSNumber *key=@(identifier);if(!textures[key])return;
    GLuint texture=[textures[key] unsignedIntValue];glDeleteTextures(1,&texture);[textures removeObjectForKey:key];
}
- (void)setMenuCursor:(int)identifier {SetThemeCursor(identifier==4?kThemeWatchCursor:kThemeArrowCursor);}
- (GLuint)texture:(NSInteger)identifier {
    NSNumber *key = @(identifier);
    if (textures[key]) return [textures[key] unsignedIntValue];
    NSString *file = [assetPath stringByAppendingPathComponent:
                      [NSString stringWithFormat:@"atlases/%ld.png", (long)identifier]];
    NSBitmapImageRep *source = (NSBitmapImageRep *)[NSBitmapImageRep imageRepWithContentsOfFile:file];
    if (!source) return 0;
    NSInteger width = source.pixelsWide, height = source.pixelsHigh;
    if(source.bitsPerSample!=8||source.samplesPerPixel!=4||source.isPlanar||
        !(source.bitmapFormat&NSAlphaNonpremultipliedBitmapFormat)||(source.bitmapFormat&NSAlphaFirstBitmapFormat)||source.bytesPerRow%4) {
        NSLog(@"Unsupported atlas pixel layout %@",file);exit(1);
    }
    GLuint texture = 0;
    glGenTextures(1,&texture);
    glBindTexture(GL_TEXTURE_2D,texture);
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);glPixelStorei(GL_UNPACK_ROW_LENGTH,(GLint)(source.bytesPerRow/4));
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,ui.smooth?GL_LINEAR:GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,ui.smooth?GL_LINEAR:GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,(GLsizei)width,(GLsizei)height,0,
                 GL_RGBA,GL_UNSIGNED_BYTE,source.bitmapData);
    glPixelStorei(GL_UNPACK_ROW_LENGTH,0);
    textures[key] = @(texture);
    return texture;
}
- (BOOL)countSpriteX:(double)x y:(double)y width:(double)w height:(double)h {
    // Carbon SetRect truncates each component before testing integer intersection.
    int16_t left=(int16_t)astro_ppc_i32(x),top=(int16_t)astro_ppc_i32(y);
    int16_t right=(int16_t)((uint32_t)astro_ppc_i32(x)+(uint32_t)astro_ppc_i32(w));
    int16_t bottom=(int16_t)((uint32_t)astro_ppc_i32(y)+(uint32_t)astro_ppc_i32(h));
    if(right<=left||bottom<=top||right<=0||bottom<=0||left>=640||top>=480)return NO;
    visualSprites=(int32_t)((uint32_t)visualSprites+1u);return YES;
}
- (void)sprite:(NSInteger)identifier x:(double)x y:(double)y width:(double)w height:(double)h {
    if(![self countSpriteX:x y:y width:w height:h])return;
    NSDictionary *sprite = game[@"sprites"][[NSString stringWithFormat:@"%ld",(long)identifier]];
    if (!sprite) return;
    NSInteger atlasID = [sprite[@"texture"] integerValue];
    NSDictionary *atlas = game[@"textures"][[NSString stringWithFormat:@"%ld",(long)atlasID]];
    GLuint texture = [self texture:atlasID];
    if (!texture) return;
    double u = number(sprite,@"x")/number(atlas,@"width");
    double v = number(sprite,@"y")/number(atlas,@"height");
    double u2 = u+number(sprite,@"width")/number(atlas,@"width");
    double v2 = v+number(sprite,@"height")/number(atlas,@"height");
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D,texture);
    glColor4d(1,1,1,1);
    glBegin(GL_QUADS);
    glTexCoord2d(u,v); glVertex2d(x,y);
    glTexCoord2d(u2,v); glVertex2d(x+w,y);
    glTexCoord2d(u2,v2); glVertex2d(x+w,y+h);
    glTexCoord2d(u,v2); glVertex2d(x,y+h);
    glEnd();
}
- (void)createSceneSprite:(const AstroSceneSprite *)scene {
    uint64_t birth=0;uint32_t tick=0;
    if(simulationRender){birth=++renderClock;tick=[self playerClockTick];}
    if(scene->persistent) {
        if(!simulationRender)return;
        AstroVisual v={scene->sprite,scene->xy[0]+camera,scene->xy[1],
            scene->xy[2]-scene->xy[0],scene->xy[5]-scene->xy[1],
            tick+(uint32_t)spriteInfo[scene->sprite].delay};
        LiveEffect effect={v,7,birth};
        [visualEffects addObject:[NSMutableData dataWithBytes:&effect length:sizeof(effect)]];return;
    }
}
- (void)drawSceneSprite:(const AstroSceneSprite *)scene {
    [self createSceneSprite:scene];
    if(scene->persistent)return;
    if(![self countSpriteX:scene->rect[0] y:scene->rect[1] width:scene->rect[2] height:scene->rect[3]])return;
    NSDictionary *sprite=game[@"sprites"][[NSString stringWithFormat:@"%d",scene->sprite]];
    int atlas=[sprite[@"texture"] intValue];NSDictionary *definition=game[@"textures"][[NSString stringWithFormat:@"%d",atlas]];
    GLuint texture=[self texture:atlas];if(!texture) return;
    double u=number(sprite,@"x")/number(definition,@"width"),v=number(sprite,@"y")/number(definition,@"height");
    double du=number(sprite,@"width")/number(definition,@"width"),dv=number(sprite,@"height")/number(definition,@"height");
    double uv[8]={u,v,u+du,v,u+du,v+dv,u,v+dv};
    glEnable(GL_TEXTURE_2D);glBindTexture(GL_TEXTURE_2D,texture);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    glColor4d(1,1,1,scene->alpha);glBegin(GL_QUADS);
    for(int i=0;i<4;i++) {glTexCoord2d(uv[i*2],uv[i*2+1]);glVertex2d(scene->xy[i*2],scene->xy[i*2+1]);}glEnd();
}
- (void)drawHUD:(BOOL)consume {
    if(consume&&!hudRedraws)return;
    AstroHUDState overlay={[world containsObject:[NSNull null]]&&!(flow.phase==ASTRO_FLOW_READY&&!initialReadyCard),playerCombat.hit_points,inventory.weapon,
        inventory.upgrade,inventory.specials,inventory.lives,score};
    NSRect bounds=[self convertRectToBacking:self.bounds];
    [hud drawState:&overlay texture:^GLuint(NSInteger n){return [self texture:n];}
        framebufferWidth:(GLsizei)bounds.size.width height:(GLsizei)bounds.size.height];
    if(consume)hudRedraws--;
}
- (void)drawRect:(NSRect)dirty {
    if(graphicsReleased)return;
    [[self openGLContext] makeCurrentContext];
    NSRect bounds = [self convertRectToBacking:self.bounds];
    if(!spriteMapsPreloaded){
        visualRateTick=[self currentGameTick];
        glViewport(0,0,(GLsizei)bounds.size.width,(GLsizei)bounds.size.height);
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);glLoadIdentity();glClear(GL_COLOR_BUFFER_BIT);
        [ui drawPicture:40 x:0 y:0 width:0 height:0 texture:^GLuint(NSInteger n){return [self texture:n];}];
        [self presentFrame];[self preloadSpriteMaps];if(![self initializeAudio])exit(1);[self reloadMainMenu];
    }
    glViewport(0,(GLint)(bounds.size.height*30/480),(GLsizei)bounds.size.width,(GLsizei)(bounds.size.height*380/480));
    BOOL worldOverlay=menuVisible&&([ui.anchor isEqual:@"Pause"]||[ui.anchor isEqual:@"GameOver"]);
    // Original RENDERGAMEWINDOW preserves both buffers outside its world draws.
    if(!worldOverlay&&(menuVisible||flow.phase!=ASTRO_FLOW_PLAY))glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION); glLoadIdentity(); glOrtho(0,640,379,0,-1,1);
    glMatrixMode(GL_MODELVIEW); glLoadIdentity();
    if(!menuVisible&&flow.phase!=ASTRO_FLOW_PLAY) {
        [self drawHUD:NO];
        glViewport(0,0,(GLsizei)bounds.size.width,(GLsizei)bounds.size.height);
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);
        glMatrixMode(GL_MODELVIEW);glLoadIdentity();
        [ui drawPicture:astro_flow_picture(&flow) x:0 y:40 width:0 height:0 texture:^GLuint(NSInteger n){return [self texture:n];}];
        if(flow.phase==ASTRO_FLOW_ENDING)
            [ui drawEndingPage:flow.ending_page texture:^GLuint(NSInteger n){return [self texture:n];}];
        else [ui drawBriefingForStage:flow.stage list:astro_flow_text_list(&flow) texture:^GLuint(NSInteger n){return [self texture:n];}];
        [self presentFrame];[self recordCardPresentation];return;
    }
    BOOL hudAfterWorld=worldOverlay||nestedWorldRender||gameOver||(changingStage&&transition.simulate_world);
    BOOL worldHUD=!(changingStage&&!transition.simulate_world);
    if(menuVisible&&!worldOverlay) {
        glViewport(0,0,(GLsizei)bounds.size.width,(GLsizei)bounds.size.height);
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);
        glMatrixMode(GL_MODELVIEW);glLoadIdentity();
        if(splashVisible) {
            [ui drawSplashWithTexture:^GLuint(NSInteger n){return [self texture:n];}];
            [self presentFrame];return;
        }
        AstroSceneSink menuSink={(__bridge void *)self,sceneLine,sceneSprite,scenePoint,sceneTrail};
        astro_stars_draw(stars,1,campaign.level,0,&menuSink);
        if(menuFrameActive){menuFrameActive=NO;[self handleMenuSprites];[self pollMenuMouse];}
        visualSprites=0;
        [ui drawSprites:^(NSInteger n,double x,double y,double w,double h){
            [self sprite:n x:x y:y width:w height:h];
        } texture:^GLuint(NSInteger n){return [self texture:n];}];
        if(!deferPresent)[self presentFrame];return;
    }
    // GAMELOOP paints HUD first; RENDERGAMEWINDOW can cover its shared edge.
    if(!hudAfterWorld&&worldHUD)[self drawHUD:YES];
    if(campaign.level<4||campaign.level==7) {
        glDisable(GL_TEXTURE_2D);glDisable(GL_BLEND);glColor3d(0,0,0);glBegin(GL_QUADS);
        glVertex2d(0,0);glVertex2d(640,0);glVertex2d(640,380);glVertex2d(0,380);glEnd();
    }
    AstroSceneSink sink={(__bridge void *)self,sceneLine,sceneSprite,scenePoint,sceneTrail};
    astro_stars_draw(stars,0,campaign.level,tickedScroll,&sink);
    visualSprites=0;
    glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    const AstroParallax *parallax=parallaxData.bytes;
    for(NSUInteger i=0;i<backgrounds.count;i++) {
        NSDictionary *background=backgrounds[i];
        [self sprite:[background[@"sprite"] integerValue] x:parallax[i].x-camera y:parallax[i].y
            width:number(background,@"width") height:number(background,@"height")];
    }
    NSMutableArray *renderObjects=[enemies mutableCopy];
    if([world containsObject:[NSNull null]])[renderObjects addObject:[NSNull null]];
    [renderObjects sortUsingComparator:^NSComparisonResult(id a,id b) {
        uint64_t first=a==[NSNull null]?playerRenderBirth:((AstroEnemy *)a)->renderBirth;
        uint64_t second=b==[NSNull null]?playerRenderBirth:((AstroEnemy *)b)->renderBirth;
        return first<second?NSOrderedAscending:first>second?NSOrderedDescending:NSOrderedSame;
    }];
    for(int layer=4;layer<=6;layer++) {
        for(id object in renderObjects) {
            if(object==[NSNull null]) {
                if(layer==6&&!playerVisualDeleted)
                    [self sprite:playerVisual.sprite x:playerX y:playerY width:playerVisual.width height:playerVisual.height];
                continue;
            }
            AstroEnemy *enemy=object;
            if(enemy->renderLayer!=layer||enemy->visualDeleted)continue;
            double x=enemy->visual.x-camera,y=enemy->visual.y;
            [self sprite:enemy->visual.sprite x:x y:y width:enemy->visual.width height:enemy->visual.height];
        }
        if(layer==4&&departureTrail)[self sprite:116 x:trailRect.x-camera y:trailRect.y width:trailRect.width height:trailRect.height];
    }
    [self renderBeams:&sink];
    NSMutableArray *effectsToDraw=[visualEffects mutableCopy];
    if(engineGlow) {
        AstroTransitionRect glow=departureTrail?departureGlow:engineGlowRect;
        LiveEffect effect={{115,glow.x,glow.y,glow.width,glow.height,0},8,engineGlowBirth};
        [effectsToDraw addObject:[NSData dataWithBytes:&effect length:sizeof(effect)]];
    }
    if(playerHitVisual.active) {
        LiveEffect effect={playerHitVisual.visual,playerHitLayer,playerHitBirth};
        [effectsToDraw addObject:[NSData dataWithBytes:&effect length:sizeof(effect)]];
    }
    [effectsToDraw sortUsingComparator:^NSComparisonResult(NSData *a,NSData *b){
        const LiveEffect *x=a.bytes,*y=b.bytes;
        if(x->layer!=y->layer)return x->layer<y->layer?NSOrderedAscending:NSOrderedDescending;
        return x->birth<y->birth?NSOrderedAscending:x->birth>y->birth?NSOrderedDescending:NSOrderedSame;
    }];
    for(NSData *data in effectsToDraw) {
        const AstroVisual *v=data.bytes;
        [self sprite:v->sprite x:v->x-camera y:v->y width:v->width height:v->height];
    }
    if(!simulationRender)[self drawSpecialOverlays];
    if(hudAfterWorld&&!worldOverlay&&worldHUD)[self drawHUD:YES];
    if(worldOverlay) {
        // Panel UI coordinates include70; the original keeps the world projection.
        glPushMatrix();glTranslated(0,-70,0);
        [ui drawSprites:^(NSInteger n,double x,double y,double w,double h){[self sprite:n x:x y:y width:w height:h];}
            texture:^GLuint(NSInteger n){return [self texture:n];}];
        glPopMatrix();
        [self drawHUD:[ui.anchor isEqual:@"Pause"]&&!panelTransitionRender];
    }
    if(!deferPresent){[self presentFrame];}
}
- (void)drawSpecialOverlays {
    glDisable(GL_TEXTURE_2D);glShadeModel(GL_SMOOTH);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    for(NSData *data in specialPolygons) {
        const AstroSpecialVertex *v=data.bytes;size_t n=data.length/sizeof(*v);glBegin(GL_POLYGON);
        for(size_t i=0;i<n;i++) {glColor4d(v[i].r,v[i].g,v[i].b,v[i].a);glVertex2d(v[i].x-camera,v[i].y);}glEnd();
    }
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    for(NSData *data in specialFlashes) {
        const AstroVisual *v=data.bytes;[self sprite:v->sprite x:v->x-camera y:v->y width:v->width height:v->height];
    }
}
- (void)renderSpecialWorld {
    simulationTick=worldRenderTick;
    deferPresent=YES;simulationRender=YES;[self display];simulationRender=NO;deferPresent=NO;
}
- (void)presentFrame {
    if(visualDebug){
        // The original rate is assigned from the signed16 frame counter.
        NSString *text=[NSString stringWithFormat:@"% .0f fps % d sprites drawn",visualRate,visualSprites];
        glColor3d(1,1,1);[ui drawText:text x:6 baseline:22 size:12 texture:^GLuint(NSInteger n){return [self texture:n];}];
    }
    visualFrames=(int16_t)((uint16_t)visualFrames+1u);
    if(campaignTestPath)glFlush();else [[self openGLContext] flushBuffer];
    glLoadIdentity();
}
- (void)presentSpecialFrame {
    [[self openGLContext] makeCurrentContext];[self drawSpecialOverlays];
    [self presentFrame];
}
- (AstroEnemy *)entityForPlacement:(NSDictionary *)placement {
    NSString *attribute=[placement[@"attribute"] stringValue];
    AstroEnemy *enemy=[AstroEnemy new];enemy->renderBirth=++renderClock;
    enemy->placement=placement; enemy->definition=game[@"attributes"][attribute];
    enemy->baseSprite=[enemy->definition[@"sprite"] intValue];
    uint32_t updateTick=[self playerClockTick];
    uint32_t animationTick=[self playerClockTick];
    uint32_t actionTick=[self playerClockTick];
    uint32_t visualTick=[self playerClockTick];
    enemy->visual=(AstroVisual){enemy->baseSprite,number(placement,@"x"),number(placement,@"y"),
        number(placement,@"width"),number(placement,@"height"),visualTick+(uint32_t)spriteInfo[enemy->baseSprite].delay};
    enemy->bounds=(AstroRect){(int)enemy->visual.x,(int)enemy->visual.y,
        (int)(enemy->visual.x+enemy->visual.width),(int)(enemy->visual.y+enemy->visual.height)};
    enemy->previousBounds=(AstroRect){0};
    enemy->state=(AstroScriptState){.frame=1,.tilt=1,.state=1,
        .update_tick=updateTick,.animation_tick=animationTick,.action_tick=actionTick,
        .x=number(placement,@"x"),.y=number(placement,@"y")};
    int group=attribute.intValue/10;enemy->subtype=attribute.intValue-group*10;
    enemy->kind=group>5&&group<20?5:group;
    enemy->layer=enemy->kind==5||(enemy->kind>=20&&enemy->kind<30)?2:0;
    enemy->renderLayer=enemy->kind==5?5:(enemy->kind>=20&&enemy->kind<30)?4:
        (enemy->kind==1||enemy->kind==2||enemy->kind==4||enemy->kind==40)?6:1;
    enemy->hitPoints=[enemy->definition[@"hit_points"] intValue];
    NSString *script=[enemy->definition[@"script"] stringValue];
    NSMutableData *program=[NSMutableData data];
    for(NSString *line in game[@"scripts"][script]) {
        AstroInstruction instruction;
        if(!astro_parse_instruction(line.UTF8String,&instruction)) {
            NSLog(@"Invalid script %@: %@",script,line); exit(1);
        }
        [program appendBytes:&instruction length:sizeof(instruction)];
    }
    enemy->program=program;
    return enemy;
}
- (void)resetEnemies {
    readyLoadPending=NO;
    score=0;inventory=(AstroInventory){10,0,1,1};playerWeapon=10;
    [self resetLevelWorld];
    [self createPlayerAtX:30 y:190];
}
- (void)resetLevelWorld {
    [self appendDebugMessage:@"0"];
    renderClock=0;enemies=[NSMutableArray array];world=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    playerNextActor=nil;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=100};playerHitVisual=(AstroPlayerHitVisual){0};
    visualEffects=[NSMutableArray array];specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    special=(AstroSpecial){0};specialLoopRunning=specialReturnPending=NO;specialTargetObjects=nil;specialTargetData=nil;
    NSString *stage=levels[selectedLevel];
    finalArena=NO;
    campaign=(AstroCampaign){[[stage substringFromIndex:5] intValue],[stage hasSuffix:@"A"]?1:2,0,0};
    campaignAction=ASTRO_CAMPAIGN_NONE;respawnTick=invulnerableUntil=0;respawnPending=NO;gameOver=NO;gameOverPending=NO;engineGlow=departureTrail=NO;playerVisualDeleted=NO;
    presentedBeams=@[];
    [self loadLevelMap];
}
- (void)loadLevelMap {
    worldTop=70;worldBottom=450;
    NSDictionary *level=game[@"levels"][levels[selectedLevel]];
    if(!starsInitialized) {astro_stars_init(stars,1,&randomSeed);starsInitialized=YES;}
    NSMutableArray *scene=[NSMutableArray array];
    for(NSDictionary *definition in game[@"scenes"][level[@"background"]]){
        NSMutableDictionary *image=[definition mutableCopy];
        image[@"birth"]=@(++renderClock);
        image[@"animation_tick"]=@([self playerClockTick]+(uint32_t)spriteInfo[[image[@"sprite"] intValue]].delay);
        [scene addObject:image];
    }
    backgrounds=scene;
    parallaxData=[NSMutableData dataWithLength:backgrounds.count*sizeof(AstroParallax)];
    AstroParallax *parallax=parallaxData.mutableBytes;
    for(NSUInteger i=0;i<backgrounds.count;i++) parallax[i]=(AstroParallax){
        number(backgrounds[i],@"x"),number(backgrounds[i],@"y"),[backgrounds[i][@"userdata"] intValue]};
    astro_stars_init(stars,0,&randomSeed);tickedScroll=1;
    for(NSDictionary *placement in level[@"entities"]) {
        [mapPlacements addObject:placement];
    }
    [self makeNewSprites];
}
- (void)finishPlayerStart {
    playerCombat.kind=-1;
    // NEWPLAYERSTART samples both local clocks even when it skips the blink loop.
    (void)[self playerClockTick];(void)[self playerClockTick];
    inventory.upgrade=0;hudRedraws=2;playerCombat.kind=1;
}
- (void)createPlayerAtX:(double)x y:(double)y {
    playerState=(AstroPlayer){{0,0},12,1,1,0,0};playerVelocity=(AstroVelocity){0,0};
    playerState.update_tick=[self playerClockTick];playerState.animation_tick=[self playerClockTick];
    lastPlayerShot=[self playerClockTick];
    x=astro_ppc_i32(x);y=astro_ppc_i32(y);playerVisualDeleted=NO;
    playerVisual=(AstroVisual){1,x,y,spriteInfo[1].width,spriteInfo[1].height,[self playerClockTick]+(uint32_t)spriteInfo[1].delay};playerEntityX=x;playerEntityY=y;
    playerX=x-camera;playerY=y;
    playerBounds=(AstroRect){(int16_t)(int32_t)x,(int16_t)(int32_t)y,(int16_t)astro_ppc_i32(x+playerVisual.width),(int16_t)astro_ppc_i32(y+playerVisual.height)};
    previousPlayerBounds=(AstroRect){0};
    playerRenderBirth=++renderClock;playerNextActor=world.firstObject;[world insertObject:[NSNull null] atIndex:0];
}
- (void)prependEnemy:(AstroEnemy *)enemy {
    enemy->active=YES;enemy->nextActor=world.firstObject;[enemies insertObject:enemy atIndex:0];[world insertObject:enemy atIndex:0];
}
- (void)makeNewSprites {
    for(NSDictionary *placement in [mapPlacements copy]) {
        if(!(number(placement,@"x")<camera+740))continue;
        AstroEnemy *enemy=[self entityForPlacement:placement];
        int tag=[placement[@"tag"] intValue];
        if(tag!=(int16_t)tag){
            NSMutableDictionary *stored=[placement mutableCopy];stored[@"tag"]=@((int16_t)tag);enemy->placement=stored;
        }
        enemy->state.x=astro_ppc_i32(enemy->state.x);enemy->state.y=astro_ppc_i32(enemy->state.y);
        enemy->visual.x=enemy->state.x;enemy->visual.y=enemy->state.y;
        uint16_t left=(uint16_t)(int32_t)enemy->state.x;
        uint16_t bottom=(uint16_t)astro_ppc_i32(enemy->state.y+spriteInfo[enemy->baseSprite].height);
        uint16_t mapBottom=(uint16_t)astro_ppc_i32(number(placement,@"y")+number(placement,@"height"));
        // Original sth at entity+39 overlaps left.low and bottom.high in the big-endian Rect.
        enemy->bounds=(AstroRect){(int16_t)((left&0xff00)|(mapBottom>>8)),(int16_t)(int32_t)enemy->state.y,
            (int16_t)astro_ppc_i32(number(placement,@"x")+number(placement,@"width")),
            (int16_t)((bottom&0xff)|((mapBottom&0xff)<<8))};
        [self prependEnemy:enemy];[mapPlacements removeObjectIdenticalTo:placement];
    }
}
- (AstroEnemy *)createBeam:(const AstroBeam *)beam {
    AstroEnemy *actor=[AstroEnemy new];
    actor->placement=@{@"attribute":@30,@"tag":@0};
    actor->definition=game[@"attributes"][@"30"];actor->program=[NSData data];
    actor->kind=2;actor->subtype=10;actor->state.state=1;
    [self prependEnemy:actor];
    actor->state.update_tick=[self playerClockTick];
    actor->state.animation_tick=[self playerClockTick];
    actor->state.action_tick=[self playerClockTick];
    actor->state.frame=1;actor->state.tilt=1;
    actor->state.x=beam->x;actor->state.y=beam->y;
    actor->renderBirth=++renderClock;
    (void)[self playerClockTick]; // NEWSPRITE creates then NEWBEAM destroys its temporary image.
    actor->visualDeleted=YES;
    actor->kind=999;actor->subtype=beam->weapon;actor->layer=1;actor->hitPoints=(int16_t)beam->damage;
    actor->bounds=(AstroRect){(int16_t)beam->x,(int16_t)beam->y,(int16_t)beam->end_x,(int16_t)beam->end_y};
    actor->state.velocity=(AstroVelocity){beam->end_x,(int16_t)beam->end_y};
    return actor;
}
- (void)renderBeams:(const AstroSceneSink *)sink {
    if(simulationRender){
        NSMutableArray *images=[NSMutableArray array];presentedBeamSeed=randomSeed;
        for(id object in [world copy]){
            if(object==[NSNull null])continue;
            AstroEnemy *actor=object;if(actor->kind!=999)continue;
            AstroBeam beam={actor->subtype,actor->hitPoints,(int)actor->state.x,(int)actor->state.y,
                (int)actor->state.velocity.x,(int)actor->state.velocity.y,-1};
            [images addObject:[NSData dataWithBytes:&beam length:sizeof(beam)]];
            astro_beam_render(&beam,-camera,0,camera,worldTop,camera+640,worldBottom,&randomSeed,sink);
            actor->state.remove=1;
        }
        presentedBeams=images;
    }else{
        uint32_t seed=presentedBeamSeed;
        for(NSData *data in presentedBeams)
            astro_beam_render(data.bytes,-camera,0,camera,worldTop,camera+640,worldBottom,&seed,sink);
    }
}
- (void)fireWeapon:(int)identifier x:(int)x y:(int)y heading:(int)heading source:(int)kind {
    if(identifier>=40&&identifier<=53) {
        NSArray *objects=[world copy];size_t count=objects.count;
        NSMutableData *targetData=[self targetsForObjects:objects];AstroTarget *targets=targetData.mutableBytes;
        AstroBeam beams[2];BeamContext context={.view=self,.objects=objects,.targets=targets,
            .soundCue=identifier>=50?295:296,.soundX=identifier>=50?x-10:x+2};
        int emitted=astro_beam_shots(identifier,x,y,heading,ui.frameInterval,kind,-1,targets,count,
            camera,worldTop,camera+640,worldBottom,&randomSeed,beams,beamHit,&context);
        if(emitted<0) {NSLog(@"Invalid beam request");exit(1);}
        emittedBeams+=emitted;return;
    }
    if(identifier>=10&&identifier<=13) [audio playStringCue:297 position:(x-camera)/640];
    if(identifier>=30&&identifier<=33) [audio playStringCue:298 position:(x-camera)/640];
    NSDictionary *definition=game[@"weapons"][[NSString stringWithFormat:@"%d",identifier]];
    if(!definition) return;
    AstroWeapon weapon={.pattern=[definition[@"header_field_2"] intValue]};
    NSArray *entries=definition[@"bullets"];
    for(NSUInteger i=0;i<MIN(entries.count,6);i++) {
        NSArray *entry=entries[i];
        weapon.shots[i]=(AstroShot){[entry[0] intValue],[entry[1] intValue],
                                  [entry[2] intValue],[entry[3] intValue]};
    }
    AstroShot shots[6];
    int count=astro_weapon_shots(&weapon,x,y,heading,&randomSeed,shots);
    if(count<0) {NSLog(@"Invalid weapon pattern %d",identifier);exit(1);}
    for(int i=0;i<count;i++) [self spawnShot:&shots[i] source:kind];
}
- (void)spawnShot:(const AstroShot *)shot source:(int)kind {
    int attribute=20+shot->type;
    NSDictionary *attr=game[@"attributes"][[NSString stringWithFormat:@"%d",attribute]];
    NSDictionary *sprite=game[@"sprites"][[attr[@"sprite"] stringValue]];
    if(!attr||!sprite) {NSLog(@"Missing bullet attribute %d",attribute);exit(1);}
    double width=number(sprite,@"width"),height=number(sprite,@"height");
    NSDictionary *placement=@{@"attribute":@(attribute),
        @"x":@((int)(shot->x-width/2)),@"y":@((int)(shot->y-height/2)),
        @"width":@(width),@"height":@(height)};
    AstroEnemy *bullet=[self entityForPlacement:placement];
    bullet->kind=attribute>30?5:2;bullet->subtype=attribute>30?attribute-50:shot->type;
    bullet->active=YES;bullet->renderLayer=6;
    bullet->layer=kind==5?2:(kind==1||kind==-1)?3:0;
    astro_vector_make(&bullet->state.velocity,shot->heading,number(attr,@"speed"));
    [self prependEnemy:bullet];emittedShots++;
 }
- (NSMutableData *)targetsForObjects:(NSArray *)objects {
    NSMutableData *data=[NSMutableData dataWithLength:objects.count*sizeof(AstroTarget)];
    AstroTarget *targets=data.mutableBytes;
    for(NSUInteger i=0;i<objects.count;i++) {
        if(objects[i]==[NSNull null])targets[i]=(AstroTarget){.kind=playerCombat.kind,.parent=-1,.remove=playerCombat.remove,
            .x=playerEntityX,.y=playerEntityY,.width=playerVisual.width,.height=playerVisual.height,.bounds_valid=1,.bounds=playerBounds};
        else {
            AstroEnemy *enemy=objects[i];targets[i]=(AstroTarget){.kind=enemy->kind,.parent=-1,.remove=enemy->state.remove,
                .x=enemy->state.x,.y=enemy->state.y,.width=enemy->visual.width,.height=enemy->visual.height,
                .bounds_valid=1,.bounds=enemy->bounds};
        }
    }
    return data;
}
- (void)spawnSpecial:(const AstroSpecialSpawn *)spawn {
    AstroEnemy *enemy=[self createSpecial:spawn];[self finishSpecial:spawn object:enemy];
}
- (AstroEnemy *)createSpecial:(const AstroSpecialSpawn *)spawn {
    int attribute=spawn->kind*10+spawn->subtype;
    NSDictionary *definition=game[@"attributes"][[NSString stringWithFormat:@"%d",attribute]];
    int sprite=[definition[@"sprite"] intValue];
    if(!definition||spriteInfo[sprite].width<=0) {NSLog(@"Invalid special entity %d",attribute);exit(1);}
    NSDictionary *placement=@{@"attribute":@(attribute),@"x":@(spawn->x),@"y":@(spawn->y),
        @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height),@"tag":@0};
    AstroEnemy *enemy=[self entityForPlacement:placement];enemy->active=YES;
    [self prependEnemy:enemy];return enemy;
}
- (void)finishSpecial:(const AstroSpecialSpawn *)spawn object:(AstroEnemy *)enemy {
    enemy->kind=spawn->kind;enemy->layer=spawn->layer;enemy->state.frame=spawn->frame;
    enemy->state.velocity=spawn->velocity;
    enemy->state.action_tick+=(uint32_t)spawn->action_offset;
    if(spawn->hit_points>0) enemy->hitPoints=spawn->hit_points;
    if(spawn->width>0) enemy->visual.width=spawn->width;
    if(spawn->height>0) enemy->visual.height=spawn->height;
    if(spawn->scale!=1) {
        enemy->bounds.right=(int16_t)astro_ppc_i32((enemy->bounds.right-enemy->bounds.left)*spawn->scale+enemy->bounds.left);
        enemy->bounds.bottom=(int16_t)astro_ppc_i32((enemy->bounds.bottom-enemy->bounds.top)*spawn->scale+enemy->bounds.top);
        enemy->visual.width*=spawn->scale;enemy->visual.height*=spawn->scale;
    }
}
- (void)addSpecialBeam:(const AstroBeam *)beam temporary:(int)temporary context:(BeamContext *)context {
    AstroEnemy *actor=[self createBeam:beam];
    [self applyBeam:beam context:context actor:actor];
    if(temporary)[self deleteActor:actor];else emittedBeams++;
}
- (void)addSpecialSprite:(int)sprite x:(double)x y:(double)y width:(double)width height:(double)height {
    ++renderClock; // FORCEDRAWSPRITENOW creates and kills an LM image even for one-frame flashes.
    uint32_t deadline=[self playerClockTick]+(uint32_t)spriteInfo[sprite].delay;
    AstroVisual v={sprite,x,y,width,height,deadline};
    [specialFlashes addObject:[NSData dataWithBytes:&v length:sizeof(v)]];
}
- (void)addSpecialPolygon:(const AstroSpecialVertex *)vertices count:(size_t)count {
    [specialPolygons addObject:[NSData dataWithBytes:vertices length:count*sizeof(*vertices)]];
}
- (void)playBeamSound:(int)index x:(int)x {
    [audio playCueIfNotPlaying:index==295?@"Zap":@"Laser" position:(x-camera)/640];
}
- (void)playSound:(int)index x:(double)x {[audio playStringCue:index position:(x-camera)/640];}
- (uint32_t)specialClockTick {
    uint32_t now=[self currentGameTick];
    return (selftestPath||campaignTestPath)?specialSimulationOrigin+(now-specialRealOrigin):now;
}
- (uint32_t)playerClockTick {
    if(specialLoopRunning||specialReturnPending)return [self specialClockTick];
    return (!wallClockPoll&&(selftestPath||campaignTestPath))?simulationTick:[self currentGameTick];
}
- (void)prepareSpecialContext:(AstroSpecialContext *)context {
    if(!specialEntered){if(specialSourceActor)specialSourceActor->kind=-1;else playerCombat.kind=-1;specialEntered=YES;}
    AstroRect bounds=specialSourceActor?specialSourceActor->bounds:playerBounds;
    context->gun_x=bounds.left+74;context->gun_y=bounds.top+12;
}
- (void)calculateSpecialContext:(AstroSpecialContext *)context world:(BeamContext *)worldContext {
    simulationTick=observedWallTick;[self cleanupWorld];[self calculateActors];
    specialTargetObjects=[world copy];specialTargetData=[self targetsForObjects:specialTargetObjects];
    worldContext->objects=specialTargetObjects;worldContext->targets=specialTargetData.mutableBytes;
    context->targets=worldContext->targets;context->target_count=specialTargetObjects.count;
    context->left=camera;context->right=camera+640;
}
- (void)animateSpecialWorld {
    [self handleVisualEffects];
}
- (void)readSpecialKeys {
    [self readKeyMap];
}
- (void)copyKeyMap:(unsigned char *)bytes {
    KeyMap snapshot;GetKeys(snapshot);memcpy(bytes,snapshot,sizeof(snapshot));
}
- (NSString *)debugJournalPath {return [screenshotBase stringByAppendingPathComponent:@"LMEngine Debug file"];}
- (int)debugAGLError {
    void *library=debugAGLLibrary();int (*readError)(void)=library?dlsym(library,"aglGetError"):NULL;return readError?readError():0;
}
- (NSData *)debugJournalHeader {
    SInt32 clock=0,memory=0,version=0;Gestalt('pclk',&clock);Gestalt('ram ',&memory);if(Gestalt(gestaltSystemVersion,&version))return nil;
    int major=0,minor=0;void *library=debugAGLLibrary();void (*readVersion)(int *,int *)=library?dlsym(library,"aglGetVersion"):NULL;if(readVersion)readVersion(&major,&minor);
    NSDateComponents *date=[[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[NSDate date]];
    return debugHeader(date,clock,memory,version,major,minor,fullscreenRequested);
}
- (BOOL)initializeDebugJournal {
    if(!engineDebug)return YES;
    NSString *path=[self debugJournalPath];if(unlink(path.fileSystemRepresentation)&&errno!=ENOENT)return NO;
    NSData *header=[self debugJournalHeader];FILE *file=fopen(path.fileSystemRepresentation,"wb");if(!file)return NO;
    BOOL ok=header&&fwrite(header.bytes,1,header.length,file)==header.length;if(fclose(file))ok=NO;
    if(ok)ok=[NSFileManager.defaultManager setAttributes:@{NSFileHFSTypeCode:@(0x54455854)} ofItemAtPath:path error:NULL];return ok;
}
- (BOOL)appendDebugMessage:(NSString *)message {
    if(!engineDebug)return YES;
    FILE *file=fopen([self debugJournalPath].fileSystemRepresentation,"ab");if(!file)return NO;
    NSData *bytes=[message dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];size_t length=MIN(bytes.length,255);
    BOOL ok=fwrite(bytes.bytes,1,length,file)==length;if(fputc('\r',file)==EOF)ok=NO;
    int error=[self debugAGLError];if(error&&fprintf(file,"   *** AGL Error: % d\r",error)<0)ok=NO;
    if(fclose(file))ok=NO;return ok;
}
- (BOOL)startFullscreen {
    if(!fullscreenRequested)return NO;
    for(NSDictionary *mode in (__bridge NSArray *)CGDisplayAvailableModes(CGMainDisplayID())) {
        if([mode[(__bridge NSString *)kCGDisplayWidth] intValue]!=640||[mode[(__bridge NSString *)kCGDisplayHeight] intValue]!=480||[mode[(__bridge NSString *)kCGDisplayBitsPerPixel] intValue]!=32)continue;
        if(![self enterFullScreenMode:NSScreen.mainScreen withOptions:@{NSFullScreenModeAllScreens:@NO,NSFullScreenModeSetting:mode}])return NO;
        fullscreenView=self;[self lockFocus];[[self openGLContext] update];[self unlockFocus];[self display];return YES;
    }
    return NO;
}
- (uint32_t)screenshotSeconds {return [self macLocalSeconds];}
- (uint32_t)macLocalSeconds {
    CFAbsoluteTime now=CFAbsoluteTimeGetCurrent();CFTimeZoneRef zone=CFTimeZoneCopySystem();
    double local=now+kCFAbsoluteTimeIntervalSince1904+CFTimeZoneGetSecondsFromGMT(zone,now);CFRelease(zone);
    return (uint32_t)(uint64_t)floor(local);
}
- (BOOL)saveScreenshot {
    unsigned channels=self.inFullScreenMode?4:3;size_t pixels=640u*480u*channels;unsigned char *rgb=malloc(pixels),*picture=NULL;size_t size=0;
    if(!rgb)return NO;
    if(self.inFullScreenMode){
        NSOpenGLContext *previous=NSOpenGLContext.currentContext;[[self openGLContext] makeCurrentContext];
        GLint readBuffer,alignment;glGetIntegerv(GL_READ_BUFFER,&readBuffer);glGetIntegerv(GL_PACK_ALIGNMENT,&alignment);
        glReadBuffer(GL_FRONT);glPixelStorei(GL_PACK_ALIGNMENT,1);glReadPixels(0,0,640,480,GL_RGBA,GL_UNSIGNED_BYTE,rgb);
        GLenum error=glGetError();glReadBuffer(readBuffer);glPixelStorei(GL_PACK_ALIGNMENT,alignment);
        if(previous)[previous makeCurrentContext];else [NSOpenGLContext clearCurrentContext];
        if(error!=GL_NO_ERROR){free(rgb);return NO;}
        unsigned char row[640*4];for(unsigned y=0;y<240;y++){unsigned char *top=rgb+y*640*4,*bottom=rgb+(479-y)*640*4;memcpy(row,top,sizeof(row));memcpy(top,bottom,sizeof(row));memcpy(bottom,row,sizeof(row));}
    }else memset(rgb,255,pixels);
    int encoded=(self.inFullScreenMode?astro_picture_fullscreen_encode:astro_picture_window_encode)(rgb,640*channels,640,480,&picture,&size);free(rgb);if(!encoded)return NO;
    NSString *folder=[screenshotBase stringByAppendingPathComponent:@"Screenshots"];
    NSFileManager *manager=NSFileManager.defaultManager;BOOL directory=NO;
    BOOL exists=[manager fileExistsAtPath:folder isDirectory:&directory];
    if((exists&&!directory)||(!exists&&![manager createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:NULL])){free(picture);return NO;}
    char filename[64];if(!astro_picture_filename([self screenshotSeconds],filename,sizeof(filename))){free(picture);return NO;}
    NSString *path=[folder stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]];
    FILE *file=fopen(path.fileSystemRepresentation,"wb");if(!file){free(picture);return NO;}
    [manager setAttributes:@{NSFileHFSTypeCode:@(ASTRO_PICTURE_TYPE),NSFileHFSCreatorCode:@(ASTRO_PICTURE_CREATOR)} ofItemAtPath:path error:NULL];
    unsigned char prefix[512]={0};BOOL success=fwrite(prefix,1,sizeof(prefix),file)==sizeof(prefix)&&fwrite(picture,1,size,file)==size;
    if(fclose(file))success=NO;free(picture);return success;
}
- (void)readKeyMap {
    if(!selftestPath&&!campaignTestPath){
        unsigned char snapshot[16];[self copyKeyMap:snapshot];
        for(unsigned i=0;i<128;i++)keys[i]=(snapshot[i>>3]>>(i&7))&1;
    }
    if(keys[55]&&keys[12])[self requestQuit];
    if(engineDebug&&keys[67]&&![self saveScreenshot])[self appendDebugMessage:@"*** Error while taking screenshot"];
}
- (void)readGameKeys {
    [self readKeyMap];[self handleMiscKeys];
}
- (void)readPauseKeys {
    [self readKeyMap];
    for(unsigned i=0;i<128;i++)if(keys[i]){[self resumePause];break;}
}
- (BOOL)startSpecial {
    return [self startSpecialFrom:nil];
}
- (BOOL)startSpecialFrom:(AstroEnemy *)actor {
    assert(!specialLoopRunning);
    specialSourceActor=actor;
    AstroRect bounds=actor?actor->bounds:playerBounds;
    NSArray *objects=[world copy];NSMutableData *data=[self targetsForObjects:objects];
    BeamContext beamWorld={.view=self,.objects=objects,.targets=data.mutableBytes};
    AstroSpecialContext context={.context=&beamWorld,.seed=&randomSeed,.targets=data.mutableBytes,
        .target_count=objects.count,.source_parent=-1,.gun_x=bounds.left+74,.gun_y=bounds.top+12,
        .frame_interval=ui.frameInterval,.left=camera,.top=worldTop,.right=camera+640,.bottom=worldBottom,
        .render_tick=&worldRenderTick,.action_tick=actor?&actor->state.action_tick:&lastPlayerShot,.render_world=specialRenderWorld,.present=specialPresent,
        .spawn=specialSpawn,.bullet=specialBullet,.beam=specialBeam,.sprite=specialSprite,
        .polygon=specialPolygon,.sound=specialSound,.create_spawn=specialCreate,.finish_spawn=specialFinish};
    inventory.specials--;hudRedraws=2;emittedSpecials++;
    if(!astro_special_start(&special,playerWeapon,context.gun_x,context.gun_y,0,[self playerClockTick],&context)) {
        NSLog(@"Cannot start special attack");exit(1);
    }
    if(!special.active){specialSourceActor=nil;return NO;}
    specialSimulationOrigin=simulationTick;
    if(selftestPath||campaignTestPath){specialRealOrigin=[self currentGameTick];observedWallTick=simulationTick;}
    specialEntered=playerWeapon<50;
    if(specialEntered){if(actor)actor->kind=-1;else playerCombat.kind=-1;}
    specialLoopRunning=YES;
    AstroSpecialLoop loop={.cpu_tick=&observedWallTick,.read_tick=specialReadTick,
        .prepare=specialPrepare,.calculate=specialCalculate,.animate=specialAnimate,.read_keys=specialKeys};
    if(!astro_special_run_nested(&special,&context,&loop)){NSLog(@"Invalid special loop");exit(1);}
    specialLoopRunning=NO;specialReturnPending=YES;if(actor)actor->kind=1;else playerCombat.kind=1;
    specialSourceActor=nil;specialTargetObjects=nil;specialTargetData=nil;
    return YES;
}

- (void)showPlayerHit:(BOOL)scenery {
    [self showPlayerHit:scenery bounds:playerBounds];
}
- (void)showPlayerHit:(BOOL)scenery bounds:(AstroRect)bounds {
    [audio playStringCue:ASTRO_PLAYER_HIT_SOUND position:(bounds.left-camera)/640];
    uint32_t visualTick=[self playerClockTick];
    int result=scenery?astro_player_scenery_hit_visual(&playerHitVisual,bounds,spriteInfo,1001,visualTick):
        astro_player_hit_visual(&playerHitVisual,bounds,spriteInfo,1001,visualTick);
    if(!result){NSLog(@"Invalid player hit visual");exit(1);}
    if(result==1){playerHitBirth=++renderClock;playerHitLayer=scenery?ASTRO_PLAYER_SCENERY_HIT_LAYER:ASTRO_PLAYER_HIT_LAYER;}
}
- (void)hitPlayerWithCombat:(AstroCombatState *)attacker {
    BOOL hit=!attacker->remove&&(attacker->layer==1||attacker->layer==2);
    astro_bullet_hits_player(attacker,&playerCombat);if(hit)hudRedraws=2;
    if(hit&&playerCombat.hit_points>0)[self showPlayerHit:NO];
}
- (void)hitPlayerWithEnemy:(AstroEnemy *)enemy {
    AstroCombatState attacker=[self combatFor:enemy];
    [self hitPlayerWithCombat:&attacker];
    [self applyCombat:attacker to:enemy];
}
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context {
    [self applyBeam:beam context:context actor:nil];
}
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context actor:(AstroEnemy *)actor {
    if(beam->target<0) return;
    AstroCombatState b=actor?[self combatFor:actor]:(AstroCombatState){.kind=999,.layer=1,.hit_points=beam->damage};
    if(context->objects[beam->target]==[NSNull null]) {
        if(playerCombat.kind==1) [self hitPlayerWithCombat:&b];
        context->targets[beam->target].remove=playerCombat.remove;
    } else {
        AstroEnemy *enemy=context->objects[beam->target];
        AstroCombatState target=[self combatFor:enemy];
        if(enemy->kind==1){
            BOOL hit=!b.remove&&(b.layer==1||b.layer==2);
            astro_bullet_hits_player(&b,&target);if(hit)hudRedraws=2;[self applyCombat:target to:enemy];
            if(target.hit_points>0)[self showPlayerHit:NO bounds:enemy->bounds];
            context->targets[beam->target].remove=target.remove;
        }
        if(enemy->kind==5||(enemy->kind>19&&enemy->kind<30)) {
            BOOL hit=!b.remove&&(b.layer==1||b.layer==3);
            int impact=astro_bullet_hits_enemy(&b,&target,[enemy->definition[@"kill_score"] intValue],&score);
            if(hit&&target.hit_points<1)hudRedraws=2;
            if(impact){assert(actor);[self addDeathEffects:actor];}
            if(target.hit_points!=enemy->hitPoints) damageHits++;
            [self applyCombat:target to:enemy];
            context->targets[beam->target].remove=target.remove;
        }
    }
    if(actor)[self applyCombat:b to:actor];
}
- (void *)emitDeathEffect:(const AstroDeathEffect *)effect {
    if(effect->type==ASTRO_EFFECT_SOUND) {
        [audio playStringCue:effect->sound_string position:(effect->x-camera)/640];return NULL;
    }
    emittedEffects++;
    // Generator deadlines encode offsets from simulationTick; retain the constructor's fresh clock.
    if(effect->type==ASTRO_EFFECT_EXPLOSION) {
        uint32_t deadline=[self playerClockTick]+(effect->animation_tick-simulationTick);
        AstroVisual visual={effect->sprite,effect->x,effect->y,effect->width,effect->height,deadline};
        [self addVisualEffect:visual layer:8];return (__bridge void *)visualEffects.lastObject;
    }
    NSDictionary *definition=game[@"attributes"][[NSString stringWithFormat:@"%d",effect->attribute]];
    int sprite=[definition[@"sprite"] intValue];
    double width=effect->type==ASTRO_EFFECT_PICKUP?spriteInfo[sprite].width:effect->width;
    double height=effect->type==ASTRO_EFFECT_PICKUP?spriteInfo[sprite].height:effect->height;
    NSDictionary *placement=@{@"attribute":@(effect->attribute),@"x":@(effect->x),@"y":@(effect->y),
        @"width":@(width),@"height":@(height),@"tag":@0};
    AstroEnemy *enemy=[self entityForPlacement:placement];enemy->active=YES;
    enemy->kind=effect->kind;enemy->subtype=effect->attribute-(effect->type==ASTRO_EFFECT_PICKUP?400:40);
    enemy->state.frame=effect->frame;
    enemy->renderLayer=6;enemy->layer=0;
    enemy->state.velocity=effect->velocity;
    if(effect->type==ASTRO_EFFECT_DEBRIS)enemy->state.action_tick+=effect->action_tick-simulationTick;
    [self prependEnemy:enemy];
    return (__bridge void *)enemy;
}
- (void)finishDeathEffect:(const AstroDeathEffect *)effect object:(void *)object baseTick:(uint32_t)tick {
    if(effect->type==ASTRO_EFFECT_SOUND)return;
    if(effect->type==ASTRO_EFFECT_EXPLOSION){
        NSMutableData *data=(__bridge NSMutableData *)object;LiveEffect *created=data.mutableBytes;
        created->visual.x=effect->x;created->visual.y=effect->y;created->visual.width=effect->width;created->visual.height=effect->height;
        created->visual.next_tick+=effect->animation_tick-(tick+(uint32_t)spriteInfo[effect->sprite].delay);
        return;
    }
    if(effect->type==ASTRO_EFFECT_DEBRIS){
        AstroEnemy *created=(__bridge AstroEnemy *)object;
        created->state.velocity=effect->velocity;created->state.frame=effect->frame;
        created->state.action_tick+=effect->action_tick-tick;
        created->bounds.right=(int16_t)astro_ppc_i32((created->bounds.right-created->bounds.left)*effect->scale+created->bounds.left);
        created->bounds.bottom=(int16_t)astro_ppc_i32((created->bounds.bottom-created->bounds.top)*effect->scale+created->bounds.top);
        created->visual.width=effect->width;created->visual.height=effect->height;
    }
}
- (void)addVisualEffect:(AstroVisual)visual layer:(int)layer {
    LiveEffect effect={visual,layer,++renderClock};
    [visualEffects addObject:[NSMutableData dataWithBytes:&effect length:sizeof(effect)]];
}
- (void)addDeathEffects:(AstroEnemy *)enemy {
    if(enemy->kind==999&&enemy->visualDeleted){
        astro_random(&randomSeed,1);astro_random(&randomSeed,1);return;
    }
    int sprite=enemy->visual.sprite;
    int explosion=[enemy->definition[@"death_effect"] intValue];
    int debris=[enemy->definition[@"debris_sprite"] intValue];
    NSDictionary *debrisDefinition=game[@"attributes"][[NSString stringWithFormat:@"%d",debris]];
    int debrisSprite=[debrisDefinition[@"sprite"] intValue];
    AstroDeathSource source={.kind=enemy->kind,.tag=[enemy->placement[@"tag"] intValue],
        .left=enemy->bounds.left,.top=enemy->bounds.top,.right=enemy->bounds.right,.bottom=enemy->bounds.bottom,
        .width=enemy->visual.width,.height=enemy->visual.height,.original_height=spriteInfo[sprite].height,.render_x=enemy->visual.x,
        .velocity=enemy->state.velocity,.explosion_sprite=explosion,.explosion_width=spriteInfo[explosion].width,
        .explosion_height=spriteInfo[explosion].height,.explosion_delay=spriteInfo[explosion].delay,
        .debris_attribute=debris,.debris_sprite=debrisSprite,.debris_width=spriteInfo[debrisSprite].width,
        .debris_height=spriteInfo[debrisSprite].height,.debris_count=[enemy->definition[@"debris_amount"] intValue]};
    DeathContext context={self,simulationTick};
    if(!astro_death_effects_phased(&source,context.tick,&randomSeed,createDeathEffect,finishDeathEffect,&context)) {
        NSLog(@"Invalid death effect configuration");exit(1);
    }
    if(source.tag==-2)[self enterFinalArena];
}
- (void)enterFinalArena {
    double offset=-camera;
    if([world containsObject:[NSNull null]]){
        playerVisual.x+=offset;playerEntityX+=offset;
    }
    for(AstroEnemy *enemy in enemies){
        enemy->visual.x+=offset;enemy->state.x+=offset;
        if(enemy->renderLayer==2)enemy->visualDeleted=YES;
    }
    for(NSMutableData *data in [visualEffects copy]){
        LiveEffect *effect=data.mutableBytes;effect->visual.x+=offset;
        if(effect->layer==2)[visualEffects removeObjectIdenticalTo:data];
    }
    if(playerHitVisual.active){playerHitVisual.visual.x+=offset;if(playerHitLayer==2)playerHitVisual.active=NO;}
    if(engineGlow)engineGlowRect.x+=offset;
    if(departureTrail)trailRect.x+=offset;
    [mapPlacements removeAllObjects];
    [audio stopMusic];if(ui.musicVolume>0)[audio playMusic:2];
    [self appendDebugMessage:@"0"];
    selectedLevel=[levels indexOfObject:@"Data 9B"];assert(selectedLevel!=NSNotFound);
    camera=-0.0;campaign.arena=0;campaign.complete=0;campaignAction=ASTRO_CAMPAIGN_NONE;finalArena=NO;
    [self loadLevelMap];finalArena=YES;
}
- (void)updateVisualEffects {
    NSMutableData *pending=[NSMutableData dataWithLength:(visualEffects.count+enemies.count+2)*sizeof(VisualUpdate)];
    VisualUpdate *images=pending.mutableBytes;size_t count=0;
    if([world containsObject:[NSNull null]]&&!playerVisualDeleted)images[count++]=(VisualUpdate){&playerVisual,playerRenderBirth,nil,3};
    if(playerHitVisual.active)images[count++]=(VisualUpdate){&playerHitVisual.visual,playerHitBirth,nil,2};
    for(NSMutableData *data in visualEffects){LiveEffect *effect=data.mutableBytes;images[count++]=(VisualUpdate){&effect->visual,effect->birth,data,0};}
    for(AstroEnemy *enemy in enemies)if(enemy->active&&!enemy->visualDeleted)images[count++]=(VisualUpdate){&enemy->visual,enemy->renderBirth,enemy,1};
    qsort(images,count,sizeof(*images),visualOrder);NSMutableArray *finished=[NSMutableArray array];
    for(size_t i=0;i<count;i++){
        VisualUpdate item=images[i];AstroVisual *v=item.visual;
        if(v->sprite<0||v->sprite>=1001){NSLog(@"Invalid visual sprite");exit(1);}
        uint32_t store=simulationTick;
        if(spriteInfo[v->sprite].next_frame>0&&(int32_t)v->next_tick<(int32_t)simulationTick)store=[self playerClockTick];
        int result=astro_visual_step_clocked(v,spriteInfo,1001,simulationTick,store);
        if(result<0){NSLog(@"Invalid visual animation");exit(1);}
        if(!result){
            if(item.kind==0)[finished addObject:item.owner];
            else if(item.kind==1)((AstroEnemy *)item.owner)->visualDeleted=YES;
            else if(item.kind==2)playerHitVisual.active=NO;
            else playerVisualDeleted=YES;
        }
    }
    [visualEffects removeObjectsInArray:finished];
}
- (void)readVisualKeys {unsigned char map[16];[self copyKeyMap:map];visualDebug=(map[122>>3]>>(122&7))&1;}
- (void)handleVisualEffects {
    simulationTick=[self playerClockTick];[self updateVisualEffects];[self handleSpriteDiagnostics];
}
- (void)handleMenuSprites {
    [ui handleSpritesAtTick:[self playerClockTick]];[self handleSpriteDiagnostics];
}
- (void)handleSpriteDiagnostics {
    [self readVisualKeys];
    uint32_t diagnostic=[self playerClockTick];
    if((int32_t)(visualRateTick+60u)<=(int32_t)diagnostic){
        visualRate=visualFrames;visualFrames=0;visualRateTick=[self playerClockTick];
    }
}
- (AstroCombatState)combatFor:(AstroEnemy *)enemy {
    return (AstroCombatState){.kind=enemy->kind,.layer=enemy->layer,
        .hit_points=enemy->hitPoints,.remove=enemy->state.remove,.velocity=enemy->state.velocity};
}
- (void)applyCombat:(AstroCombatState)combat to:(AstroEnemy *)enemy {
    enemy->hitPoints=combat.hit_points;enemy->state.remove=combat.remove;
    enemy->state.velocity=combat.velocity;
}
- (void)checkCollisionsFor:(id)object {
    BOOL playerSource=object==[NSNull null];
    AstroEnemy *source=playerSource?nil:object;
    int kind=playerSource?playerCombat.kind:source->kind;
    AstroRect a=playerSource?playerBounds:source->bounds;
    for(id targetObject in [world copy]) {
        if(object==targetObject)continue;
        BOOL playerTarget=targetObject==[NSNull null];
        AstroEnemy *target=playerTarget?nil:targetObject;
        int targetKind=playerTarget?playerCombat.kind:target->kind;
        if(kind==targetKind)continue;
        AstroRect b=playerTarget?playerBounds:target->bounds;
        if(a.right<=a.left||a.bottom<=a.top||b.right<=b.left||b.bottom<=b.top||
            a.left>=b.right||b.left>=a.right||a.top>=b.bottom||b.top>=a.bottom)continue;
        if((kind==2||kind==5)&&targetKind==1) {
            AstroCombatState attacker=[self combatFor:source];
            if(playerTarget){[self hitPlayerWithCombat:&attacker];playerVelocity=playerCombat.velocity;}
            else {
                AstroCombatState victim=[self combatFor:target];
                BOOL hit=!attacker.remove&&(attacker.layer==1||attacker.layer==2);
                astro_bullet_hits_player(&attacker,&victim);if(hit)hudRedraws=2;[self applyCombat:victim to:target];
                if(hit&&victim.hit_points>0)[self showPlayerHit:NO bounds:b];
            }
            [self applyCombat:attacker to:source];
        } else if(kind==2&&(targetKind==5||(targetKind>=20&&targetKind<=29))) {
            AstroCombatState bullet=[self combatFor:source],victim=[self combatFor:target];
            BOOL hit=!bullet.remove&&(bullet.layer==1||bullet.layer==3);
            int impact=astro_bullet_hits_enemy(&bullet,&victim,[target->definition[@"kill_score"] intValue],&score);
            if(hit&&victim.hit_points<1)hudRedraws=2;
            if(impact)[self addDeathEffects:source];
            if(victim.hit_points!=target->hitPoints)damageHits++;
            [self applyCombat:bullet to:source];[self applyCombat:victim to:target];
        } else if(kind==1&&targetKind==40) {
            int old=target->state.remove;
            AstroCombatState collector=playerSource?playerCombat:[self combatFor:source];
            astro_pickup(&collector,[target->placement[@"attribute"] intValue]%10,target->hitPoints,&target->state.remove,&inventory);
            if(playerSource)playerCombat=collector;else [self applyCombat:collector to:source];
            if(!old&&target->state.remove)[audio playStringCue:[target->placement[@"attribute"] intValue]%10==1?302:
                [target->placement[@"attribute"] intValue]%10==9?304:303 position:(a.left-camera)/640];
            hudRedraws=2;playerWeapon=inventory.weapon+inventory.upgrade;
        } else if(kind==1&&targetKind>=20&&targetKind<=29) {
            AstroCombatState scenery=[self combatFor:target],actor=playerSource?playerCombat:[self combatFor:source];
            if(playerSource)actor.velocity=playerVelocity;
            BOOL hit=!scenery.remove;
            astro_player_hits_scenery(&actor,a,&scenery,b);if(hit)hudRedraws=2;[self applyCombat:scenery to:target];
            if(playerSource){playerCombat=actor;playerVelocity=actor.velocity;}else [self applyCombat:actor to:source];
            if(hit&&actor.hit_points>0)[self showPlayerHit:YES bounds:a];
        }
    }
}
- (void)stepPlayer {
    playerVisual.x+=playerVelocity.x;playerVisual.y+=playerVelocity.y;
    playerVisual.x+=tickedScroll;playerVisual.y+=0.0;
    astro_visual_change(&playerVisual,playerState.frame,spriteInfo,1001,[self playerClockTick]);
    playerEntityX=playerVisual.x;playerEntityY=playerVisual.y;
    playerX=playerVisual.x-camera;playerY=playerVisual.y;
    previousPlayerBounds=playerBounds;
    playerBounds=(AstroRect){(int16_t)(int)playerVisual.x,(int16_t)(int)playerVisual.y,
        (int16_t)(int)(playerVisual.x+playerVisual.width),(int16_t)(int)(playerVisual.y+playerVisual.height)};
    playerCombat.velocity=playerVelocity;
    [self checkCollisionsFor:[NSNull null]];
    if(![self updatePlayerMotion:&playerState velocity:&playerVelocity bounds:playerBounds width:playerVisual.width height:playerVisual.height])return;
    playerCombat.velocity=playerVelocity;
    [self firePlayerWeapons];
}
- (BOOL)updatePlayerMotion:(AstroPlayer *)actor velocity:(AstroVelocity *)velocity bounds:(AstroRect)bounds width:(double)width height:(double)height {
    unsigned controls=0;
    if(keys[controlKeys[4]])controls|=ASTRO_KEY_LEFT;
    if(keys[controlKeys[5]])controls|=ASTRO_KEY_RIGHT;
    if(keys[controlKeys[2]])controls|=ASTRO_KEY_UP;
    if(keys[controlKeys[3]])controls|=ASTRO_KEY_DOWN;
    if(changingStage&&!transition.allow_input)controls=transition.controls;
    uint32_t comparison=[self playerClockTick],store=actor->animation_tick;
    if((int32_t)(comparison-actor->animation_tick)>10)store=[self playerClockTick];
    astro_player_animate(actor,comparison,store,controls);
    comparison=[self playerClockTick];
    if((int32_t)(comparison-actor->update_tick)<=0)return NO;
    actor->velocity=*velocity;
    astro_player_move(actor,controls,1,bounds,width,height,
        (AstroViewport){camera,worldTop,camera+640,worldBottom},changingStage);
    *velocity=actor->velocity;return YES;
}
- (void)firePlayerWeapons {
    [self fireOrdinaryPlayerWeaponFrom:playerBounds actionTick:&lastPlayerShot kind:playerCombat.kind];
    BOOL timed=[self requestPlayerSpecialFrom:nil actionTick:&lastPlayerShot];
    uint32_t finishTick=timed?[self specialClockTick]:[self playerClockTick];
    simulationTick=finishTick;[self finishPlayerUpdateAtTick:finishTick];
}
- (BOOL)requestPlayerSpecialFrom:(AstroEnemy *)actor actionTick:(uint32_t *)actionTick {
    BOOL startSpecial=(!changingStage||transition.allow_input)&&keys[selftestPath?58:controlKeys[1]]&&!special.active&&inventory.specials>0&&
        (int32_t)([self playerClockTick]-*actionTick)>
        60.0/[game[@"weapons"][[NSString stringWithFormat:@"%d",playerWeapon]][@"rate"] doubleValue];
    return startSpecial&&(actor?[self startSpecialFrom:actor]:[self startSpecial]);
}
- (void)fireOrdinaryPlayerWeaponFrom:(AstroRect)bounds actionTick:(uint32_t *)actionTick kind:(int)kind {
    if((!changingStage||transition.allow_input)&&keys[selftestPath?8:controlKeys[0]]&&(int32_t)([self playerClockTick]-*actionTick)>
        60.0/[game[@"weapons"][[NSString stringWithFormat:@"%d",playerWeapon]][@"rate"] doubleValue]) {
        [self fireWeapon:playerWeapon x:astro_ppc_i32(38+(bounds.left+bounds.right)/2.0)
            y:astro_ppc_i32((bounds.top+bounds.bottom)/2.0) heading:0 source:kind];
        *actionTick=[self playerClockTick]+(uint32_t)ui.frameInterval-1;
    }
}
- (void)finishPlayerUpdateAtTick:(uint32_t)tick {
    playerState.update_tick=tick;
    astro_player_hit_follow(&playerHitVisual,playerBounds);
    if(engineGlow){
        engineGlowRect=astro_transition_engine_glow(playerVisual.x,playerVisual.y,playerVisual.height,playerState.frame);
        playerState.animation_tick-=5;
    }
}
- (void)updateOtherPlayer:(AstroEnemy *)enemy {
    AstroScriptState *state=&enemy->state;
    AstroPlayer actor={state->velocity,state->frame,state->tilt,state->state,state->animation_tick,state->update_tick};
    BOOL open=[self updatePlayerMotion:&actor velocity:&state->velocity bounds:enemy->bounds width:enemy->visual.width height:enemy->visual.height];
    state->frame=actor.frame;state->tilt=actor.tilt;state->state=actor.state;state->animation_tick=actor.animation_tick;
    if(!open)return;
    [self fireOrdinaryPlayerWeaponFrom:enemy->bounds actionTick:&state->action_tick kind:enemy->kind];
    BOOL timed=[self requestPlayerSpecialFrom:enemy actionTick:&state->action_tick];
    uint32_t finishTick=timed?[self specialClockTick]:[self playerClockTick];
    simulationTick=finishTick;state->update_tick=finishTick;
    astro_player_hit_follow(&playerHitVisual,enemy->bounds);
    if(engineGlow){
        engineGlowRect=astro_transition_engine_glow(playerVisual.x,playerVisual.y,playerVisual.height,state->frame);
        state->animation_tick-=5;
    }
}
- (id)nextActor:(id)object {return object==[NSNull null]?playerNextActor:((AstroEnemy *)object)->nextActor;}
- (void)setNextActor:(id)next forActor:(id)object {
    if(object==[NSNull null])playerNextActor=next;else ((AstroEnemy *)object)->nextActor=next;
}
- (void)syncActorLinks {
    for(NSUInteger i=0;i<world.count;i++)[self setNextActor:i+1<world.count?world[i+1]:nil forActor:world[i]];
}
- (void)deleteActor:(id)object {
    NSUInteger index=[world indexOfObjectIdenticalTo:object];
    if(index!=NSNotFound&&index>0)[self setNextActor:[self nextActor:object] forActor:world[index-1]];
    [world removeObjectIdenticalTo:object];
    if(object!=[NSNull null])[enemies removeObjectIdenticalTo:object];
    else if(!actorTraversalDepth)playerNextActor=nil;
}
- (void)cleanupWorld {
    [self syncActorLinks];
    for(id object in [world copy]) {
        BOOL player=object==[NSNull null];AstroEnemy *enemy=player?nil:object;
        int remove=player?playerCombat.remove:enemy->state.remove;
        if(!remove)continue;
        if(remove==-1) {
            if(player) {
                AstroEnemy *body=[AstroEnemy new];body->kind=playerCombat.kind;
                body->placement=@{@"attribute":@11,@"tag":@0};body->definition=game[@"attributes"][@"11"];
                body->visual=playerVisual;body->bounds=playerBounds;body->state.velocity=playerVelocity;[self addDeathEffects:body];
                if(inventory.lives==0){if(!gameOver&&!selftestPath)gameOverPending=YES;gameOver=YES;}
                else respawnPending=YES;
            } else {
                [self addDeathEffects:enemy];
                int action=changingStage?ASTRO_CAMPAIGN_NONE:astro_campaign_event(&campaign,[enemy->placement[@"tag"] intValue],0);
                if(action!=ASTRO_CAMPAIGN_NONE)campaignAction=action;
            }
        }
        [self deleteActor:object];
    }
}
- (void)moveChildren:(AstroEnemy *)parent heading:(int)heading amount:(double)amount {
    for(id object in world){
        actorVisits++;
        if(object!=[NSNull null]&&((AstroEnemy *)object)->parent==parent)
            astro_vector_make(&((AstroEnemy *)object)->state.velocity,heading,amount);
    }
}
- (void)stepActor:(id)object {
    actorVisits++;
    if(object==[NSNull null]){[self stepPlayer];return;}
    AstroEnemy *enemy=object;
    if(enemy->kind==999)return;
    AstroScriptState *state=&enemy->state;
    enemy->visual.x+=state->velocity.x;enemy->visual.y+=state->velocity.y;
    if([enemy->definition[@"animated"] boolValue]&&enemy->kind!=2&&enemy->kind!=4&&enemy->kind!=20&&enemy->kind!=40)
        astro_visual_change(&enemy->visual,enemy->baseSprite+state->frame-1,spriteInfo,1001,[self playerClockTick]);
    state->x=enemy->visual.x;state->y=enemy->visual.y;
    enemy->previousBounds=enemy->bounds;
    enemy->bounds=(AstroRect){(int16_t)(int)state->x,(int16_t)(int)state->y,
        (int16_t)(int)(state->x+enemy->visual.width),(int16_t)(int)(state->y+enemy->visual.height)};
    if(enemy->bounds.left>camera+(enemy->kind==2?650:740)||enemy->bounds.right<camera-10||
       (enemy->kind==2&&(enemy->bounds.top>390||enemy->bounds.bottom< -10))) {
        state->remove=1;
    }
    [self checkCollisionsFor:enemy];
    if(enemy->kind==1||enemy->kind==-1){[self updateOtherPlayer:enemy];return;}
    if(enemy->kind==5&&enemy->program.length&&enemy->bounds.left<camera+640&&enemy->bounds.right>camera) {
        int heading=astro_heading(state->x,state->y,enemy->visual.width,enemy->visual.height,
            playerEntityX,playerEntityY,playerVisual.width,playerVisual.height);
        EnemyContext source={self,enemy};
        AstroScriptContext context={.player_present=[world containsObject:[NSNull null]],.target_heading=(int)heading,
            .player_x=playerEntityX,.player_y=playerEntityY,
            .animated=[enemy->definition[@"animated"] intValue],
            .weapon=[enemy->definition[@"weapon"] intValue],
            .userdata=&source,.fire=enemyFire,.move_children=enemyMoveChildren,.hit_player=enemyHit,
            .gun_x=astro_script_gun_coordinate(enemy->bounds.left,[enemy->definition[@"turret_x"] intValue],
                enemy->visual.width,spriteInfo[enemy->visual.sprite].width),
            .gun_y=astro_script_gun_coordinate(enemy->bounds.top,[enemy->definition[@"turret_y"] intValue],
                enemy->visual.height,spriteInfo[enemy->visual.sprite].height)};
        if(!astro_script_step_clocked(state,enemy->program.bytes,
            enemy->program.length/sizeof(AstroInstruction),actorReadTick,(__bridge void *)self,&context)) {
            NSLog(@"Script ended outside RETURN"); exit(1);
        }
        scriptSteps++;
    }
    if(enemy->kind==2&&state->state==1){
        uint32_t comparison=[self playerClockTick];
        if((int32_t)(comparison-state->update_tick)>0)state->update_tick=[self playerClockTick];
    }
    if(enemy->kind==4||enemy->kind==20) {
        AstroDebris debris={enemy->kind,state->state,state->frame,state->remove,state->update_tick,
            state->animation_tick,state->action_tick,state->velocity};
        astro_debris_step_clocked(&debris,enemy->bounds.right,camera,finalArena?-.2:astro_debris_gravity(campaign.level),actorReadTick,(__bridge void *)self);
        state->velocity=debris.velocity;state->update_tick=debris.update_tick;
        state->animation_tick=debris.animation_tick;state->remove=debris.remove;
    }
    if([enemy->placement[@"attribute"] intValue]==399) {
        int tag=[enemy->placement[@"tag"] intValue];
        int action=changingStage?ASTRO_CAMPAIGN_NONE:astro_campaign_event(&campaign,tag,1);
        if(action!=ASTRO_CAMPAIGN_NONE)campaignAction=action;
        tickedScroll=0;
        if(tag!=-1){state->remove=1;[audio stopMusic];if(ui.musicVolume>0)[audio playMusic:3];}
    }
}
- (void)loadCampaignStage:(AstroCampaign)next {
    initialReadyCard=NO;readyLoadPending=NO;
    NSString *stage=[NSString stringWithFormat:@"Data %d%c",next.level,next.half==1?'A':'B'];
    NSUInteger index=[levels indexOfObject:stage];if(index==NSNotFound){NSLog(@"Missing stage %@",stage);exit(1);}
    selectedLevel=index;camera=-0.0;[self resetLevelWorld];
    playerX=30;playerY=190;
    if(selftestPath)playerCombat.hit_points=30000;
}
- (void)beginStageTransition {
    hudRedraws=2;
    pendingCampaign=campaign;
    if(!finalArena)campaign.level=[[levels[selectedLevel] substringFromIndex:5] intValue];
    if(pendingCampaign.complete){pendingCampaign.level=campaign.level+1;pendingCampaign.half=1;}
    campaign.half=[levels[selectedLevel] hasSuffix:@"A"]?1:2;campaign.complete=0;campaign.arena=1;
    campaignAction=ASTRO_CAMPAIGN_NONE;changingStage=YES;playerCombat.hit_points=200;
    astro_transition_begin(&transition,campaign.half==1?ASTRO_TRANSITION_MID:ASTRO_TRANSITION_END,simulationTick,0);
}
- (void)stepStageTransition {
    astro_transition_step(&transition,simulationTick+1,playerBounds,playerVisual.width,playerVisual.height,
        (AstroRect){(int)camera,(int)worldTop,(int)(camera+640),(int)worldBottom},-camera,0);
    if(transition.events&ASTRO_TRANSITION_BLOW) {
        for(int pass=0;pass<2;pass++) {
            for(AstroEnemy *enemy in enemies)enemy->state.remove=-1;
            [self cleanupWorld];
        }
    }
    if(transition.zero_velocity){playerVelocity=(AstroVelocity){0,0};playerState.velocity=playerVelocity;}
    if(transition.events&ASTRO_TRANSITION_ENGINE_GLOW){engineGlow=YES;engineGlowBirth=++renderClock;
        engineGlowRect=astro_transition_engine_glow(playerVisual.x,playerVisual.y,playerVisual.height,playerState.frame);}
    if(transition.events&ASTRO_TRANSITION_HYPER_SOUND)[audio playCue:@"Hyper"];
    if(transition.events&ASTRO_TRANSITION_BANG_SOUND)[audio playCue:@"Bang3"];
    if(transition.events&ASTRO_TRANSITION_TRAIL_SPRITE) {
        departureTrail=YES;playerState.frame=15;
        astro_visual_change(&playerVisual,15,spriteInfo,1001,simulationTick);
        departureGlow=astro_transition_departure_glow(playerVisual.x,playerVisual.y,playerVisual.width,playerVisual.height);
        trailRect=astro_transition_departure_trail(departureGlow);
    }
    if(transition.events&ASTRO_TRANSITION_MENU_MUSIC)[audio playMusic:1];
    if(transition.phase==ASTRO_TRANSITION_DONE) {
        int oldStage=campaign.level,oldHalf=campaign.half;AstroCampaign next=pendingCampaign;
        changingStage=NO;
        if(oldHalf==1&&next.half==2){
            initialReadyCard=NO;readyLoadPending=YES;campaign=next;
            [enemies removeAllObjects];[world removeAllObjects];[mapPlacements removeAllObjects];playerNextActor=nil;
            [visualEffects removeAllObjects];presentedBeams=@[];
            [specialPolygons removeAllObjects];[specialFlashes removeAllObjects];playerHitVisual.active=NO;engineGlow=departureTrail=NO;
        } else [self loadCampaignStage:next];
        astro_flow_stage_end(&flow,oldStage,oldHalf,next.level,next.half,next.complete);
        cardClockStarted=NO;
        if(flow.phase==ASTRO_FLOW_READY)[self unlockStage];
        if(flow.phase==ASTRO_FLOW_PLAY){[self createPlayerAtX:30 y:190];[self finishPlayerStart];inventory.weapon=playerWeapon=10;}
    } else if(transition.phase==ASTRO_TRANSITION_CARD) {
        astro_flow_stage_end(&flow,campaign.level,campaign.half,pendingCampaign.level,pendingCampaign.half,pendingCampaign.complete);
        cardClockStarted=NO;
    }
}
- (void)stepEnemies {
    if(campaignAction!=ASTRO_CAMPAIGN_NONE&&!changingStage) {
        if(selftestPath) {
            AstroCampaign next=campaign;[self loadCampaignStage:next];
            [self createPlayerAtX:30 y:190];[self finishPlayerStart];inventory.weapon=playerWeapon=10;
        } else [self beginStageTransition];
    }
    if(changingStage)[self stepStageTransition];
    if(flow.phase!=ASTRO_FLOW_PLAY)return;
    if(changingStage&&!transition.simulate_world){simulationTick++;tickedScroll=transition.scroll_x;return;}
    [self stepWorldWithoutFlow];
}
- (void)stepWorldWithoutFlow {
    simulationTick++;
    [self cleanupWorld];
    BOOL blinking=invulnerableUntil!=0;
    if(blinking)playerVisual.width=spriteInfo[playerVisual.sprite].width;
    [self calculateActors];
    if(blinking)playerVisual.width=respawnBlinkWidth;
}
- (void)beginRespawnWait {
    respawnWaitStartTick=[self playerClockTick];respawnTick=1;
}
- (void)pollRespawnWaitFrame {
    [self pollNestedWorld];
    [audio serviceMusic];
    [self pollRespawnWait];
}
- (void)pollNestedWorld {
    uint32_t comparison=[self playerClockTick];
    if((int32_t)(comparison-observedWallTick)>0){
        observedWallTick=[self playerClockTick];simulationTick=observedWallTick;
        [self advanceWorldForWait:YES];
    }
}
- (void)pollRespawnWait {
    [self readGameKeys];
    if((int32_t)([self playerClockTick]-respawnWaitStartTick)>60){
        playerCombat=(AstroCombatState){.kind=-1,.hit_points=100};
        [self createPlayerAtX:camera+30 y:190];
        [self beginRespawnBlink];
        inventory.upgrade=0;playerWeapon=inventory.weapon;playerSpawnTick=simulationTick;respawnTick=0;
    }
}
- (void)beginRespawnBlink {
    respawnStartTick=[self playerClockTick];respawnBlinkTick=[self playerClockTick];
    respawnBlinkWidth=0;invulnerableUntil=1;hudRedraws=2;
}
- (void)pollRespawnBlink {
    uint32_t comparison=[self playerClockTick];
    if((int32_t)(comparison-respawnBlinkTick)>5){
        respawnBlinkWidth=respawnBlinkWidth==0?spriteInfo[playerVisual.sprite].width:0;
        respawnBlinkTick=[self playerClockTick];
    }
    [self makeNewSprites];
    [audio serviceMusic];
    [self readGameKeys];
    if((int32_t)([self playerClockTick]-respawnStartTick)>180||gameEndRequested){
        invulnerableUntil=0;playerVisual.width=spriteInfo[playerVisual.sprite].width;playerCombat.kind=1;
    }
}
- (void)inheritParentState {
    for(id object in world)if(object!=[NSNull null]){
        AstroEnemy *enemy=object;
        if(enemy->parent){
            enemy->state.velocity=enemy->parent->state.velocity;
            if(enemy->parent->state.remove==-1)enemy->state.remove=-1;
        }
    }
}
- (void)calculateActors {
    actorVisits=0;
    astro_stars_move(stars,-camera,0,camera,worldTop,camera+640,worldBottom,tickedScroll,0,0,0,ui.frameInterval,&randomSeed,
        parallaxData.mutableBytes,backgrounds.count,0);
    camera=astro_camera_advance(camera,tickedScroll);
    worldTop=-0.0;worldBottom=380;
    [specialPolygons removeAllObjects];[specialFlashes removeAllObjects];
    [self syncActorLinks];actorTraversalDepth++;
    id actor=world.firstObject;
    while(actor){
        // CALC caches only this next pointer; nested cleanup can change later links.
        id next=[self nextActor:actor];
        if([world indexOfObjectIdenticalTo:actor]!=NSNotFound)[self stepActor:actor];
        actor=next;
    }
    [self inheritParentState];
    if(!--actorTraversalDepth&&![world containsObject:[NSNull null]])playerNextActor=nil;
}
- (void)renderTick {
    uint32_t comparison=[self playerClockTick];
    if((int32_t)(comparison-worldRenderTick)>=ui.frameInterval){
        worldRenderTick=[self playerClockTick];simulationTick=worldRenderTick;
        BOOL trail=changingStage&&transition.phase==ASTRO_TRANSITION_TRAIL;
        if(trail){
            astro_transition_render_trail(&transition);tickedScroll=transition.scroll_x;
            astro_stars_move(stars,-camera,0,camera,worldTop,camera+640,worldBottom,tickedScroll,0,0,0,ui.frameInterval,&randomSeed,
                parallaxData.mutableBytes,backgrounds.count,0);
        }
        simulationRender=YES;[self display];simulationRender=NO;
        if(trail&&transition.phase==ASTRO_TRANSITION_CARD){
            [audio playMusic:1];
            astro_flow_stage_end(&flow,campaign.level,campaign.half,pendingCampaign.level,pendingCampaign.half,pendingCampaign.complete);
            cardClockStarted=NO;
        }
    }
    if(!menuVisible&&flow.phase==ASTRO_FLOW_PLAY&&(!changingStage||transition.simulate_world)) {
        [self handleVisualEffects];
    }
}
- (void)beginGameLoop {
    lastSpawnTick=[self playerClockTick];observedWallTick=[self playerClockTick];worldRenderTick=[self playerClockTick];
}
- (void)pollMapSpawns {
    if(menuVisible||paused||gameOver||flow.phase!=ASTRO_FLOW_PLAY||changingStage)return;
    if(respawnTick){[self pollRespawnWait];return;}
    if(invulnerableUntil){[self pollRespawnBlink];if(invulnerableUntil)return;}
    uint32_t comparison=[self playerClockTick];
    if((int32_t)(comparison-lastSpawnTick)>20){[self makeNewSprites];lastSpawnTick=[self playerClockTick];}
}
- (void)pollGame {
    if(respawnTick){[self pollRespawnWaitFrame];return;}
    if(invulnerableUntil){[self pollNestedWorld];[self pollMapSpawns];if(!invulnerableUntil){[audio serviceMusic];[self readGameKeys];[self completeGameLoopIfRequested];}specialReturnPending=NO;return;}
    if(gameEndRequested){[audio serviceMusic];[self pollMapSpawns];[self readGameKeys];[self completeGameLoopIfRequested];return;}
    uint32_t comparison=[self playerClockTick];
    if((int32_t)(comparison-observedWallTick)>0){
        observedWallTick=[self playerClockTick];simulationTick=observedWallTick;
        if(respawnPending){
            respawnPending=NO;inventory.lives--;[self beginRespawnWait];[self pollRespawnWaitFrame];return;
        }
        [self advanceWorldForWait:NO];
    }
    [audio serviceMusic];[self pollMapSpawns];if(flow.phase==ASTRO_FLOW_PLAY){[self readGameKeys];[self completeGameLoopIfRequested];}specialReturnPending=NO;
}
- (void)advanceWorldForWait:(BOOL)waiting {
    tickedScroll=changingStage&&transition.simulate_world?transition.scroll_x:
        (!changingStage&&automatic&&!campaign.arena&&campaignAction==ASTRO_CAMPAIGN_NONE?1:0);
    simulationTick=observedWallTick-1;
    if(waiting)[self stepWorldWithoutFlow];else [self stepEnemies];
    BOOL previous=nestedWorldRender;nestedWorldRender=waiting;
    @try {[self renderTick];} @finally {nestedWorldRender=previous;}
}
- (void)advanceFlowWithKey:(BOOL)anyKey {
    AstroFlowPhase previous=flow.phase;int previousPage=flow.ending_page;astro_flow_step(&flow,anyKey);
    if(previous!=flow.phase||previousPage!=flow.ending_page)cardClockStarted=NO;
    if(previous==ASTRO_FLOW_END_CARD&&flow.phase!=previous&&changingStage) {
        AstroCampaign next=pendingCampaign;astro_transition_accept_card(&transition);changingStage=NO;
        if(!next.complete){[self loadCampaignStage:next];if(flow.phase==ASTRO_FLOW_READY)[self unlockStage];}
        else {campaign=next;[enemies removeAllObjects];[world removeAllObjects];playerNextActor=nil;}
    }
    if(previous==ASTRO_FLOW_READY&&flow.phase==ASTRO_FLOW_PLAY){
        [audio stopMusic];if(ui.musicVolume>0)[audio playMusic:2];
        if(initialReadyCard)[self beginGameLoop];
        else {
            if(readyLoadPending)[self loadCampaignStage:pendingCampaign];
            [self createPlayerAtX:30 y:190];[self finishPlayerStart];inventory.weapon=playerWeapon=10;
            [self pollMapSpawns];[self readGameKeys];[self completeGameLoopIfRequested];specialReturnPending=NO;
        }
    }
    if(flow.phase==ASTRO_FLOW_FINISHED)[self beginGameOver];
}
- (void)probePreferences:(NSString *)stage {
    NSString *domain=NSBundle.mainBundle.bundleIdentifier;
    if(![domain hasPrefix:@"local.astrosquid.persistence-probe."]) {
        fputs("Preference probe requires its own isolated test bundle identifier\n",stderr);exit(2);
    }
    NSUserDefaults *preferences=[NSUserDefaults standardUserDefaults];
    if([stage isEqual:@"write"]) {
        assert(controlKeys[0]==55&&fabs(ui.soundVolume-.6)<.001&&ui.musicVolume==1&&ui.smooth&&ui.unlockedLevel==1);
        assert(highscores[0].score==0&&preferenceFPS==60&&ui.frameInterval==1);splashVisible=NO;
        [self testCaptureKey:14];
        [self performMenuAction:@"SetSmooth"];[self performMenuAction:@"SetSVolume"];[self performMenuAction:@"SetMVolume"];
        assert(astro_scores_insert(highscores,650,"Persistence Probe")==1);[self saveScores];
        campaign=(AstroCampaign){4,1,0,0};[self unlockStage];
        assert(ui.unlockedLevel==7&&[preferences integerForKey:@"AstroSquidUnlockedLevel"]==0);
        preferenceFPS=20;[self saveSettings];assert(ui.frameInterval==1&&[preferences integerForKey:@"AstroSquidUnlockedLevel"]==7);
        assert([preferences synchronize]);puts("PASS isolated preference write through actual UI handlers");
    } else if([stage isEqual:@"read"]) {
        assert(controlKeys[0]==14&&fabs(ui.soundVolume-.7)<.001&&ui.musicVolume==0&&!ui.smooth&&ui.unlockedLevel==7);
        assert(highscores[0].score==650&&!strcmp(highscores[0].name,"Persistence Probe"));
        assert(preferenceFPS==20&&ui.frameInterval==3);
        [preferences removePersistentDomainForName:domain];assert([preferences synchronize]);
        puts("PASS new-process reload of keys, volumes, filter, unlocked stage and score; probe preferences removed");
    } else {fputs("Unknown preference probe stage\n",stderr);exit(2);}
    fflush(stdout);exit(0);
}
- (void)beginCampaignTest:(NSString *)path {
    splashVisible=NO;campaignTestPath=[path copy];campaignVisits=[NSMutableArray array];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    [self performMenuAction:@"New Game"];audio.soundVolume=audio.musicVolume=0;
    GLint interval=0;[[self openGLContext] setValues:&interval forParameter:NSOpenGLCPSwapInterval];
}
- (void)writeCampaignReport:(BOOL)finished passed:(BOOL)passed reason:(NSString *)reason {
    NSDictionary *report=@{@"finished":@(finished),@"passed":@(passed),@"reason":reason,
        @"controlled_pilot":@"Replenished shield, weapon53; real world/AI/collision/flow, no stage teleport",
        @"ticks":@(campaignTestTicks),@"stages":campaignVisits,@"score":@(score),
        @"current_stage":levels[selectedLevel],@"flow":@(flow.phase),@"transition":@(transition.phase),
        @"map_remaining":@(mapPlacements.count),@"live_entities":@(enemies.count),@"camera":@(camera),
        @"player_x":@(playerVisual.x),@"player_y":@(playerY)};
    [[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil]
        writeToFile:[campaignTestPath stringByAppendingPathComponent:@"result.json"] atomically:YES];
    if(finished){puts(passed?"PASS controlled complete campaign route":"FAIL controlled campaign route");fflush(stdout);exit(passed?0:1);}
}
- (void)driveCampaignTest {
    for(int step=0;step<20;step++) {
        campaignTestTicks++;
        NSString *stage=levels[selectedLevel];
        if(![campaignVisits containsObject:stage]) {
            [campaignVisits addObject:stage];campaignLastChange=campaignTestTicks;campaignLastCamera=0;campaignLastBossHP=INT32_MAX;
            NSLog(@"Campaign reached %@ at tick %lu",stage,(unsigned long)campaignTestTicks);
        }
        if(menuVisible&&gameOver){[self writeCampaignReport:YES passed:campaign.complete&&campaignVisits.count==17 reason:campaign.complete?@"ending reached":@"pilot died"];return;}
        BOOL waitDriven=NO;
        if(flow.phase!=ASTRO_FLOW_PLAY){simulationTick++;[self advanceFlowWithKey:YES];}
        else if(respawnPending||respawnTick||invulnerableUntil){simulationTick++;[self pollGame];waitDriven=YES;}
        else {
            memset(keys,0,sizeof(keys));
            if(!changingStage){
                keys[controlKeys[0]]=YES;playerWeapon=53;inventory.weapon=50;inventory.upgrade=3;
                playerCombat.hit_points=200;playerCombat.kind=-1;
                for(AstroEnemy *enemy in enemies) {
                    if([enemy->placement[@"tag"] intValue]>=0||!(enemy->kind==5||(enemy->kind>=20&&enemy->kind<=29))||enemy->state.remove||
                        enemy->bounds.left>camera+640||enemy->bounds.right<camera)continue;
                    double targetX=MIN(camera+570,enemy->visual.x+enemy->visual.width/2-45);
                    double targetY=enemy->visual.y+enemy->visual.height/2-playerVisual.height/2;
                    if(playerVisual.x<targetX-6)keys[controlKeys[5]]=YES;
                    if(playerVisual.x>targetX+6)keys[controlKeys[4]]=YES;
                    if(playerY<targetY-6)keys[controlKeys[3]]=YES;
                    if(playerY>targetY+6)keys[controlKeys[2]]=YES;
                    break;
                }
            }
            tickedScroll=changingStage&&transition.simulate_world?transition.scroll_x:
                (!changingStage&&automatic&&!campaign.arena&&campaignAction==ASTRO_CAMPAIGN_NONE?1:0);
            [self stepEnemies];
        }
        if(!waitDriven){[self renderTick];[audio serviceMusic];[self pollMapSpawns];specialReturnPending=NO;}
        int bossHP=0;
        for(AstroEnemy *enemy in enemies)if([enemy->placement[@"tag"] intValue]<0&&enemy->kind!=39)bossHP+=MAX(0,enemy->hitPoints);
        if(camera>campaignLastCamera+1||bossHP<campaignLastBossHP){campaignLastChange=campaignTestTicks;campaignLastCamera=camera;campaignLastBossHP=bossHP;}
        if(!bossHP)campaignLastBossHP=INT32_MAX;
        if(campaignTestTicks%1000==0)[self writeCampaignReport:NO passed:NO reason:@"running"];
        if(campaignTestTicks>1000000||campaignTestTicks-campaignLastChange>30000){
            [self writeCampaignReport:YES passed:NO reason:@"campaign stalled"];return;
        }
    }
}
- (void)reloadMainMenu {
    [ui reloadMenuWithRandom:&randomSeed afterRandomization:^{
        astro_stars_init(stars,1,&randomSeed);starsInitialized=YES;
        menuScroll.x=astro_random(&randomSeed,8)-4;menuScroll.y=astro_random(&randomSeed,8)-4;
    }];
}
- (void)pollKeyCaptureEvents {
    // EventAvail(0): update input availability without consuming queued events.
    (void)[NSApp nextEventMatchingMask:0 untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:NO];
}
- (void)stepKeyCaptureMenu {
    astro_stars_move(stars,ui.cameraX,ui.cameraY,-ui.cameraX,-ui.cameraY,640-ui.cameraX,480-ui.cameraY,
        menuScroll.x,menuScroll.y,0,0,ui.frameInterval,&randomSeed,NULL,0,1);
    BOOL previous=deferPresent,previousMenuFrame=menuFrameActive;deferPresent=YES;menuFrameActive=NO;
    @try {[self display];[ui animateMenuObjects];if(!previous)[self presentFrame];}
    @finally {deferPresent=previous;menuFrameActive=previousMenuFrame;}
    [audio serviceMusic];
}
- (int)waitForMenuKey {
    uint32_t start=[self currentGameTick];
    for(;;){
        [self pollKeyCaptureEvents];unsigned char snapshot[16];
        if(keyCaptureTestMap){
            assert(selftestPath||[NSBundle.mainBundle.bundleIdentifier hasPrefix:@"local.astrosquid.persistence-probe."]);
            assert(keyCaptureTestMap.length==16);memcpy(snapshot,keyCaptureTestMap.bytes,16);
        }else [self copyKeyMap:snapshot];
        int code=-1;for(unsigned bit=0;bit<128;bit++)if(snapshot[bit>>3]&(0x80u>>(bit&7)))code=(int)bit^7;
        uint32_t comparison=[self currentGameTick];
        if((int32_t)(comparison-observedWallTick)>=ui.frameInterval){observedWallTick=[self currentGameTick];[self stepKeyCaptureMenu];}
        uint32_t end=[self currentGameTick];
        if(code>=0||(int32_t)(end-start)>600)return code;
    }
}
- (void)testCaptureKey:(unsigned)code {
    assert(code<128&&(selftestPath||[NSBundle.mainBundle.bundleIdentifier hasPrefix:@"local.astrosquid.persistence-probe."]));
    unsigned char map[16]={0};map[code>>3]=1u<<(code&7);keyCaptureTestMap=[NSData dataWithBytes:map length:16];
    @try {[self performMenuAction:@"SetKeyFire"];}@finally {keyCaptureTestMap=nil;}
}
- (void)acceptSplash {
    if(!splashVisible)return;
    splashVisible=NO;menuMouseLatched=YES;
    [ui show:@"Main Menu"];observedWallTick=[self currentGameTick];
}
- (void)pollSplash {
    [audio serviceMusic];[self readKeyMap];
    BOOL any=NO;for(unsigned i=0;i<128;i++)if(keys[i]){any=YES;break;}
    BOOL button=[self menuMouseButtonPressed];
    if(any||button)[self acceptSplash];
}
- (void)pollMenuMouse {
    NSPoint p=[self currentMenuMousePoint];[ui pollMouseX:p.x y:p.y];
    if(![self menuMouseButtonPressed]){menuMouseLatched=NO;[ui mouseUpX:p.x y:p.y];}
}
- (void)stepMenu {
    if(splashVisible)return;
    BOOL overlay=[ui.anchor isEqual:@"Pause"]||[ui.anchor isEqual:@"GameOver"];
    if(!overlay){
        [ui advanceMenuCamera];
        astro_stars_move(stars,ui.cameraX,ui.cameraY,-ui.cameraX,-ui.cameraY,640-ui.cameraX,480-ui.cameraY,
            menuScroll.x,menuScroll.y,ui.cameraStepX,ui.cameraStepY,ui.frameInterval,&randomSeed,NULL,0,1);
    }
    if(overlay)[self pollMenuMouse];
    BOOL previous=deferPresent,previousMenuFrame=menuFrameActive;deferPresent=YES;menuFrameActive=!overlay;
    @try {
        [self display];
        if([ui.anchor isEqual:@"Pause"])[audio serviceMusic];
        if(overlay)[ui animateTicks:1];else [ui animateMenuObjects];
        if(!previous)[self presentFrame];
    } @finally {deferPresent=previous;menuFrameActive=previousMenuFrame;}
}
- (void)finishMenuNavigation {
    if(!navigationButton)return;
    [ui setButton:navigationButton pressed:NO];navigationButton=nil;menuMouseLatched=YES;
}
- (void)pollMenu {
    if(splashVisible){[self pollSplash];return;}
    BOOL gameOverPanel=[ui.anchor isEqual:@"GameOver"];
    if(gameOverPanel)[self readKeyMap];
    uint32_t comparison=[self currentGameTick];
    if((int32_t)(comparison-observedWallTick)<ui.frameInterval){[self pollHeldMenuMouse];return;}
    BOOL overlay=[ui.anchor isEqual:@"Pause"]||[ui.anchor isEqual:@"GameOver"];
    if(!overlay)observedWallTick=[self currentGameTick];
    BOOL finishGameOver=NO;
    if(gameOverPanel){
        if(ui.editingHighscore>0){
            if(scoreKeyEvents.length){
                unsigned char ch=*(const unsigned char *)scoreKeyEvents.bytes;
                [scoreKeyEvents replaceBytesInRange:NSMakeRange(0,1) withBytes:NULL length:0];
                if(![self editScoreByte:ch])return;
                [self refreshScoreEditor];
            }
            finishGameOver=scoreEditor.submitted;
        }else for(unsigned i=0;i<128;i++)if(keys[i]){finishGameOver=YES;break;}
        if(finishGameOver)ui.gameOverClosing=YES;
    }
    BOOL moving=ui.transitioning||navigationButton!=nil;
    [self stepMenu];
    if(![ui.anchor isEqual:@"Pause"])[audio serviceMusic];
    if(overlay)observedWallTick=[self currentGameTick];
    if([ui.anchor isEqual:@"Pause"]&&paused)[self readPauseKeys];
    else if(!gameOverPanel)[self readKeyMap];
    if(!overlay&&!moving&&ui.activeRegistrationField>=0&&registrationKeyEvents.length){
        unsigned char ch=*(const unsigned char *)registrationKeyEvents.bytes;
        [registrationKeyEvents replaceBytesInRange:NSMakeRange(0,1) withBytes:NULL length:0];
        if([ui editRegistrationByte:ch]==ASTRO_SCORE_EDIT_ALERT&&![self resolveTextOverflow:&[ui registrationFields][ui.activeRegistrationField] byte:ch])return;
    }
    [self pollHeldMenuMouse];
    if(navigationButton&&!ui.transitioning)[self finishMenuNavigation];
    if(gameOverPanel&&finishGameOver)[self finishGameOver];
}
- (uint32_t)cardDelayClockTick {
    return (uint32_t)(uint64_t)floor(NSProcessInfo.processInfo.systemUptime*60);
}
- (void)recordCardPresentation {
    if(!cardClockStarted){cardDelayStartTick=[self cardDelayClockTick];cardClockStarted=YES;}
}
- (void)pollFlowCard {
    if(!cardClockStarted)return;
    if(flow.phase==ASTRO_FLOW_READY||flow.phase==ASTRO_FLOW_ENDING){
        if((uint32_t)([self cardDelayClockTick]-cardDelayStartTick)<60)return;
        flow.ticks=59;
    }
    [self readKeyMap];[audio serviceMusic];BOOL anyKey=NO;for(int i=0;i<128;i++)anyKey|=keys[i];
    [self advanceFlowWithKey:anyKey];
}
- (void)tickWallClock {
    if(pauseLoopRunning||editingKey>=0)return;
    wallClockPoll=YES;@try {
        if(gameEndRequested){[self pollGame];return;}
        if(!menuVisible&&!paused&&!gameOver&&flow.phase==ASTRO_FLOW_PLAY){
            [self pollGame];self.window.title=@"AstroSquid";return;
        }
        if(!menuVisible&&flow.phase!=ASTRO_FLOW_PLAY){
            [self pollFlowCard];
            if(flow.phase!=ASTRO_FLOW_PLAY&&!cardClockStarted)[self setNeedsDisplay:YES];
            self.window.title=@"AstroSquid";return;
        }
        uint32_t stamp=(uint32_t)floor((NSProcessInfo.processInfo.systemUptime-clockOrigin)*60);
        uint32_t elapsed=stamp-observedWallTick;
        if(!elapsed&&!menuVisible)return;
        if(!menuVisible)observedWallTick=stamp;simulationTick=stamp;
        if(gameOverPending){gameOverPending=NO;[self beginGameOver];observedWallTick=[self currentGameTick];return;}
        BOOL idle=menuVisible||paused||gameOver||flow.phase!=ASTRO_FLOW_PLAY;
        if(menuVisible)[self pollMenu];
        if(gameEndRequested){[self pollGame];return;}
        if(idle&&!menuVisible)[self setNeedsDisplay:YES];
        self.window.title=@"AstroSquid";
    } @finally {
        wallClockPoll=NO;
        if(quitRequested&&!gameLoopActive)[self closeDown];
    }
}
- (void)tick:(NSTimer *)sender {
    if(pauseLoopRunning||editingKey>=0)return;
    if(campaignTestPath){[self driveCampaignTest];return;}
    if(!selftestPath){[self tickWallClock];return;}
    double now=[NSDate timeIntervalSinceReferenceDate];
    double dt=fmin(now-previousTime,.05); previousTime=now;
    tickRemainder+=dt;
    if(!menuVisible&&flow.phase!=ASTRO_FLOW_PLAY) {
        BOOL anyKey=NO;for(int i=0;i<128;i++)anyKey|=keys[i];[self advanceFlowWithKey:anyKey];
    }
    if(menuVisible) [self pollMenu];
    if(paused||gameOver||menuVisible||flow.phase!=ASTRO_FLOW_PLAY) tickRemainder=0;
    while(tickRemainder>=1.0/60.0&&flow.phase==ASTRO_FLOW_PLAY&&!menuVisible&&!paused) {
        tickRemainder-=1.0/60.0;
        if(respawnPending||respawnTick||invulnerableUntil){simulationTick++;[self pollGame];continue;}
        tickedScroll=changingStage&&transition.simulate_world?transition.scroll_x:
            selftestPath&&keys[7]?2:
            automatic&&!campaign.arena&&campaignAction==ASTRO_CAMPAIGN_NONE?1:0;
        if(selftestPath&&keys[6])tickedScroll=fmax(0,astro_camera_advance(camera,tickedScroll)-2)-camera;
        [self stepEnemies];[self renderTick];[audio serviceMusic];[self pollMapSpawns];specialReturnPending=NO;
    }
    if(!selftestPath) self.window.title=[NSString stringWithFormat:@"AstroSquid — %@ — HP %d · Lives %d · Score %d%@",
        levels[selectedLevel],playerCombat.hit_points,inventory.lives,score,
        gameOver?@" · GAME OVER (R)":campaign.complete?@" · COMPLETE":paused?@" · PAUSED":@""];
    if(!menuVisible&&flow.phase!=ASTRO_FLOW_PLAY)[self setNeedsDisplay:YES];
    if(selftestPath) {
        if(playerX>selftestStartX+10) selftestMoved=YES;
        selftestTicks++;
        if(selftestTicks==20) [self keyUp:[self testEvent:NSKeyUp code:124]];
        if(selftestTicks==90||selftestTicks==170||selftestTicks==250||selftestTicks==370) {
            playerWeapon=selftestTicks==90?13:selftestTicks==170?33:selftestTicks==250?43:53;
            keys[8]=NO;lastPlayerShot=simulationTick-1000;
            selftestExpectedSpecial=emittedSpecials+1;selftestWaitingSpecial=YES;
            inventory.specials=1;[self keyDown:[self testEvent:NSKeyDown code:58]];
        }
        if(selftestWaitingSpecial&&emittedSpecials>=selftestExpectedSpecial) {
            [self keyUp:[self testEvent:NSKeyUp code:58]];keys[8]=YES;selftestWaitingSpecial=NO;
        }
        if(selftestTicks==40) [self keyDown:[self testEvent:NSKeyDown code:20]];
        if(selftestTicks==60) [self keyDown:[self testEvent:NSKeyDown code:21]];
        if(selftestTicks==450) [self finishSelfTest];
    }
}
- (NSEvent *)testEvent:(NSEventType)type code:(unsigned short)code {
    return [NSEvent keyEventWithType:type location:NSZeroPoint modifierFlags:0
        timestamp:0 windowNumber:self.window.windowNumber context:nil characters:@""
        charactersIgnoringModifiers:@"" isARepeat:NO keyCode:code];
}
- (NSEvent *)testMouse:(NSEventType)type x:(double)x y:(double)y {
    NSPoint p=[self convertPoint:NSMakePoint(x*self.bounds.size.width/640,
        (480-y)*self.bounds.size.height/480) toView:nil];
    return [NSEvent mouseEventWithType:type location:p modifierFlags:0 timestamp:0
        windowNumber:self.window.windowNumber context:nil eventNumber:0 clickCount:1 pressure:1];
}
- (void)beginSelfTest:(NSString *)path {
    selftestPath=[path copy];
    assert(splashVisible);[self keyDown:[self testEvent:NSKeyDown code:36]];assert(!splashVisible);
    while(ui.transitioning)[self pollMenu];[self keyUp:[self testEvent:NSKeyUp code:36]];
    assert(menuVisible&&[ui.anchor isEqual:@"Main Menu"]);
    [self mouseDown:[self testMouse:NSLeftMouseDown x:369 y:175]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:369 y:175]];
    assert([ui.anchor isEqual:@"Play Menu"]);[ui animateTicks:120];
    for(unsigned released=0;released<2;released++){observedWallTick=[self currentGameTick]-(uint32_t)ui.frameInterval;[self pollMenu];}
    [self mouseDown:[self testMouse:NSLeftMouseDown x:394 y:268]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:394 y:268]];
    assert(!menuVisible&&selectedLevel==0&&flow.phase==ASTRO_FLOW_READY);
    for(int i=0;i<60;i++)astro_flow_step(&flow,1);
    assert(flow.phase==ASTRO_FLOW_PLAY);
    NSString *savedTestPath=selftestPath;selftestPath=nil;
    [self keyDown:[self testEvent:NSKeyDown code:53]];assert(!paused);[self enterPause];selftestPath=savedTestPath;
    assert(menuVisible&&paused);[ui animateTicks:120];[self stepMenu];
    [self mouseDown:[self testMouse:NSLeftMouseDown x:365 y:250]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:365 y:250]];
    assert(!menuVisible&&!paused);memset(keys,0,sizeof(keys));
    keys[53]=YES;[self handleMiscKeys];
    assert(!paused&&!menuVisible&&!pauseLoopRunning);memset(keys,0,sizeof(keys));
    int testControls[6]={49,58,126,125,123,124};memcpy(controlKeys,testControls,sizeof(testControls));
    automatic=NO;
    selftestPath=[path copy]; selftestTicks=0; selftestStartX=playerX;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
        withIntermediateDirectories:YES attributes:nil error:nil];
    [self keyDown:[self testEvent:NSKeyDown code:124]];
    [self keyDown:[self testEvent:NSKeyDown code:8]];
    [self keyDown:[self testEvent:NSKeyDown code:45]];
    selftestStageSwitched=selectedLevel==1;
    for(NSDictionary *placement in game[@"levels"][levels[selectedLevel]][@"entities"]) {
        NSDictionary *definition=game[@"attributes"][[placement[@"attribute"] stringValue]];
        if([game[@"scripts"][[definition[@"script"] stringValue]] count]) {
            camera=fmax(0,number(placement,@"x")-400);[self makeNewSprites];
            playerY=number(placement,@"y")+number(placement,@"height")/2-12;
            playerVisual.x=playerX+camera;playerVisual.y=playerY;playerEntityX=playerVisual.x;playerEntityY=playerY;break;
        }
    }
    playerCombat.hit_points=30000;
    audio.musicVolume=0;audio.soundVolume=0;
    [audio playMusic:2];
}
- (void)finishSelfTest {
    [self keyUp:[self testEvent:NSKeyUp code:124]];
    uint32_t before=randomSeed;NSUInteger effectCount=visualEffects.count;
    [self display];[self display];assert(randomSeed==before&&visualEffects.count==effectCount);
    [[self openGLContext] makeCurrentContext];
    NSRect bounds=[self convertRectToBacking:self.bounds];
    NSInteger width=(NSInteger)bounds.size.width,height=(NSInteger)bounds.size.height;
    size_t stride=(size_t)width*4,bytes=stride*(size_t)height;
    unsigned char *pixels=malloc(bytes);
    glReadBuffer(GL_FRONT); glPixelStorei(GL_PACK_ALIGNMENT,1);
    glReadPixels(0,0,(GLsizei)width,(GLsizei)height,GL_RGBA,GL_UNSIGNED_BYTE,pixels);
    NSBitmapImageRep *image=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
        pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4
        hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace
        bitmapFormat:0 bytesPerRow:stride bitsPerPixel:32];
    unsigned colored=0;
    for(NSInteger y=0;y<height;y++) {
        memcpy(image.bitmapData+(size_t)y*stride,pixels+(size_t)(height-1-y)*stride,stride);
        for(NSInteger x=0;x<width;x++) {
            unsigned char *p=pixels+(size_t)y*stride+(size_t)x*4;
            if(p[0]>30 && p[0]>p[1]*1.3 && p[2]>p[1]*1.1) colored++;
        }
    }
    free(pixels);
    NSData *png=[image representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    [png writeToFile:[selftestPath stringByAppendingPathComponent:@"frame.png"] atomically:YES];
    BOOL moved=selftestMoved;
    BOOL audioOK=audio.music.isPlaying && audio.music.currentTime>0;
    BOOL passed=emittedSpecials==4 && emittedEffects>0 && emittedBeams>0 && damageHits>0 && emittedShots>0 && scriptSteps>0 && moved && selftestStageSwitched && colored>100 && textures.count>0 && audioOK;
    NSDictionary *report=@{@"controlled_runtime_fixture":@YES,@"passed":@(passed),@"script_steps":@(scriptSteps),@"emitted_shots":@(emittedShots),@"damage_hits":@(damageHits),@"emitted_beams":@(emittedBeams),@"emitted_effects":@(emittedEffects),@"special_attacks":@(emittedSpecials),
        @"player_hit_points":@(playerCombat.hit_points),@"score":@(score),@"player_moved":@(moved),
        @"stage_switched":@(selftestStageSwitched),@"music_time":@(audio.music.currentTime),
        @"music_playing":@(audio.music.isPlaying),@"colored_pixels":@(colored),
        @"textures_loaded":@(textures.count),@"frame_width":@(width),@"frame_height":@(height)};
    [self testStageTransitionHandlers];
    [self testScoreAndSettingsHandlers];
    [self testOrdinaryLifeCycle];
    [self testPausedClock];
    [[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil]
        writeToFile:[selftestPath stringByAppendingPathComponent:@"result.json"] atomically:YES];
    puts(passed?"PASS: native menus, cards, settings, score entry, renderer, combat and audio":"FAIL: native preview self-test");
    fflush(stdout);
    exit(passed?0:1);
}
- (void)testStageTransitionHandlers {
    for(int half=1;half<=2;half++) {
        selectedLevel=[levels indexOfObject:half==1?@"Data 1A":@"Data 1B"];camera=-0.0;[self resetEnemies];
        [enemies removeAllObjects];[world removeAllObjects];[world addObject:[NSNull null]];[mapPlacements removeAllObjects];
        flow=(AstroFlow){0};menuVisible=NO;paused=NO;memset(keys,0,sizeof(keys));
        campaign=(AstroCampaign){half==1?1:2,half==1?2:1,0,0};[self beginStageTransition];
        int steps=0;
        while(flow.phase==ASTRO_FLOW_PLAY&&steps++<1200) {
            tickedScroll=transition.simulate_world?transition.scroll_x:0;
            [self stepEnemies];[self renderTick];
        }
        assert(steps<1200);
        if(half==1)assert(flow.phase==ASTRO_FLOW_READY&&readyLoadPending&&world.count==0&&[levels[selectedLevel] isEqual:@"Data 1A"]);
        else {
            assert(flow.phase==ASTRO_FLOW_END_CARD&&engineGlow&&departureTrail);
            [self advanceFlowWithKey:YES];
            assert(flow.phase==ASTRO_FLOW_READY&&[levels[selectedLevel] isEqual:@"Data 2A"]);
        }
        assert(![world containsObject:[NSNull null]]);
        flow.ticks=59;[self advanceFlowWithKey:YES];
        assert(flow.phase==ASTRO_FLOW_PLAY&&[world containsObject:[NSNull null]]&&!readyLoadPending);
        assert(inventory.weapon==10&&inventory.upgrade==0);
    }
}
- (void)testPausedClock {
    [self performMenuAction:@"New Game"];for(int i=0;i<60;i++){simulationTick++;[self advanceFlowWithKey:YES];}
    [enemies removeAllObjects];[world removeAllObjects];[world addObject:[NSNull null]];[mapPlacements removeAllObjects];
    memset(keys,0,sizeof(keys));automatic=YES;campaign.arena=0;paused=YES;menuVisible=YES;
    simulationTick=100;observedWallTick=100;clockOrigin=NSProcessInfo.processInfo.systemUptime-100.0/60;
    double old=camera;clockOrigin-=5;[self tickWallClock];
    assert(simulationTick>=400&&camera==old);
    lastPlayerShot=100;paused=NO;menuVisible=NO;clockOrigin-=2.0/60;[self tickWallClock];
    assert(camera==old+1&&simulationTick>=402&&lastPlayerShot==100);
}
- (void)testModifier:(unsigned short)code flags:(NSEventModifierFlags)flags {
    [self flagsChanged:[NSEvent keyEventWithType:NSFlagsChanged location:NSZeroPoint modifierFlags:flags
        timestamp:0 windowNumber:self.window.windowNumber context:nil characters:@""
        charactersIgnoringModifiers:@"" isARepeat:NO keyCode:code]];
}
- (void)testOrdinaryLifeCycle {
    [self performMenuAction:@"New Game"];for(int i=0;i<60;i++)[self advanceFlowWithKey:YES];
    [enemies removeAllObjects];[world removeAllObjects];[world addObject:[NSNull null]];[mapPlacements removeAllObjects];
    memset(keys,0,sizeof(keys));inventory=(AstroInventory){40,3,2,1};playerWeapon=43;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=100};
    AstroCombatState hit={.kind=2,.layer=2,.hit_points=10};[self hitPlayerWithCombat:&hit];
    assert(playerCombat.hit_points==90&&playerHitVisual.active&&playerHitVisual.visual.sprite==71);
    uint64_t birth=playerHitBirth;hit=(AstroCombatState){.kind=2,.layer=2,.hit_points=10};[self hitPlayerWithCombat:&hit];
    assert(playerCombat.hit_points==80&&playerHitVisual.visual.sprite==72&&playerHitBirth==birth);
    AstroEnemy *obstacle=[self entityForPlacement:@{@"attribute":@201,@"x":@(playerBounds.left+5),@"y":@(playerBounds.top+3),@"width":@90,@"height":@80,@"tag":@0}];
    obstacle->kind=20;obstacle->hitPoints=100;[self prependEnemy:obstacle];
    [self checkCollisionsFor:[NSNull null]];
    assert(playerCombat.hit_points==70&&playerHitLayer==7&&playerHitBirth==birth&&playerHitVisual.visual.sprite==72);
    playerHitVisual.active=0;[self checkCollisionsFor:[NSNull null]];
    assert(playerCombat.hit_points==60&&playerHitLayer==8&&playerHitVisual.visual.sprite==71);
    [world removeObjectIdenticalTo:obstacle];[enemies removeObjectIdenticalTo:obstacle];
    playerCombat.remove=-1;
    uint32_t deathTick=simulationTick;[self cleanupWorld];
    assert(![world containsObject:[NSNull null]]&&inventory.lives==1&&respawnPending&&!respawnTick);
    observedWallTick=simulationTick-1;[self pollGame];
    assert(inventory.lives==0&&!respawnPending&&respawnTick&&respawnWaitStartTick==deathTick);
    for(int i=0;i<61;i++){simulationTick++;[self pollGame];}
    assert([world containsObject:[NSNull null]]&&playerCombat.kind==-1&&inventory.weapon==40&&inventory.upgrade==0&&inventory.specials==2&&playerWeapon==40);
    assert(playerSpawnTick==simulationTick&&((simulationTick-playerSpawnTick)/6)%2==0);
    for(int i=0;i<181;i++){simulationTick++;[self pollGame];}assert(playerCombat.kind==1&&!invulnerableUntil);
    [self enterPause];assert(paused&&menuVisible&&audio.music.isPlaying);
    memset(keys,0,sizeof(keys));uint32_t stopped=simulationTick;[self keyDown:[self testEvent:NSKeyDown code:124]];
    assert(paused);[self readPauseKeys];assert(!paused&&!menuVisible&&simulationTick==stopped);
    [self enterPause];memset(keys,0,sizeof(keys));
    [self testModifier:55 flags:NSEventModifierFlagCommand|NX_DEVICELCMDKEYMASK];assert(paused);
    [self readPauseKeys];assert(!paused&&!menuVisible&&keys[55]);
    [self testModifier:54 flags:NSEventModifierFlagCommand|NX_DEVICELCMDKEYMASK|NX_DEVICERCMDKEYMASK];assert(keys[55]&&keys[54]);
    [self testModifier:55 flags:NSEventModifierFlagCommand|NX_DEVICERCMDKEYMASK];assert(!keys[55]&&keys[54]);
    [self testModifier:54 flags:0];assert(!keys[55]&&!keys[54]);
    [self enterPause];memset(keys,0,sizeof(keys));
    [self testModifier:55 flags:0];[self readPauseKeys];assert(paused);
    [self testModifier:58 flags:NSEventModifierFlagOption|NX_DEVICELALTKEYMASK];assert(paused);
    [self readPauseKeys];assert(!paused&&!menuVisible);
    [self testModifier:58 flags:0];
    campaign=(AstroCampaign){1,2,0,0};[self beginStageTransition];assert(changingStage);
    [self performMenuAction:@"PauseQuit"];[self pollGame];[self performMenuAction:@"New Game"];
    assert(!changingStage&&transition.phase==0&&pendingCampaign.level==0&&selectedLevel==0&&flow.phase==ASTRO_FLOW_READY);
}
- (void)testScoreAndSettingsHandlers {
    double volume=ui.soundVolume;
    for(int i=0;i<11;i++)[self performMenuAction:@"SetSVolume"];
    assert(fabs(ui.soundVolume-volume)<.001);
    BOOL smooth=ui.smooth;[self performMenuAction:@"SetSmooth"];assert(ui.smooth!=smooth);
    [self performMenuAction:@"SetSmooth"];assert(ui.smooth==smooth);
    int fire=controlKeys[0];[self testCaptureKey:7];assert(controlKeys[0]==7&&editingKey==-1);
    [self testModifier:58 flags:NSEventModifierFlagOption|NX_DEVICELALTKEYMASK];assert(keys[58]);[self testCaptureKey:58];
    assert(controlKeys[0]==58&&editingKey==-1);[self testModifier:58 flags:0];controlKeys[0]=fire;
    AstroScore saved[10];memcpy(saved,highscores,sizeof(saved));astro_scores_clear(highscores);
    int oldScore=score;score=12345;[self beginGameOver];assert(ui.editingHighscore>0);assert((int)ui.scoreField.origin.y==183);
    NSEvent *text=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0
        timestamp:0 windowNumber:self.window.windowNumber context:nil characters:@"TEST"
        charactersIgnoringModifiers:@"TEST" isARepeat:NO keyCode:17];
    [self keyDown:text];assert(!scoreEditor.name[0]);
    for(unsigned i=0;i<4;i++){observedWallTick=[self currentGameTick]-(uint32_t)ui.frameInterval;[self pollMenu];}
    assert(!strcmp(scoreEditor.name,"TEST"));
    [self keyDown:[self testEvent:NSKeyDown code:36]];assert(!gameEndRequested);
    observedWallTick=[self currentGameTick]-(uint32_t)ui.frameInterval;[self pollMenu];assert(gameEndRequested);[self pollGame];
    assert([ui.anchor isEqual:@"Highscores Menu"]&&!strcmp(highscores[0].name,"TEST")&&highscores[0].score==12345);
    [self keyDown:[self testEvent:NSKeyDown code:17]];assert(highscores[1].score==0);
    score=0;gameLoopActive=YES;[self beginGameOver];assert(ui.editingHighscore==0);
    [self testModifier:55 flags:NSEventModifierFlagCommand|NX_DEVICELCMDKEYMASK];assert(gameOver);
    observedWallTick=[self currentGameTick]-(uint32_t)ui.frameInterval;[self pollMenu];[self pollGame];
    assert(!gameOver&&[ui.anchor isEqual:@"Play Menu"]);[self testModifier:55 flags:0];
    memcpy(highscores,saved,sizeof(saved));score=oldScore;[self refreshScores];
}
- (void)drawPanelTransition {
    // Original PAUSETRANS/GAMEOVERTRANS redraw without world steps or Delay.
    BOOL previous=panelTransitionRender;panelTransitionRender=YES;
    @try {while(ui.transitioning){[ui animateTicks:1];[self display];}}
    @finally {panelTransitionRender=previous;}
}
- (void)enterPause {
    menuVisible=YES;paused=YES;[audio playCue:@"Menu"];
    [ui show:@"Pause"];[self drawPanelTransition];
}
- (void)pumpPauseEvents {
    NSEvent *event;
    while((event=[NSApp nextEventMatchingMask:NSEventMaskAny untilDate:[NSDate distantPast]
        inMode:NSDefaultRunLoopMode dequeue:YES]))[NSApp sendEvent:event];
}
- (void)handleMiscKeys {
    if(!keys[53])return;
    // PAUSE returns to this exact WAIT/blink/outer-loop continuation.
    pauseLoopRunning=YES;
    @try {
        [self enterPause];
        do { @autoreleasepool {[self pollMenu];[self pumpPauseEvents];} } while(paused);
    } @finally {pauseLoopRunning=NO;}
    if([ui.anchor isEqual:@"Pause"])[self resumePause];
}
- (void)resumePause {
    if(pauseLoopRunning){paused=NO;return;}
    if(!gameOver&&!respawnPending&&!gameEndRequested){[ui beginPauseExit];[self drawPanelTransition];}
    menuVisible=NO;paused=NO;[audio setPaused:NO];
}
- (NSString *)scoreOperandDescription:(NSData *)operand {
    NSMutableData *shown=[operand mutableCopy];
    if(shown.length>=15){shown.length=15;((unsigned char *)shown.mutableBytes)[14]=0xc9;}
    NSString *text=[[NSString alloc] initWithData:shown encoding:NSMacOSRomanStringEncoding];
    return [NSString stringWithFormat:@"\"%@\" (length %lu)",text,(unsigned long)operand.length];
}
- (BOOL)continueScoreOverflow:(NSData *)left right:(NSData *)right {
    NSAlert *alert=[NSAlert new];alert.alertStyle=NSAlertStyleCritical;
    alert.messageText=@"Length >255 while adding strings:";
    alert.informativeText=[NSString stringWithFormat:@"%@ +\n%@",[self scoreOperandDescription:left],[self scoreOperandDescription:right]];
    [alert addButtonWithTitle:@"Stop"];[alert addButtonWithTitle:@"Continue"];
    return [alert runModal]==NSAlertSecondButtonReturn;
}
- (BOOL)resolveTextOverflow:(AstroScoreEditor *)editor byte:(unsigned)ch {
    size_t length=strlen(editor->name);
    size_t left=editor->cursor<0?0:MIN((size_t)editor->cursor,length);
    size_t right=editor->cursor>(int)length?0:MIN((size_t)((int)length-editor->cursor),length);
    NSMutableData *first=[NSMutableData dataWithBytes:editor->name length:left];
    unsigned char character=(unsigned char)ch;
    NSData *second;
    if(left==255)second=[NSData dataWithBytes:&character length:1];
    else{[first appendBytes:&character length:1];second=[NSData dataWithBytes:editor->name+length-right length:right];}
    BOOL proceed=[self continueScoreOverflow:first right:second];
    if(astro_score_editor_resolve_alert(editor,proceed)==ASTRO_SCORE_EDIT_STOP){terminationAllowed=YES;[NSApp terminate:nil];return NO;}
    return YES;
}
- (BOOL)editScoreByte:(unsigned)ch {
    if(astro_score_editor_key(&scoreEditor,ch)!=ASTRO_SCORE_EDIT_ALERT)return YES;
    return [self resolveTextOverflow:&scoreEditor byte:ch];
}
- (NSData *)fieldCharacters:(NSEvent *)event {
    unsigned byte=0;
    switch(event.keyCode){
        case 51:byte=8;break;case 117:byte=127;break;case 123:byte=28;break;case 124:byte=29;break;
        case 126:byte=30;break;case 125:byte=31;break;case 115:byte=1;break;case 119:byte=4;break;
        case 116:byte=11;break;case 121:byte=12;break;case 114:byte=5;break;case 71:byte=27;break;
        case 36:byte=13;break;case 76:byte=3;break;case 48:byte=9;break;case 53:byte=27;break;
    }
    if(!byte&&event.characters.length){unichar ch=[event.characters characterAtIndex:0];if(ch>=NSF1FunctionKey&&ch<=NSF35FunctionKey)byte=16;}
    if(byte){unsigned char ch=byte;return [NSData dataWithBytes:&ch length:1];}
    return [event.characters dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:NO];
}
- (void)keyDown:(NSEvent *)event {
    unsigned key=event.keyCode;
    if(splashVisible){if(key<128){keys[key]=YES;[self acceptSplash];}return;}
    if(key<128) keys[key]=YES;
    if(menuVisible&&!gameOver&&!paused&&editingKey<0&&ui.activeRegistrationField>=0){
        if(!registrationKeyEvents)registrationKeyEvents=[NSMutableData data];
        NSData *bytes=[self fieldCharacters:event];if(bytes)[registrationKeyEvents appendData:bytes];
        return;
    }
    if(menuVisible&&[ui.anchor isEqual:@"GameOver"]&&ui.editingHighscore>0) {
        if(!scoreKeyEvents)scoreKeyEvents=[NSMutableData data];
        NSData *bytes=[self fieldCharacters:event];if(bytes)[scoreKeyEvents appendData:bytes];
        return;
    }
    if(menuVisible&&gameOver)return;
    if(menuVisible&&paused)return;
    if(event.isARepeat) return;
    if(editingKey>=0&&key<128) {
        return;
    }
    if(!selftestPath)return;
    if(key==45||key==35) {
        selectedLevel=(selectedLevel+levels.count+(key==45?1:-1))%levels.count;
        camera=-0.0;
        [self resetEnemies];
        self.window.title=[NSString stringWithFormat:@"AstroSquid reconstruction preview — %@",levels[selectedLevel]];
    }
    if(key==18) playerWeapon=10;
    if(key==19) playerWeapon=30;
    if(key==20) playerWeapon=40;
    if(key==21) playerWeapon=50;
    if(key==18||key==19||key==20||key==21) {
        inventory.weapon=playerWeapon;inventory.upgrade=0;
    }
    if(key==49) automatic=!automatic;
    if(key==36) {paused=!paused;[audio setPaused:paused];}
    if(key==15) {[audio setPaused:NO];[audio playMusic:2];camera=-0.0;selectedLevel=0;[self resetEnemies];playerX=30;playerY=190;paused=NO;}
    if(key==46) audio.musicVolume=audio.musicVolume>0?0:.5;
    if(key==53){terminationAllowed=YES;[NSApp terminate:nil];}
}
- (void)keyUp:(NSEvent *)event { if(event.keyCode<128) keys[event.keyCode]=NO; }
- (void)flagsChanged:(NSEvent *)event {
    unsigned code=event.keyCode;
    NSEventModifierFlags flag=code==58||code==61?NSEventModifierFlagOption:
        code==56||code==60?NSEventModifierFlagShift:code==59||code==62?NSEventModifierFlagControl:
        code==55||code==54?NSEventModifierFlagCommand:code==57?NSEventModifierFlagCapsLock:
        code==63?NSEventModifierFlagFunction:0;
    if(!flag||code>=128)return;
    NSUInteger device=code==57?NSEventModifierFlagCapsLock:code==63?NSEventModifierFlagFunction:
        code==55?NX_DEVICELCMDKEYMASK:code==54?NX_DEVICERCMDKEYMASK:
        code==58?NX_DEVICELALTKEYMASK:code==61?NX_DEVICERALTKEYMASK:
        code==56?NX_DEVICELSHIFTKEYMASK:code==60?NX_DEVICERSHIFTKEYMASK:
        code==59?NX_DEVICELCTLKEYMASK:NX_DEVICERCTLKEYMASK;
    keys[code]=(event.modifierFlags&device)!=0;
    if(!keys[code])return;
    if(splashVisible){[self acceptSplash];return;}
    if(menuVisible&&paused)return;
    if(menuVisible&&gameOver&&ui.editingHighscore<=0)return;
}
- (void)refreshScores {
    NSMutableArray *rows=[NSMutableArray array];
    for(int i=0;i<10;i++){
        NSString *name=[[NSString alloc] initWithBytes:highscores[i].name length:strlen(highscores[i].name) encoding:NSMacOSRomanStringEncoding];
        [rows addObject:@{@"name":name?:@"",@"score":@(highscores[i].score)}];
    }
    ui.highscores=rows;
}
- (void)loadScores {
    astro_scores_clear(highscores);
    NSArray *rows=[[NSUserDefaults standardUserDefaults] arrayForKey:@"AstroSquidHighscores"];
    AstroScore loaded[10];BOOL valid=rows.count==10;
    for(int i=0;valid&&i<10;i++){
        NSDictionary *row=rows[i];
        if(![row isKindOfClass:[NSDictionary class]]||![row[@"name"] isKindOfClass:[NSString class]]||
            ![row[@"score"] isKindOfClass:[NSNumber class]]){valid=NO;break;}
        NSData *name=[row[@"name"] dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:NO];
        long long value=[row[@"score"] longLongValue];
        if(!name||name.length>255||value<0||value>INT32_MAX||(i&&value>loaded[i-1].score)) {valid=NO;break;}
        loaded[i].score=(int32_t)value;memcpy(loaded[i].name,name.bytes,name.length);loaded[i].name[name.length]=0;
    }
    if(valid)memcpy(highscores,loaded,sizeof(loaded));[self refreshScores];
}
- (void)saveScores {
    [self refreshScores];if(!selftestPath&&!campaignTestPath)[[NSUserDefaults standardUserDefaults] setObject:ui.highscores forKey:@"AstroSquidHighscores"];
}
- (void)refreshScoreEditor {
    ui.editingName=[[NSString alloc] initWithBytes:scoreEditor.name length:strlen(scoreEditor.name) encoding:NSMacOSRomanStringEncoding];
    ui.editingCursor=scoreEditor.cursor;
}
- (uint32_t)currentGameTick {
    return (uint32_t)floor((NSProcessInfo.processInfo.systemUptime-clockOrigin)*60);
}
- (void)delayGameTicks:(uint32_t)ticks {
    [NSThread sleepForTimeInterval:ticks/60.0];
}
- (void)beginGameOver {
    gameOver=YES;gameOverPending=NO;menuVisible=NO;ui.editingHighscore=0;
    AstroFlowPhase savedPhase=flow.phase;flow.phase=ASTRO_FLOW_PLAY;
    for(int milliseconds=10;milliseconds<=100;milliseconds+=10){
        simulationTick=[self currentGameTick];[self cleanupWorld];
        [self calculateActors];[self handleVisualEffects];
        simulationRender=YES;[self display];simulationRender=NO;
        [self delayGameTicks:(uint32_t)(milliseconds*60/1000)];
    }
    flow.phase=savedPhase;simulationTick=[self currentGameTick];
    menuVisible=YES;[ui show:@"GameOver"];[self drawPanelTransition];
    ui.editingHighscore=astro_scores_qualifies(highscores,score)?1:0;
    if(ui.editingHighscore>0)[ui prepareScoreField];
    astro_score_editor_begin(&scoreEditor);[ui beginScoreClock:[self currentGameTick]];[self refreshScoreEditor];
    scoreKeyEvents=nil;[self flushGameEvents];
}
- (void)finishGameOver {
    BOOL entered=ui.editingHighscore>0;
    [ui beginGameOverExit];BOOL previous=deferPresent;
    @try {
        deferPresent=NO;[self display];
        deferPresent=YES;[self display];
    } @finally {deferPresent=previous;}
    gameEndRequested=YES;gameEndHighscores=entered;
    if(entered){ui.editingHighscore=astro_scores_insert(highscores,score,scoreEditor.name);[self saveScores];}
    [ui finishGameOverExit];scoreKeyEvents=nil;
    paused=NO;gameOver=NO;menuVisible=NO;flow.phase=ASTRO_FLOW_PLAY;
}
- (void)requestQuit {quitRequested=YES;}
- (BOOL)canTerminateApplication {return terminationAllowed;}
- (void)destroyGameWorld {
    for(id object in [world copy]){
        [self deleteActor:object];[self setNextActor:nil forActor:object];
        if(object!=[NSNull null])((AstroEnemy *)object)->parent=nil;
    }
    [mapPlacements removeAllObjects];playerNextActor=nil;
    [visualEffects removeAllObjects];[specialPolygons removeAllObjects];[specialFlashes removeAllObjects];
    presentedBeams=@[];playerVisualDeleted=YES;playerHitVisual.active=NO;engineGlow=departureTrail=NO;
}
- (void)flushGameEvents {[NSApp discardEventsMatchingMask:NSEventMaskAny beforeEvent:nil];}
- (void)terminateApplication {[NSApp terminate:nil];}
- (void)releaseGraphics {
    if(graphicsReleased)return;graphicsReleased=YES;
    [self appendDebugMessage:@" "];[self appendDebugMessage:@"---------- Shutdown  -----------"];[self appendDebugMessage:@" "];
    [self appendDebugMessage:@"Disposing Spritemaps"];NSUInteger disposed=textures.count;
    NSOpenGLContext *context=[self openGLContext];[context makeCurrentContext];
    for(NSNumber *identifier in [textures.allKeys sortedArrayUsingSelector:@selector(compare:)])[self killSpriteMap:identifier.integerValue];
    [textures removeAllObjects];
    [self appendDebugMessage:[NSString stringWithFormat:@"    Disposed %lu SpriteMaps",(unsigned long)disposed]];
    [self appendDebugMessage:@"Disposing SpriteList"];
    [visualEffects removeAllObjects];[specialPolygons removeAllObjects];[specialFlashes removeAllObjects];
    for(AstroEnemy *enemy in enemies)enemy->visualDeleted=YES;
    presentedBeams=@[];playerVisualDeleted=YES;playerHitVisual.active=NO;engineGlow=departureTrail=NO;
    [self appendDebugMessage:@"Deactivating OpenGL context"];
    [NSOpenGLContext clearCurrentContext];[context clearDrawable];restoreFullscreen();
    [NSOpenGLContext clearCurrentContext];[self setOpenGLContext:nil];
    [self appendDebugMessage:@" "];[self appendDebugMessage:@"---------- End of Shutdown  -----------"];[self appendDebugMessage:@" "];
}
- (void)closeDown {
    if(terminationAllowed)return;
    [timer invalidate];timer=nil;
    [self saveSettings];[self releaseGraphics];[audio stopEffects];[self destroyGameWorld];[audio stopMusic];audio=nil;
    terminationAllowed=YES;[self terminateApplication];
}
- (void)completeGameLoopIfRequested {
    if(!gameLoopActive||(!quitRequested&&!gameEndRequested)||respawnTick||invulnerableUntil||
        changingStage||flow.phase!=ASTRO_FLOW_PLAY||menuVisible||paused||gameOver||
        pauseLoopRunning||specialLoopRunning||actorTraversalDepth)return;
    [self destroyGameWorld];gameLoopActive=NO;
    paused=gameOver=gameOverPending=NO;menuVisible=YES;
    [self reloadMainMenu];[ui show:gameEndHighscores?@"Highscores Menu":@"Play Menu"];
    [self display];gameEndHighscores=NO;[self flushGameEvents];
    [audio setPaused:NO];[audio stopMusic];[audio playMusic:1];
    gameEndRequested=NO;
}
- (void)unlockStage {
    ui.unlockedLevel=MAX(ui.unlockedLevel,MIN(16,(campaign.level-1)*2+campaign.half));
}
- (void)refreshKeyLabels {
    NSMutableArray *labels=[NSMutableArray array];
    for(int i=0;i<6;i++)[labels addObject:[ui nameForKeyCode:controlKeys[i]]];
    ui.keyLabels=labels;
}
- (void)saveSettings {
    if(selftestPath||campaignTestPath)return;
    [[NSUserDefaults standardUserDefaults] setInteger:ui.unlockedLevel forKey:@"AstroSquidUnlockedLevel"];
    NSMutableArray *codes=[NSMutableArray array];for(int i=0;i<6;i++)[codes addObject:@(controlKeys[i])];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"smooth":@(ui.smooth),@"sound":@(ui.soundVolume),
        @"music":@(ui.musicVolume),@"keys":codes,@"fps":@(preferenceFPS)} forKey:@"AstroSquidSettings"];
}
- (NSPoint)menuPoint:(NSEvent *)event {
    NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];
    return NSMakePoint(p.x*640/self.bounds.size.width,(self.bounds.size.height-p.y)*480/self.bounds.size.height);
}
- (NSPoint)currentMenuMousePoint {
    NSPoint p=[self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
    return NSMakePoint(p.x*640/self.bounds.size.width,(self.bounds.size.height-p.y)*480/self.bounds.size.height);
}
- (BOOL)menuMouseButtonPressed {return ([NSEvent pressedMouseButtons]&1)!=0;}
- (void)handleMenuMouseAtPoint:(NSPoint)p {
    if(navigationButton)return;
    if([ui.anchor isEqual:@"GameOver"]&&ui.editingHighscore>0&&[ui scoreFieldContainsX:p.x y:p.y]) {
        scoreEditor.cursor=[ui scoreCursorAtX:p.x];[self refreshScoreEditor];
    }
    if(![ui.anchor isEqual:@"Pause"]&&![ui.anchor isEqual:@"GameOver"])[ui selectRegistrationFieldX:p.x y:p.y];
    if(menuMouseLatched)return;
    NSString *name=[ui mouseDownX:p.x y:p.y];
    AstroUIAction action=astro_ui_command(name.UTF8String).action;
    if(action!=ASTRO_UI_NAVIGATE&&action!=ASTRO_UI_KEY)menuMouseLatched=YES;
    [self performMenuAction:name];
}
- (void)pollHeldMenuMouse {
    if(navigationButton||!menuVisible||splashVisible||editingKey>=0||ui.transitioning||![self menuMouseButtonPressed])return;
    [self handleMenuMouseAtPoint:[self currentMenuMousePoint]];
}
- (void)mouseDown:(NSEvent *)event {
    if(!menuVisible||editingKey>=0)return;
    if(splashVisible){[self acceptSplash];return;}
    if(ui.transitioning)return;
    [self handleMenuMouseAtPoint:[self menuPoint:event]];
}
- (void)mouseMoved:(NSEvent *)event {[self mouseDragged:event];}
- (BOOL)resignFirstResponder {memset(keys,0,sizeof(keys));return [super resignFirstResponder];}
- (void)mouseDragged:(NSEvent *)event {
    if(!menuVisible)return;NSPoint p=[self menuPoint:event];[ui moveMouseX:p.x y:p.y];
}
- (void)mouseUp:(NSEvent *)event {
    if(!menuVisible||editingKey>=0)return;
    if(splashVisible)return;
    NSPoint p=[self menuPoint:event];
    [ui mouseUpX:p.x y:p.y];
}
- (void)performMenuAction:(NSString *)name {
    AstroUICommand command=astro_ui_command(name.UTF8String);
    double position=[ui clickPosition:name];
    if(command.action!=ASTRO_UI_SOUND_VOLUME&&(command.action!=ASTRO_UI_NONE||isfinite(position)))[audio playCue:@"Click" position:position];
    if(command.action==ASTRO_UI_NAVIGATE){
        if([@[@"Back3",@"Back4",@"Back5",@"Back6",@"Back7"]containsObject:name])ui.activeRegistrationField=-1;
        navigationButton=[name copy];[ui setButton:name pressed:YES];
        if([name isEqual:@"Register"])ui.activeRegistrationField=0;
        if([name isEqual:@"Back"])[self saveSettings];
        [ui show:[NSString stringWithUTF8String:command.destination]];observedWallTick=[self currentGameTick];
        if(!ui.transitioning)[self finishMenuNavigation];
    }
    if(command.action==ASTRO_UI_CLEAR_SCORES){
        [ui setButton:name pressed:YES];[self display];[self delayGameTicks:3];
        astro_scores_clear(highscores);ui.editingHighscore=0;[self saveScores];[ui setButton:name pressed:NO];
    }
    if(command.action==ASTRO_UI_KEY) {
        ui.activeRegistrationField=-1;editingKey=command.key;[ui setButton:name pressed:YES];
        @try {int code=[self waitForMenuKey];if(code>=0)controlKeys[editingKey]=code;}
        @finally {[ui setButton:name pressed:NO];editingKey=-1;[self refreshKeyLabels];menuMouseLatched=YES;}
    }
    if(command.action==ASTRO_UI_SMOOTH) {
        [[self openGLContext] makeCurrentContext];[self setMenuCursor:4];[ui setButton:name pressed:YES];ui.smooth=!ui.smooth;
        for(int identifier=0;identifier<107;identifier++){[self killSpriteMap:identifier];[self texture:identifier];}
        [ui setButton:name pressed:NO];[self setMenuCursor:0];
    }
    if(command.action==ASTRO_UI_SOUND_VOLUME) {
        ui.soundVolume=((int)lround(ui.soundVolume*10)+1)%11/10.0;audio.soundVolume=ui.soundVolume/2;
        [audio playCue:@"Click"];[ui setButton:name pressed:YES];[self display];[ui setButton:name pressed:NO];
    }
    if(command.action==ASTRO_UI_MUSIC_VOLUME) {
        [ui setButton:name pressed:YES];[self display];
        ui.musicVolume=((int)lround(ui.musicVolume*10)+1)%11/10.0;audio.musicVolume=ui.musicVolume;
        [ui setButton:name pressed:NO];
    }
    if(command.action==ASTRO_UI_NEW_GAME||command.action==ASTRO_UI_CONTINUE) {
        NSString *stage=[NSString stringWithFormat:@"Data %d%c",command.stage,command.section==1?'A':'B'];
        NSUInteger index=[levels indexOfObject:stage];if(index==NSNotFound)return;
        if(!selftestPath&&!campaignTestPath)simulationTick=(uint32_t)floor((NSProcessInfo.processInfo.systemUptime-clockOrigin)*60);
        initialReadyCard=YES;changingStage=NO;transition=(AstroTransition){0};pendingCampaign=(AstroCampaign){0};
        ui.editingHighscore=0;selectedLevel=index;camera=-0.0;[self resetEnemies];playerX=30;playerY=190;
        [self finishPlayerStart];
        memset(keys,0,sizeof(keys));automatic=YES;paused=NO;menuVisible=NO;
        gameLoopActive=YES;gameEndRequested=gameEndHighscores=NO;
        astro_flow_ready(&flow,campaign.level,campaign.half);cardClockStarted=NO;[self unlockStage];
        [audio setPaused:NO];[audio playMusic:1];
    } else if(command.action==ASTRO_UI_QUIT) [self requestQuit];
    else if(command.action==ASTRO_UI_RESUME) {[self resumePause];}
    else if(command.action==ASTRO_UI_GAME_OVER_OK){gameEndRequested=YES;if(!ui.gameOverClosing)[self finishGameOver];}
    else if(command.action==ASTRO_UI_QUIT_GAME) {
        gameEndRequested=YES;gameEndHighscores=NO;
        paused=NO;gameOver=NO;menuVisible=NO;
    }
}
- (void)viewDidMoveToWindow { [self.window makeFirstResponder:self]; }
@end

@interface AstroDelegate : NSObject<NSApplicationDelegate,NSWindowDelegate>
@property(strong) NSWindow *window;
@property(strong) AstroView *view;
@end
@implementation AstroDelegate
- (void)presentGameWindow {
    [self.window center];[NSApp activateIgnoringOtherApps:YES];
    if(![self.view startFullscreen])[self.window makeKeyAndOrderFront:nil];
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"assets"];
    NSArray *arguments=[[NSProcessInfo processInfo] arguments];
    NSString *testPath=nil,*campaignPath=nil,*preferenceProbe=nil;
    for(NSUInteger i=1;i<arguments.count;i++) {
        if([arguments[i] isEqualToString:@"--self-test"] && i+1<arguments.count) testPath=arguments[++i];
        else if([arguments[i] isEqualToString:@"--campaign-test"] && i+1<arguments.count) campaignPath=arguments[++i];
        else if([arguments[i] isEqualToString:@"--preferences-probe"] && i+1<arguments.count) preferenceProbe=arguments[++i];
        else if([arguments[i] isEqualToString:@"--assets"] && i+1<arguments.count) path=arguments[++i];
    }
    NSRect frame=NSMakeRect(0,0,640,480);
    self.window=[[NSWindow alloc] initWithContentRect:frame
        styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title=@"AstroSquid";
    self.window.delegate=self;self.window.acceptsMouseMovedEvents=YES;
    AstroView *view=[[AstroView alloc] initWithFrame:frame assets:path];
    if(!view) { NSLog(@"Missing or invalid extracted game assets at %@",path); [NSApp terminate:nil]; return; }
    [view initializeDebugJournal];
    self.view=view;self.window.contentView=view;
    [self presentGameWindow];
    if(preferenceProbe)[view probePreferences:preferenceProbe];
    if(testPath) [view beginSelfTest:testPath];
    if(campaignPath) [view beginCampaignTest:campaignPath];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    AstroView *view=self.view ?: (AstroView *)self.window.contentView;
    if(![view isKindOfClass:[AstroView class]]||[view canTerminateApplication])return NSTerminateNow;
    [view requestQuit];return NSTerminateCancel;
}
- (BOOL)windowShouldClose:(NSWindow *)window {
    AstroView *view=(AstroView *)window.contentView;
    if(![view isKindOfClass:[AstroView class]]||[view canTerminateApplication])return YES;
    [view requestQuit];return NO;
}
- (void)applicationWillTerminate:(NSNotification *)notification {restoreFullscreen();}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
@end

int main(int argc,const char **argv) {
    atexit(restoreFullscreen);
    @autoreleasepool {
        NSApplication *app=[NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        AstroDelegate *delegate=[AstroDelegate new]; app.delegate=delegate;
        NSMenu *menu=[NSMenu new]; NSMenuItem *root=[NSMenuItem new]; [menu addItem:root];
        NSMenu *application=[NSMenu new];
        [application addItemWithTitle:@"Quit AstroSquid" action:@selector(terminate:) keyEquivalent:@"q"];
        root.submenu=application; app.mainMenu=menu;
        [app run];
    }
    return 0;
}
