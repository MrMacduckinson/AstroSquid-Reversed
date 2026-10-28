#import "hud_renderer.h"
@implementation AstroHUDRenderer {
    NSDictionary *_game;
    AstroUIRenderer *_ui;
}
- (instancetype)initWithGame:(NSDictionary *)game ui:(AstroUIRenderer *)ui {
    if((self=[super init])){_game=game;_ui=ui;}return self;
}
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture framebufferWidth:(GLsizei)width height:(GLsizei)height {
    AstroHUDCommand commands[32];size_t count=astro_hud_commands(state,commands,32);
    glMatrixMode(GL_PROJECTION);glLoadIdentity();glViewport(0,0,width,height);glOrtho(0,640,480,0,-1,1);glMatrixMode(GL_MODELVIEW);
    glEnable(GL_BLEND);glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    for(size_t i=0;i<count;i++){
        AstroHUDCommand c=commands[i];double alpha=MAX(0,MIN(1,c.a));glColor4d(c.r,c.g,c.b,alpha);
        if(c.kind==ASTRO_HUD_BOX){
            glDisable(GL_TEXTURE_2D);glBegin(GL_QUADS);glVertex2d(c.x,c.y);glVertex2d(c.x+c.width,c.y);glVertex2d(c.x+c.width,c.y+c.height);glVertex2d(c.x,c.y+c.height);glEnd();
        }else if(c.kind==ASTRO_HUD_SPRITE){
            if(self.didDrawSprite)self.didDrawSprite(c.sprite,c.x,c.y,c.width,c.height);
            NSDictionary *s=_game[@"sprites"][[NSString stringWithFormat:@"%d",c.sprite]];if(!s)continue;
            NSInteger identifier=[s[@"texture"] integerValue];NSDictionary *a=_game[@"textures"][[NSString stringWithFormat:@"%ld",(long)identifier]];
            double aw=[a[@"width"] doubleValue],ah=[a[@"height"] doubleValue];
            double u=[s[@"x"] doubleValue]/aw,v=[s[@"y"] doubleValue]/ah,du=[s[@"width"] doubleValue]/aw,dv=[s[@"height"] doubleValue]/ah;
            glEnable(GL_TEXTURE_2D);glBindTexture(GL_TEXTURE_2D,texture(identifier));
            glBegin(GL_QUADS);glTexCoord2d(u,v);glVertex2d(c.x,c.y);glTexCoord2d(u+du,v);glVertex2d(c.x+c.width,c.y);
            glTexCoord2d(u+du,v+dv);glVertex2d(c.x+c.width,c.y+c.height);glTexCoord2d(u,v+dv);glVertex2d(c.x,c.y+c.height);glEnd();
        }else{
            NSString *number=[NSString stringWithFormat:c.value>=0?@" %d":@"%d",c.value];
            NSString *text=c.kind==ASTRO_HUD_LIVES?[@"x" stringByAppendingString:number]:number;
            double x=c.x;if(c.kind==ASTRO_HUD_SCORE)x-=(int)[_ui textWidth:text size:c.height]/2.0;
            [_ui drawText:text x:x baseline:c.y size:c.height texture:texture];
        }
    }
    glColor4d(1,1,1,1);glMatrixMode(GL_PROJECTION);glLoadIdentity();
    glViewport(0,(GLint)(height*30/480),width,(GLsizei)(height*380/480));glOrtho(0,640,379,0,-1,1);glMatrixMode(GL_MODELVIEW);
}
@end
