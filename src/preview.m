// Partial native gameplay reconstruction; remaining limits are listed in README.md.
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <AVFoundation/AVFoundation.h>
#include "physics.h"
#include "script.h"
#include "weapons.h"
#include "combat.h"
#include "beams.h"
#include "player.h"
#include "campaign.h"
#include "flow.h"
#include "scores.h"
#include "transition.h"
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
typedef struct { __unsafe_unretained AstroView *view; __unsafe_unretained NSArray *objects; AstroTarget *targets; } BeamContext;
typedef struct { __unsafe_unretained AstroView *view; __unsafe_unretained id enemy; } EnemyContext;
typedef struct { AstroBeam beam; uint32_t expires; } LiveBeam;

@interface AstroEnemy : NSObject {
@public
    AstroScriptState state;
    NSDictionary *placement, *definition;
    NSData *program;
    int kind,layer,hitPoints,baseSprite;
    AstroVisual visual;
    AstroRect bounds,previousBounds;
    BOOL active;
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
    AstroCombatState playerCombat;
    uint32_t randomSeed,lastPlayerShot;
    int score;
    NSUInteger emittedShots,damageHits,emittedBeams;
    int playerWeapon;
    AstroInventory inventory;
    AstroCampaign campaign;
    AstroFlow flow;
    AstroTransition transition;
    AstroCampaign pendingCampaign;
    BOOL changingStage,engineGlow,departureTrail;
    AstroTransitionRect departureGlow,trailRect;
    AstroScore highscores[10];
    AstroScoreEditor scoreEditor;
    int campaignAction;
    uint32_t respawnTick,invulnerableUntil;
    BOOL paused,gameOver;
    NSMutableArray *liveBeams;
    NSArray *presentedBeams;
    uint32_t presentedBeamSeed;
    BOOL simulationRender;
    uint32_t simulationTick,lastSpawnTick;
    NSUInteger scriptSteps;
    NSString *assetPath;
    NSTimer *timer;
    AstroAudio *audio;
    AstroUIRenderer *ui;
    AstroHUDRenderer *hud;
    BOOL menuVisible,splashVisible;
    uint64_t renderClock,playerRenderBirth;
    double keyCaptureDeadline;
    int controlKeys[6],editingKey;
    AstroSpriteInfo spriteInfo[1001];
    NSMutableArray *visualEffects;
    AstroVisual playerVisual;
    AstroStar stars[3000];
    BOOL starsInitialized;
    NSArray *backgrounds;
    NSMutableData *parallaxData;
    double tickedScroll;
    AstroRect playerBounds,previousPlayerBounds;
    NSUInteger emittedEffects,emittedSpecials;
    AstroSpecial special;
    NSArray *suspendedSpecialTail;
    BOOL specialResumePending;
    NSMutableArray *specialPolygons,*specialFlashes;
    BOOL keys[128];
    NSInteger selectedLevel;
    double camera;
    double playerX,playerY,playerEntityX,playerEntityY;
    double previousTime;
    double tickRemainder;
    AstroVelocity playerVelocity;
    AstroPlayer playerState;
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
- (void)beginSelfTest:(NSString *)path;
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context;
- (void)hitPlayerWithEnemy:(AstroEnemy *)enemy;
- (void)emitDeathEffect:(const AstroDeathEffect *)effect;
- (void)spawnSpecial:(const AstroSpecialSpawn *)spawn;
- (void)spawnShot:(const AstroShot *)shot source:(int)kind;
- (void)addSpecialBeam:(const AstroBeam *)beam temporary:(int)temporary context:(BeamContext *)context;
- (void)addSpecialSprite:(int)sprite x:(double)x y:(double)y width:(double)width height:(double)height;
- (void)addSpecialPolygon:(const AstroSpecialVertex *)vertices count:(size_t)count;
- (void)playSound:(int)index x:(int)x;
- (void)drawSceneSprite:(const AstroSceneSprite *)sprite;
- (void)fireWeapon:(int)weapon x:(int)x y:(int)y heading:(int)heading source:(int)kind;
@end

static double number(NSDictionary *d, NSString *key) { return [d[key] doubleValue]; }

static void enemyFire(void *context,int weapon,int x,int y,int heading) {
    EnemyContext *source=context;
    [source->view fireWeapon:weapon x:x y:y heading:heading source:5];
}

static void enemyHit(void *context) {
    EnemyContext *source=context;[source->view hitPlayerWithEnemy:source->enemy];
}

static void beamHit(void *context,const AstroBeam *beam) {
    BeamContext *world=context;
    [world->view applyBeam:beam context:world];
}

static void deathEffect(void *context,const AstroDeathEffect *effect) {
    [(__bridge AstroView *)context emitDeathEffect:effect];
}

static void specialSpawn(void *c,const AstroSpecialSpawn *s) {BeamContext *w=c;[w->view spawnSpecial:s];}
static void specialBullet(void *c,const AstroShot *s) {BeamContext *w=c;[w->view spawnShot:s source:1];}
static void specialBeam(void *c,const AstroBeam *b,int temporary) {BeamContext *w=c;[w->view addSpecialBeam:b temporary:temporary context:w];}
static void specialSprite(void *c,int sprite,double x,double y,double width,double height) {
    BeamContext *w=c;[w->view addSpecialSprite:sprite x:x y:y width:width height:height];
}
static void specialPolygon(void *c,const AstroSpecialVertex *v,size_t n) {BeamContext *w=c;[w->view addSpecialPolygon:v count:n];}
static void specialSound(void *c,int index,int x) {BeamContext *w=c;[w->view playSound:index x:x];}

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
    randomSeed=1;
    [self resetEnemies];
    playerX = 30; playerY = 190;automatic=YES;
    previousTime = [NSDate timeIntervalSinceReferenceDate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self
                                           selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    audio=[[AstroAudio alloc] initWithAssets:path error:&error];
    if(!audio) {NSLog(@"Cannot load original audio: %@",error);return nil;}
    ui=[[AstroUIRenderer alloc] initWithAssets:path error:&error];
    if(!ui) {NSLog(@"Cannot load original interface: %@",error);return nil;}
    ui.registered=YES;ui.registeredName=@"MACSPB";editingKey=-1;
    ui.unlockedLevel=MAX(1,MIN(16,[[NSUserDefaults standardUserDefaults] integerForKey:@"AstroSquidUnlockedLevel"]));
    int defaults[6]={55,58,126,125,123,124};memcpy(controlKeys,defaults,sizeof(defaults));
    NSUserDefaults *preferences=[NSUserDefaults standardUserDefaults];
    NSDictionary *settings=[preferences dictionaryForKey:@"AstroSquidSettings"];
    if(settings) {
        ui.smooth=[settings[@"smooth"] boolValue];
        ui.soundVolume=fmax(0,fmin(1,[settings[@"sound"] doubleValue]));
        ui.musicVolume=fmax(0,fmin(1,[settings[@"music"] doubleValue]));
        NSArray *stored=settings[@"keys"];
        if(stored.count==6)for(int i=0;i<6;i++)if([stored[i] intValue]>=0&&[stored[i] intValue]<128)controlKeys[i]=[stored[i] intValue];
    }
    audio.soundVolume=ui.soundVolume;audio.musicVolume=ui.musicVolume;
    [self refreshKeyLabels];
    [self loadScores];
    hud=[[AstroHUDRenderer alloc] initWithGame:game ui:ui];
    menuVisible=YES;splashVisible=YES;
    [audio playMusic:1];
    return self;
}
- (BOOL)acceptsFirstResponder { return YES; }
- (void)prepareOpenGL {
    [super prepareOpenGL];
    GLint interval = 1;
    [[self openGLContext] setValues:&interval forParameter:NSOpenGLCPSwapInterval];
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0,0,0,1);
}
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
- (void)sprite:(NSInteger)identifier x:(double)x y:(double)y width:(double)w height:(double)h {
    NSDictionary *sprite = game[@"sprites"][[NSString stringWithFormat:@"%ld",(long)identifier]];
    if (!sprite) return;
    NSInteger atlasID = [sprite[@"texture"] integerValue];
    NSDictionary *atlas = game[@"textures"][[NSString stringWithFormat:@"%ld",(long)atlasID]];
    GLuint texture = [self texture:atlasID];
    if (!texture) return;
    if (w <= 0) w = number(sprite,@"width");
    if (h <= 0) h = number(sprite,@"height");
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
- (void)drawSceneSprite:(const AstroSceneSprite *)scene {
    if(scene->persistent) {
        if(!simulationRender)return;
        AstroVisual v={scene->sprite,scene->xy[0]+camera,scene->xy[1],
            scene->xy[2]-scene->xy[0],scene->xy[5]-scene->xy[1],
            simulationTick+(uint32_t)spriteInfo[scene->sprite].delay};
        [visualEffects addObject:[NSMutableData dataWithBytes:&v length:sizeof(v)]];return;
    }
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
- (void)drawRect:(NSRect)dirty {
    [[self openGLContext] makeCurrentContext];
    NSRect bounds = [self convertRectToBacking:self.bounds];
    glViewport(0,(GLint)(bounds.size.height*30/480),(GLsizei)bounds.size.width,(GLsizei)(bounds.size.height*380/480));
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION); glLoadIdentity(); glOrtho(0,640,379,0,-1,1);
    glMatrixMode(GL_MODELVIEW); glLoadIdentity();
    if(!menuVisible&&flow.phase!=ASTRO_FLOW_PLAY) {
        AstroHUDState overlay={!playerCombat.remove,playerCombat.hit_points,inventory.weapon,
            inventory.upgrade,inventory.specials,inventory.lives,score};
        [hud drawState:&overlay texture:^GLuint(NSInteger n){return [self texture:n];}
            framebufferWidth:(GLsizei)bounds.size.width height:(GLsizei)bounds.size.height];
        glViewport(0,0,(GLsizei)bounds.size.width,(GLsizei)bounds.size.height);
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);
        glMatrixMode(GL_MODELVIEW);glLoadIdentity();
        [ui drawPicture:astro_flow_picture(&flow) x:0 y:40 width:0 height:0 texture:^GLuint(NSInteger n){return [self texture:n];}];
        if(flow.phase==ASTRO_FLOW_ENDING)
            [ui drawEndingPage:flow.ending_page texture:^GLuint(NSInteger n){return [self texture:n];}];
        else [ui drawBriefingForStage:flow.stage list:astro_flow_text_list(&flow) texture:^GLuint(NSInteger n){return [self texture:n];}];
        if(campaignTestPath)glFlush();else [[self openGLContext] flushBuffer];return;
    }
    if(menuVisible) {
        glViewport(0,0,(GLsizei)bounds.size.width,(GLsizei)bounds.size.height);
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);
        glMatrixMode(GL_MODELVIEW);glLoadIdentity();
        if(splashVisible) {
            [ui drawSplashWithTexture:^GLuint(NSInteger n){return [self texture:n];}];
            if(campaignTestPath)glFlush();else [[self openGLContext] flushBuffer];return;
        }
        AstroSceneSink menuSink={(__bridge void *)self,sceneLine,sceneSprite,scenePoint,sceneTrail};
        astro_stars_draw(stars,1,campaign.level,0,&menuSink);
        [ui drawSprites:^(NSInteger n,double x,double y,double w,double h){
            [self sprite:n x:x y:y width:w height:h];
        } texture:^GLuint(NSInteger n){return [self texture:n];}];
        if(campaignTestPath)glFlush();else [[self openGLContext] flushBuffer];return;
    }
    AstroSceneSink sink={(__bridge void *)self,sceneLine,sceneSprite,scenePoint,sceneTrail};
    astro_stars_draw(stars,0,campaign.level,tickedScroll,&sink);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
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
                if(layer==6&&(!invulnerableUntil||(simulationTick/6)%2))
                    [self sprite:playerVisual.sprite x:playerX y:playerY width:playerVisual.width height:playerVisual.height];
                continue;
            }
            AstroEnemy *enemy=object;
            int renderLayer=enemy->kind==5?5:(enemy->kind>=20&&enemy->kind<=29)?4:
                (enemy->kind==2||enemy->kind==4||enemy->kind==40)?6:1;
            if(renderLayer!=layer)continue;
            double x=enemy->visual.x-camera,y=enemy->visual.y;
            if(x+enemy->visual.width<0||x>640||y+enemy->visual.height<0||y>380)continue;
            [self sprite:enemy->visual.sprite x:x y:y width:enemy->visual.width height:enemy->visual.height];
        }
        if(layer==4&&departureTrail)[self sprite:116 x:trailRect.x-camera y:trailRect.y width:trailRect.width height:trailRect.height];
    }
    if(simulationRender){presentedBeams=[liveBeams copy];presentedBeamSeed=randomSeed;[liveBeams removeAllObjects];}
    uint32_t beamSeed=presentedBeamSeed;
    for(NSData *data in presentedBeams) {
        const LiveBeam *live=data.bytes;
        astro_beam_render(&live->beam,-camera,0,camera,0,camera+640,380,&beamSeed,&sink);
    }
    if(simulationRender)randomSeed=beamSeed;
    for(NSMutableData *data in visualEffects) {
        const AstroVisual *v=data.bytes;
        [self sprite:v->sprite x:v->x-camera y:v->y width:v->width height:v->height];
    }
    if(engineGlow) {
        AstroTransitionRect glow=departureTrail?departureGlow:
            astro_transition_engine_glow(playerVisual.x,playerY,playerVisual.height,playerState.frame);
        [self sprite:115 x:glow.x-camera y:glow.y width:glow.width height:glow.height];
    }
    glDisable(GL_TEXTURE_2D);glShadeModel(GL_SMOOTH);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    for(NSData *data in specialPolygons) {
        const AstroSpecialVertex *v=data.bytes;size_t n=data.length/sizeof(*v);glBegin(GL_POLYGON);
        for(size_t i=0;i<n;i++) {glColor4d(v[i].r,v[i].g,v[i].b,v[i].a);glVertex2d(v[i].x-camera,v[i].y);}glEnd();
    }
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    for(NSData *data in specialFlashes) {
        const AstroVisual *v=data.bytes;[self sprite:v->sprite x:v->x-camera y:v->y width:v->width height:v->height];
    }
    AstroHUDState overlay={!playerCombat.remove,playerCombat.hit_points,inventory.weapon,
        inventory.upgrade,inventory.specials,inventory.lives,score};
    [hud drawState:&overlay texture:^GLuint(NSInteger n){return [self texture:n];}
        framebufferWidth:(GLsizei)bounds.size.width height:(GLsizei)bounds.size.height];
    if(campaignTestPath)glFlush();else [[self openGLContext] flushBuffer];
}
- (AstroEnemy *)entityForPlacement:(NSDictionary *)placement {
    NSString *attribute=[placement[@"attribute"] stringValue];
    AstroEnemy *enemy=[AstroEnemy new];enemy->renderBirth=++renderClock;
    enemy->placement=placement; enemy->definition=game[@"attributes"][attribute];
    enemy->baseSprite=[enemy->definition[@"sprite"] intValue];
    enemy->visual=(AstroVisual){enemy->baseSprite,number(placement,@"x"),number(placement,@"y"),
        number(placement,@"width"),number(placement,@"height"),simulationTick+(uint32_t)spriteInfo[enemy->baseSprite].delay};
    enemy->bounds=(AstroRect){(int)enemy->visual.x,(int)enemy->visual.y,
        (int)(enemy->visual.x+enemy->visual.width),(int)(enemy->visual.y+enemy->visual.height)};
    enemy->previousBounds=enemy->bounds;
    enemy->state=(AstroScriptState){.frame=1,.tilt=1,.state=1,
        .x=number(placement,@"x"),.y=number(placement,@"y")};
    int group=attribute.intValue/10;
    enemy->kind=group>5&&group<20?5:group;
    enemy->layer=enemy->kind==5?2:0;
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
    renderClock=0;enemies=[NSMutableArray array];world=[NSMutableArray array];mapPlacements=[NSMutableArray array];
    simulationTick=0;lastSpawnTick=0;lastPlayerShot=0;score=0;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=100};
    visualEffects=[NSMutableArray array];specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    special=(AstroSpecial){0};suspendedSpecialTail=nil;specialResumePending=NO;
    playerVisual=(AstroVisual){1,30,190,71,20,0};playerEntityX=30;playerEntityY=190;
    playerBounds=(AstroRect){30,190,101,210};previousPlayerBounds=playerBounds;
    playerState=(AstroPlayer){{0,0},12,3,1,0,0};playerVelocity=(AstroVelocity){0,0};
    inventory=(AstroInventory){10,0,1,1};
    NSString *stage=levels[selectedLevel];
    campaign=(AstroCampaign){[[stage substringFromIndex:5] intValue],[stage hasSuffix:@"A"]?1:2,0,0};
    campaignAction=ASTRO_CAMPAIGN_NONE;respawnTick=invulnerableUntil=0;gameOver=NO;engineGlow=departureTrail=NO;
    playerWeapon=10;liveBeams=[NSMutableArray array];presentedBeams=@[];
    NSDictionary *level=game[@"levels"][levels[selectedLevel]];
    if(!starsInitialized) {astro_stars_init(stars,1,&randomSeed);starsInitialized=YES;}
    astro_stars_init(stars,0,&randomSeed);
    backgrounds=game[@"scenes"][level[@"background"]];
    parallaxData=[NSMutableData dataWithLength:backgrounds.count*sizeof(AstroParallax)];
    AstroParallax *parallax=parallaxData.mutableBytes;
    for(NSUInteger i=0;i<backgrounds.count;i++) parallax[i]=(AstroParallax){
        number(backgrounds[i],@"x"),number(backgrounds[i],@"y"),[backgrounds[i][@"userdata"] intValue]};
    for(NSDictionary *placement in level[@"entities"]) {
        if([placement[@"attribute"] intValue]==11) continue;
        [mapPlacements addObject:placement];
    }
    [self makeNewSprites];playerRenderBirth=++renderClock;[world insertObject:[NSNull null] atIndex:0];
}
- (void)prependEnemy:(AstroEnemy *)enemy {
    enemy->active=YES;[enemies insertObject:enemy atIndex:0];[world insertObject:enemy atIndex:0];
}
- (void)makeNewSprites {
    for(NSDictionary *placement in [mapPlacements copy]) {
        if(number(placement,@"x")>=camera+740)continue;
        AstroEnemy *enemy=[self entityForPlacement:placement];
        enemy->state.x=(int)enemy->state.x;enemy->state.y=(int)enemy->state.y;
        enemy->visual.x=enemy->state.x;enemy->visual.y=enemy->state.y;
        enemy->state.update_tick=enemy->state.animation_tick=enemy->state.action_tick=simulationTick;
        [self prependEnemy:enemy];[mapPlacements removeObjectIdenticalTo:placement];
    }
}
- (void)fireWeapon:(int)identifier x:(int)x y:(int)y heading:(int)heading source:(int)kind {
    if(identifier>=40&&identifier<=53) {
        [audio playStringCue:identifier>=50?295:296 position:(x-camera)/640];
        NSArray *objects=[world copy];size_t count=objects.count;
        NSMutableData *targetData=[self targetsForObjects:objects];AstroTarget *targets=targetData.mutableBytes;
        AstroBeam beams[2];BeamContext context={self,objects,targets};
        int emitted=astro_beam_shots(identifier,x,y,heading,1,kind,-1,targets,count,
            camera,0,camera+640,380,&randomSeed,beams,beamHit,&context);
        if(emitted<0) {NSLog(@"Invalid beam request");exit(1);}
        for(int i=0;i<emitted;i++) {
            LiveBeam live={beams[i],simulationTick+1};
            [liveBeams insertObject:[NSData dataWithBytes:&live length:sizeof(live)] atIndex:0];
        }
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
    bullet->kind=attribute>30?5:2;bullet->active=YES;
    bullet->layer=kind==5?2:(kind==1||kind==-1)?3:0;
    bullet->state.update_tick=bullet->state.animation_tick=
        bullet->state.action_tick=simulationTick;
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
    int attribute=spawn->kind*10+spawn->subtype;
    NSDictionary *definition=game[@"attributes"][[NSString stringWithFormat:@"%d",attribute]];
    int sprite=[definition[@"sprite"] intValue];
    if(!definition||spriteInfo[sprite].width<=0) {NSLog(@"Invalid special entity %d",attribute);exit(1);}
    NSDictionary *placement=@{@"attribute":@(attribute),@"x":@(spawn->x),@"y":@(spawn->y),
        @"width":@(spriteInfo[sprite].width),@"height":@(spriteInfo[sprite].height),@"tag":@0};
    AstroEnemy *enemy=[self entityForPlacement:placement];enemy->active=YES;
    enemy->kind=spawn->kind;enemy->layer=spawn->layer;enemy->state.frame=spawn->frame;
    enemy->state.velocity=spawn->velocity;
    enemy->state.action_tick=simulationTick+(uint32_t)spawn->action_offset;
    enemy->state.update_tick=enemy->state.animation_tick=simulationTick;
    if(spawn->hit_points>0) enemy->hitPoints=spawn->hit_points;
    if(spawn->width>0) enemy->visual.width=spawn->width;
    if(spawn->height>0) enemy->visual.height=spawn->height;
    if(spawn->scale!=1) {
        enemy->bounds.right=(int)(enemy->bounds.left+(enemy->bounds.right-enemy->bounds.left)*spawn->scale);
        enemy->bounds.bottom=(int)(enemy->bounds.top+(enemy->bounds.bottom-enemy->bounds.top)*spawn->scale);
        enemy->visual.width*=spawn->scale;enemy->visual.height*=spawn->scale;
    }
    [self prependEnemy:enemy];
}
- (void)addSpecialBeam:(const AstroBeam *)beam temporary:(int)temporary context:(BeamContext *)context {
    [self applyBeam:beam context:context];
    if(!temporary) {LiveBeam live={*beam,simulationTick+1};
        [liveBeams insertObject:[NSData dataWithBytes:&live length:sizeof(live)] atIndex:0];emittedBeams++;}
}
- (void)addSpecialSprite:(int)sprite x:(double)x y:(double)y width:(double)width height:(double)height {
    AstroVisual v={sprite,x,y,width,height,simulationTick};
    [specialFlashes addObject:[NSData dataWithBytes:&v length:sizeof(v)]];
}
- (void)addSpecialPolygon:(const AstroSpecialVertex *)vertices count:(size_t)count {
    [specialPolygons addObject:[NSData dataWithBytes:vertices length:count*sizeof(*vertices)]];
}
- (void)playSound:(int)index x:(int)x {[audio playStringCue:index position:(x-camera)/640];}
- (int)stepSpecial:(BOOL)start {
    NSArray *objects=[world copy];NSMutableData *data=[self targetsForObjects:objects];
    BeamContext beamWorld={self,objects,data.mutableBytes};
    AstroSpecialContext context={.context=&beamWorld,.seed=&randomSeed,.targets=data.mutableBytes,
        .target_count=objects.count,.source_parent=-1,.gun_x=playerBounds.left+74,.gun_y=playerBounds.top+12,
        .frame_interval=1,.left=camera,.top=0,.right=camera+640,.bottom=380,
        .spawn=specialSpawn,.bullet=specialBullet,.beam=specialBeam,.sprite=specialSprite,
        .polygon=specialPolygon,.sound=specialSound};
    if(start) {
        if(playerWeapon>=40) {playerCombat.kind=-1;NSUInteger index=[objects indexOfObjectIdenticalTo:[NSNull null]];
            if(index!=NSNotFound)((AstroTarget *)data.mutableBytes)[index].kind=-1;}
        if(!astro_special_start_nested(&special,playerWeapon,context.gun_x,context.gun_y,0,simulationTick,&context)) {
            NSLog(@"Cannot start special attack");exit(1);
        }
        inventory.specials--;emittedSpecials++;
    }
    int flags=0;
    if(!start&&special.active)flags=astro_special_step_nested(&special,simulationTick,&context);
    lastPlayerShot=special.action_until;
    if(!special.active&&!invulnerableUntil)playerCombat.kind=1;
    return flags;
}

- (void)hitPlayerWithEnemy:(AstroEnemy *)enemy {
    AstroCombatState attacker=[self combatFor:enemy];
    astro_bullet_hits_player(&attacker,&playerCombat);
    [self applyCombat:attacker to:enemy];
}
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context {
    if(beam->target<0) return;
    AstroCombatState b={.kind=999,.layer=1,.hit_points=beam->damage};
    if(context->objects[beam->target]==[NSNull null]) {
        if(playerCombat.kind==1) astro_bullet_hits_player(&b,&playerCombat);
        context->targets[beam->target].remove=playerCombat.remove;
    } else {
        AstroEnemy *enemy=context->objects[beam->target];
        AstroCombatState target=[self combatFor:enemy];
        if(enemy->kind==5||(enemy->kind>19&&enemy->kind<30)) {
            astro_bullet_hits_enemy(&b,&target,[enemy->definition[@"kill_score"] intValue],&score);
            if(target.hit_points!=enemy->hitPoints) damageHits++;
            [self applyCombat:target to:enemy];
            context->targets[beam->target].remove=target.remove;
        }
    }
}
- (void)emitDeathEffect:(const AstroDeathEffect *)effect {
    if(effect->type==ASTRO_EFFECT_SOUND) {
        [audio playStringCue:effect->sound_string position:(effect->x-camera)/640];return;
    }
    emittedEffects++;
    if(effect->type==ASTRO_EFFECT_EXPLOSION) {
        AstroVisual visual={effect->sprite,effect->x,effect->y,effect->width,effect->height,effect->animation_tick};
        [visualEffects addObject:[NSMutableData dataWithBytes:&visual length:sizeof(visual)]];return;
    }
    NSDictionary *definition=game[@"attributes"][[NSString stringWithFormat:@"%d",effect->attribute]];
    int sprite=[definition[@"sprite"] intValue];
    double width=effect->type==ASTRO_EFFECT_PICKUP?spriteInfo[sprite].width:effect->width;
    double height=effect->type==ASTRO_EFFECT_PICKUP?spriteInfo[sprite].height:effect->height;
    NSDictionary *placement=@{@"attribute":@(effect->attribute),@"x":@(effect->x),@"y":@(effect->y),
        @"width":@(width),@"height":@(height),@"tag":@0};
    AstroEnemy *enemy=[self entityForPlacement:placement];enemy->active=YES;
    enemy->kind=effect->kind;enemy->state.frame=effect->frame;
    enemy->state.velocity=effect->velocity;
    enemy->state.update_tick=enemy->state.animation_tick=simulationTick;
    enemy->state.action_tick=effect->action_tick;
    [self prependEnemy:enemy];
}
- (void)addDeathEffects:(AstroEnemy *)enemy {
    int sprite=enemy->visual.sprite;
    int explosion=[enemy->definition[@"death_effect"] intValue];
    int debris=[enemy->definition[@"debris_sprite"] intValue];
    NSDictionary *debrisDefinition=game[@"attributes"][[NSString stringWithFormat:@"%d",debris]];
    int debrisSprite=[debrisDefinition[@"sprite"] intValue];
    AstroDeathSource source={.kind=enemy->kind,.tag=[enemy->placement[@"tag"] intValue],
        .left=enemy->bounds.left,.top=enemy->bounds.top,.right=enemy->bounds.right,.bottom=enemy->bounds.bottom,
        .width=enemy->visual.width,.height=enemy->visual.height,.original_height=spriteInfo[sprite].height,
        .velocity=enemy->state.velocity,.explosion_sprite=explosion,.explosion_width=spriteInfo[explosion].width,
        .explosion_height=spriteInfo[explosion].height,.explosion_delay=spriteInfo[explosion].delay,
        .debris_attribute=debris,.debris_sprite=debrisSprite,.debris_width=spriteInfo[debrisSprite].width,
        .debris_height=spriteInfo[debrisSprite].height,.debris_count=[enemy->definition[@"debris_amount"] intValue]};
    if(!astro_death_effects(&source,simulationTick,&randomSeed,deathEffect,(__bridge void *)self)) {
        NSLog(@"Invalid death effect configuration");exit(1);
    }
}
- (void)updateVisualEffects {
    NSIndexSet *finished=[visualEffects indexesOfObjectsPassingTest:
        ^BOOL(NSMutableData *data,NSUInteger index,BOOL *stop) {
            int result=astro_visual_step(data.mutableBytes,spriteInfo,1001,simulationTick);
            if(result<0) {NSLog(@"Invalid effect animation");exit(1);}
            return result==0;
        }];
    [visualEffects removeObjectsAtIndexes:finished];
    for(AstroEnemy *enemy in enemies) if(enemy->active&&!enemy->state.remove) {
        int result=astro_visual_step(&enemy->visual,spriteInfo,1001,simulationTick);
        if(result<0) {NSLog(@"Invalid entity animation");exit(1);}
        if(!result) enemy->state.remove=1;
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
            astro_bullet_hits_player(&attacker,&playerCombat);[self applyCombat:attacker to:source];
            playerVelocity=playerCombat.velocity;
        } else if(kind==2&&(targetKind==5||(targetKind>=20&&targetKind<=29))) {
            AstroCombatState bullet=[self combatFor:source],victim=[self combatFor:target];
            int impact=astro_bullet_hits_enemy(&bullet,&victim,[target->definition[@"kill_score"] intValue],&score);
            if(impact)[self addDeathEffects:source];
            if(victim.hit_points!=target->hitPoints)damageHits++;
            [self applyCombat:bullet to:source];[self applyCombat:victim to:target];
        } else if(kind==1&&targetKind==40) {
            int old=target->state.remove;
            astro_pickup(&playerCombat,[target->placement[@"attribute"] intValue]%10,target->hitPoints,&target->state.remove,&inventory);
            if(!old&&target->state.remove)[audio playStringCue:[target->placement[@"attribute"] intValue]%10==1?302:
                [target->placement[@"attribute"] intValue]%10==9?304:303 position:playerX/640];
            playerWeapon=inventory.weapon+inventory.upgrade;
        } else if(kind==1&&targetKind>=20&&targetKind<=29) {
            AstroCombatState scenery=[self combatFor:target];playerCombat.velocity=playerVelocity;
            astro_player_hits_scenery(&playerCombat,a,&scenery,b);[self applyCombat:scenery to:target];
            playerVelocity=playerCombat.velocity;
        }
    }
}
- (void)stepPlayer {
    playerVisual.x+=playerVelocity.x+tickedScroll;playerVisual.y+=playerVelocity.y;
    astro_visual_change(&playerVisual,playerState.frame,spriteInfo,1001,simulationTick);
    playerEntityX=playerVisual.x;playerEntityY=playerVisual.y;
    playerX=playerVisual.x-camera;playerY=playerVisual.y;
    previousPlayerBounds=playerBounds;
    playerBounds=(AstroRect){(int16_t)(int)playerVisual.x,(int16_t)(int)playerVisual.y,
        (int16_t)(int)(playerVisual.x+playerVisual.width),(int16_t)(int)(playerVisual.y+playerVisual.height)};
    playerCombat.velocity=playerVelocity;
    [self checkCollisionsFor:[NSNull null]];
    unsigned controls=0;
    if(keys[controlKeys[4]])controls|=ASTRO_KEY_LEFT;
    if(keys[controlKeys[5]])controls|=ASTRO_KEY_RIGHT;
    if(keys[controlKeys[2]])controls|=ASTRO_KEY_UP;
    if(keys[controlKeys[3]])controls|=ASTRO_KEY_DOWN;
    if(changingStage&&!transition.allow_input)controls=transition.controls;
    playerState.velocity=playerVelocity;
    astro_player_step(&playerState,simulationTick,controls,1,playerBounds,playerVisual.width,playerVisual.height,
        (AstroRect){(int)camera,0,(int)(camera+640),380},changingStage);
    playerVelocity=playerState.velocity;playerCombat.velocity=playerVelocity;
    if((!changingStage||transition.allow_input)&&keys[selftestPath?8:controlKeys[0]]&&!special.active&&(int32_t)(simulationTick-lastPlayerShot)>
        60.0/[game[@"weapons"][[NSString stringWithFormat:@"%d",playerWeapon]][@"rate"] doubleValue]) {
        lastPlayerShot=simulationTick;
        [self fireWeapon:playerWeapon x:(playerBounds.left+playerBounds.right)/2+20 y:(playerBounds.top+playerBounds.bottom)/2 heading:0 source:1];
    }
    BOOL startSpecial=(!changingStage||transition.allow_input)&&keys[selftestPath?58:controlKeys[1]]&&!special.active&&inventory.specials>0&&
        (int32_t)(simulationTick-lastPlayerShot)>
        60.0/[game[@"weapons"][[NSString stringWithFormat:@"%d",playerWeapon]][@"rate"] doubleValue];
    if(startSpecial)[self stepSpecial:YES];
}
- (void)cleanupWorld {
    for(id object in [world copy]) {
        BOOL player=object==[NSNull null];AstroEnemy *enemy=player?nil:object;
        int remove=player?playerCombat.remove:enemy->state.remove;
        if(!remove)continue;
        if(remove==-1) {
            if(player) {
                AstroEnemy *body=[self entityForPlacement:@{@"attribute":@11,@"x":@(playerVisual.x),@"y":@(playerY),
                    @"width":@(playerVisual.width),@"height":@(playerVisual.height),@"tag":@0}];
                body->visual=playerVisual;body->bounds=playerBounds;body->state.velocity=playerVelocity;[self addDeathEffects:body];
                if(inventory.lives==0){gameOver=YES;if(!selftestPath)[self beginGameOver];}
                else {inventory.lives--;respawnTick=simulationTick+61;}
            } else {
                [self addDeathEffects:enemy];
                int action=changingStage?ASTRO_CAMPAIGN_NONE:astro_campaign_event(&campaign,[enemy->placement[@"tag"] intValue],0);
                if(action!=ASTRO_CAMPAIGN_NONE)campaignAction=action;
            }
        }
        [world removeObjectIdenticalTo:object];if(!player)[enemies removeObjectIdenticalTo:enemy];
    }
}
- (void)stepActor:(id)object {
    if(object==[NSNull null]){[self stepPlayer];return;}
    AstroEnemy *enemy=object;
    AstroScriptState *state=&enemy->state;
    enemy->visual.x+=state->velocity.x;enemy->visual.y+=state->velocity.y;
    if([enemy->definition[@"animated"] boolValue]&&enemy->kind!=2&&enemy->kind!=4&&enemy->kind!=20&&enemy->kind!=40)
        astro_visual_change(&enemy->visual,enemy->baseSprite+state->frame-1,spriteInfo,1001,simulationTick);
    state->x=enemy->visual.x;state->y=enemy->visual.y;
    enemy->previousBounds=enemy->bounds;
    enemy->bounds=(AstroRect){(int16_t)(int)state->x,(int16_t)(int)state->y,
        (int16_t)(int)(state->x+enemy->visual.width),(int16_t)(int)(state->y+enemy->visual.height)};
    if(enemy->bounds.left>camera+(enemy->kind==2?650:740)||enemy->bounds.right<camera-10||
       (enemy->kind==2&&(enemy->bounds.top>390||enemy->bounds.bottom< -10))) {
        state->remove=1;
    }
    [self checkCollisionsFor:enemy];
    if(enemy->kind==5&&enemy->program.length&&enemy->bounds.left<camera+640&&enemy->bounds.right>camera) {
        double w=enemy->bounds.right-enemy->bounds.left,h=enemy->bounds.bottom-enemy->bounds.top;
        int heading=astro_heading(state->x,state->y,w,h,playerEntityX,playerEntityY,
            playerBounds.right-playerBounds.left,playerBounds.bottom-playerBounds.top);
        EnemyContext source={self,enemy};
        AstroScriptContext context={.player_present=[world containsObject:[NSNull null]],.target_heading=(int)heading,
            .player_x=playerEntityX,.player_y=playerEntityY,
            .animated=[enemy->definition[@"animated"] intValue],
            .weapon=[enemy->definition[@"weapon"] intValue],
            .userdata=&source,.fire=enemyFire,.hit_player=enemyHit,
            .gun_x=(int)state->x+[enemy->definition[@"turret_x"] intValue],
            .gun_y=(int)state->y+[enemy->definition[@"turret_y"] intValue]};
        if(!astro_script_step(state,enemy->program.bytes,
            enemy->program.length/sizeof(AstroInstruction),simulationTick,&context)) {
            NSLog(@"Script ended outside RETURN"); exit(1);
        }
        scriptSteps++;
    }
    if(enemy->kind==2&&state->state==1&&simulationTick>state->update_tick)state->update_tick=simulationTick;
    if(enemy->kind==4||enemy->kind==20) {
        AstroDebris debris={enemy->kind,state->state,state->frame,state->remove,state->update_tick,
            state->animation_tick,state->action_tick,state->velocity};
        astro_debris_step(&debris,simulationTick,enemy->bounds.right,camera,astro_debris_gravity(campaign.level));
        state->velocity=debris.velocity;state->update_tick=debris.update_tick;
        state->animation_tick=debris.animation_tick;state->remove=debris.remove;
    }
    if([enemy->placement[@"attribute"] intValue]==399) {
        int tag=[enemy->placement[@"tag"] intValue];
        int action=changingStage?ASTRO_CAMPAIGN_NONE:astro_campaign_event(&campaign,tag,1);
        if(action!=ASTRO_CAMPAIGN_NONE)campaignAction=action;
        tickedScroll=0;
        if(tag!=-1){state->remove=1;[audio playMusic:3];}
    }
}
- (void)loadCampaignStage:(AstroCampaign)next {
    NSString *stage=[NSString stringWithFormat:@"Data %d%c",next.level,next.half==1?'A':'B'];
    NSUInteger index=[levels indexOfObject:stage];if(index==NSNotFound){NSLog(@"Missing stage %@",stage);exit(1);}
    AstroInventory saved=inventory;int savedScore=score;
    selectedLevel=index;camera=0;[self resetEnemies];inventory=saved;score=savedScore;
    inventory.weapon=10;inventory.upgrade=0;playerWeapon=10;playerX=30;playerY=190;
    if(selftestPath)playerCombat.hit_points=1000000;
    [self unlockStage];
}
- (void)beginStageTransition {
    pendingCampaign=campaign;
    campaign.level=[[levels[selectedLevel] substringFromIndex:5] intValue];
    campaign.half=[levels[selectedLevel] hasSuffix:@"A"]?1:2;campaign.complete=0;campaign.arena=1;
    campaignAction=ASTRO_CAMPAIGN_NONE;changingStage=YES;playerCombat.hit_points=200;
    astro_transition_begin(&transition,campaign.half==1?ASTRO_TRANSITION_MID:ASTRO_TRANSITION_END,simulationTick,0);
}
- (void)stepStageTransition {
    astro_transition_step(&transition,simulationTick+1,playerBounds,playerVisual.width,playerVisual.height,
        (AstroRect){(int)camera,0,(int)(camera+640),380},-camera,0);
    if(transition.events&ASTRO_TRANSITION_BLOW) {
        for(int pass=0;pass<2;pass++) {
            for(AstroEnemy *enemy in enemies)enemy->state.remove=-1;
            [self cleanupWorld];
        }
    }
    if(transition.zero_velocity){playerVelocity=(AstroVelocity){0,0};playerState.velocity=playerVelocity;}
    if(transition.events&ASTRO_TRANSITION_ENGINE_GLOW)engineGlow=YES;
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
        changingStage=NO;[self loadCampaignStage:next];
        astro_flow_stage_end(&flow,oldStage,oldHalf,next.level,next.half,next.complete);
    } else if(transition.phase==ASTRO_TRANSITION_CARD) {
        astro_flow_stage_end(&flow,campaign.level,campaign.half,pendingCampaign.level,pendingCampaign.half,pendingCampaign.complete);
    }
}
- (void)stepEnemies {
    if(campaignAction!=ASTRO_CAMPAIGN_NONE&&!changingStage&&!suspendedSpecialTail) {
        if(selftestPath||(campaignAction==ASTRO_CAMPAIGN_LOAD&&campaign.level==9)) {
            AstroCampaign next=campaign;[self loadCampaignStage:next];
        } else [self beginStageTransition];
    }
    if(changingStage)[self stepStageTransition];
    simulationTick++;
    if(!changingStage||transition.simulate_world)[self cleanupWorld];
    astro_stars_move(stars,-camera,0,camera,0,camera+640,380,tickedScroll,0,0,0,1,&randomSeed,
        parallaxData.mutableBytes,backgrounds.count,0);
    [specialPolygons removeAllObjects];[specialFlashes removeAllObjects];
    NSIndexSet *expired=[liveBeams indexesOfObjectsPassingTest:
        ^BOOL(NSData *data,NSUInteger index,BOOL *stop) {
            const LiveBeam *live=data.bytes;return live->expires<simulationTick;
        }];
    [liveBeams removeObjectsAtIndexes:expired];
    NSArray *actors=(!changingStage||transition.simulate_world)?[world copy]:@[];
    BOOL nestedPass=suspendedSpecialTail!=nil;
    for(NSUInteger i=0;i<actors.count;i++) {
        [self stepActor:actors[i]];
        if(!nestedPass&&special.active&&actors[i]==[NSNull null]) {
            suspendedSpecialTail=[actors subarrayWithRange:NSMakeRange(i+1,actors.count-i-1)];break;
        }
    }
    if(nestedPass)specialResumePending=([self stepSpecial:NO]&ASTRO_SPECIAL_RESUME)!=0;
    if(respawnTick&&simulationTick>=respawnTick) {
        playerCombat=(AstroCombatState){.kind=-1,.hit_points=100};
        playerX=30;playerY=190;playerVelocity=(AstroVelocity){0,0};
        playerVisual=(AstroVisual){1,playerX+camera,playerY,71,20,simulationTick};
        playerEntityX=playerVisual.x;playerEntityY=playerVisual.y;
        playerState=(AstroPlayer){{0,0},12,3,1,simulationTick,simulationTick};
        inventory.weapon=10;inventory.upgrade=0;playerWeapon=10;
        playerRenderBirth=++renderClock;[world insertObject:[NSNull null] atIndex:0];
        invulnerableUntil=simulationTick+181;respawnTick=0;
    }
    if(invulnerableUntil&&simulationTick>=invulnerableUntil) {
        invulnerableUntil=0;if(!special.active)playerCombat.kind=1;
    }
}
- (void)renderTick {
    simulationRender=YES;[self display];simulationRender=NO;
    if(!menuVisible&&flow.phase==ASTRO_FLOW_PLAY&&(!changingStage||transition.simulate_world)) {
        [self updateVisualEffects];
        if(specialResumePending) {
            NSArray *tail=suspendedSpecialTail;suspendedSpecialTail=nil;specialResumePending=NO;
            for(id object in tail)if([world containsObject:object])[self stepActor:object];
            [self updateVisualEffects];
        }
        if(!suspendedSpecialTail&&simulationTick-lastSpawnTick>20){lastSpawnTick=simulationTick;[self makeNewSprites];}
    }
}
- (void)advanceFlowWithKey:(BOOL)anyKey {
    AstroFlowPhase previous=flow.phase;astro_flow_step(&flow,anyKey);
    if(previous==ASTRO_FLOW_END_CARD&&flow.phase!=previous&&changingStage) {
        AstroCampaign next=pendingCampaign;astro_transition_accept_card(&transition);changingStage=NO;
        if(!next.complete)[self loadCampaignStage:next];
        else {campaign.complete=1;[enemies removeAllObjects];[world removeAllObjects];}
    }
    if(previous!=flow.phase&&flow.phase==ASTRO_FLOW_PLAY)[audio playMusic:2];
    if(flow.phase==ASTRO_FLOW_FINISHED)[self beginGameOver];
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
        if(flow.phase!=ASTRO_FLOW_PLAY)[self advanceFlowWithKey:YES];
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
            double previous=camera;
            if(changingStage&&transition.simulate_world)camera+=transition.scroll_x;
            else if(!changingStage&&automatic&&!campaign.arena&&campaignAction==ASTRO_CAMPAIGN_NONE)camera+=1;
            tickedScroll=camera-previous;[self stepEnemies];
        }
        [self renderTick];
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
- (void)tick:(NSTimer *)sender {
    if(campaignTestPath){[self driveCampaignTest];return;}
    double now=[NSDate timeIntervalSinceReferenceDate];
    double dt=fmin(now-previousTime,.05); previousTime=now;
    tickRemainder+=dt;
    if(!menuVisible&&flow.phase!=ASTRO_FLOW_PLAY) {
        BOOL anyKey=NO;for(int i=0;i<128;i++)anyKey|=keys[i];[self advanceFlowWithKey:anyKey];
    }
    if(editingKey>=0&&[NSDate timeIntervalSinceReferenceDate]>=keyCaptureDeadline){editingKey=-1;[self refreshKeyLabels];}
    if(menuVisible) [ui animateTicks:1];
    if(paused||gameOver||menuVisible||flow.phase!=ASTRO_FLOW_PLAY) tickRemainder=0;
    while(tickRemainder>=1.0/60.0&&flow.phase==ASTRO_FLOW_PLAY&&!menuVisible&&!paused) {
        tickRemainder-=1.0/60.0;
        double previousCamera=camera;
        if(changingStage&&transition.simulate_world)camera+=transition.scroll_x;
        else if(selftestPath&&keys[7])camera+=2;
        else if(automatic&&!campaign.arena&&campaignAction==ASTRO_CAMPAIGN_NONE)camera+=1;
        if(selftestPath&&keys[6])camera=fmax(0,camera-2);
        tickedScroll=camera-previousCamera;
        [self stepEnemies];[self renderTick];
    }
    if(!selftestPath) self.window.title=[NSString stringWithFormat:@"AstroSquid — %@ — HP %d · Lives %d · Score %d%@",
        levels[selectedLevel],playerCombat.hit_points,inventory.lives,score,
        gameOver?@" · GAME OVER (R)":campaign.complete?@" · COMPLETE":paused?@" · PAUSED":@""];
    if(menuVisible||flow.phase!=ASTRO_FLOW_PLAY)[self setNeedsDisplay:YES];
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
    assert(menuVisible&&[ui.anchor isEqual:@"Main Menu"]);
    [self mouseDown:[self testMouse:NSLeftMouseDown x:369 y:175]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:369 y:175]];
    assert([ui.anchor isEqual:@"Play Menu"]);[ui animateTicks:120];
    [self mouseDown:[self testMouse:NSLeftMouseDown x:394 y:268]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:394 y:268]];
    assert(!menuVisible&&selectedLevel==0&&flow.phase==ASTRO_FLOW_READY);
    for(int i=0;i<60;i++)astro_flow_step(&flow,1);
    assert(flow.phase==ASTRO_FLOW_PLAY);
    NSString *savedTestPath=selftestPath;selftestPath=nil;
    [self keyDown:[self testEvent:NSKeyDown code:53]];selftestPath=savedTestPath;
    assert(menuVisible&&paused);[ui animateTicks:120];
    [self mouseDown:[self testMouse:NSLeftMouseDown x:365 y:250]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:365 y:250]];
    assert(!menuVisible&&!paused);memset(keys,0,sizeof(keys));
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
    playerCombat.hit_points=1000000;
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
    [[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil]
        writeToFile:[selftestPath stringByAppendingPathComponent:@"result.json"] atomically:YES];
    puts(passed?"PASS: native menus, cards, settings, score entry, renderer, combat and audio":"FAIL: native preview self-test");
    fflush(stdout);
    exit(passed?0:1);
}
- (void)testStageTransitionHandlers {
    for(int half=1;half<=2;half++) {
        selectedLevel=[levels indexOfObject:half==1?@"Data 1A":@"Data 1B"];camera=0;[self resetEnemies];
        [enemies removeAllObjects];[world removeAllObjects];[world addObject:[NSNull null]];[mapPlacements removeAllObjects];
        flow=(AstroFlow){0};menuVisible=NO;paused=NO;memset(keys,0,sizeof(keys));
        campaign=(AstroCampaign){half==1?1:2,half==1?2:1,0,0};[self beginStageTransition];
        int steps=0;
        while(flow.phase==ASTRO_FLOW_PLAY&&steps++<1200) {
            double old=camera;if(transition.simulate_world)camera+=transition.scroll_x;tickedScroll=camera-old;
            [self stepEnemies];
        }
        assert(steps<1200);
        if(half==1)assert(flow.phase==ASTRO_FLOW_READY&&[levels[selectedLevel] isEqual:@"Data 1B"]);
        else {
            assert(flow.phase==ASTRO_FLOW_END_CARD&&engineGlow&&departureTrail);
            [self advanceFlowWithKey:YES];
            assert(flow.phase==ASTRO_FLOW_READY&&[levels[selectedLevel] isEqual:@"Data 2A"]);
        }
        assert(inventory.weapon==10&&inventory.upgrade==0);
    }
}
- (void)testScoreAndSettingsHandlers {
    double volume=ui.soundVolume;
    for(int i=0;i<11;i++)[self performMenuAction:@"SetSVolume"];
    assert(fabs(ui.soundVolume-volume)<.001);
    BOOL smooth=ui.smooth;[self performMenuAction:@"SetSmooth"];assert(ui.smooth!=smooth);
    [self performMenuAction:@"SetSmooth"];assert(ui.smooth==smooth);
    int fire=controlKeys[0];[self performMenuAction:@"SetKeyFire"];
    [self keyDown:[self testEvent:NSKeyDown code:7]];assert(controlKeys[0]==7&&editingKey==-1);controlKeys[0]=fire;
    AstroScore saved[10];memcpy(saved,highscores,sizeof(saved));astro_scores_clear(highscores);
    int oldScore=score;score=12345;[self beginGameOver];assert(ui.editingHighscore>0);
    NSEvent *text=[NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:0
        timestamp:0 windowNumber:self.window.windowNumber context:nil characters:@"TEST"
        charactersIgnoringModifiers:@"TEST" isARepeat:NO keyCode:17];
    [self keyDown:text];assert(!strcmp(scoreEditor.name,"TEST"));
    [self keyDown:[self testEvent:NSKeyDown code:36]];
    assert([ui.anchor isEqual:@"Highscores Menu"]&&!strcmp(highscores[0].name,"TEST")&&highscores[0].score==12345);
    [self keyDown:[self testEvent:NSKeyDown code:17]];assert(highscores[1].score==0);
    memcpy(highscores,saved,sizeof(saved));score=oldScore;[self refreshScores];
}
- (void)keyDown:(NSEvent *)event {
    unsigned key=event.keyCode;
    if(splashVisible){splashVisible=NO;memset(keys,0,sizeof(keys));return;}
    if(key<128) keys[key]=YES;
    if(menuVisible&&[ui.anchor isEqual:@"GameOver"]&&ui.editingHighscore>0) {
        unsigned ch=key==51?8:key==117?127:key==123?28:key==124?29:
            key==126||key==115?30:key==125||key==119?31:key==36?13:key==76?3:0;
        if(ch)astro_score_editor_key(&scoreEditor,ch);
        else {
            NSData *bytes=[event.characters dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:NO];
            const unsigned char *text=bytes.bytes;
            for(NSUInteger i=0;i<bytes.length;i++)astro_score_editor_key(&scoreEditor,text[i]);
        }
        [self refreshScoreEditor];if(scoreEditor.submitted)[self finishGameOver];return;
    }
    if(menuVisible&&gameOver){[self finishGameOver];return;}
    if(event.isARepeat) return;
    if(editingKey>=0&&key<128) {
        controlKeys[editingKey]=key;editingKey=-1;[self refreshKeyLabels];[self saveSettings];return;
    }
    if(!selftestPath) {
        if(key==53) {
            if(menuVisible&&paused) {menuVisible=NO;paused=NO;[audio setPaused:NO];}
            else if(!menuVisible&&flow.phase==ASTRO_FLOW_PLAY) {menuVisible=YES;paused=YES;[audio setPaused:YES];[ui show:@"Pause"];}
        }
        return;
    }
    if(key==45||key==35) {
        selectedLevel=(selectedLevel+levels.count+(key==45?1:-1))%levels.count;
        camera=0;
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
    if(key==15) {[audio setPaused:NO];[audio playMusic:2];camera=0;selectedLevel=0;[self resetEnemies];playerX=30;playerY=190;paused=NO;}
    if(key==46) audio.musicVolume=audio.musicVolume>0?0:.5;
    if(key==53) [NSApp terminate:nil];
}
- (void)keyUp:(NSEvent *)event { if(event.keyCode<128) keys[event.keyCode]=NO; }
- (void)flagsChanged:(NSEvent *)event {
    unsigned code=event.keyCode;
    NSEventModifierFlags flag=code==58||code==61?NSEventModifierFlagOption:
        code==56||code==60?NSEventModifierFlagShift:code==59||code==62?NSEventModifierFlagControl:
        code==55||code==54?NSEventModifierFlagCommand:0;
    if(splashVisible&&flag&&(event.modifierFlags&flag)){splashVisible=NO;return;}
    if(flag&&code<128) {
        keys[code]=(event.modifierFlags&flag)!=0;
        if(editingKey>=0&&keys[code]) [self keyDown:event];
    }
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
- (void)beginGameOver {
    gameOver=YES;menuVisible=YES;[ui show:@"GameOver"];
    ui.editingHighscore=astro_scores_qualifies(highscores,score)?1:0;
    astro_score_editor_begin(&scoreEditor);[self refreshScoreEditor];
}
- (void)finishGameOver {
    BOOL entered=ui.editingHighscore>0;
    if(entered){ui.editingHighscore=astro_scores_insert(highscores,score,scoreEditor.name);[self saveScores];}
    paused=NO;gameOver=NO;[ui show:entered?@"Highscores Menu":@"Play Menu"];
    [audio setPaused:NO];[audio playMusic:1];
}
- (void)unlockStage {
    ui.unlockedLevel=MAX(ui.unlockedLevel,MIN(16,(campaign.level-1)*2+campaign.half));
    if(!selftestPath&&!campaignTestPath)[[NSUserDefaults standardUserDefaults] setInteger:ui.unlockedLevel forKey:@"AstroSquidUnlockedLevel"];
}
- (void)refreshKeyLabels {
    NSMutableArray *labels=[NSMutableArray array];
    for(int i=0;i<6;i++)[labels addObject:[ui nameForKeyCode:controlKeys[i]]];
    ui.keyLabels=labels;
}
- (void)saveSettings {
    if(selftestPath||campaignTestPath)return;
    NSMutableArray *codes=[NSMutableArray array];for(int i=0;i<6;i++)[codes addObject:@(controlKeys[i])];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"smooth":@(ui.smooth),@"sound":@(ui.soundVolume),
        @"music":@(ui.musicVolume),@"keys":codes} forKey:@"AstroSquidSettings"];
}
- (NSPoint)menuPoint:(NSEvent *)event {
    NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];
    return NSMakePoint(p.x*640/self.bounds.size.width,(self.bounds.size.height-p.y)*480/self.bounds.size.height);
}
- (void)mouseDown:(NSEvent *)event {
    if(!menuVisible||splashVisible||editingKey>=0)return;NSPoint p=[self menuPoint:event];
    if([ui.anchor isEqual:@"GameOver"]&&ui.editingHighscore>0&&p.x>=223&&p.x<423&&p.y>=254&&p.y<277) {
        scoreEditor.cursor=[ui scoreCursorAtX:p.x];[self refreshScoreEditor];return;
    }
    [ui mouseDownX:p.x y:p.y];
}
- (void)mouseMoved:(NSEvent *)event {[self mouseDragged:event];}
- (BOOL)resignFirstResponder {memset(keys,0,sizeof(keys));return [super resignFirstResponder];}
- (void)mouseDragged:(NSEvent *)event {
    if(!menuVisible)return;NSPoint p=[self menuPoint:event];[ui moveMouseX:p.x y:p.y];
}
- (void)mouseUp:(NSEvent *)event {
    if(!menuVisible||editingKey>=0)return;
    if(splashVisible){splashVisible=NO;return;}
    NSPoint p=[self menuPoint:event];
    NSString *name=[ui mouseUpX:p.x y:p.y];
    [self performMenuAction:name];
}
- (void)performMenuAction:(NSString *)name {
    AstroUICommand command=astro_ui_command(name.UTF8String);
    if(command.action!=ASTRO_UI_NONE)[audio playCue:@"Click"];
    if(command.action==ASTRO_UI_CLEAR_SCORES){astro_scores_clear(highscores);ui.editingHighscore=0;[self saveScores];}
    if(command.action==ASTRO_UI_KEY) {editingKey=command.key;keyCaptureDeadline=[NSDate timeIntervalSinceReferenceDate]+10;NSMutableArray *labels=[ui.keyLabels mutableCopy];labels[editingKey]=@"Press a key";ui.keyLabels=labels;}
    if(command.action==ASTRO_UI_SMOOTH) {
        ui.smooth=!ui.smooth;[[self openGLContext] makeCurrentContext];
        for(NSNumber *texture in textures.allValues){glBindTexture(GL_TEXTURE_2D,texture.unsignedIntValue);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,ui.smooth?GL_LINEAR:GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,ui.smooth?GL_LINEAR:GL_NEAREST);}
        [self saveSettings];
    }
    if(command.action==ASTRO_UI_SOUND_VOLUME) {ui.soundVolume=((int)lround(ui.soundVolume*10)+1)%11/10.0;audio.soundVolume=ui.soundVolume;[self saveSettings];}
    if(command.action==ASTRO_UI_MUSIC_VOLUME) {ui.musicVolume=((int)lround(ui.musicVolume*10)+1)%11/10.0;audio.musicVolume=ui.musicVolume;[self saveSettings];}
    if(command.action==ASTRO_UI_NEW_GAME||command.action==ASTRO_UI_CONTINUE) {
        NSString *stage=[NSString stringWithFormat:@"Data %d%c",command.stage,command.section==1?'A':'B'];
        NSUInteger index=[levels indexOfObject:stage];if(index==NSNotFound)return;
        ui.editingHighscore=0;selectedLevel=index;camera=0;[self resetEnemies];playerX=30;playerY=190;
        memset(keys,0,sizeof(keys));automatic=YES;paused=NO;menuVisible=NO;
        astro_flow_ready(&flow,campaign.level,campaign.half);[self unlockStage];
        [audio setPaused:NO];[audio playMusic:1];
    } else if(command.action==ASTRO_UI_QUIT) [NSApp terminate:nil];
    else if(command.action==ASTRO_UI_RESUME) {menuVisible=NO;paused=NO;[audio setPaused:NO];}
    else if(command.action==ASTRO_UI_GAME_OVER_OK)[self finishGameOver];
    else if(command.action==ASTRO_UI_QUIT_GAME) {
        paused=NO;gameOver=NO;[ui show:@"Play Menu"];[audio setPaused:NO];[audio playMusic:1];
    }
}
- (void)viewDidMoveToWindow { [self.window makeFirstResponder:self]; }
@end

@interface AstroDelegate : NSObject<NSApplicationDelegate,NSWindowDelegate>
@property(strong) NSWindow *window;
@end
@implementation AstroDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"assets"];
    NSArray *arguments=[[NSProcessInfo processInfo] arguments];
    NSString *testPath=nil,*campaignPath=nil;
    for(NSUInteger i=1;i<arguments.count;i++) {
        if([arguments[i] isEqualToString:@"--self-test"] && i+1<arguments.count) testPath=arguments[++i];
        else if([arguments[i] isEqualToString:@"--campaign-test"] && i+1<arguments.count) campaignPath=arguments[++i];
        else if([arguments[i] isEqualToString:@"--assets"] && i+1<arguments.count) path=arguments[++i];
    }
    NSRect frame=NSMakeRect(0,0,campaignPath?640:960,campaignPath?480:720);
    self.window=[[NSWindow alloc] initWithContentRect:frame
        styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title=@"AstroSquid reconstruction preview — Data 1A";
    self.window.delegate=self;self.window.acceptsMouseMovedEvents=YES;
    AstroView *view=[[AstroView alloc] initWithFrame:frame assets:path];
    if(!view) { NSLog(@"Missing or invalid extracted game assets at %@",path); [NSApp terminate:nil]; return; }
    self.window.contentView=view;
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    if(testPath) [view beginSelfTest:testPath];
    if(campaignPath) [view beginCampaignTest:campaignPath];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
@end

int main(int argc,const char **argv) {
    @autoreleasepool {
        NSApplication *app=[NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        AstroDelegate *delegate=[AstroDelegate new]; app.delegate=delegate;
        NSMenu *menu=[NSMenu new]; NSMenuItem *root=[NSMenuItem new]; [menu addItem:root];
        NSMenu *application=[NSMenu new];
        [application addItemWithTitle:@"Quit AstroSquid Preview" action:@selector(terminate:) keyEquivalent:@"q"];
        root.submenu=application; app.mainMenu=menu;
        [app run];
    }
    return 0;
}
