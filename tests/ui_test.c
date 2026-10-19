#include "../src/ui_model.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
int main(void){
    AstroUICommand c=astro_ui_command("Play");double x,y;
    assert(c.action==ASTRO_UI_NAVIGATE&&!strcmp(c.destination,"Play Menu"));
    c=astro_ui_command("Back6");assert(!strcmp(c.destination,"Settings Menu"));
    c=astro_ui_command("Level1");assert(c.stage==1&&c.section==1);
    c=astro_ui_command("Level2");assert(c.stage==1&&c.section==2);
    c=astro_ui_command("Level15");assert(c.stage==8&&c.section==1);
    c=astro_ui_command("Level16");assert(c.stage==8&&c.section==2);
    assert(astro_ui_command("Level17").action==ASTRO_UI_NONE);
    assert(astro_ui_command("Level2junk").action==ASTRO_UI_NONE);
    assert(astro_ui_command(NULL).action==ASTRO_UI_NONE);
    assert(astro_ui_command("SetKeyRight").key==5);
    astro_ui_camera("Main Menu",796,460.5,247,247,&x,&y);
    assert(x==-599.5&&y==-344);
    astro_ui_camera("Continue Menu",1188,-870,166,169,&x,&y);
    assert(x==-1141&&y==1145.5);
    assert(astro_ui_contains(10,20,30,40,10,20));
    assert(!astro_ui_contains(10,20,30,40,40,20));
    puts("PASS original menu actions, paired level selection, camera and hit bounds");
}
