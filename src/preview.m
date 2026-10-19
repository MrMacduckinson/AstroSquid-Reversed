// Native renderer/input smoke test. Gameplay has not yet been reconstructed.
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <AVFoundation/AVFoundation.h>
#include "physics.h"
#include "script.h"

@interface AstroEnemy : NSObject {
@public
    AstroScriptState state;
    NSDictionary *placement, *definition;
    NSData *program;
}
@end
@implementation AstroEnemy
@end

@interface AstroView : NSOpenGLView {
    NSDictionary *game;
    NSMutableDictionary *textures;
    NSArray *levels;
    NSMutableArray *enemies;
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
    BOOL automatic;
    NSString *selftestPath;
    NSInteger selftestTicks;
    double selftestStartX;
}
- (instancetype)initWithFrame:(NSRect)frame assets:(NSString *)path;
- (void)beginSelfTest:(NSString *)path;
@end

static double number(NSDictionary *d, NSString *key) { return [d[key] doubleValue]; }

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
    glViewport(0,0,(GLsizei)bounds.size.width,(GLsizei)bounds.size.height);
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION); glLoadIdentity(); glOrtho(0,640,480,0,-1,1);
    glMatrixMode(GL_MODELVIEW); glLoadIdentity();
    glDisable(GL_TEXTURE_2D); glColor4d(.4,.5,.6,1); glPointSize(1);
    glBegin(GL_POINTS);
    for (unsigned i=0;i<600;i++) {
        unsigned seed=i*2654435761u;
        double x=fmod((seed%640)-camera*.15+640*100,640);
        glVertex2d(x,70+(seed/640)%380);
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
        if(enemy->state.remove) continue;
        NSDictionary *entity=enemy->placement;
        double x=enemy->state.x-camera,y=enemy->state.y;
        double w=number(entity,@"width"),h=number(entity,@"height");
        if(x+w<0||x>640||y+h<70||y>450) continue;
        NSInteger sprite=[enemy->definition[@"sprite"] integerValue]+enemy->state.frame-1;
        [self sprite:sprite x:x y:y width:w height:h];
    }
    [self sprite:1 x:playerX y:playerY width:0 height:0];
    [[self openGLContext] flushBuffer];
}
- (void)resetEnemies {
    enemies=[NSMutableArray array]; simulationTick=0;
    NSDictionary *level=game[@"levels"][levels[selectedLevel]];
    for(NSDictionary *placement in level[@"entities"]) {
        NSString *attribute=[placement[@"attribute"] stringValue];
        if([attribute isEqualToString:@"11"]) continue;
        AstroEnemy *enemy=[AstroEnemy new];
        enemy->placement=placement; enemy->definition=game[@"attributes"][attribute];
        enemy->state=(AstroScriptState){.frame=1,.tilt=1,.state=1,
            .x=number(placement,@"x"),.y=number(placement,@"y")};
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
        [enemies addObject:enemy];
    }
}
- (void)stepEnemies {
    simulationTick++;
    for(AstroEnemy *enemy in enemies) {
        AstroScriptState *state=&enemy->state;
        // shortcut: preview activates visible objects; recover original spawn/parent rules next.
        if(state->remove||state->x-camera>700||state->x-camera< -300) continue;
        if(enemy->program.length) {
            double w=number(enemy->placement,@"width"),h=number(enemy->placement,@"height");
            double dx=(int)(playerX+camera+40)-(int)(state->x+w/2);
            double dy=(int)(playerY+15)-(int)(state->y+h/2);
            double heading=atan2(-dy,dx)*180/M_PI;
            if(heading<0) heading+=360;
            AstroScriptContext context={.player_present=1,.target_heading=(int)heading,
                .player_x=playerX+camera,.player_y=playerY,
                .animated=[enemy->definition[@"animated"] intValue],
                .weapon=[enemy->definition[@"weapon"] intValue],
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
    }
}
- (void)tick:(NSTimer *)sender {
    double now=[NSDate timeIntervalSinceReferenceDate];
    double dt=fmin(now-previousTime,.05); previousTime=now;
    tickRemainder+=dt;
    while(tickRemainder>=1.0/60.0) {
        tickRemainder-=1.0/60.0;
        [self stepEnemies];
        playerX+=playerVelocity.x; playerY+=playerVelocity.y;
        // Original player acceleration and drag: DOPLAYERSPRITE literals.
        if(keys[123]||keys[0]) astro_vector_make(&playerVelocity,180,.5);
        if(keys[124]||keys[2]) astro_vector_make(&playerVelocity,0,.5);
        if(keys[126]||keys[13]) astro_vector_make(&playerVelocity,90,.5);
        if(keys[125]||keys[1]) astro_vector_make(&playerVelocity,270,.5);
        astro_vector_slow(&playerVelocity,.1);
        // Preview bounds are temporary; original collision handling is pending.
        playerX=fmax(0,fmin(playerX,560)); playerY=fmax(70,fmin(playerY,425));
    }
    if(keys[7]||automatic) camera+=120*dt;
    if(keys[6]) camera=fmax(0,camera-120*dt);
    [self setNeedsDisplay:YES];
    if(selftestPath && ++selftestTicks==90) [self finishSelfTest];
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
    [self keyDown:[self testEvent:NSKeyDown code:45]];
    for(AstroEnemy *enemy in enemies) if(enemy->program.length) {
        camera=fmax(0,enemy->state.x-400); break;
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
    BOOL passed=scriptSteps>0 && moved && selectedLevel==1 && colored>100 && textures.count>0 && audio;
    NSDictionary *report=@{@"passed":@(passed),@"script_steps":@(scriptSteps),@"player_moved":@(moved),
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
