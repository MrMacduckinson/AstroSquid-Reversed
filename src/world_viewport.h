#ifndef ASTROSQUID_WORLD_VIEWPORT_H
#define ASTROSQUID_WORLD_VIEWPORT_H
#include <OpenGL/gl.h>
static inline void astro_world_viewport(GLsizei width,GLsizei height) {
    // Round shared edges, not offset and height separately, so the HUD leaves no pixel gap.
    GLint bottom=(height*30+240)/480,top=(height*410+240)/480;
    glViewport(0,bottom,width,top-bottom);
}
#endif
