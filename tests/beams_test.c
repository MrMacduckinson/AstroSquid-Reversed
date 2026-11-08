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
    // No targets is a valid shot, including a null pointer with zero count.
    const int emptyWeapons[]={40,41,42,43,50,51,52,53};
    for(unsigned w=0;w<8;w++)for(int heading=0;heading<360;heading++){
        AstroBeam shots[2];uint32_t seed=123;
        int n=astro_beam_shots(emptyWeapons[w],320,190,heading,1,1,-1,NULL,0,0,0,640,380,&seed,shots,NULL,NULL);
        assert(n==(w<2?1:w<4?2:0));
        for(int i=0;i<n;i++)assert(shots[i].target==-1);
    }
    char line[512];unsigned checked=0,stale_cases=0,legacy_differences=0,edge_cases=0,interval_cases=0;
    unsigned char interval_seen[8][9]={{0}};
    while(fgets(line,sizeof(line),f)) {
        long long values[20];int length=0;
        for(char *p=strtok(line,",");p;p=strtok(NULL,",")) {
            assert(length<20);values[length++]=strtoll(p,NULL,10);
        }
        int id=(int)values[0],n=(int)values[1],expected=(int)values[2],edge=n>=200;
        static const int signed_intervals[]={-32768,-3,-2,-1,0,1,2,3,32767};
        assert(n>=0||(-n-1>=0&&-n-1<9));
        int interval=n<0?signed_intervals[-n-1]:n%3+1;
        if(n<0){int family=id<=43?id-40:id-46;assert(family>=0&&family<8);assert(!interval_seen[family][-n-1]++);}
        assert(expected>=0&&expected<=2&&length==4+7*expected);
        AstroTarget targets[6];
        for(int i=0;i<6;i++) {
            double x=100+(n*13+i*37)%350,y=100+(n*7+i*17)%130,w=20+i*3,h=25+i*5;
            if(n>=100&&n<200){x+=.25*(i%3);y+=.5*(i%2);}
            if(edge){x=(n%2?-30000:30000)+i*37;y=(n%4<2?-30000:30000)+i*17;w=h=20;}
            targets[i]=(AstroTarget){.kind=i%3==0?1:i%3==1?5:20,.parent=-1,.x=x,.y=y,.width=w,.height=h};
            if(n>=100&&n<200){
                int left=(int)x-11+i,top=(int)y+3-i;
                targets[i].bounds_valid=1;targets[i].bounds=(AstroRect){left,top,left+(int)w-7,top+(int)h+5};
                targets[i].width=w+20;targets[i].height=h+17;
            }
        }
        AstroTarget legacy[6];memcpy(legacy,targets,sizeof(legacy));
        uint32_t seed=(uint32_t)n*123456789u;AstroBeam beams[2];
        int count=astro_beam_shots(id,edge?(n%2?30000:-30000):70+n%100,edge?(n%4<2?30000:-30000):110+n%100,n*17,interval,
            edge?1:n%2?1:5,-1,targets,6,0,0,640,380,&seed,beams,n%4==0?destroy_first:NULL,targets);
        assert(count==expected&&seed==(uint32_t)values[length-1]);
        for(int i=0;i<count;i++) {
            AstroBeam *b=&beams[i];int offset=3+i*7;
            int actual[7]={b->weapon,b->damage,b->x,b->y,b->end_x,b->end_y,b->target};
            for(int j=0;j<7;j++)if(actual[j]!=values[offset+j]){
                fprintf(stderr,"beam%d case%d shot%d field%d original%lld port%d\n",id,n,i,j,values[offset+j],actual[j]);exit(1);
            }
        }
        if(n>=100&&n<200) {
            for(int i=0;i<6;i++)legacy[i].bounds_valid=0;
            uint32_t old_seed=(uint32_t)n*123456789u;AstroBeam old[2];
            int old_count=astro_beam_shots(id,70+n%100,110+n%100,n*17,interval,
                n%2?1:5,-1,legacy,6,0,0,640,380,&old_seed,old,n%4==0?destroy_first:NULL,legacy);
            if(old_count!=count||old_seed!=seed||memcmp(old,beams,count*sizeof(*beams)))legacy_differences++;
            stale_cases++;
        }
        if(edge)edge_cases++;if(n<0)interval_cases++;checked++;
    }
    fclose(f);assert(checked==(edge_cases?32:interval_cases?72:160));
    if(interval_cases){assert(interval_cases==checked);for(int i=0;i<8;i++)for(int j=0;j<9;j++)assert(interval_seen[i][j]==1);}
    if(stale_cases)assert(legacy_differences>0);
    AstroTarget targets[]={{.kind=5,.parent=-1,.x=100,.y=50,.width=20,.height=20},
                          {.kind=5,.parent=-1,.x=150,.y=50,.width=20,.height=20}};
    uint32_t seed=1;AstroBeam beams[2];
    assert(astro_beam_shots(53,70,60,0,1,1,-1,targets,2,0,0,640,380,&seed,beams,
        destroy_first,targets)==1&&targets[0].remove);
    printf("PASS: %u original G5 beam captures; stale-geometry cases%u differfromlegacy%u; damage-before-chain ordering\n",checked,stale_cases,legacy_differences);
    return 0;
}
