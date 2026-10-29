#include "preferences.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
static void put(unsigned char *p,unsigned v){p[0]=v>>8;p[1]=v;}
static void emit(const unsigned char *p){assert(fwrite(p,1,542,stdout)==542);}
int main(int argc,char **argv){
    assert(argc==2);unsigned char slots[512],live[542],disk[542],out[542],before[542];
    FILE *f=fopen(argv[1],"rb");assert(f&&fread(slots,1,512,f)==512&&fgetc(f)==EOF);fclose(f);
    unsigned cases=0;
    for(unsigned pattern=0;pattern<3;pattern++)for(unsigned n=0;n<=542;n++){
        for(unsigned i=0;i<542;i++)disk[i]=pattern==0?0:pattern==1?255:(i*17+31)&255;
        memset(live,0xa5,542);assert(astro_preferences_load(live,slots,slots+256,disk,n));emit(live);cases++;
    }
    for(unsigned value=0;value<65536;value++){
        for(unsigned i=0;i<542;i++)disk[i]=(i*23+value)&255;put(disk+534,value);
        assert(astro_preferences_load(live,slots,slots+256,disk,542));emit(live);
        put(live+534,value);memcpy(before,live,542);astro_preferences_save(live,out);assert(!memcmp(before,live,542));emit(out);
        astro_preferences_save(live,live);assert(!memcmp(out,live,542));cases+=2;
    }
    memset(live,0x37,542);memcpy(before,live,542);
    assert(!astro_preferences_load(live,slots,slots+256,NULL,1));assert(!memcmp(live,before,542));
    assert(!astro_preferences_load(live,slots,slots+256,disk,543));assert(!memcmp(live,before,542));
    assert(astro_preferences_load(live,slots,slots+256,NULL,0));
    fprintf(stderr,"PASS %u packed preference transactions, invalid read bounds, unchanged live save and in-place save\n",cases);return 0;
}
