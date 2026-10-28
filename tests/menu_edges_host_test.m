#import "../src/ui_renderer.h"
#include "../src/ui_model.h"
#include <assert.h>
@interface AstroUIRenderer (EdgeTest)
- (NSString *)hitX:(double)x y:(double)y;
@end
static uint64_t bits(double x){uint64_t b;memcpy(&b,&x,8);return b;}
int main(int argc,const char **argv){@autoreleasepool{
    assert(argc==3);FILE *input=fopen(argv[2],"r");assert(input);
    AstroUIRenderer *ui=nil;NSArray *objects=nil;char line[256];unsigned lastFrame=0,queries=0,states=0,profiles=0;
    while(fgets(line,sizeof(line),input)){
        unsigned profile,frame,index,p,interval;unsigned long long cx,cy;
        if(line[0]=='P'){
            assert(sscanf(line,"P,%u,%u,%llx,%llx",&profile,&interval,&cx,&cy)==4);
            assert(profile==profiles++&&interval==profile%3+1);
            ui=[[AstroUIRenderer alloc]initWithAssets:[NSString stringWithUTF8String:argv[1]] error:NULL];assert(ui);
            // The native fixture retains every raw scene node.
            ui.registered=NO;ui.unlockedLevel=16;ui.frameInterval=interval;
            double x,y;memcpy(&x,&cx,8);memcpy(&y,&cy,8);[ui setValue:@(x) forKey:@"cameraX"];[ui setValue:@(y) forKey:@"cameraY"];
            objects=[ui valueForKey:@"objects"];assert(objects.count==52);lastFrame=0;
            printf("P,%u,%u,%016llx,%016llx\n",profile,interval,bits(ui.cameraX),bits(ui.cameraY));
        }else if(line[0]=='N'){
            assert(ui&&sscanf(line,"N,%u,%u,%u",&profile,&frame,&index)==3&&index<52&&frame>=lastFrame&&frame<=60);
            while(lastFrame<frame){[ui animateMenuObjects];lastFrame++;}
            AstroUIMotion *s=[[[ui valueForKey:@"orbStates"]objectForKey:objects[index][@"name"]]mutableBytes];
            printf("N,%u,%u,%u,%d,%d,%016llx,%016llx,%016llx,%016llx\n",profile,frame,index,s->sprite,s->counter,bits(s->x),bits(s->y),bits(s->width),bits(s->height));states++;
        }else{
            int x,y,expected;assert(line[0]=='Q'&&sscanf(line,"Q,%u,%u,%u,%u,%d,%d,%d",&profile,&frame,&index,&p,&x,&y,&expected)==7);
            assert(ui&&frame==lastFrame&&index<52&&p<12);NSString *hit=[ui hitX:x y:y];int actual=-1;
            for(unsigned j=0;j<52;j++)if([hit isEqual:objects[j][@"name"]])actual=j;
            printf("Q,%u,%u,%u,%u,%d,%d,%d\n",profile,frame,index,p,x,y,actual);queries++;
        }
    }
    assert(feof(input)&&!ferror(input)&&profiles==9&&queries==342576&&states==28548);assert(!fclose(input));
}}
