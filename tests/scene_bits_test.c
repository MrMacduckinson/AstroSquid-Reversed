/* Replay original CPU command bits; GPU-generated transformed quads are separate. */
#include "../src/scene.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static FILE *reference;
static unsigned lines,sprites,case_number;
static char row[1024];
static char *token(void){char *t=strtok(NULL,",");assert(t);return t;}
static double from_hex(const char *text){uint64_t u=strtoull(text,NULL,16);double d;memcpy(&d,&u,8);return d;}
static void equal_word(double value,const char *text,int field){
    uint64_t actual,expected=strtoull(text,NULL,16);memcpy(&actual,&value,8);
    if(actual!=expected){fprintf(stderr,"scene case%u field%d expected%016llx actual%016llx\n",case_number,field,(unsigned long long)expected,(unsigned long long)actual);exit(1);}
}
static void begin(char kind){assert(fgets(row,sizeof(row),reference));assert(strtok(row,",")[0]==kind);}
static void line(void *context,double x,double y,double ex,double ey,AstroLineStyle style){
    (void)context;begin('L');double values[9]={x,y,ex,ey,style.r,style.g,style.b,style.a,style.width};
    for(int j=0;j<9;j++)equal_word(values[j],token(),j);lines++;
}
static void sprite(void *context,const AstroSceneSprite *s){
    (void)context;begin('S');assert(s->sprite==atoi(token()));assert(s->persistent==atoi(token()));
    double fields[8]={s->rect[0],s->rect[1],s->rect[2],s->rect[3],s->angle,s->pivot_x,s->pivot_y,s->alpha};
    for(int j=0;j<8;j++)equal_word(fields[j],token(),j);sprites++;
}
int main(int argc,char **argv){
    assert(argc==2);reference=fopen(argv[1],"r");assert(reference);
    AstroSceneSink sink={.line=line,.sprite=sprite};
    while(fgets(row,sizeof(row),reference)){
        assert(strtok(row,",")[0]=='C');AstroBeam beam={0};
        beam.weapon=atoi(token());beam.x=atoi(token());beam.y=atoi(token());beam.end_x=atoi(token());beam.end_y=atoi(token());
        double cx=from_hex(token()),cy=from_hex(token());uint32_t seed=(uint32_t)strtoul(token(),NULL,10);
        unsigned expected_lines=(unsigned)strtoul(token(),NULL,10),expected_sprites=(unsigned)strtoul(token(),NULL,10);
        uint32_t final=(uint32_t)strtoul(token(),NULL,10);lines=sprites=0;
        astro_beam_render(&beam,cx,cy,0,70,640,450,&seed,&sink);
        assert(lines==expected_lines&&sprites==expected_sprites&&seed==final);case_number++;
    }
    assert(feof(reference));fclose(reference);assert(case_number==49);
    printf("PASS:%u original beam CPU command traces: every IEEE word, event order and RNG exact, including zero/short beams\n",case_number);return 0;
}
