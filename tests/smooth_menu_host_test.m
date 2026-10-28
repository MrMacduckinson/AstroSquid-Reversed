#define main astrosquid_application_main
#include "../src/preview.m"
#undef main
#import <CommonCrypto/CommonDigest.h>
#include "smooth_maps.h"
static unsigned sample,reads;static BOOL observing;static NSDictionary *digests;
static NSData *digest(GLuint texture){
 glBindTexture(GL_TEXTURE_2D,texture);GLint w,h;glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_WIDTH,&w);glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_HEIGHT,&h);assert(w>0&&h>0&&w<=4096&&h<=4096);
 NSMutableData *pixels=[NSMutableData dataWithLength:(NSUInteger)w*h*4];glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_UNSIGNED_BYTE,pixels.mutableBytes);unsigned char hash[CC_SHA256_DIGEST_LENGTH];CC_SHA256(pixels.bytes,(CC_LONG)pixels.length,hash);return [NSData dataWithBytes:hash length:sizeof(hash)];
}
@interface SmoothAudio:AstroAudio
@end
@implementation SmoothAudio
- (BOOL)playCue:(NSString *)name position:(double)p {assert([name isEqual:@"Click"]);if(observing){uint64_t b;memcpy(&b,&p,8);printf("P,%u,%016llx\n",sample,b);}return YES;}
- (void)stop {}
@end
@interface SmoothView:AstroView
- (void)checkSmooth;
@end
@implementation SmoothView
- (BOOL)appendDebugMessage:(NSString *)message {return YES;}
- (uint32_t)currentGameTick {if(!observing)return 100;uint32_t t=100+reads++;printf("T,%u,%u\n",sample,t);return t;}
- (void)setMenuCursor:(int)value {if(observing){assert(value==4||value==0);printf("C,%u,%d\n",sample,value);}}
- (void)display {assert(!observing);}
- (void)killSpriteMap:(NSInteger)identifier {
 GLuint old=[textures[@(identifier)]unsignedIntValue];if(observing&&old){AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"SetSmooth"]mutableBytes];printf("D,%u,%ld,%d,%d\n",sample,(long)identifier,s->sprite,ui.smooth);}
 [super killSpriteMap:identifier];if(observing){assert(!textures[@(identifier)]);if(old)assert(!glIsTexture(old));}
}
- (GLuint)texture:(NSInteger)identifier {
 GLuint value=[super texture:identifier];if(observing){
  AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"SetSmooth"]mutableBytes];printf("L,%u,%ld,%d,%d,%d\n",sample,(long)identifier,value!=0,s->sprite,ui.smooth);
  if(value){glBindTexture(GL_TEXTURE_2D,value);GLint min,mag;glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,&min);glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,&mag);assert(min==(ui.smooth?GL_LINEAR:GL_NEAREST)&&mag==min);assert([digest(value)isEqual:digests[@(identifier)]]);}
 }return value;
}
- (void)checkSmooth {
 [timer invalidate];timer=nil;[audio stop];audio=[SmoothAudio new];splashVisible=NO;[[self openGLContext]makeCurrentContext];[self preloadSpriteMaps];assert(textures.count==54);
 NSMutableDictionary *baseline=[NSMutableDictionary dictionary];for(unsigned i=0;i<sizeof(smooth_map_ids)/sizeof(*smooth_map_ids);i++){NSNumber *key=@(smooth_map_ids[i]);assert(textures[key]);baseline[key]=digest([textures[key]unsignedIntValue]);}digests=baseline;
 [ui show:@"Settings Menu"];[ui animateTicks:120];[ui setValue:@0 forKey:@"cameraX"];[ui setValue:@0 forKey:@"cameraY"];
 for(sample=0;sample<2;sample++){
  AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:@"SetSmooth"]mutableBytes];assert(s);*s=(AstroUIMotion){381,222,65,65,0,900};ui.smooth=sample;reads=0;observing=YES;[self performMenuAction:@"SetSmooth"];observing=NO;
  uint32_t d=[[[ui valueForKey:@"hoverDeadlines"]objectForKey:@"SetSmooth"]unsignedIntValue];printf("Z,%u,%d,%d,%u,%u\n",sample,ui.smooth,s->sprite,d,reads);assert(reads==2&&textures.count==54&&spriteMapsPreloaded&&![[ui valueForKey:@"pressed"]length]&&glGetError()==GL_NO_ERROR);
 }
 [self releaseGraphics];[audio stop];assert(!textures.count);fputs("PASS real GL deletes/reloads,54 unchanged texture digests each toggle,filters and cleanup\n",stderr);
}
@end
int main(int argc,const char **argv){@autoreleasepool{
 assert(argc==2);[NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];[[NSUserDefaults standardUserDefaults]setVolatileDomain:@{@"AstroSquidSettings":@{@"smooth":@NO,@"sound":@0,@"music":@0}}forName:NSArgumentDomain];SmoothView *v=[[SmoothView alloc]initWithFrame:NSMakeRect(0,0,640,480) assets:[NSString stringWithUTF8String:argv[1]]];assert(v);[v checkSmooth];
}}
