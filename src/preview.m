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
}
@end
@implementation AstroEnemy
@end

@interface AstroView : NSOpenGLView {
    NSDictionary *game;
    NSMutableDictionary *textures;
    NSArray *levels;
    NSMutableArray *enemies,*pendingEnemies;
    AstroCombatState playerCombat;
    uint32_t randomSeed,lastPlayerShot;
    int score;
    NSUInteger emittedShots,damageHits,emittedBeams;
    int playerWeapon;
    AstroInventory inventory;
    AstroCampaign campaign;
    int campaignAction;
    uint32_t respawnTick,invulnerableUntil;
    BOOL paused,gameOver;
    NSMutableArray *liveBeams;
    uint32_t simulationTick,lastSpawnTick;
    NSUInteger scriptSteps;
    NSString *assetPath;
    NSTimer *timer;
    AstroAudio *audio;
    AstroUIRenderer *ui;
    AstroHUDRenderer *hud;
    BOOL menuVisible;
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
    NSMutableArray *specialPolygons,*specialFlashes;
    BOOL keys[128];
    NSInteger selectedLevel;
    double camera;
    double playerX, playerY;
    double previousTime;
    double tickRemainder;
    AstroVelocity playerVelocity;
    AstroPlayer playerState;
    BOOL automatic;
    NSString *selftestPath;
    NSInteger selftestTicks;
    double selftestStartX;
    BOOL selftestStageSwitched,selftestMoved;
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
    ui.registered=YES;editingKey=-1;
    int defaults[6]={49,58,126,125,123,124};memcpy(controlKeys,defaults,sizeof(defaults));
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
    hud=[[AstroHUDRenderer alloc] initWithGame:game ui:ui];
    menuVisible=YES;
    [audio playMusic:1];
    return self;
}
- (BOOL)acceptsFirstResponder { return YES; }
- (void)prepareOpenGL {
    [super prepareOpenGL];
    GLint interval = 1;
    [[self openGLContext] setValues:&interval forParameter:NSOpenGLCPSwapInterval];
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
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
    NSBitmapImageRep *rgba = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0
        bytesPerRow:width*4 bitsPerPixel:32];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:rgba];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    [source drawInRect:NSMakeRect(0,0,width,height)];
    [NSGraphicsContext restoreGraphicsState];
    GLuint texture = 0;
    glGenTextures(1,&texture);
    glBindTexture(GL_TEXTURE_2D,texture);
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,(GLsizei)width,(GLsizei)height,0,
                 GL_RGBA,GL_UNSIGNED_BYTE,rgba.bitmapData);
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
    glEnable(GL_TEXTURE_2D);glBindTexture(GL_TEXTURE_2D,texture);glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    glColor4d(scene->alpha,scene->alpha,scene->alpha,scene->alpha);glBegin(GL_QUADS);
    for(int i=0;i<4;i++) {glTexCoord2d(uv[i*2],uv[i*2+1]);glVertex2d(scene->xy[i*2],scene->xy[i*2+1]);}glEnd();
}
- (void)drawRect:(NSRect)dirty {
    [[self openGLContext] makeCurrentContext];
    NSRect bounds = [self convertRectToBacking:self.bounds];
    glViewport(0,(GLint)(bounds.size.height*30/480),(GLsizei)bounds.size.width,(GLsizei)(bounds.size.height*380/480));
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION); glLoadIdentity(); glOrtho(0,640,379,0,-1,1);
    glMatrixMode(GL_MODELVIEW); glLoadIdentity();
    if(menuVisible) {
        glViewport(0,0,(GLsizei)bounds.size.width,(GLsizei)bounds.size.height);
        glMatrixMode(GL_PROJECTION);glLoadIdentity();glOrtho(0,640,480,0,-1,1);
        glMatrixMode(GL_MODELVIEW);glLoadIdentity();
        AstroSceneSink menuSink={(__bridge void *)self,sceneLine,sceneSprite,scenePoint,sceneTrail};
        astro_stars_draw(stars,1,campaign.level,0,&menuSink);
        [ui drawSprites:^(NSInteger n,double x,double y,double w,double h){
            [self sprite:n x:x y:y width:w height:h];
        } texture:^GLuint(NSInteger n){return [self texture:n];}];
        [[self openGLContext] flushBuffer];return;
    }
    AstroSceneSink sink={(__bridge void *)self,sceneLine,sceneSprite,scenePoint,sceneTrail};
    astro_stars_draw(stars,0,campaign.level,tickedScroll,&sink);
    glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    const AstroParallax *parallax=parallaxData.bytes;
    for(NSUInteger i=0;i<backgrounds.count;i++) {
        NSDictionary *background=backgrounds[i];
        [self sprite:[background[@"sprite"] integerValue] x:parallax[i].x-camera y:parallax[i].y
            width:number(background,@"width") height:number(background,@"height")];
    }
    for(int layer=4;layer<=6;layer++) for (AstroEnemy *enemy in enemies) {
        int renderLayer=enemy->kind==5?5:(enemy->kind>=20&&enemy->kind<30)?4:6;
        if(renderLayer!=layer||enemy->state.remove||!enemy->active) continue;
        double x=enemy->visual.x-camera,y=enemy->visual.y;
        if(x+enemy->visual.width<0||x>640||y+enemy->visual.height<0||y>380) continue;
        [self sprite:enemy->visual.sprite x:x y:y width:enemy->visual.width height:enemy->visual.height];
    }
    if(!playerCombat.remove&&(!invulnerableUntil||(simulationTick/6)%2))
        [self sprite:playerVisual.sprite x:playerX y:playerY width:playerVisual.width height:playerVisual.height];
    for(NSData *data in [liveBeams copy]) {
        const LiveBeam *live=data.bytes;
        astro_beam_render(&live->beam,-camera,0,camera,0,camera+640,380,&randomSeed,&sink);
    }
    [liveBeams removeAllObjects];
    for(NSMutableData *data in visualEffects) {
        const AstroVisual *v=data.bytes;
        [self sprite:v->sprite x:v->x-camera y:v->y width:v->width height:v->height];
    }
    glDisable(GL_TEXTURE_2D);glShadeModel(GL_SMOOTH);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    for(NSData *data in specialPolygons) {
        const AstroSpecialVertex *v=data.bytes;size_t n=data.length/sizeof(*v);glBegin(GL_POLYGON);
        for(size_t i=0;i<n;i++) {glColor4d(v[i].r,v[i].g,v[i].b,v[i].a);glVertex2d(v[i].x-camera,v[i].y);}glEnd();
    }
    glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    for(NSData *data in specialFlashes) {
        const AstroVisual *v=data.bytes;[self sprite:v->sprite x:v->x-camera y:v->y width:v->width height:v->height];
    }
    AstroHUDState overlay={!playerCombat.remove,playerCombat.hit_points,inventory.weapon,
        inventory.upgrade,inventory.specials,inventory.lives,score};
    [hud drawState:&overlay texture:^GLuint(NSInteger n){return [self texture:n];}
        framebufferWidth:(GLsizei)bounds.size.width height:(GLsizei)bounds.size.height];
    [[self openGLContext] flushBuffer];
}
- (AstroEnemy *)entityForPlacement:(NSDictionary *)placement {
    NSString *attribute=[placement[@"attribute"] stringValue];
    AstroEnemy *enemy=[AstroEnemy new];
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
    enemies=[NSMutableArray array]; pendingEnemies=[NSMutableArray array];
    simulationTick=0;lastSpawnTick=0;lastPlayerShot=0;score=0;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=100};
    visualEffects=[NSMutableArray array];specialPolygons=[NSMutableArray array];specialFlashes=[NSMutableArray array];
    special=(AstroSpecial){0};
    playerVisual=(AstroVisual){1,30,190,71,20,0};
    playerBounds=(AstroRect){30,190,101,210};previousPlayerBounds=playerBounds;
    playerState=(AstroPlayer){{0,0},12,3,1,0,0};playerVelocity=(AstroVelocity){0,0};
    inventory=(AstroInventory){10,0,1,1};
    NSString *stage=levels[selectedLevel];
    campaign=(AstroCampaign){[[stage substringFromIndex:5] intValue],[stage hasSuffix:@"A"]?1:2,0,0};
    campaignAction=ASTRO_CAMPAIGN_NONE;respawnTick=invulnerableUntil=0;gameOver=NO;
    playerWeapon=10;liveBeams=[NSMutableArray array];
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
        [enemies addObject:[self entityForPlacement:placement]];
    }
}
- (void)fireWeapon:(int)identifier x:(int)x y:(int)y heading:(int)heading source:(int)kind {
    if(identifier>=40&&identifier<=53) {
        [audio playStringCue:identifier>=50?295:296 position:(x-camera)/640];
        NSArray *objects=[enemies copy];
        size_t count=objects.count+1;
        AstroTarget *targets=calloc(count,sizeof(*targets));
        if(!targets) {NSLog(@"Cannot allocate beam targets");exit(1);}
        for(NSUInteger i=0;i<objects.count;i++) {
            AstroEnemy *enemy=objects[i];
            targets[i]=(AstroTarget){enemy->active?enemy->kind:2,-1,enemy->state.remove,
                enemy->state.x,enemy->state.y,enemy->visual.width,enemy->visual.height};
        }
        targets[count-1]=(AstroTarget){playerCombat.kind,-1,playerCombat.remove,playerX+camera,playerY,playerVisual.width,playerVisual.height};
        AstroBeam beams[2];BeamContext context={self,objects,targets};
        int emitted=astro_beam_shots(identifier,x,y,heading,1,kind,-1,targets,count,
            camera,0,camera+640,380,&randomSeed,beams,beamHit,&context);
        free(targets);
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
    [pendingEnemies addObject:bullet];emittedShots++;
 }
- (NSMutableData *)targetsForObjects:(NSArray *)objects {
    NSMutableData *data=[NSMutableData dataWithLength:(objects.count+1)*sizeof(AstroTarget)];
    AstroTarget *targets=data.mutableBytes;
    for(NSUInteger i=0;i<objects.count;i++) {
        AstroEnemy *enemy=objects[i];
        targets[i]=(AstroTarget){enemy->active?enemy->kind:2,-1,enemy->state.remove,
            enemy->state.x,enemy->state.y,enemy->visual.width,enemy->visual.height};
    }
    targets[objects.count]=(AstroTarget){playerCombat.kind,-1,playerCombat.remove,
        playerX+camera,playerY,playerVisual.width,playerVisual.height};return data;
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
    [pendingEnemies addObject:enemy];
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
- (void)stepSpecial:(BOOL)start {
    NSArray *objects=[enemies copy];NSMutableData *data=[self targetsForObjects:objects];
    BeamContext world={self,objects,data.mutableBytes};
    AstroSpecialContext context={.context=&world,.seed=&randomSeed,.targets=data.mutableBytes,
        .target_count=objects.count+1,.source_parent=-1,.gun_x=playerBounds.left+74,.gun_y=playerBounds.top+12,
        .frame_interval=1,.left=camera,.top=0,.right=camera+640,.bottom=380,
        .spawn=specialSpawn,.bullet=specialBullet,.beam=specialBeam,.sprite=specialSprite,
        .polygon=specialPolygon,.sound=specialSound};
    if(start) {
        if(playerWeapon>=40) {playerCombat.kind=-1;((AstroTarget *)data.mutableBytes)[objects.count].kind=-1;}
        if(!astro_special_start(&special,playerWeapon,context.gun_x,context.gun_y,0,simulationTick,&context)) {
            NSLog(@"Cannot start special attack");exit(1);
        }
        inventory.specials--;emittedSpecials++;
    }
    if(special.active) astro_special_step(&special,simulationTick,&context);
    if(!special.active&&!invulnerableUntil) playerCombat.kind=1;
}

- (void)hitPlayerWithEnemy:(AstroEnemy *)enemy {
    AstroCombatState attacker=[self combatFor:enemy];
    astro_bullet_hits_player(&attacker,&playerCombat);
    [self applyCombat:attacker to:enemy];
}
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context {
    if(beam->target<0) return;
    AstroCombatState b={.kind=999,.layer=1,.hit_points=beam->damage};
    if((NSUInteger)beam->target==context->objects.count) {
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
    [pendingEnemies addObject:enemy];
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
- (void)checkCombat {
    NSRect player=NSMakeRect(playerX+camera,playerY,playerVisual.width,playerVisual.height);
    for(AstroEnemy *pickup in enemies) {
        if(!pickup->active||pickup->state.remove||pickup->kind!=40||playerCombat.remove||invulnerableUntil) continue;
        NSRect bounds=NSMakeRect((int)pickup->state.x,(int)pickup->state.y,
            pickup->visual.width,pickup->visual.height);
        if(NSIntersectsRect(bounds,player)) {
            [audio playStringCue:[pickup->placement[@"attribute"] intValue]%10==1?302:[pickup->placement[@"attribute"] intValue]%10==9?304:303 position:playerX/640];
            astro_pickup(&playerCombat,[pickup->placement[@"attribute"] intValue]%10,
                pickup->hitPoints,&pickup->state.remove,&inventory);
            playerWeapon=inventory.weapon+inventory.upgrade;
        }
    }
    playerCombat.velocity=playerVelocity;
    for(AstroEnemy *scenery in enemies) {
        if(!scenery->active||scenery->state.remove||scenery->kind<20||scenery->kind>29||playerCombat.remove||invulnerableUntil) continue;
        double x=scenery->state.x,y=scenery->state.y;
        double w=scenery->visual.width,h=scenery->visual.height;
        if(NSIntersectsRect(player,NSMakeRect((int)x,(int)y,w,h))) {
            AstroCombatState s=[self combatFor:scenery];
            AstroRect a={(int)(playerX+camera),(int)playerY,(int)(playerX+camera+71),(int)(playerY+20)};
            AstroRect b={(int)x,(int)y,(int)(x+w),(int)(y+h)};
            astro_player_hits_scenery(&playerCombat,a,&s,b);
            [self applyCombat:s to:scenery];
        }
    }
    playerVelocity=playerCombat.velocity;
    for(AstroEnemy *bullet in enemies) {
        if(!bullet->active||bullet->state.remove||(bullet->kind!=2&&bullet->kind!=5)) continue;
        NSRect bounds=NSMakeRect((int)bullet->state.x,(int)bullet->state.y,
            bullet->visual.width,bullet->visual.height);
        AstroCombatState b=[self combatFor:bullet];
        if(!playerCombat.remove&&!invulnerableUntil&&NSIntersectsRect(bounds,player))
            astro_bullet_hits_player(&b,&playerCombat);
        if(b.kind==2) for(AstroEnemy *enemy in enemies) {
            if(enemy==bullet||!enemy->active||enemy->state.remove||
               !(enemy->kind==5||(enemy->kind>19&&enemy->kind<30))) continue;
            NSRect target=NSMakeRect((int)enemy->state.x,(int)enemy->state.y,
                enemy->visual.width,enemy->visual.height);
            if(NSIntersectsRect(bounds,target)) {
                AstroCombatState e=[self combatFor:enemy];
                int impact=astro_bullet_hits_enemy(&b,&e,[enemy->definition[@"kill_score"] intValue],&score);
                if(impact) [self addDeathEffects:bullet];
                if(e.hit_points!=enemy->hitPoints) damageHits++;
                [self applyCombat:e to:enemy];
            }
        }
        [self applyCombat:b to:bullet];
    }
}
- (void)stepEnemies {
    simulationTick++;
    astro_stars_move(stars,-camera,0,camera,0,camera+640,380,tickedScroll,0,0,0,1,&randomSeed,
        parallaxData.mutableBytes,backgrounds.count,0);
    [specialPolygons removeAllObjects];[specialFlashes removeAllObjects];
    NSIndexSet *expired=[liveBeams indexesOfObjectsPassingTest:
        ^BOOL(NSData *data,NSUInteger index,BOOL *stop) {
            const LiveBeam *live=data.bytes;return live->expires<simulationTick;
        }];
    [liveBeams removeObjectsAtIndexes:expired];
    for(AstroEnemy *enemy in enemies) {
        AstroScriptState *state=&enemy->state;
        if(state->remove) continue;
        // MAKENEWSPRITES consumes map entries 100 pixels beyond the right edge.
        if(!enemy->active) {
            if(simulationTick-lastSpawnTick<=20||state->x>=camera+740) continue;
            enemy->active=YES;
            state->x=(int)state->x;state->y=(int)state->y;
            enemy->visual.x=state->x;enemy->visual.y=state->y;
            state->update_tick=state->animation_tick=state->action_tick=simulationTick;
        }
        if([enemy->placement[@"attribute"] intValue]==399) {
            if(state->x<camera+740) {
                campaignAction=astro_campaign_event(&campaign,[enemy->placement[@"tag"] intValue],1);
                state->remove=1;
            }
            continue;
        }
        enemy->visual.x+=state->velocity.x;enemy->visual.y+=state->velocity.y;
        if([enemy->definition[@"animated"] boolValue]&&enemy->kind!=2&&enemy->kind!=4&&enemy->kind!=20&&enemy->kind!=40)
            astro_visual_change(&enemy->visual,enemy->baseSprite+state->frame-1,spriteInfo,1001,simulationTick);
        state->x=enemy->visual.x;state->y=enemy->visual.y;
        enemy->previousBounds=enemy->bounds;
        enemy->bounds=(AstroRect){(int16_t)(int)state->x,(int16_t)(int)state->y,
            (int16_t)(int)(state->x+enemy->visual.width),(int16_t)(int)(state->y+enemy->visual.height)};
        double width=enemy->visual.width,height=enemy->visual.height;
        if(state->x>camera+(enemy->kind==2?650:740)||state->x+width<camera-10||
           (enemy->kind==2&&(state->y>390||state->y+height< -10))) {
            state->remove=1;continue;
        }
        if(enemy->kind==5&&enemy->program.length&&state->x<camera+640&&state->x+width>camera) {
            double w=enemy->visual.width,h=enemy->visual.height;
            int heading=astro_heading(state->x,state->y,w,h,playerX+camera,playerY,playerVisual.width,playerVisual.height);
            EnemyContext source={self,enemy};
            AstroScriptContext context={.player_present=!playerCombat.remove,.target_heading=(int)heading,
                .player_x=playerX+camera,.player_y=playerY,
                .animated=[enemy->definition[@"animated"] intValue],
                .weapon=[enemy->definition[@"weapon"] intValue],
                .userdata=&source,.fire=enemyFire,.hit_player=enemyHit,
                .gun_x=(int)state->x+[enemy->definition[@"turret_x"] intValue],
                .gun_y=(int)state->y+[enemy->definition[@"turret_y"] intValue]};
            // shortcut: parent/child motion awaits original attachment/spawn recovery.
            if(!astro_script_step(state,enemy->program.bytes,
                enemy->program.length/sizeof(AstroInstruction),simulationTick,&context)) {
                NSLog(@"Script ended outside RETURN"); exit(1);
            }
            scriptSteps++;
        }
        if(enemy->kind==4||enemy->kind==20) {
            AstroDebris debris={enemy->kind,state->state,state->frame,state->remove,state->update_tick,
                state->animation_tick,state->action_tick,state->velocity};
            astro_debris_step(&debris,simulationTick,enemy->bounds.right,camera,astro_debris_gravity(campaign.level));
            state->velocity=debris.velocity;state->update_tick=debris.update_tick;
            state->animation_tick=debris.animation_tick;state->remove=debris.remove;
        }
    }
    if(simulationTick-lastSpawnTick>20) lastSpawnTick=simulationTick;
    [enemies addObjectsFromArray:pendingEnemies];[pendingEnemies removeAllObjects];
    [self checkCombat];
    NSIndexSet *removed=[enemies indexesOfObjectsPassingTest:
        ^BOOL(AstroEnemy *enemy,NSUInteger index,BOOL *stop){return enemy->state.remove!=0;}];
    for(NSUInteger i=removed.firstIndex;i!=NSNotFound;i=[removed indexGreaterThanIndex:i]) {
        AstroEnemy *enemy=enemies[i];
        if(enemy->state.remove==-1) {
            [self addDeathEffects:enemy];
            int action=astro_campaign_event(&campaign,[enemy->placement[@"tag"] intValue],0);
            if(action!=ASTRO_CAMPAIGN_NONE) campaignAction=action;
        }
    }
    [enemies removeObjectsAtIndexes:removed];
    if(campaignAction==ASTRO_CAMPAIGN_LOAD) {
        NSString *stage=[NSString stringWithFormat:@"Data %d%c",campaign.level,campaign.half==1?'A':'B'];
        NSUInteger index=[levels indexOfObject:stage];
        if(index==NSNotFound) {NSLog(@"Missing stage %@",stage);exit(1);}
        AstroInventory saved=inventory;int savedScore=score;
        selectedLevel=index;camera=0;[self resetEnemies];inventory=saved;score=savedScore;
        playerWeapon=inventory.weapon+inventory.upgrade;playerX=30;playerY=190;
    }
    if(playerCombat.remove&&!respawnTick&&!gameOver) {
        AstroEnemy *body=[self entityForPlacement:@{@"attribute":@11,@"x":@(playerX+camera),@"y":@(playerY),
            @"width":@(playerVisual.width),@"height":@(playerVisual.height),@"tag":@0}];
        body->visual=playerVisual;body->bounds=playerBounds;body->state.velocity=playerVelocity;
        [self addDeathEffects:body];
        if(inventory.lives==0) {
            gameOver=YES;
            if(!selftestPath){menuVisible=YES;[ui show:@"GameOver"];}
        }
        else {inventory.lives--;respawnTick=simulationTick+60;}
    }
    if(respawnTick&&simulationTick>=respawnTick) {
        playerCombat=(AstroCombatState){.kind=-1,.hit_points=100};
        playerX=30;playerY=190;playerVelocity=(AstroVelocity){0,0};
        playerVisual=(AstroVisual){1,playerX+camera,playerY,71,20,simulationTick};
        playerState=(AstroPlayer){{0,0},12,3,1,simulationTick,simulationTick};
        inventory.weapon=10;inventory.upgrade=0;playerWeapon=10;
        invulnerableUntil=simulationTick+180;respawnTick=0;
    }
    [self updateVisualEffects];
    if(invulnerableUntil&&simulationTick>=invulnerableUntil) {
        invulnerableUntil=0;playerCombat.kind=1;
    }
}
- (void)tick:(NSTimer *)sender {
    double now=[NSDate timeIntervalSinceReferenceDate];
    double dt=fmin(now-previousTime,.05); previousTime=now;
    tickRemainder+=dt;
    if(menuVisible) [ui animateTicks:1];
    if(paused||gameOver||campaign.complete||menuVisible) tickRemainder=0;
    while(tickRemainder>=1.0/60.0) {
        tickRemainder-=1.0/60.0;
        double previousCamera=camera;
        if(keys[7]) camera+=2;
        else if(automatic&&!campaign.arena) camera+=1;
        if(keys[6]) camera=fmax(0,camera-2);
        tickedScroll=camera-previousCamera;
        [self stepEnemies];
        if(keys[selftestPath?8:controlKeys[0]]&&!playerCombat.remove&&!special.active&&(int32_t)(simulationTick-special.action_until)>=0&&simulationTick-lastPlayerShot>
            60.0/[game[@"weapons"][[NSString stringWithFormat:@"%d",playerWeapon]][@"rate"] doubleValue]) {
            lastPlayerShot=simulationTick;
            [self fireWeapon:playerWeapon x:(playerBounds.left+playerBounds.right)/2+20 y:(playerBounds.top+playerBounds.bottom)/2 heading:0 source:1];
        }
        playerVisual.x=playerX+camera+playerVelocity.x;playerVisual.y=playerY+playerVelocity.y;
        astro_visual_change(&playerVisual,playerState.frame,spriteInfo,1001,simulationTick);
        playerX=playerVisual.x-camera;playerY=playerVisual.y;
        previousPlayerBounds=playerBounds;
        playerBounds=(AstroRect){(int16_t)(int)playerVisual.x,(int16_t)(int)playerVisual.y,
            (int16_t)(int)(playerVisual.x+playerVisual.width),(int16_t)(int)(playerVisual.y+playerVisual.height)};
        unsigned controls=0;
        if(keys[controlKeys[4]]) controls|=ASTRO_KEY_LEFT;
        if(keys[controlKeys[5]]) controls|=ASTRO_KEY_RIGHT;
        if(keys[controlKeys[2]]) controls|=ASTRO_KEY_UP;
        if(keys[controlKeys[3]]) controls|=ASTRO_KEY_DOWN;
        playerState.velocity=playerVelocity;
        AstroRect bounds=playerBounds;
        astro_player_step(&playerState,simulationTick,controls,1,bounds,playerVisual.width,playerVisual.height,
            (AstroRect){(int)camera,0,(int)(camera+640),380},0);
        playerVelocity=playerState.velocity;
        BOOL startSpecial=keys[selftestPath?58:controlKeys[1]]&&!playerCombat.remove&&!special.active&&inventory.specials>0&&
            (int32_t)(simulationTick-special.action_until)>=0;
        if(startSpecial||special.active) [self stepSpecial:startSpecial];
    }
    if(!selftestPath) self.window.title=[NSString stringWithFormat:@"AstroSquid — %@ — HP %d · Lives %d · Score %d%@",
        levels[selectedLevel],playerCombat.hit_points,inventory.lives,score,
        gameOver?@" · GAME OVER (R)":campaign.complete?@" · COMPLETE":paused?@" · PAUSED":@""];
    [self setNeedsDisplay:YES];
    if(selftestPath) {
        if(playerX>selftestStartX+10) selftestMoved=YES;
        selftestTicks++;
        if(selftestTicks==20) [self keyUp:[self testEvent:NSKeyUp code:124]];
        if(selftestTicks==90||selftestTicks==170||selftestTicks==250||selftestTicks==370) {
            playerWeapon=selftestTicks==90?13:selftestTicks==170?33:selftestTicks==250?43:53;
            inventory.specials=1;[self keyDown:[self testEvent:NSKeyDown code:58]];
        }
        if(selftestTicks==91||selftestTicks==171||selftestTicks==251||selftestTicks==371)
            [self keyUp:[self testEvent:NSKeyUp code:58]];
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
    assert(menuVisible&&[ui.anchor isEqual:@"Main Menu"]);
    [self mouseDown:[self testMouse:NSLeftMouseDown x:369 y:175]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:369 y:175]];
    assert([ui.anchor isEqual:@"Play Menu"]);[ui animateTicks:120];
    [self mouseDown:[self testMouse:NSLeftMouseDown x:394 y:268]];
    [self mouseUp:[self testMouse:NSLeftMouseUp x:394 y:268]];
    assert(!menuVisible&&selectedLevel==0);
    [self keyDown:[self testEvent:NSKeyDown code:53]];
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
    for(AstroEnemy *enemy in enemies) if(enemy->program.length) {
        camera=fmax(0,enemy->state.x-400);
        playerY=enemy->state.y+enemy->visual.height/2-12; break;
    }
    audio.musicVolume=0;audio.soundVolume=0;
    [audio playMusic:2];
}
- (void)finishSelfTest {
    [self keyUp:[self testEvent:NSKeyUp code:124]];
    [self display];
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
    NSDictionary *report=@{@"passed":@(passed),@"script_steps":@(scriptSteps),@"emitted_shots":@(emittedShots),@"damage_hits":@(damageHits),@"emitted_beams":@(emittedBeams),@"emitted_effects":@(emittedEffects),@"special_attacks":@(emittedSpecials),
        @"player_hit_points":@(playerCombat.hit_points),@"score":@(score),@"player_moved":@(moved),
        @"stage_switched":@(selftestStageSwitched),@"music_time":@(audio.music.currentTime),
        @"music_playing":@(audio.music.isPlaying),@"colored_pixels":@(colored),
        @"textures_loaded":@(textures.count),@"frame_width":@(width),@"frame_height":@(height)};
    [[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil]
        writeToFile:[selftestPath stringByAppendingPathComponent:@"result.json"] atomically:YES];
    puts(passed?"PASS: native renderer, key handlers, level switch, recovered movement and audio decoder":"FAIL: native preview self-test");
    fflush(stdout);
    exit(passed?0:1);
}
- (void)keyDown:(NSEvent *)event {
    unsigned key=event.keyCode;
    if(key<128) keys[key]=YES;
    if(event.isARepeat) return;
    if(!selftestPath) {
        if(editingKey>=0&&key<128) {
            controlKeys[editingKey]=key;editingKey=-1;[self refreshKeyLabels];[self saveSettings];return;
        }
        if(key==53) {
            if(menuVisible&&paused) {menuVisible=NO;paused=NO;[audio setPaused:NO];}
            else if(!menuVisible) {menuVisible=YES;paused=YES;[audio setPaused:YES];[ui show:@"Pause"];}
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
    if(flag&&code<128) {
        keys[code]=(event.modifierFlags&flag)!=0;
        if(editingKey>=0&&keys[code]) [self keyDown:event];
    }
}
- (void)refreshKeyLabels {
    NSDictionary *names=@{@49:@"Space",@58:@"Option",@61:@"Right Option",@126:@"Up",@125:@"Down",@123:@"Left",@124:@"Right",@56:@"Shift",@59:@"Control",@55:@"Command"};
    NSMutableArray *labels=[NSMutableArray array];
    for(int i=0;i<6;i++)[labels addObject:names[@(controlKeys[i])]?:[NSString stringWithFormat:@"Key %d",controlKeys[i]]];
    ui.keyLabels=labels;
}
- (void)saveSettings {
    if(selftestPath)return;
    NSMutableArray *codes=[NSMutableArray array];for(int i=0;i<6;i++)[codes addObject:@(controlKeys[i])];
    [[NSUserDefaults standardUserDefaults] setObject:@{@"smooth":@(ui.smooth),@"sound":@(ui.soundVolume),
        @"music":@(ui.musicVolume),@"keys":codes} forKey:@"AstroSquidSettings"];
}
- (NSPoint)menuPoint:(NSEvent *)event {
    NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];
    return NSMakePoint(p.x*640/self.bounds.size.width,(self.bounds.size.height-p.y)*480/self.bounds.size.height);
}
- (void)mouseDown:(NSEvent *)event {
    if(!menuVisible)return;NSPoint p=[self menuPoint:event];[ui mouseDownX:p.x y:p.y];
}
- (void)mouseDragged:(NSEvent *)event {
    if(!menuVisible)return;NSPoint p=[self menuPoint:event];[ui moveMouseX:p.x y:p.y];
}
- (void)mouseUp:(NSEvent *)event {
    if(!menuVisible)return;NSPoint p=[self menuPoint:event];
    NSString *name=[ui mouseUpX:p.x y:p.y];
    AstroUICommand command=astro_ui_command(name.UTF8String);
    if(command.action!=ASTRO_UI_NONE)[audio playCue:@"Click"];
    if(command.action==ASTRO_UI_KEY) {editingKey=command.key;NSMutableArray *labels=[ui.keyLabels mutableCopy];labels[editingKey]=@"Press a key";ui.keyLabels=labels;}
    if(command.action==ASTRO_UI_SMOOTH) {ui.smooth=!ui.smooth;[self saveSettings];}
    if(command.action==ASTRO_UI_SOUND_VOLUME) {ui.soundVolume=((int)lround(ui.soundVolume*10)+1)%11/10.0;audio.soundVolume=ui.soundVolume;[self saveSettings];}
    if(command.action==ASTRO_UI_MUSIC_VOLUME) {ui.musicVolume=((int)lround(ui.musicVolume*10)+1)%11/10.0;audio.musicVolume=ui.musicVolume;[self saveSettings];}
    if(command.action==ASTRO_UI_NEW_GAME||command.action==ASTRO_UI_CONTINUE) {
        NSString *stage=[NSString stringWithFormat:@"Data %d%c",command.stage,command.section==1?'A':'B'];
        NSUInteger index=[levels indexOfObject:stage];if(index==NSNotFound)return;
        selectedLevel=index;camera=0;[self resetEnemies];playerX=30;playerY=190;
        memset(keys,0,sizeof(keys));automatic=YES;paused=NO;menuVisible=NO;
        [audio setPaused:NO];[audio playMusic:2];
    } else if(command.action==ASTRO_UI_QUIT) [NSApp terminate:nil];
    else if(command.action==ASTRO_UI_RESUME) {menuVisible=NO;paused=NO;[audio setPaused:NO];}
    else if(command.action==ASTRO_UI_QUIT_GAME||command.action==ASTRO_UI_GAME_OVER_OK) {
        paused=NO;gameOver=NO;[ui show:@"Main Menu"];[audio setPaused:NO];[audio playMusic:1];
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
    NSString *testPath=nil;
    for(NSUInteger i=1;i<arguments.count;i++) {
        if([arguments[i] isEqualToString:@"--self-test"] && i+1<arguments.count) testPath=arguments[++i];
        else if([arguments[i] isEqualToString:@"--assets"] && i+1<arguments.count) path=arguments[++i];
    }
    NSRect frame=NSMakeRect(0,0,960,720);
    self.window=[[NSWindow alloc] initWithContentRect:frame
        styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title=@"AstroSquid reconstruction preview — Data 1A";
    self.window.delegate=self;
    AstroView *view=[[AstroView alloc] initWithFrame:frame assets:path];
    if(!view) { NSLog(@"Missing or invalid extracted game assets at %@",path); [NSApp terminate:nil]; return; }
    self.window.contentView=view;
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    if(testPath) [view beginSelfTest:testPath];
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
