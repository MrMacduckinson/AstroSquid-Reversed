#include "../src/beams.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void destroy_first(void *context,const AstroBeam *beam) {
    AstroTarget *targets=context;if(beam->target>=0) targets[beam->target].remove=-1;
}
int main(int argc,char **argv) {
    assert(argc==2);FILE *f=fopen(argv[1],"r");assert(f);
    char line[512];unsigned checked=0;
    while(fgets(line,sizeof(line),f)) {
        long long values[20];int length=0;
        for(char *p=strtok(line,",");p;p=strtok(NULL,",")) {
            assert(length<20);values[length++]=strtoll(p,NULL,10);
        }
        int id=(int)values[0],n=(int)values[1],expected=(int)values[2];
        assert(expected>=0&&expected<=2&&length==4+7*expected);
        AstroTarget targets[6];
        for(int i=0;i<6;i++) targets[i]=(AstroTarget){i%3==0?1:i%3==1?5:20,-1,0,
            100+(n*13+i*37)%350,100+(n*7+i*17)%130,20+i*3,25+i*5};
        uint32_t seed=(uint32_t)n*123456789u;AstroBeam beams[2];
        int count=astro_beam_shots(id,70+n%100,110+n%100,n*17,n%3+1,
            n%2?1:5,-1,targets,6,0,0,640,380,&seed,beams,n%4==0?destroy_first:NULL,targets);
        assert(count==expected&&seed==(uint32_t)values[length-1]);
        for(int i=0;i<count;i++) {
            AstroBeam *b=&beams[i];int offset=3+i*7;
            assert(b->weapon==values[offset]&&b->damage==values[offset+1]&&
                   b->x==values[offset+2]&&b->y==values[offset+3]&&
                   b->end_x==values[offset+4]&&b->end_y==values[offset+5]&&
                   b->target==values[offset+6]);
        }
        checked++;
    }
    fclose(f);assert(checked==160);
    AstroTarget targets[]={{5,-1,0,100,50,20,20},{5,-1,0,150,50,20,20}};
    uint32_t seed=1;AstroBeam beams[2];
    assert(astro_beam_shots(53,70,60,0,1,1,-1,targets,2,0,0,640,380,&seed,beams,
        destroy_first,targets)==1&&targets[0].remove);
    printf("PASS: %u original G5 beam captures; damage-before-chain ordering\n",checked);
    return 0;
}
