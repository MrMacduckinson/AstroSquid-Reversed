#include "../src/physics.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc,char **argv) {
    if(argc!=2) { fprintf(stderr,"usage: physics_test vectors.csv\n");return 2; }
    FILE *f=fopen(argv[1],"r");
    if(!f) { perror(argv[1]);return 2; }
    char header[256];
    if(!fgets(header,sizeof(header),f)) return 2;
    unsigned count=0;
    double x,y,angle,amount,friction,mx,my,sx,sy;
    while(fscanf(f,"%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf\n",&x,&y,&angle,&amount,&friction,&mx,&my,&sx,&sy)==9) {
        AstroVelocity v={x,y};
        astro_vector_make(&v,angle,amount);
        if(fabs(v.x-mx)>1e-10 || fabs(v.y-my)>1e-10) {
            fprintf(stderr,"Original VECTORMAKE mismatch at row %u\n",count+1);return 1;
        }
        astro_vector_slow(&v,friction);
        if(fabs(v.x-sx)>1e-10 || fabs(v.y-sy)>1e-10) {
            fprintf(stderr,"Original VECTORSLOW mismatch at row %u\n",count+1);return 1;
        }
        count++;
    }
    if(!feof(f)||count!=1000) { fprintf(stderr,"Incomplete or malformed vector file\n");return 1; }
    fclose(f);
    puts("PASS: 2000 recovered-physics results match original G5 captures (tolerance 1e-10)");
    return 0;
}
