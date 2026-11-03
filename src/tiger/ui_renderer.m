#import "compat.h"
#import "ui_renderer.h"
#include "ui_model.h"
#include "weapons.h"
#include "scores.h"
#include <math.h>

@implementation AstroUIRenderer
- (void)dealloc{[_data release];[_objects release];[_anchor release];[_hover release];[_pressed release];[_orbStates release];[_hoverDeadlines release];[_panelWorldX release];[_registeredName release];[_editingName release];[_keyLabels release];[_highscores release];if(_readTick)Block_release(_readTick);if(_registrationFooterText)Block_release(_registrationFooterText);[super dealloc];}
@synthesize soundVolume=_soundVolume,scoreField=_scoreField;
@synthesize frameInterval=_frameInterval;
@synthesize gameOverClosing=_gameOverClosing;
@synthesize registered=_registered;
- (NSString *)registeredName{return _registeredName;}
- (void)setRegisteredName:(NSString *)value{id replacement=[value copy];[_registeredName release];_registeredName=replacement;}
@synthesize activeRegistrationField=_activeRegistrationField;
@synthesize editingHighscore=_editingHighscore;
- (NSString *)editingName{return _editingName;}
- (void)setEditingName:(NSString *)value{id replacement=[value copy];[_editingName release];_editingName=replacement;}
@synthesize editingCursor=_editingCursor;
@synthesize unlockedLevel=_unlockedLevel;
@synthesize smooth=_smooth;
@synthesize musicVolume=_musicVolume;
- (NSArray *)keyLabels{return _keyLabels;}
- (void)setKeyLabels:(NSArray *)value{id replacement=[value copy];[_keyLabels release];_keyLabels=replacement;}
- (NSArray *)highscores{return _highscores;}
- (void)setHighscores:(NSArray *)value{id replacement=[value copy];[_highscores release];_highscores=replacement;}
- (NSString *(^)(NSString *prefix,NSString *name))registrationFooterText {return _registrationFooterText;}
- (void)setRegistrationFooterText:(NSString *(^)(NSString *prefix,NSString *name))value {if(_registrationFooterText==value)return; if(_registrationFooterText)Block_release(_registrationFooterText); _registrationFooterText=value?Block_copy(value):NULL;}
- (uint32_t (^)(void))readTick {return _readTick;}
- (void)setReadTick:(uint32_t (^)(void))value {if(_readTick==value)return; if(_readTick)Block_release(_readTick); _readTick=value?Block_copy(value):NULL;}
@synthesize anchor=_anchor;
@synthesize transitioning=_transitioning;
@synthesize panelOffset=_panelOffset;
@synthesize panelWorldOriginX=_panelWorldOriginX;
@synthesize cameraX=_cameraX,cameraY=_cameraY,cameraStepX=_cameraStepX,cameraStepY=_cameraStepY;
- (void)setPanelWorldOriginX:(double)origin {
    _panelWorldOriginX=origin;
    // HUD drawing can truncate the world camera after panel sprites are born.
    for(NSString *name in _panelWorldX){
        AstroUIMotion *state=[_orbStates[name] mutableBytes];
        state->x=[_panelWorldX[name] doubleValue]-origin;
    }
}
- (instancetype)initWithAssets:(NSString *)assets error:(NSError **)error {
    if((self=[super init])){
        NSData *bytes=[NSData dataWithContentsOfFile:[assets stringByAppendingPathComponent:@"ui/ui.plist"] options:0 error:error];
        if(!bytes){[self release];return nil;}
        ASTRO_STORE(_data,[AstroTigerSerialization JSONObjectWithData:bytes options:0 error:error]);
        if(![_data[@"scenes"] isKindOfClass:[NSDictionary class]]||![_data[@"font"][@"advance"] isKindOfClass:[NSArray class]]){[self release];return nil;}
        ASTRO_STORE(_orbStates,[NSMutableDictionary dictionary]);ASTRO_STORE(_hoverDeadlines,[NSMutableDictionary dictionary]);_registered=YES;ASTRO_STORE(_registeredName,@"");ASTRO_STORE(_editingName,@"");
        _scoreField=NSMakeRect(223,185,200,22);
        _frameInterval=1;_unlockedLevel=1;_smooth=YES;_soundVolume=.6;_musicVolume=1;
        ASTRO_STORE(_keyLabels,@[@"Space",@"Option",@"Up",@"Down",@"Left",@"Right"]);
        ASTRO_STORE(_highscores,@[]);astro_score_caret_begin(&_caret,0);
        [self show:@"Main Menu"];_activeRegistrationField=-1;[self resetRegistrationFields];
    }return self;
}
- (NSDictionary *)object:(NSString *)name {
    for(NSDictionary *object in _objects)if([object[@"name"] isEqual:name])return object;
    return nil;
}
- (void)show:(NSString *)anchor {
    _panelFrames=0;_panelOffset=0;_gameOverClosing=NO;
    ASTRO_STORE(_panelWorldX,[NSMutableDictionary dictionary]);
    NSString *scene=[anchor isEqual:@"Pause"]?@"Data B3":[anchor isEqual:@"GameOver"]?@"Data B1":@"Data B2";
    BOOL sameScene=[scene isEqual:@"Data B2"]&&_objects==_data[@"scenes"][scene];
    ASTRO_STORE(_objects,_data[@"scenes"][scene]);ASTRO_STORE(_anchor,[[anchor copy] autorelease]);ASTRO_STORE(_hover,nil);ASTRO_STORE(_pressed,nil);
    if(!sameScene){
        if(!_deferMenuCamera){_cameraX=0;_cameraY=0;}[_orbStates removeAllObjects];[_hoverDeadlines removeAllObjects];
        for(NSDictionary *object in _objects){
            NSInteger counter=[object[@"animation_counter"] integerValue];
            AstroUIMotion state={[object[@"x"] doubleValue],[object[@"y"] doubleValue],[object[@"width"] doubleValue],[object[@"height"] doubleValue],(int32_t)counter,[object[@"sprite"] shortValue]};
            _orbStates[object[@"name"]]=[NSMutableData dataWithBytes:&state length:sizeof(state)];
            // All initial UI sprites (0,1,900,998) have zero animation delay.
            _hoverDeadlines[object[@"name"]]=@(self.readTick?self.readTick():0);
        }
    }
    _targetX=0;_targetY=0;
    if([scene isEqual:@"Data B2"]){
        NSString *name=[anchor isEqual:@"Credits"]?@"CreditsMenu":anchor;
        NSDictionary *a=[self object:name];
        if(a){const AstroUIMotion *state=[_orbStates[a[@"name"]] bytes];
            astro_ui_camera(name.UTF8String,state->x,state->y,state->width,state->height,&_targetX,&_targetY);
        }
    }
    _transitioning=sameScene&&![_anchor isEqual:@"Credits"];
    if(!_transitioning&&!_deferMenuCamera){
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
            if(self.panelWorldOriginX!=0){
                _panelWorldX[object[@"name"]]=@(state->x+self.panelWorldOriginX);
                state->x=[_panelWorldX[object[@"name"]] doubleValue]-self.panelWorldOriginX;
            }
            state->y=(state->y-380)-70;
        }
    }
}
- (void)beginGameOverExit {
    _gameOverClosing=YES;ASTRO_STORE(_pressed,@"GameOverOK");
    [self changeSprite:901 object:[self object:_pressed]];
}
- (void)finishGameOverExit {
    NSArray *names=@[@"GameOverOK",@"GameOverFade"];
    NSMutableArray *remaining=[NSMutableArray array];for(NSDictionary *object in _objects)if(![names containsObject:object[@"name"]])[remaining addObject:object];ASTRO_STORE(_objects,remaining);
    [_orbStates removeObjectsForKeys:names];[_hoverDeadlines removeObjectsForKeys:names];
}
- (void)beginPauseExit {
    if(![_anchor isEqual:@"Pause"])return;
    _panelFrames=30;_panelStep=-380.0/30;_transitioning=YES;
}
- (void)reloadMenuWithRandom:(uint32_t *)seed {
    [self reloadMenuWithRandom:seed afterRandomization:nil];
}
- (void)reloadMenuWithRandom:(uint32_t *)seed afterRandomization:(void (^)(void))initializeBackground {
    _deferMenuCamera=YES;ASTRO_STORE(_objects,nil);[self show:@"Main Menu"];_deferMenuCamera=NO;
    // PUTCONTROLS initializes both registration field timers before orb RNG.
    [self resetRegistrationFields];
    for(NSDictionary *object in _objects){
        NSInteger sprite=[object[@"sprite"] integerValue];
        if(sprite==900||sprite==901)((AstroUIMotion *)[_orbStates[object[@"name"]] mutableBytes])->counter=astro_random(seed,60);
    }
    _cameraX=0;_cameraY=0;
    if(initializeBackground)initializeBackground();
    _transitioning=YES;[self finishMenuCameraMove];
}
- (void)finishMenuCameraMove {
    // MOVEMENUTO(anchor,0) samples the clock even without rendered frames.
    uint32_t previous=self.readTick?self.readTick():0;
    while(_transitioning){
        uint32_t now=self.readTick?self.readTick():0;
        if((int32_t)(now-previous)<0)continue;
        previous=self.readTick?self.readTick():0;
        [self advanceMenuCamera];
    }
}
- (BOOL)enabled:(NSDictionary *)object {
    NSString *name=object[@"name"];
    if(self.registered&&[name isEqual:@"Register"])return NO;
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

    for(int kind=1;kind<=10;kind++)for(NSDictionary *object in _objects){
        if([object[@"kind"] intValue]!=kind||![self enabled:object])continue;
        NSRect r=[self bounds:object];double pointY=y;
        if([_anchor isEqual:@"Pause"]||[_anchor isEqual:@"GameOver"]){
            const AstroUIMotion *state=[_orbStates[object[@"name"]] bytes];
            r.origin.y=state->y+_cameraY;
            if(![_anchor isEqual:@"GameOver"]||!_gameOverClosing)pointY-=70;
        }
        if(astro_ui_contains(r.origin.x,r.origin.y,r.size.width,r.size.height,x,pointY))result=object[@"name"];
    }
    return result;
}
- (double)clickPosition:(NSString *)name {
    NSDictionary *object=[self object:name];return object?[self bounds:object].origin.x/640:NAN;
}
- (void)moveMouseX:(double)x y:(double)y {ASTRO_STORE(_hover,[self hitX:x y:y]);}
- (void)pollMouseX:(double)x y:(double)y {
    for(NSDictionary *object in _objects){
        AstroUIMotion *state=[_orbStates[object[@"name"]] mutableBytes];
        if(state->sprite==902)state->sprite=900;
    }
    [self moveMouseX:x y:y];NSDictionary *object=[self object:_hover];
    if(!object||[object[@"kind"] intValue]<=8)return;
    AstroUIMotion *state=[_orbStates[object[@"name"]] mutableBytes];
    if(state->sprite!=900)return;
    [self changeSprite:902 object:object];
}
- (void)changeSprite:(int16_t)sprite object:(NSDictionary *)object {
    if(!object)return;
    AstroUIMotion *state=[_orbStates[object[@"name"]] mutableBytes];
    uint32_t tick=self.readTick?self.readTick():0;
    NSNumber *worldX=_panelWorldX[object[@"name"]];if(worldX)state->x=worldX.doubleValue;
    // Original900/901/902 all use222px images; preserve each centering operation.
    state->x=state->width/2+state->x;state->y=state->height/2+state->y;
    state->width=(state->width/222)*222;state->height=(state->height/222)*222;
    state->x=state->x-state->width/2;state->y=state->y-state->height/2;
    if(worldX){_panelWorldX[object[@"name"]]=@(state->x);state->x-=self.panelWorldOriginX;}
    state->sprite=sprite;_hoverDeadlines[object[@"name"]]=@(tick+(sprite==902?1u:0u));
}

- (void)setButton:(NSString *)name pressed:(BOOL)pressed {
    [self changeSprite:pressed?901:900 object:[self object:name]];
    ASTRO_STORE(_pressed,pressed?name:nil);
}
- (NSString *)mouseDownX:(double)x y:(double)y {
    if(_pressed||_transitioning)return nil;
    NSString *result=[_anchor isEqual:@"Credits"]?@"Yeah":[self hitX:x y:y];ASTRO_STORE(_pressed,result);ASTRO_STORE(_hover,result);
    return result;
}
- (NSString *)mouseUpX:(double)x y:(double)y {
    ASTRO_STORE(_pressed,nil);ASTRO_STORE(_hover,[self hitX:x y:y]);return nil;
}
- (void)advanceMenuCamera {
    _cameraStepX=0;_cameraStepY=0;
    if(!_transitioning||_panelFrames)return;
    _cameraStepX=(_targetX-_cameraX)/(10.0/_frameInterval);_cameraStepY=(_targetY-_cameraY)/(10.0/_frameInterval);
    _cameraX+=_cameraStepX;_cameraY+=_cameraStepY;
    if(fabs(_cameraStepX)<1&&fabs(_cameraStepY)<1){_targetX=_cameraX;_targetY=_cameraY;_transitioning=NO;ASTRO_STORE(_pressed,nil);}
}
- (void)handleSpritesAtTick:(uint32_t)tick {
    // Of the UI sprites, only902 has a nonzero next frame (900).
    for(NSDictionary *object in _objects){
        AstroUIMotion *state=[_orbStates[object[@"name"]] mutableBytes];
        if(state->sprite==902&&(int32_t)[_hoverDeadlines[object[@"name"]] unsignedIntValue]<(int32_t)tick)
            [self changeSprite:900 object:object];
    }
}
- (void)animateMenuObjects {
    for(NSDictionary *object in _objects){
        NSString *name=object[@"name"];AstroUIMotion *state=[_orbStates[name] mutableBytes];
        NSNumber *worldX=_panelWorldX[name];if(worldX)state->x=worldX.doubleValue;
        astro_ui_animate(state,_frameInterval);
        // Keep original world-space rounding while exposing screen-space UI bounds.
        if(worldX){_panelWorldX[name]=@(state->x);state->x-=self.panelWorldOriginX;}
    }
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
- (void)prepareScoreField {
    AstroUIMotion *fade=[_orbStates[@"GameOverFade"] mutableBytes];
    _scoreField=NSMakeRect(223+fade->x,185+fade->y,200,22);
}
- (BOOL)scoreFieldContainsX:(double)x y:(double)y {
    return astro_ui_contains(_scoreField.origin.x,_scoreField.origin.y,_scoreField.size.width,_scoreField.size.height,x,y-(_gameOverClosing?0:70));
}
- (void)beginScoreClock:(uint32_t)tick {astro_score_caret_begin(&_caret,tick);}
- (AstroScoreEditor *)registrationFields {return _registrationFields;}
- (void)resetRegistrationFields {
    NSDictionary *anchor=[self object:@"Register Menu"];
    double x=[anchor[@"x"] doubleValue]-320,y=[anchor[@"y"] doubleValue];
    for(unsigned i=0;i<2;i++){
        int submitted=_registrationFields[i].submitted;
        astro_score_editor_begin(&_registrationFields[i]);
        // PUTCONTROLS clears only the first field's submit flag.
        if(i)_registrationFields[i].submitted=submitted;
        _registrationBounds[i]=NSMakeRect(x,y+(i?250:195),200,22);
        astro_score_caret_begin(&_registrationCarets[i],self.readTick?self.readTick():0);
    }
}
- (NSRect)registrationFieldBounds:(unsigned)index {
    NSParameterAssert(index<2);return NSOffsetRect(_registrationBounds[index],_cameraX,_cameraY);
}
- (BOOL)selectRegistrationFieldX:(double)x y:(double)y {
    BOOL found=NO;
    for(unsigned i=0;i<2;i++){
        NSRect r=[self registrationFieldBounds:i];
        if(x<(int)r.origin.x||y<(int)r.origin.y||x>=(int)NSMaxX(r)||y>=(int)NSMaxY(r))continue;
        _activeRegistrationField=i;found=YES;AstroScoreEditor *field=&_registrationFields[i];
        NSString *text=[[[NSString alloc]initWithBytes:field->name length:strlen(field->name) encoding:NSMacOSRomanStringEncoding] autorelease];
        field->cursor=-1;int offset=(int)((int)x-r.origin.x);
        for(NSUInteger prefix=0;prefix<=text.length;prefix++)if([self textWidth:[text substringToIndex:prefix] size:20]<offset)field->cursor++;
    }
    return found;
}
- (int)editRegistrationByte:(unsigned)byte {
    double widths[]={_registrationBounds[0].size.width,_registrationBounds[1].size.width};int focus=(int)_activeRegistrationField;
    int result=astro_registration_editor_key(_registrationFields,widths,&focus,byte);_activeRegistrationField=focus;return result;
}
- (void)drawEditField:(NSRect)bounds label:(NSString *)label text:(NSString *)text cursor:(NSInteger)index
             focused:(BOOL)focused caret:(AstroScoreCaret *)caret texture:(AstroUITextureLoader)texture {
    int left=(int)bounds.origin.x,top=(int)bounds.origin.y;
    double right=left+bounds.size.width,bottom=top+bounds.size.height,shade=focused?1:.5;
    glColor4d(shade,shade,shade,1);
    glDisable(GL_TEXTURE_2D);glPolygonMode(GL_FRONT_AND_BACK,GL_LINE);glBegin(GL_QUADS);
    glVertex2d(left,top);glVertex2d(right,top);glVertex2d(right,bottom);glVertex2d(left,bottom);glEnd();glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);
    [self drawText:label x:left+2 baseline:top size:12 texture:texture];
    glColor4d(1,1,1,1);
    [self drawText:text x:left+2 baseline:top+23 size:20 texture:texture];
    if(!focused)return;
    if(self.readTick){
        uint32_t tick=self.readTick();
        if((int32_t)caret->deadline<(int32_t)tick){
            // The original toggles before sampling the reset clock.
            caret->visible=(int16_t)-caret->visible;
            caret->deadline=self.readTick()+20u;
        }
    }
    if(caret->visible==1){
        NSUInteger prefix=MIN((NSUInteger)MAX(index,0),text.length);double x=left+2+[self textWidth:[text substringToIndex:prefix] size:20];
        glDisable(GL_TEXTURE_2D);glBegin(GL_QUADS);glVertex2d(x,top+1);glVertex2d(x+1,top+1);glVertex2d(x+1,bottom-2);glVertex2d(x,bottom-2);glEnd();
    }
}
- (double)textWidth:(NSString *)text size:(double)size {
    NSData *bytes=[text dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
    const unsigned char *chars=bytes.bytes;NSArray *advance=_data[@"font"][@"advance"];double width=0;
    for(NSUInteger i=0;i<bytes.length;i++)width+=size*[advance[chars[i]] doubleValue];
    return (int)width;
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
        NSString *name=object[@"name"];const AstroUIMotion *state=[_orbStates[name] bytes];NSInteger sprite=state->sprite;
        if(sprite>=900&&sprite<=902&&[name isEqual:_pressed])sprite=901;
        sprites(sprite,r.origin.x,r.origin.y,r.size.width,r.size.height);
    }
    glColor4d(.8,.8,.8,1);
    NSDictionary *labelMap=@{@"Back":@"Back",@"Back2":@"Back",@"Back3":@"Back",@"Back4":@"Back",@"Back5":@"Back",@"Back6":@"Back",@"Back7":@"Back",@"Yeah":@"Yeah",@"SetSmooth":self.smooth?@"Graphics: Smooth":@"Graphics: Fast",@"SetKeys":@"Set Keys",@"SetSVolume":@"Sound Volume:",@"SetMVolume":@"Music Volume:",@"PauseContinue":@"Continue",@"PauseQuit":@"Quit",@"GameOverOK":@"OK",@"RegOK":@"OK"};
    for(NSDictionary *object in _objects){
        if([object[@"kind"] intValue]<9||![self enabled:object])continue;
        NSString *name=object[@"name"],*label=labelMap[name]?:name;
        if([_anchor isEqual:@"GameOver"]&&[name isEqual:@"GameOverOK"])continue;
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
        NSString *registration=_data[@"labels"][@"165"];
        if(self.registered){
            NSString *prefix=_data[@"labels"][@"223"]?:@"Registered to: ",*name=self.registeredName?:@"";
            registration=self.registrationFooterText?self.registrationFooterText(prefix,name):[prefix stringByAppendingString:name];
            if(!registration)return;
        }
        glColor4d(.8,.8,.8,1);
        [self drawText:registration x:x baseline:(int)(NSMidY(r)+215) size:10 texture:texture];
        [self drawText:_data[@"labels"][@"224"] x:x baseline:(int)(NSMidY(r)+230) size:10 texture:texture];
    }
    if([_anchor isEqual:@"Pause"]&&!_transitioning){glColor4d(1,1,1,1);[self drawText:@"Game Paused" x:220 baseline:220 size:32 texture:texture];}
    if([_anchor isEqual:@"GameOver"]&&!_transitioning&&!_gameOverClosing){double shade=self.editingHighscore>0?.5:1;glColor4d(shade,shade,shade,1);[self drawText:@"Game Over" x:240 baseline:190 size:32 texture:texture];}
    if([_anchor isEqual:@"GameOver"]){
        NSDictionary *button=[self object:@"GameOverOK"];glColor4d(.8,.8,.8,1);
        if(button)[self label:@"OK" object:button left:NO texture:texture];
    }
    if([_anchor isEqual:@"GameOver"]&&self.editingHighscore>0){
        NSRect bounds=_scoreField;bounds.origin.y+=70;
        [self drawEditField:bounds label:@"Name:" text:self.editingName?:@"" cursor:self.editingCursor focused:YES caret:&_caret texture:texture];
        [self drawText:@"Highscore!" x:240 baseline:240 size:32 texture:texture];
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
    if(![_anchor isEqual:@"Pause"]&&![_anchor isEqual:@"GameOver"]){
        for(unsigned i=0;i<2;i++){
            AstroScoreEditor *field=&_registrationFields[i];
            NSString *text=[[[NSString alloc]initWithBytes:field->name length:strlen(field->name) encoding:NSMacOSRomanStringEncoding] autorelease];
            [self drawEditField:[self registrationFieldBounds:i] label:_data[@"labels"][i?@"321":@"273"] text:text cursor:field->cursor
                       focused:_activeRegistrationField==(NSInteger)i caret:&_registrationCarets[i] texture:texture];
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
    // Original LMDRAWPICTURE leaves the map in NEAREST after a natural-size draw.
    if(natural){glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);}
    glBegin(GL_QUADS);
    glTexCoord2d(0,0);glVertex2d(x,y);glTexCoord2d(u,0);glVertex2d(x+width,y);
    glTexCoord2d(u,v);glVertex2d(x+width,y+height);glTexCoord2d(0,v);glVertex2d(x,y+height);glEnd();
}
- (NSInteger)scoreCursorAtX:(double)x {
    NSString *name=self.editingName?:@"";
    int position=(int)(x-_scoreField.origin.x);NSInteger cursor=-1;
    for(NSUInteger i=0;i<=name.length;i++)
        if([self textWidth:[name substringToIndex:i] size:20]<position)cursor++;
    return cursor;
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
    glColor4d(.7,.7,.7,1);[self drawText:text x:320-(int)[self textWidth:text size:12]/2.0 baseline:330 size:12 texture:texture];
    glColor4d(.4,.4,.4,1);NSString *prompt=_data[@"labels"][@"278"];
    [self drawText:prompt x:320-(int)[self textWidth:prompt size:10]/2.0 baseline:370 size:10 texture:texture];glColor4d(1,1,1,1);
}
- (void)drawSplashWithTexture:(AstroUITextureLoader)texture {
    NSDictionary *credits=_data[@"credits"];
    [self drawPicture:[credits[@"picture"] integerValue] x:0 y:[credits[@"picture_y"] doubleValue] width:0 height:0 texture:texture];
    for(NSDictionary *line in credits[@"lines"]){
        double size=[line[@"size"] doubleValue],brightness=[line[@"brightness"] doubleValue];NSString *text=line[@"text"];
        glColor4d(brightness,brightness,brightness,1);
        [self drawText:text x:[line[@"center_x"] doubleValue]-(int)[self textWidth:text size:size]/2.0 baseline:[line[@"baseline"] doubleValue] size:size texture:texture];
    }glColor4d(1,1,1,1);
}
- (void)drawEndingPage:(NSInteger)page texture:(AstroUITextureLoader)texture {
    NSArray *pages=_data[@"ending"];if(page<0||page>=(NSInteger)pages.count)return;
    NSString *prompt=_data[@"labels"][@"278"];
    glColor4d(.4,.4,.4,1);[self drawText:prompt x:320-(int)[self textWidth:prompt size:10]/2.0 baseline:370 size:10 texture:texture];
    NSDictionary *p=pages[page];NSString *text=p[@"text"];double size=[p[@"size"] doubleValue];
    glColor4d(.7,.7,.7,1);[self drawText:text x:[p[@"center_x"] doubleValue]-(int)[self textWidth:text size:size]/2.0 baseline:[p[@"baseline"] doubleValue] size:size texture:texture];glColor4d(1,1,1,1);
}
@end
