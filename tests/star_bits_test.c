/* Full original MOVESTARS words, not a weighted checksum or float tolerance. */
#include "../src/scene.h"
#include "../src/weapons.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void equal(FILE *f,double value,int trial,int star,int field){
    unsigned long long word;assert(fscanf(f,"%llx",&word)==1);uint64_t actual;memcpy(&actual,&value,8);
    if(actual!=(uint64_t)word){fprintf(stderr,"star trial%d index%d field%d native%016llx port%016llx\n",trial,star,field,word,(unsigned long long)actual);exit(1);}
}
int main(int argc,char **argv){
    assert(argc==2);FILE*f=fopen(argv[1],"r");assert(f);uint32_t seed=0x12345678,fixture=0x98765432;
    AstroStar stars[3000];
    for(int trial=0;trial<4;trial++){
        char tag;int index;unsigned final;assert(fscanf(f," %c %d %u",&tag,&index,&final)==3&&tag=='C'&&index==trial);
        double cx=trial%3*33.3,cy=trial%5*-17.3,l=-cx,t=70-cy,r=640-cx,b=450-cy;
        double sx=(trial%20-10)*33.333,sy=(trial%9-4)*8.888,ix=trial%2?0:12,iy=trial%3?7:0;
        for(int i=0;i<3000;i++){
            stars[i].brightness=astro_random(&fixture,100);stars[i].x=astro_random(&fixture,2000)-700;
            stars[i].y=astro_random(&fixture,1200)-400;stars[i].speed=astro_random(&fixture,100);
        }
        AstroParallax layers[3]={{55,66,10},{777,888,0},{91,92,-5}};
        astro_stars_move(stars,cx,cy,l,t,r,b,sx,sy,ix,iy,trial%5+1,&seed,layers,3,trial%2);
        assert(seed==final);
        for(int i=0;i<3000;i++){
            double values[4]={stars[i].brightness,stars[i].x,stars[i].y,stars[i].speed};
            for(int j=0;j<4;j++)equal(f,values[j],trial,i,j);
        }
        for(int i=0;i<3;i++){equal(f,layers[i].x,trial,3000+i,0);equal(f,layers[i].y,trial,3000+i,1);}
    }
    char extra;assert(fscanf(f," %c",&extra)==EOF);fclose(f);
    puts("PASS:12000 original MOVESTARS results: all48000 IEEE words, parallax and RNG exact");return 0;
}
