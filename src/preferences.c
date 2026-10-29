#include "preferences.h"
#include <string.h>
static unsigned word(const uint8_t *p){return (unsigned)p[0]*256+p[1];}
static void put(uint8_t *p,unsigned n){p[0]=(uint8_t)(n>>8);p[1]=(uint8_t)n;}
int astro_preferences_load(uint8_t live[ASTRO_PREFS_SIZE],const uint8_t name[256],
                           const uint8_t code[256],const void *disk,size_t length){
    if(length>ASTRO_PREFS_SIZE||(!disk&&length))return 0;
    put(live,1);put(live+2,60);put(live+4,10);put(live+6,6);
    /* FBSetPascalStr copies words, including the next byte for even lengths. */
    memcpy(live+ASTRO_PREFS_NAME,name,2+2*(name[0]/2));
    memcpy(live+ASTRO_PREFS_CODE,code,2+2*(code[0]/2));
    const unsigned keys[]={48,61,121,122,123,124};
    for(unsigned i=0;i<6;i++)put(live+ASTRO_PREFS_KEYS+i*2,keys[i]);
    put(live+ASTRO_PREFS_LEVEL,1);put(live+ASTRO_PREFS_FILTER,1);
    if(length)memmove(live,disk,length);
    unsigned bits=(word(live+ASTRO_PREFS_LEVEL)-100u)&65535u;
    int level=bits<32768u?(int)bits:(int)bits-65536;
    put(live+ASTRO_PREFS_LEVEL,level<1?1u:bits);return 1;
}
void astro_preferences_save(const uint8_t live[ASTRO_PREFS_SIZE],uint8_t disk[ASTRO_PREFS_SIZE]){
    memmove(disk,live,ASTRO_PREFS_SIZE);
    put(disk+ASTRO_PREFS_LEVEL,word(disk+ASTRO_PREFS_LEVEL)+100u);
}
