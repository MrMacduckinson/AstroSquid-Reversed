#include "../src/scene.h"
#include "../src/weapons.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned lines,sprites,points,trails;
static double total;
static void line(void *p,double x,double y,double ex,double ey,AstroLineStyle s) {
    (void)p;double v[9]={x,y,ex,ey,s.r,s.g,s.b,s.a,s.width};
    for(int j=0;j<9;j++)total+=v[j]*(lines%23+1)*(j+1);lines++;
}
static void sprite(void *p,const AstroSceneSprite *s) {
    (void)p;total+=s->sprite*31+s->persistent*37+s->alpha*41;
    for(int j=0;j<8;j++)total+=s->xy[j]*(sprites+1)*(j+1);sprites++;
}
static void point(void *p,double x,double y,double gray) {(void)p;(void)x;(void)y;assert(gray>=0&&gray<=1);points++;}
static void trail(void *p,double x,double y,double ex,double gray) {(void)p;(void)y;(void)gray;assert(ex>x);trails++;}
int main(int argc,char **argv) {
    FILE *f=fopen(argc>1?argv[1]:"tests/scene_vectors.csv","r");assert(f);
    char row[512];assert(fgets(row,sizeof(row),f));int cases=0;
    AstroSceneSink sink={NULL,line,sprite,point,trail};
    while(fgets(row,sizeof(row),f)) {
        AstroBeam beam={0};double cx,cy,expected;uint32_t seed,last;unsigned nl,ns;
        assert(sscanf(row,"%d,%d,%d,%d,%d,%lf,%lf,%u,%u,%u,%u,%lf",&beam.weapon,&beam.x,&beam.y,&beam.end_x,&beam.end_y,&cx,&cy,&seed,&nl,&ns,&last,&expected)==12);
        lines=sprites=0;total=0;
        astro_beam_render(&beam,cx,cy,0,70,640,450,&seed,&sink);
        if(lines!=nl||sprites!=ns||seed!=last||fabs(total-expected)>1e-5) {
            fprintf(stderr,"Original scene fixture mismatch case%d counts%u/%u,%u/%u sum%.17g/%.17g\n",cases,lines,nl,sprites,ns,total,expected);return 1;
        }
        cases++;
    }
    fclose(f);assert(cases==8);
    AstroStar stars[3000];memset(stars,0,sizeof(stars));uint32_t seed=123,check=123;
    astro_stars_init(stars,1,&seed);
    for(int i=0;i<12004;i++)astro_random(&check,1);
    assert(seed==check);
    for(int i=0;i<3000;i++) {assert(stars[i].brightness>=3&&stars[i].brightness<=100);assert(stars[i].x>0&&stars[i].x<=640);}
    seed=check=123;astro_stars_init(stars,0,&seed);
    for(int i=0;i<4004;i++)astro_random(&check,1);assert(seed==check);
    points=trails=0;astro_stars_draw(stars,0,1,200,&sink);assert(points==1000&&trails==0);
    points=trails=0;astro_stars_draw(stars,0,1,201,&sink);assert(points==0&&trails==1000);
    points=trails=0;astro_stars_draw(stars,0,6,1,&sink);assert(points==0&&trails==0);
    points=trails=0;astro_stars_draw(stars,1,0,0,&sink);assert(points==3000);
    for(int i=0;i<3000;i++)stars[i]=(AstroStar){50,100,200,40};
    stars[0].x=-11;stars[1].x=651;stars[2].y=59;stars[3].y=461;
    AstroParallax layer={55,66,10};
    astro_stars_move(stars,0,0,0,70,640,450,0,0,0,0,1,&seed,&layer,1,0);
    assert(stars[0].x==649&&stars[1].x==-9&&stars[2].y==459&&stars[3].y==61);
    assert(layer.x==55&&layer.y==66);
    puts("PASS:8 PowerPC beam geometry fixtures, exact star RNG initialization, wrap boundaries and render modes");
    return 0;
}
