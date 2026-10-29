#ifndef ASTRO_PREFERENCES_H
#define ASTRO_PREFERENCES_H
#include <stddef.h>
#include <stdint.h>
enum { ASTRO_PREFS_SIZE=542, ASTRO_PREFS_NAME=10, ASTRO_PREFS_CODE=266,
       ASTRO_PREFS_KEYS=522, ASTRO_PREFS_LEVEL=534, ASTRO_PREFS_FILTER=536 };
/* Caller supplies live bytes and separate disk input; unused bytes survive short reads. */
int astro_preferences_load(uint8_t live[ASTRO_PREFS_SIZE],const uint8_t name[256],
                           const uint8_t code[256],const void *disk,size_t length);
void astro_preferences_save(const uint8_t live[ASTRO_PREFS_SIZE],uint8_t disk[ASTRO_PREFS_SIZE]);
#endif
