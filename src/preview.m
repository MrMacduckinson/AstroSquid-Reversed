// Native renderer/input smoke test. Gameplay has not yet been reconstructed.
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <AVFoundation/AVFoundation.h>
#include "physics.h"
#include "script.h"
#include "weapons.h"
#include "combat.h"
#include "beams.h"
#include "player.h"

@class AstroView;
typedef struct { __unsafe_unretained AstroView *view; __unsafe_unretained NSArray *objects; AstroTarget *targets; } BeamContext;
typedef struct { AstroBeam beam; uint32_t expires; } LiveBeam;

@interface AstroEnemy : NSObject {
@public
    AstroScriptState state;
    NSDictionary *placement, *definition;
    NSData *program;
    int kind,layer,hitPoints;
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
    NSMutableArray *liveBeams;
    uint32_t simulationTick;
    NSUInteger scriptSteps;
    NSString *assetPath;
    NSTimer *timer;
    AVAudioPlayer *music;
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
}
- (instancetype)initWithFrame:(NSRect)frame assets:(NSString *)path;
- (void)beginSelfTest:(NSString *)path;
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context;
- (void)fireWeapon:(int)weapon x:(int)x y:(int)y heading:(int)heading source:(int)kind;
@end

static double number(NSDictionary *d, NSString *key) { return [d[key] doubleValue]; }

static void enemyFire(void *context,int weapon,int x,int y,int heading) {
    [(__bridge AstroView *)context fireWeapon:weapon x:x y:y heading:heading source:5];
}

static void beamHit(void *context,const AstroBeam *beam) {
    BeamContext *world=context;
    [world->view applyBeam:beam context:world];
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
    textures = [NSMutableDictionary dictionary];
    [self resetEnemies];
    playerX = 60; playerY = 220;
    previousTime = [NSDate timeIntervalSinceReferenceDate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self
                                           selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    NSString *song = [path stringByAppendingPathComponent:@"Music1.mp3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:song]) {
        music = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:song] error:&error];
        music.numberOfLoops = -1;
        music.volume = 0.25;
        [music prepareToPlay];
    }
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
- (void)drawRect:(NSRect)dirty {
    [[self openGLContext] makeCurrentContext];
    NSRect bounds = [self convertRectToBacking:self.bounds];
    glViewport(0,(GLint)(bounds.size.height*30/480),(GLsizei)bounds.size.width,(GLsizei)(bounds.size.height*380/480));
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION); glLoadIdentity(); glOrtho(0,640,380,0,-1,1);
    glMatrixMode(GL_MODELVIEW); glLoadIdentity();
    glDisable(GL_TEXTURE_2D); glColor4d(.4,.5,.6,1); glPointSize(1);
    glBegin(GL_POINTS);
    for (unsigned i=0;i<600;i++) {
        unsigned seed=i*2654435761u;
        double x=fmod((seed%640)-camera*.15+640*100,640);
        glVertex2d(x,(seed/640)%380);
    }
    glEnd();
    NSDictionary *level = game[@"levels"][levels[selectedLevel]];
    for(NSDictionary *background in game[@"scenes"][level[@"background"]]) {
        double x=number(background,@"x")-camera*.2;
        double y=number(background,@"y");
        [self sprite:[background[@"sprite"] integerValue] x:x y:y
               width:number(background,@"width") height:number(background,@"height")];
    }
    for (AstroEnemy *enemy in enemies) {
        if(enemy->state.remove||!enemy->active) continue;
        NSDictionary *entity=enemy->placement;
        double x=enemy->state.x-camera,y=enemy->state.y;
        double w=number(entity,@"width"),h=number(entity,@"height");
        if(x+w<0||x>640||y+h<0||y>380) continue;
        NSInteger sprite=[enemy->definition[@"sprite"] integerValue]+enemy->state.frame-1;
        [self sprite:sprite x:x y:y width:w height:h];
    }
    if(!playerCombat.remove) [self sprite:playerState.frame x:playerX y:playerY width:0 height:0];
    glDisable(GL_TEXTURE_2D);glLineWidth(2);
    for(NSData *data in liveBeams) {
        const LiveBeam *live=data.bytes;const AstroBeam *beam=&live->beam;
        if(beam->weapon<50) glColor4d(1,.2,.1,1); else glColor4d(.4,.7,1,1);
        // shortcut: straight beam visualization until original effect renderer is restored.
        glBegin(GL_LINES);glVertex2d(beam->x-camera,beam->y);
        glVertex2d(beam->end_x-camera,beam->end_y);glEnd();
    }
    [[self openGLContext] flushBuffer];
}
- (AstroEnemy *)entityForPlacement:(NSDictionary *)placement {
    NSString *attribute=[placement[@"attribute"] stringValue];
    AstroEnemy *enemy=[AstroEnemy new];
    enemy->placement=placement; enemy->definition=game[@"attributes"][attribute];
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
    simulationTick=0;randomSeed=1;lastPlayerShot=0;score=0;
    playerCombat=(AstroCombatState){.kind=1,.hit_points=100};
    playerState=(AstroPlayer){{0,0},12,3,1,0,0};playerVelocity=(AstroVelocity){0,0};
    inventory=(AstroInventory){10,0,1,1};
    playerWeapon=10;liveBeams=[NSMutableArray array];
    NSDictionary *level=game[@"levels"][levels[selectedLevel]];
    for(NSDictionary *placement in level[@"entities"]) {
        if([placement[@"attribute"] intValue]==11) continue;
        [enemies addObject:[self entityForPlacement:placement]];
    }
}
- (void)fireWeapon:(int)identifier x:(int)x y:(int)y heading:(int)heading source:(int)kind {
    if(identifier>=40&&identifier<=53) {
        NSArray *objects=[enemies copy];
        size_t count=objects.count+1;
        AstroTarget *targets=calloc(count,sizeof(*targets));
        if(!targets) {NSLog(@"Cannot allocate beam targets");exit(1);}
        for(NSUInteger i=0;i<objects.count;i++) {
            AstroEnemy *enemy=objects[i];
            targets[i]=(AstroTarget){enemy->active?enemy->kind:2,-1,enemy->state.remove,
                enemy->state.x,enemy->state.y,number(enemy->placement,@"width"),number(enemy->placement,@"height")};
        }
        targets[count-1]=(AstroTarget){1,-1,playerCombat.remove,playerX+camera,playerY,71,20};
        AstroBeam beams[2];BeamContext context={self,objects,targets};
        int emitted=astro_beam_shots(identifier,x,y,heading,1,kind,-1,targets,count,
            camera,0,camera+640,380,&randomSeed,beams,beamHit,&context);
        free(targets);
        if(emitted<0) {NSLog(@"Invalid beam request");exit(1);}
        for(int i=0;i<emitted;i++) {
            LiveBeam live={beams[i],simulationTick+1};
            [liveBeams addObject:[NSData dataWithBytes:&live length:sizeof(live)]];
        }
        emittedBeams+=emitted;return;
    }
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
    for(int i=0;i<count;i++) {
        int attribute=20+shots[i].type;
        NSDictionary *attr=game[@"attributes"][[NSString stringWithFormat:@"%d",attribute]];
        NSDictionary *sprite=game[@"sprites"][[attr[@"sprite"] stringValue]];
        if(!attr||!sprite) {NSLog(@"Missing bullet attribute %d",attribute);exit(1);}
        double width=number(sprite,@"width"),height=number(sprite,@"height");
        NSDictionary *placement=@{@"attribute":@(attribute),
            @"x":@((int)(shots[i].x-width/2)),@"y":@((int)(shots[i].y-height/2)),
            @"width":@(width),@"height":@(height)};
        AstroEnemy *bullet=[self entityForPlacement:placement];
        bullet->kind=attribute>30?5:2;bullet->active=YES;
        bullet->layer=kind==5?2:(kind==1||kind==-1)?3:0;
        bullet->state.update_tick=bullet->state.animation_tick=
            bullet->state.action_tick=simulationTick;
        astro_vector_make(&bullet->state.velocity,shots[i].heading,number(attr,@"speed"));
        [pendingEnemies addObject:bullet];emittedShots++;
    }
}
- (void)applyBeam:(const AstroBeam *)beam context:(BeamContext *)context {
    if(beam->target<0) return;
    AstroCombatState b={.kind=999,.layer=1,.hit_points=beam->damage};
    if((NSUInteger)beam->target==context->objects.count) {
        astro_bullet_hits_player(&b,&playerCombat);
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
- (AstroCombatState)combatFor:(AstroEnemy *)enemy {
    return (AstroCombatState){.kind=enemy->kind,.layer=enemy->layer,
        .hit_points=enemy->hitPoints,.remove=enemy->state.remove,.velocity=enemy->state.velocity};
}
- (void)applyCombat:(AstroCombatState)combat to:(AstroEnemy *)enemy {
    enemy->hitPoints=combat.hit_points;enemy->state.remove=combat.remove;
    enemy->state.velocity=combat.velocity;
}
- (void)checkCombat {
    NSRect player=NSMakeRect(playerX+camera,playerY,71,20);
    for(AstroEnemy *pickup in enemies) {
        if(!pickup->active||pickup->state.remove||pickup->kind!=40||playerCombat.remove) continue;
        NSRect bounds=NSMakeRect((int)pickup->state.x,(int)pickup->state.y,
            number(pickup->placement,@"width"),number(pickup->placement,@"height"));
        if(NSIntersectsRect(bounds,player)) {
            astro_pickup(&playerCombat,[pickup->placement[@"attribute"] intValue]%10,
                pickup->hitPoints,&pickup->state.remove,&inventory);
            playerWeapon=inventory.weapon+inventory.upgrade;
        }
    }
    playerCombat.velocity=playerVelocity;
    for(AstroEnemy *scenery in enemies) {
        if(!scenery->active||scenery->state.remove||scenery->kind<20||scenery->kind>29||playerCombat.remove) continue;
        double x=scenery->state.x,y=scenery->state.y;
        double w=number(scenery->placement,@"width"),h=number(scenery->placement,@"height");
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
            number(bullet->placement,@"width"),number(bullet->placement,@"height"));
        AstroCombatState b=[self combatFor:bullet];
        if(!playerCombat.remove&&NSIntersectsRect(bounds,player))
            astro_bullet_hits_player(&b,&playerCombat);
        if(b.kind==2) for(AstroEnemy *enemy in enemies) {
            if(enemy==bullet||!enemy->active||enemy->state.remove||
               !(enemy->kind==5||(enemy->kind>19&&enemy->kind<30))) continue;
            NSRect target=NSMakeRect((int)enemy->state.x,(int)enemy->state.y,
                number(enemy->placement,@"width"),number(enemy->placement,@"height"));
            if(NSIntersectsRect(bounds,target)) {
                AstroCombatState e=[self combatFor:enemy];
                astro_bullet_hits_enemy(&b,&e,[enemy->definition[@"kill_score"] intValue],&score);
                if(e.hit_points!=enemy->hitPoints) damageHits++;
                [self applyCombat:e to:enemy];
            }
        }
        [self applyCombat:b to:bullet];
    }
}
- (void)stepEnemies {
    simulationTick++;
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
            if(state->x>=camera+740) continue;
            enemy->active=YES;
            state->x=(int)state->x;state->y=(int)state->y;
            state->update_tick=state->animation_tick=state->action_tick=simulationTick;
        }
        double width=number(enemy->placement,@"width"),height=number(enemy->placement,@"height");
        if(state->x>camera+(enemy->kind==2?650:740)||state->x+width<camera-10||
           (enemy->kind==2&&(state->y>390||state->y+height< -10))) {
            state->remove=1;continue;
        }
        if(enemy->kind==5&&enemy->program.length&&state->x<camera+640&&state->x+width>camera) {
            double w=number(enemy->placement,@"width"),h=number(enemy->placement,@"height");
            int heading=astro_heading(state->x,state->y,w,h,playerX+camera,playerY,71,20);
            AstroScriptContext context={.player_present=1,.target_heading=(int)heading,
                .player_x=playerX+camera,.player_y=playerY,
                .animated=[enemy->definition[@"animated"] intValue],
                .weapon=[enemy->definition[@"weapon"] intValue],
                .userdata=(__bridge void *)self,.fire=enemyFire,
                .gun_x=(int)state->x+[enemy->definition[@"turret_x"] intValue],
                .gun_y=(int)state->y+[enemy->definition[@"turret_y"] intValue]};
            // shortcut: weapon/damage callbacks await reconstructed combat; no invented bullets.
            if(!astro_script_step(state,enemy->program.bytes,
                enemy->program.length/sizeof(AstroInstruction),simulationTick,&context)) {
                NSLog(@"Script ended outside RETURN"); exit(1);
            }
            scriptSteps++;
        }
        state->x+=state->velocity.x; state->y+=state->velocity.y;
        if(enemy->kind==2&&(state->x-camera< -300||state->x-camera>1000||
            state->y< -200||state->y>700)) state->remove=-1;
    }
    [enemies addObjectsFromArray:pendingEnemies];[pendingEnemies removeAllObjects];
    [self checkCombat];
    NSIndexSet *removed=[enemies indexesOfObjectsPassingTest:
        ^BOOL(AstroEnemy *enemy,NSUInteger index,BOOL *stop){return enemy->state.remove!=0;}];
    [enemies removeObjectsAtIndexes:removed];
}
- (void)tick:(NSTimer *)sender {
    double now=[NSDate timeIntervalSinceReferenceDate];
    double dt=fmin(now-previousTime,.05); previousTime=now;
    tickRemainder+=dt;
    while(tickRemainder>=1.0/60.0) {
        tickRemainder-=1.0/60.0;
        [self stepEnemies];
        if(keys[8]&&!playerCombat.remove&&simulationTick-lastPlayerShot>
            60.0/[game[@"weapons"][[NSString stringWithFormat:@"%d",playerWeapon]][@"rate"] doubleValue]) {
            lastPlayerShot=simulationTick;
            [self fireWeapon:playerWeapon x:(int)(playerX+camera)+74 y:(int)playerY+12 heading:0 source:1];
        }
        playerX+=playerVelocity.x; playerY+=playerVelocity.y;
        unsigned controls=0;
        if(keys[123]||keys[0]) controls|=ASTRO_KEY_LEFT;
        if(keys[124]||keys[2]) controls|=ASTRO_KEY_RIGHT;
        if(keys[126]||keys[13]) controls|=ASTRO_KEY_UP;
        if(keys[125]||keys[1]) controls|=ASTRO_KEY_DOWN;
        playerState.velocity=playerVelocity;
        AstroRect bounds={(int)(playerX+camera),(int)playerY,(int)(playerX+camera+71),(int)(playerY+20)};
        astro_player_step(&playerState,simulationTick,controls,1,bounds,71,20,
            (AstroRect){(int)camera,0,(int)(camera+640),380},0);
        playerVelocity=playerState.velocity;
    }
    if(keys[7]||automatic) camera+=120*dt;
    if(keys[6]) camera=fmax(0,camera-120*dt);
    [self setNeedsDisplay:YES];
    if(selftestPath) {
        selftestTicks++;
        if(selftestTicks==20) [self keyUp:[self testEvent:NSKeyUp code:124]];
        if(selftestTicks==40) [self keyDown:[self testEvent:NSKeyDown code:20]];
        if(selftestTicks==60) [self keyDown:[self testEvent:NSKeyDown code:21]];
        if(selftestTicks==90) [self finishSelfTest];
    }
}
- (NSEvent *)testEvent:(NSEventType)type code:(unsigned short)code {
    return [NSEvent keyEventWithType:type location:NSZeroPoint modifierFlags:0
        timestamp:0 windowNumber:self.window.windowNumber context:nil characters:@""
        charactersIgnoringModifiers:@"" isARepeat:NO keyCode:code];
}
- (void)beginSelfTest:(NSString *)path {
    selftestPath=[path copy]; selftestTicks=0; selftestStartX=playerX;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
        withIntermediateDirectories:YES attributes:nil error:nil];
    [self keyDown:[self testEvent:NSKeyDown code:124]];
    [self keyDown:[self testEvent:NSKeyDown code:8]];
    [self keyDown:[self testEvent:NSKeyDown code:45]];
    for(AstroEnemy *enemy in enemies) if(enemy->program.length) {
        camera=fmax(0,enemy->state.x-400);
        playerY=enemy->state.y+number(enemy->placement,@"height")/2-12; break;
    }
    music.volume=0;
    [music play];
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
    BOOL moved=playerX>selftestStartX+10;
    BOOL audio=music.isPlaying && music.currentTime>0;
    BOOL passed=emittedBeams>0 && damageHits>0 && emittedShots>0 && scriptSteps>0 && moved && selectedLevel==1 && colored>100 && textures.count>0 && audio;
    NSDictionary *report=@{@"passed":@(passed),@"script_steps":@(scriptSteps),@"emitted_shots":@(emittedShots),@"damage_hits":@(damageHits),@"emitted_beams":@(emittedBeams),
        @"player_hit_points":@(playerCombat.hit_points),@"score":@(score),@"player_moved":@(moved),
        @"stage_switched":@(selectedLevel==1),@"music_time":@(music.currentTime),
        @"music_playing":@(music.isPlaying),@"colored_pixels":@(colored),
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
    if(key==46) { if(music.isPlaying) [music pause]; else [music play]; }
    if(key==53) [NSApp terminate:nil];
}
- (void)keyUp:(NSEvent *)event { if(event.keyCode<128) keys[event.keyCode]=NO; }
- (void)flagsChanged:(NSEvent *)event { }
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
