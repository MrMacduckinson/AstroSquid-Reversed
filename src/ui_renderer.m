#import "ui_renderer.h"
#include "ui_model.h"
#include "weapons.h"
#include "scores.h"
#include <math.h>

@implementation AstroUIRenderer {
    NSDictionary *_data;
    NSArray *_objects;
    NSString *_anchor,*_hover,*_pressed;
    double _cameraX,_cameraY,_cameraStepX,_cameraStepY;
    AstroScoreCaret _caret;
    double _targetX,_targetY;
    BOOL _transitioning;
    unsigned _panelFrames;
    double _panelOffset,_panelStep;
    NSMutableDictionary *_orbStates;
}
@synthesize anchor=_anchor;
@synthesize transitioning=_transitioning;
@synthesize panelOffset=_panelOffset;
@synthesize cameraX=_cameraX,cameraY=_cameraY,cameraStepX=_cameraStepX,cameraStepY=_cameraStepY;
- (instancetype)initWithAssets:(NSString *)assets error:(NSError **)error {
    if((self=[super init])){
        NSData *bytes=[NSData dataWithContentsOfFile:[assets stringByAppendingPathComponent:@"ui/ui.json"] options:0 error:error];
        if(!bytes)return nil;
        _data=[NSJSONSerialization JSONObjectWithData:bytes options:0 error:error];
        if(![_data[@"scenes"] isKindOfClass:[NSDictionary class]]||![_data[@"font"][@"advance"] isKindOfClass:[NSArray class]])return nil;
        _orbStates=[NSMutableDictionary dictionary];_registered=YES;_registeredName=@"";_editingName=@"";
        _frameInterval=1;_unlockedLevel=1;_smooth=YES;_soundVolume=.6;_musicVolume=1;
        _keyLabels=@[@"Space",@"Option",@"Up",@"Down",@"Left",@"Right"];
        _highscores=@[];astro_score_caret_begin(&_caret,0);
        [self show:@"Main Menu"];
    }return self;
}
- (NSDictionary *)object:(NSString *)name {
    for(NSDictionary *object in _objects)if([object[@"name"] isEqual:name])return object;
    return nil;
}
- (void)show:(NSString *)anchor {
    _panelFrames=0;_panelOffset=0;
    NSString *scene=[anchor isEqual:@"Pause"]?@"Data B3":[anchor isEqual:@"GameOver"]?@"Data B1":@"Data B2";
    BOOL sameScene=[scene isEqual:@"Data B2"]&&_objects==_data[@"scenes"][scene];
    _objects=_data[@"scenes"][scene];_anchor=[anchor copy];_hover=nil;_pressed=nil;
    if(!sameScene){
        _cameraX=0;_cameraY=0;[_orbStates removeAllObjects];
        for(NSDictionary *object in _objects){
            NSInteger counter=[object[@"animation_counter"] integerValue];
            AstroUIMotion state={[object[@"x"] doubleValue],[object[@"y"] doubleValue],[object[@"width"] doubleValue],[object[@"height"] doubleValue],(int32_t)counter,[object[@"sprite"] shortValue]};
            _orbStates[object[@"name"]]=[NSMutableData dataWithBytes:&state length:sizeof(state)];
        }
    }
    _targetX=0;_targetY=0;
    if([scene isEqual:@"Data B2"]){
        NSString *name=[anchor isEqual:@"Credits"]?@"CreditsMenu":anchor;
        NSDictionary *a=[self object:name];
        if(a)astro_ui_camera(name.UTF8String,[a[@"x"] doubleValue],[a[@"y"] doubleValue],
                            [a[@"width"] doubleValue],[a[@"height"] doubleValue],&_targetX,&_targetY);
    }
    _transitioning=sameScene&&![_anchor isEqual:@"Credits"];
    if(!_transitioning){
        if([scene isEqual:@"Data B2"]){
            double dx,dy;do {dx=(_targetX-_cameraX)/(10.0/_frameInterval);dy=(_targetY-_cameraY)/(10.0/_frameInterval);_cameraX+=dx;_cameraY+=dy;}while(fabs(dx)>=1||fabs(dy)>=1);
        }else {_cameraX=_targetX;_cameraY=_targetY;}
    }
    if([anchor isEqual:@"Pause"]||[anchor isEqual:@"GameOver"]){
        _panelFrames=[anchor isEqual:@"Pause"]?30:60;_panelOffset=-380;
        _panelStep=380.0/_panelFrames;_transitioning=YES;
        for(NSDictionary *object in _objects){
            if([anchor isEqual:@"GameOver"]&&![object[@"name"] isEqual:@"GameOverOK"]&&![object[@"name"] isEqual:@"GameOverFade"])continue;
            AstroUIMotion *state=[_orbStates[object[@"name"]] mutableBytes];
            state->y=(state->y-380)-70;
        }
    }
}
- (void)beginPauseExit {
    if(![_anchor isEqual:@"Pause"])return;
    _panelFrames=30;_panelStep=-380.0/30;_transitioning=YES;
}
- (void)reloadMenuWithRandom:(uint32_t *)seed {
    _objects=nil;[self show:@"Main Menu"];
    for(NSDictionary *object in _objects){
        NSInteger sprite=[object[@"sprite"] integerValue];
        if(sprite==900||sprite==901)((AstroUIMotion *)[_orbStates[object[@"name"]] mutableBytes])->counter=astro_random(seed,60);
    }
}
- (BOOL)enabled:(NSDictionary *)object {
    NSString *name=object[@"name"];
    if(self.registered&&[@[@"Register",@"RegOK",@"Register Menu",@"Reg Thanks",@"Back3",@"Back5"] containsObject:name])return NO;
    if([name hasPrefix:@"Level"]){int n=[[name substringFromIndex:5] intValue];return n>0&&n<=self.unlockedLevel;}
    return YES;
}
- (NSRect)bounds:(NSDictionary *)object {
    const AstroUIMotion *state=[_orbStates[object[@"name"]] bytes];
    double y=state->y+_cameraY;if([_anchor isEqual:@"Pause"]||[_anchor isEqual:@"GameOver"])y+=70;
    return NSMakeRect(state->x+_cameraX,y,state->width,state->height);
}
- (NSString *)hitX:(double)x y:(double)y {
    NSString *result=nil;
    if(_transitioning)return nil;
    for(int kind=9;kind<=10;kind++)for(NSDictionary *object in _objects){
        if([object[@"kind"] intValue]!=kind||![self enabled:object])continue;
        NSRect r=[self bounds:object];
        if(astro_ui_contains(r.origin.x,r.origin.y,r.size.width,r.size.height,x,y))result=object[@"name"];
    }
    return result;
}
- (void)moveMouseX:(double)x y:(double)y {_hover=[self hitX:x y:y];}
- (NSString *)mouseDownX:(double)x y:(double)y {
    if(_pressed)return nil;
    if([_anchor isEqual:@"Credits"]){if(_beforeNavigate)_beforeNavigate(@"Yeah");[self show:@"Main Menu"];return @"Yeah";}
    NSString *result=[self hitX:x y:y];_pressed=result;_hover=result;
    if(result){AstroUICommand command=astro_ui_command(result.UTF8String);
        if(command.action==ASTRO_UI_NAVIGATE){if(_beforeNavigate)_beforeNavigate(result);[self show:[NSString stringWithUTF8String:command.destination]];_pressed=result;}
    }return result;
}
- (NSString *)mouseUpX:(double)x y:(double)y {
    _pressed=nil;_hover=[self hitX:x y:y];return nil;
}
- (void)advanceMenuCamera {
    _cameraStepX=0;_cameraStepY=0;
    if(!_transitioning||_panelFrames)return;
    _cameraStepX=(_targetX-_cameraX)/(10.0/_frameInterval);_cameraStepY=(_targetY-_cameraY)/(10.0/_frameInterval);
    _cameraX+=_cameraStepX;_cameraY+=_cameraStepY;
    if(fabs(_cameraStepX)<1&&fabs(_cameraStepY)<1){_targetX=_cameraX;_targetY=_cameraY;_transitioning=NO;_pressed=nil;}
}
- (void)animateMenuObjects {
    for(NSDictionary *object in _objects)astro_ui_animate([_orbStates[object[@"name"]] mutableBytes],_frameInterval);
}
- (void)animateTicks:(unsigned)ticks {
    for(unsigned i=0;i<ticks;i++){
        if(_panelFrames){
            _panelOffset+=_panelStep;
            for(NSDictionary *object in _objects){
                if([_anchor isEqual:@"GameOver"]&&![object[@"name"] isEqual:@"GameOverOK"]&&![object[@"name"] isEqual:@"GameOverFade"])continue;
                astro_ui_panel_step([_orbStates[object[@"name"]] mutableBytes],_panelStep);
            }
            if(!--_panelFrames){_transitioning=NO;if(_panelStep>0)_panelOffset=0;}
            continue;
        }else [self advanceMenuCamera];
        [self animateMenuObjects];
    }
}
- (BOOL)editingCaretVisible {return _caret.visible==1;}
- (void)beginScoreClock:(uint32_t)tick {astro_score_caret_begin(&_caret,tick);}
- (double)textWidth:(NSString *)text size:(double)size {
    NSData *bytes=[text dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
    const unsigned char *chars=bytes.bytes;NSArray *advance=_data[@"font"][@"advance"];double width=0;
    for(NSUInteger i=0;i<bytes.length;i++)width+=size*[advance[chars[i]] doubleValue];
    return width;
}
- (void)drawText:(NSString *)text x:(double)x baseline:(double)y size:(double)size texture:(AstroUITextureLoader)texture {
    NSData *bytes=[text dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
    const unsigned char *chars=bytes.bytes;NSArray *advance=_data[@"font"][@"advance"];
    glEnable(GL_TEXTURE_2D);glEnable(GL_BLEND);glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    glBindTexture(GL_TEXTURE_2D,texture(50));
    for(NSUInteger i=0;i<bytes.length;i++){
        unsigned c=chars[i];
        if(c&&c!=32){unsigned cell=c-1;double u=(cell%16)/16.0+.0015,v=(cell/16)/16.0+.0015,e=.0595;
            glBegin(GL_QUADS);
            glTexCoord2d(u,v);glVertex2d(x,y-size);
            glTexCoord2d(u+e,v);glVertex2d(x+size,y-size);
            glTexCoord2d(u+e,v+e);glVertex2d(x+size,y);
            glTexCoord2d(u,v+e);glVertex2d(x,y);glEnd();
        }x+=size*[advance[c] doubleValue];
    }
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
}
- (void)label:(NSString *)text object:(NSDictionary *)object left:(BOOL)left texture:(AstroUITextureLoader)texture {
    NSRect r=[self bounds:object];NSDictionary *spec=_data[@"label_layout"][object[@"name"]];
    double size=spec?[spec[@"size"] doubleValue]:16;
    double x=left?r.origin.x-8-[self textWidth:text size:size]:NSMaxX(r)+8,y=NSMidY(r)+8;
    if(spec){
        double values[]={r.origin.x,r.origin.y,r.size.width,r.size.height,1};x=0;y=0;
        for(int i=0;i<5;i++){x+=[spec[@"x"][i] doubleValue]*values[i];y+=[spec[@"y"][i] doubleValue]*values[i];}
        if([spec[@"subtract_text_width"] boolValue])x-=[self textWidth:text size:size];
    }
    [self drawText:text x:(int)x baseline:(int)y size:size texture:texture];
}
- (void)drawSprites:(AstroUISpriteDrawer)sprites texture:(AstroUITextureLoader)texture {
    if([_anchor isEqual:@"Credits"]){[self drawSplashWithTexture:texture];return;}
    glColor4d(1,1,1,1);
    for(int kind=1;kind<=10;kind++)for(NSDictionary *object in _objects){
        if([object[@"kind"] intValue]!=kind||![self enabled:object])continue;
        NSRect r=[self bounds:object];if(NSMaxX(r)<0||r.origin.x>640||NSMaxY(r)<0||r.origin.y>480)continue;
        NSString *name=object[@"name"];NSInteger sprite=[object[@"sprite"] integerValue];
        if(sprite==900){if([name isEqual:_pressed])sprite=901;else if([name isEqual:_hover])sprite=902;}
        sprites(sprite,r.origin.x,r.origin.y,r.size.width,r.size.height);
    }
    glColor4d(.8,.8,.8,1);
    NSDictionary *labelMap=@{@"Back":@"Back",@"Back2":@"Back",@"Back3":@"Back",@"Back4":@"Back",@"Back5":@"Back",@"Back6":@"Back",@"Back7":@"Back",@"Yeah":@"Yeah",@"SetSmooth":self.smooth?@"Graphics: Smooth":@"Graphics: Fast",@"SetKeys":@"Set Keys",@"SetSVolume":@"Sound Volume:",@"SetMVolume":@"Music Volume:",@"PauseContinue":@"Continue",@"PauseQuit":@"Quit",@"GameOverOK":@"OK",@"RegOK":@"OK"};
    for(NSDictionary *object in _objects){
        if([object[@"kind"] intValue]<9||![self enabled:object])continue;
        NSString *name=object[@"name"],*label=labelMap[name]?:name;
        if([name isEqual:@"SetSVolume"])label=[label stringByAppendingString:self.soundVolume>0?[NSString stringWithFormat:@" %d",(int)lround(self.soundVolume*10)]:@"Mute"];
        if([name isEqual:@"SetMVolume"])label=[label stringByAppendingString:self.musicVolume>0?[NSString stringWithFormat:@" %d",(int)lround(self.musicVolume*10)]:@"Mute"];
        if([name hasPrefix:@"Level"]){NSInteger index=[[name substringFromIndex:5] integerValue]-1;
            if(index>=0&&index<(NSInteger)[_data[@"level_names"] count])label=_data[@"level_names"][index];
        }
        NSArray *keyNames=@[@"SetKeyFire",@"SetKeySpecial",@"SetKeyUp",@"SetKeyDown",@"SetKeyLeft",@"SetKeyRight"];
        NSUInteger key=[keyNames indexOfObject:name];
        if(key!=NSNotFound&&key<self.keyLabels.count){NSArray *prefix=@[@"Fire",@"Special",@"Up",@"Down",@"Left",@"Right"];label=[NSString stringWithFormat:@"%@: %@",prefix[key],self.keyLabels[key]];}
        BOOL left=[@[@"Settings",@"Register",@"Back2",@"Back3",@"Back4",@"Back5",@"Back6",@"PauseQuit"] containsObject:name];
        [self label:label object:object left:left texture:texture];
    }
    NSDictionary *mainMenu=[self object:@"Main Menu"];
    if(mainMenu){
        // DRAWGLMENU footer follows the menu anchor while its camera pans.
        NSRect r=[self bounds:mainMenu];double x=(int)(NSMidX(r)-310);
        NSString *registration=self.registered?[(_data[@"labels"][@"223"]?:@"Registered to: ") stringByAppendingString:self.registeredName?:@""]:_data[@"labels"][@"165"];
        glColor4d(.8,.8,.8,1);
        [self drawText:registration x:x baseline:(int)(NSMidY(r)+215) size:10 texture:texture];
        [self drawText:_data[@"labels"][@"224"] x:x baseline:(int)(NSMidY(r)+230) size:10 texture:texture];
    }
    if([_anchor isEqual:@"Pause"]&&!_transitioning){glColor4d(1,1,1,1);[self drawText:@"Game Paused" x:220 baseline:220 size:32 texture:texture];}
    if([_anchor isEqual:@"GameOver"]&&!_transitioning){glColor4d(1,1,1,1);[self drawText:@"Game Over" x:240 baseline:190 size:32 texture:texture];}
    if([_anchor isEqual:@"GameOver"]&&self.editingHighscore>0){
        glColor4d(1,1,1,1);[self drawText:@"Highscore!" x:240 baseline:240 size:32 texture:texture];
        glDisable(GL_TEXTURE_2D);glBegin(GL_LINE_LOOP);
        glVertex2d(223,254);glVertex2d(423,254);glVertex2d(423,276);glVertex2d(223,276);glEnd();
        [self drawText:@"Name:" x:225 baseline:254 size:12 texture:texture];
        NSString *name=self.editingName?:@"";
        NSUInteger cursor=MIN((NSUInteger)MAX(self.editingCursor,0),name.length);
        double cursorWidth=[self textWidth:[name substringToIndex:cursor] size:20];
        double offset=MAX(0,cursorWidth-196);
        GLint viewport[4],oldScissor[4];glGetIntegerv(GL_VIEWPORT,viewport);glGetIntegerv(GL_SCISSOR_BOX,oldScissor);
        GLboolean scissor=glIsEnabled(GL_SCISSOR_TEST);glEnable(GL_SCISSOR_TEST);
        glScissor(viewport[0]+(GLint)(225*viewport[2]/640.0),viewport[1]+(GLint)(203*viewport[3]/480.0),
            (GLsizei)(198*viewport[2]/640.0),(GLsizei)(22*viewport[3]/480.0));
        [self drawText:name x:225-offset baseline:277 size:20 texture:texture];
        if(self.readTick){
            uint32_t tick=self.readTick();
            uint32_t reset=(int32_t)_caret.deadline<(int32_t)tick?self.readTick():tick;
            astro_score_caret_draw(&_caret,tick,reset);
        }
        if(self.editingCaretVisible){
            double x=225+cursorWidth-offset;
            glDisable(GL_TEXTURE_2D);glBegin(GL_QUADS);glVertex2d(x,255);glVertex2d(x+1,255);glVertex2d(x+1,274);glVertex2d(x,274);glEnd();
        }
        glScissor(oldScissor[0],oldScissor[1],oldScissor[2],oldScissor[3]);if(!scissor)glDisable(GL_SCISSOR_TEST);
    }
    if([_anchor isEqual:@"Highscores Menu"]){
        NSDictionary *object=[self object:@"Highscores Menu"];NSRect r=[self bounds:object];NSInteger i=0;
        double x=(int)(NSMidX(r)+95),y=(int)(NSMidY(r)+50);
        glColor4d(1,1,1,1);
        for(NSDictionary *entry in self.highscores){NSString *line=[NSString stringWithFormat:@"'%@' %s%@pts",entry[@"name"]?:@"",[entry[@"score"] longLongValue]>=0?" ":"",entry[@"score"]?:@0];
            glColor4d(self.editingHighscore>0&&self.editingHighscore!=i+1?.5:1,self.editingHighscore>0&&self.editingHighscore!=i+1?.5:1,self.editingHighscore>0&&self.editingHighscore!=i+1?.5:1,1);
            [self drawText:line x:x+30 baseline:y+25*i size:16 texture:texture];
            [self drawText:[NSString stringWithFormat:@" %ld",(long)i+1] x:x-(i==9?11:0) baseline:y+25*i+4 size:24 texture:texture];
            if(++i==10)break;
        }
    }
    glColor4d(1,1,1,1);
}
- (void)drawPicture:(NSInteger)identifier x:(double)x y:(double)y width:(double)width height:(double)height texture:(AstroUITextureLoader)texture {
    NSDictionary *p=_data[@"pictures"][[NSString stringWithFormat:@"%ld",(long)identifier]];
    if(!p)return;
    double pw=[p[@"width"] doubleValue],ph=[p[@"height"] doubleValue];
    BOOL natural=width==0&&height==0;
    if(!width)width=pw;if(!height)height=ph;if(!x)x=320-width/2;if(!y)y=240-height/2;
    double u=pw/[p[@"texture_width"] doubleValue],v=ph/[p[@"texture_height"] doubleValue];
    glEnable(GL_TEXTURE_2D);glBindTexture(GL_TEXTURE_2D,texture(identifier));glColor4d(1,1,1,1);
    if(natural){glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);}
    glBegin(GL_QUADS);
    glTexCoord2d(0,0);glVertex2d(x,y);glTexCoord2d(u,0);glVertex2d(x+width,y);
    glTexCoord2d(u,v);glVertex2d(x+width,y+height);glTexCoord2d(0,v);glVertex2d(x,y+height);glEnd();
    GLint filter=self.smooth?GL_LINEAR:GL_NEAREST;
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,filter);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,filter);
}
- (NSInteger)scoreCursorAtX:(double)x {
    NSString *name=self.editingName?:@"";
    NSUInteger cursor=MIN((NSUInteger)MAX(self.editingCursor,0),name.length);
    double offset=MAX(0,[self textWidth:[name substringToIndex:cursor] size:20]-196);
    double position=x-225+offset;
    for(NSUInteger i=0;i<name.length;i++) {
        double left=[self textWidth:[name substringToIndex:i] size:20];
        double right=[self textWidth:[name substringToIndex:i+1] size:20];
        if(position<(left+right)/2)return i;
    }
    return name.length;
}
- (NSString *)nameForKeyCode:(NSInteger)code {
    NSArray *names=_data[@"key_names"];NSInteger bit=code^7;
    if(bit>=0&&bit<(NSInteger)names.count&&[names[bit] length])return names[bit];
    return [NSString stringWithFormat:@"[%ld]",(long)code];
}
- (NSString *)briefingForStage:(NSInteger)stage list:(NSInteger)list {
    NSArray *lines=_data[@"briefings"][[NSString stringWithFormat:@"%ld",(long)list]];
    return stage>=1&&stage<=(NSInteger)lines.count?lines[stage-1]:@"";
}
- (void)drawBriefingForStage:(NSInteger)stage list:(NSInteger)list texture:(AstroUITextureLoader)texture {
    NSString *text=[self briefingForStage:stage list:list];
    glColor4d(.7,.7,.7,1);[self drawText:text x:320-[self textWidth:text size:12]/2 baseline:330 size:12 texture:texture];
    glColor4d(.4,.4,.4,1);NSString *prompt=_data[@"labels"][@"278"];
    [self drawText:prompt x:320-[self textWidth:prompt size:10]/2 baseline:370 size:10 texture:texture];glColor4d(1,1,1,1);
}
- (void)drawSplashWithTexture:(AstroUITextureLoader)texture {
    NSDictionary *credits=_data[@"credits"];
    [self drawPicture:[credits[@"picture"] integerValue] x:0 y:[credits[@"picture_y"] doubleValue] width:0 height:0 texture:texture];
    for(NSDictionary *line in credits[@"lines"]){
        double size=[line[@"size"] doubleValue],brightness=[line[@"brightness"] doubleValue];NSString *text=line[@"text"];
        glColor4d(brightness,brightness,brightness,1);
        [self drawText:text x:[line[@"center_x"] doubleValue]-[self textWidth:text size:size]/2 baseline:[line[@"baseline"] doubleValue] size:size texture:texture];
    }glColor4d(1,1,1,1);
}
- (void)drawEndingPage:(NSInteger)page texture:(AstroUITextureLoader)texture {
    NSArray *pages=_data[@"ending"];if(page<0||page>=(NSInteger)pages.count)return;
    NSDictionary *p=pages[page];NSString *text=p[@"text"];double size=[p[@"size"] doubleValue];
    glColor4d(.7,.7,.7,1);[self drawText:text x:[p[@"center_x"] doubleValue]-[self textWidth:text size:size]/2 baseline:[p[@"baseline"] doubleValue] size:size texture:texture];glColor4d(1,1,1,1);
}
@end
