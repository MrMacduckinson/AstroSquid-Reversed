#include "../src/weapons.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "weapon_definitions.h"

int main(int argc,char **argv) {
    assert(argc==2);
    FILE *f=fopen(argv[1],"r");assert(f);
    char line[1024];unsigned checked=0;
    while(fgets(line,sizeof(line),f)) {
        long long values[32];int n=0;
        for(char *p=strtok(line,",");p;p=strtok(NULL,",")) {
            assert(n<32);values[n++]=strtoll(p,NULL,10);
        }
        assert(n>=7);
        const AstroWeapon *weapon=NULL;
        for(unsigned i=0;i<sizeof(definitions)/sizeof(definitions[0]);i++)
            if(definitions[i].id==values[0]) weapon=&definitions[i].weapon;
        assert(weapon);
        uint32_t seed=(uint32_t)values[1];AstroShot shots[6];
        int count=astro_weapon_shots(weapon,(int)values[2],(int)values[3],(int)values[4],&seed,shots);
        assert(count==values[5]&&n==7+count*4);
        for(int i=0;i<count;i++) {
            int offset=6+i*4;
            assert(shots[i].type==values[offset]&&shots[i].x==values[offset+1]&&
                   shots[i].y==values[offset+2]&&shots[i].heading==values[offset+3]);
        }
        assert(seed==(uint32_t)values[n-1]);checked++;
    }
    fclose(f);assert(checked==140);
    AstroShot out[6];AstroWeapon bad={.pattern=13};
    assert(astro_weapon_shots(&bad,0,0,0,NULL,out)==-1);
    bad.pattern=7;assert(astro_weapon_shots(&bad,0,0,0,NULL,out)==-1);
    printf("PASS: %u original G5 weapon captures, projectile arguments and RNG states\n",checked);
    return 0;
}
