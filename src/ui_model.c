#include "ui_model.h"
#include <stdlib.h>
#include <string.h>

AstroUICommand astro_ui_command(const char *name)
{
    static const struct {const char *name,*destination;} links[] = {
        {"Play","Play Menu"},{"Settings","Settings Menu"},{"Register","Register Menu"},
        {"Highscores","Highscores Menu"},{"Continue","Continue Menu"},{"SetKeys","Keys Menu"},
        {"Yeah","Main Menu"},{"Back","Main Menu"},{"Back2","Main Menu"},
        {"Back3","Main Menu"},{"Back4","Main Menu"},{"Back5","Main Menu"},
        {"Back6","Settings Menu"},{"Back7","Play Menu"}};
    static const struct {const char *name;AstroUIAction action;} actions[] = {
        {"New Game",ASTRO_UI_NEW_GAME},{"Quit",ASTRO_UI_QUIT},
        {"PauseContinue",ASTRO_UI_RESUME},{"PauseQuit",ASTRO_UI_QUIT_GAME},
        {"GameOverOK",ASTRO_UI_GAME_OVER_OK},{"SetSmooth",ASTRO_UI_SMOOTH},
        {"SetSVolume",ASTRO_UI_SOUND_VOLUME},{"SetMVolume",ASTRO_UI_MUSIC_VOLUME},
        {"Clear",ASTRO_UI_CLEAR_SCORES},{"RegOK",ASTRO_UI_REGISTER}};
    static const char *keys[]={"SetKeyFire","SetKeySpecial","SetKeyUp",
                               "SetKeyDown","SetKeyLeft","SetKeyRight"};
    AstroUICommand result={ASTRO_UI_NONE,0,0,0,0};
    size_t i;
    if(!name)return result;
    for(i=0;i<sizeof(links)/sizeof(*links);i++)if(!strcmp(name,links[i].name)){
        result.action=ASTRO_UI_NAVIGATE;result.destination=links[i].destination;return result;
    }
    for(i=0;i<sizeof(actions)/sizeof(*actions);i++)if(!strcmp(name,actions[i].name)){
        result.action=actions[i].action;
        if(result.action==ASTRO_UI_NEW_GAME){result.stage=1;result.section=1;}
        return result;
    }
    for(i=0;i<sizeof(keys)/sizeof(*keys);i++)if(!strcmp(name,keys[i])){
        result.action=ASTRO_UI_KEY;result.key=(int)i;return result;
    }
    if(!strncmp(name,"Level",5)){
        char *end;long level=strtol(name+5,&end,10);
        if(*end==0&&level>=1&&level<=16){
            result.action=ASTRO_UI_CONTINUE;
            result.stage=(int)((level+1)/2);result.section=level%2?1:2;
        }
    }
    return result;
}

void astro_ui_camera(const char *anchor,double x,double y,double width,double height,
                     double *camera_x,double *camera_y)
{
    double cx=320-(x+width/2),cy=240-(y+height/2);
    if(anchor){
        if(!strcmp(anchor,"Highscores Menu")){cx-=200;cy-=140;}
        else if(!strcmp(anchor,"Register Menu")){cx+=180;cy-=120;}
        else if(!strcmp(anchor,"Continue Menu")){cx-=190;cy+=120;}
    }
    if(camera_x)*camera_x=cx;
    if(camera_y)*camera_y=cy;
}

int astro_ui_contains(double x,double y,double width,double height,double px,double py)
{
    int left=(int)x,top=(int)y,right=left+(int)width,bottom=top+(int)height;
    return right>left&&bottom>top&&px>=left&&py>=top&&px<right&&py<bottom;
}

void astro_ui_animate(AstroUIMotion *s,int32_t interval) {
    if(s->sprite<900||s->sprite>902)return;
    double delta=.1*(double)interval;
    if(s->counter<31){s->x=s->x-delta;s->y=s->y-delta;s->width=delta*2+s->width;s->height=delta*2+s->height;}
    else {s->x=delta+s->x;s->y=delta+s->y;s->width=s->width-delta*2;s->height=s->height-delta*2;if(s->counter>59)s->counter=0;}
    s->counter=(int32_t)((uint32_t)s->counter+1);
}
void astro_ui_panel_step(AstroUIMotion *s,double step) {s->y=step+s->y;}

int astro_registration_valid(const unsigned char *name,size_t length,const unsigned char *code,size_t code_length){
    if(length>255||(!name&&length)||!code||code_length!=8)return 0;
    unsigned first=length?name[0]:0,second=length>1?name[1]:0,third=length>2?name[2]:0;
    unsigned penultimate=length?name[length>1?length-2:0]:0;
    unsigned p=penultimate*42%26,q=second*35%26,r=third*24%26,t=third*11%26;
    unsigned a=(length*128%26+p)%26,b=(q+a)%26,c=(q+b)%26;
    unsigned digits[]={a,(first*13%26+q)%26,(p+r)%26,b,(first*72%26+r)%26,c,(r+t)%26,(t+c)%26};
    unsigned char expected[8];for(unsigned i=0;i<8;i++)expected[i]='A'+digits[i];
    return memcmp(code,expected,8)==0;
}
