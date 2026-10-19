#ifndef ASTROSQUID_UI_MODEL_H
#define ASTROSQUID_UI_MODEL_H
#include <stddef.h>

typedef enum {
    ASTRO_UI_NONE, ASTRO_UI_NAVIGATE, ASTRO_UI_NEW_GAME, ASTRO_UI_CONTINUE,
    ASTRO_UI_QUIT, ASTRO_UI_RESUME, ASTRO_UI_QUIT_GAME, ASTRO_UI_GAME_OVER_OK,
    ASTRO_UI_SMOOTH, ASTRO_UI_SOUND_VOLUME, ASTRO_UI_MUSIC_VOLUME,
    ASTRO_UI_KEY, ASTRO_UI_CLEAR_SCORES, ASTRO_UI_REGISTER
} AstroUIAction;
typedef struct {
    AstroUIAction action;
    const char *destination;
    int stage, section, key;
} AstroUICommand;

/* Original DOMOUSE names, including the eight paired campaign stages. */
AstroUICommand astro_ui_command(const char *name);
void astro_ui_camera(const char *anchor,double x,double y,double width,double height,
                     double *camera_x,double *camera_y);
/* Point test used by LMPOINTSPRITE: rectangular bounds, right/bottom excluded. */
int astro_ui_contains(double x,double y,double width,double height,double px,double py);
#endif
