#include "ieee_exact.h"
#include "../src/physics.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc,char **argv) {
    /* Actual original INITSAGAIA conversion on G5, including raw malformed prefs. */
    static const int16_t fps_cases[][2] = {
        {-32768,0},{-61,0},{-60,-1},{-30,-2},{-2,-30},{-1,-60},
        {0,-1},{1,60},{2,30},{3,20},{7,8},{10,6},{12,5},{15,4},
        {20,3},{24,2},{25,2},{30,2},{31,1},{59,1},{60,1},
        {61,0},{120,0},{32767,0}
    };
    for(unsigned i=0;i<sizeof(fps_cases)/sizeof(fps_cases[0]);i++) {
        if(astro_frame_interval(fps_cases[i][0]) != fps_cases[i][1]) {
            fprintf(stderr,"Original frame interval mismatch for FPS %d\n",fps_cases[i][0]);return 1;
        }
    }
    puts("PASS: 24 original G5 FPS conversions, including zero and signed16 limits");
    if(argc!=3) { fprintf(stderr,"usage: physics_test vectors.csv headings.csv\n");return 2; }
    FILE *f=fopen(argv[1],"r");
    if(!f) { perror(argv[1]);return 2; }
    char header[256];
    if(!fgets(header,sizeof(header),f)) return 2;
    unsigned count=0;
    double x,y,angle,amount,friction,mx,my,sx,sy;
    while(fscanf(f,"%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf\n",&x,&y,&angle,&amount,&friction,&mx,&my,&sx,&sy)==9) {
        AstroVelocity v={x,y};
        astro_vector_make(&v,angle,amount);
        if(!ieee_exact(v.x,mx)||!ieee_exact(v.y,my)) {
            fprintf(stderr,"Original VECTORMAKE mismatch at row %u\n",count+1);return 1;
        }
        astro_vector_slow(&v,friction);
        if(!ieee_exact(v.x,sx)||!ieee_exact(v.y,sy)) {
            fprintf(stderr,"Original VECTORSLOW mismatch at row %u\n",count+1);return 1;
        }
        count++;
    }
    if(!feof(f)||count!=1000) { fprintf(stderr,"Incomplete or malformed vector file\n");return 1; }
    fclose(f);
    puts("PASS: 2000 recovered-physics results match original G5 captures (raw IEEE equality)");
    f=fopen(argv[2],"r");if(!f) {perror(argv[2]);return 2;}
    int ax,ay,aw,ah,bx,by,bw,bh,expected;count=0;
    while(fscanf(f,"%d,%d,%d,%d,%d,%d,%d,%d,%d",&ax,&ay,&aw,&ah,&bx,&by,&bw,&bh,&expected)==9) {
        if(astro_heading(ax,ay,aw,ah,bx,by,bw,bh)!=expected) {
            fprintf(stderr,"Original heading mismatch at row %u\n",count+1);return 1;
        }
        count++;
    }
    if(!feof(f)||count!=1004) return 1;
    fclose(f);puts("PASS: 1004 original G5 heading captures, including coincident centers and axes");
    return 0;
}
