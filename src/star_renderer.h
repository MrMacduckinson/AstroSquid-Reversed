#ifndef ASTROSQUID_STAR_RENDERER_H
#define ASTROSQUID_STAR_RENDERER_H
#include "scene.h"
#include <OpenGL/gl.h>
static void astro_star_point_gl(void *unused,double x,double y,double gray) {
    glColor3d(gray,gray,gray);glVertex2d(x,y);
}
static void astro_star_trail_gl(void *unused,double x,double y,double end,double gray) {
    glColor3d(gray,gray,gray);glVertex2d(x,y);glColor3d(0,0,0);glVertex2d(end,y);
}
static void astro_stars_draw_gl(const AstroStar *stars,int menu,int stage,double scroll,double scale) {
    if(!menu&&!(stage<4||stage==7))return;
    int trails=!menu&&scroll>200;
    AstroSceneSink sink={.point=astro_star_point_gl,.star_trail=astro_star_trail_gl};
    glDisable(GL_TEXTURE_2D);
    if(trails){glShadeModel(GL_SMOOTH);glLineWidth(scale);}else glPointSize(scale);
    // Preserve vertex/color order without thousands of individual GL submissions.
    glBegin(trails?GL_LINES:GL_POINTS);astro_stars_draw(stars,menu,stage,scroll,&sink);glEnd();
}
#endif
