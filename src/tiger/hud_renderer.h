#import "compat.h"
#import "ui_renderer.h"
#include "hud.h"
#include "../world_viewport.h"
@interface AstroHUDRenderer : NSObject {

    NSDictionary *_game;
    AstroUIRenderer *_ui;
AstroUISpriteDrawer _didDrawSprite;
}
@property(nonatomic,copy) AstroUISpriteDrawer didDrawSprite;
- (instancetype)initWithGame:(NSDictionary *)game ui:(AstroUIRenderer *)ui;
/* Sets full HUD projection then restores game viewport (0,30,640,380),
   ortho(0,640,379,0). Framebuffer dimensions support Retina backing pixels. */
- (void)drawState:(const AstroHUDState *)state texture:(AstroUITextureLoader)texture
    framebufferWidth:(GLsizei)width height:(GLsizei)height;
@end
