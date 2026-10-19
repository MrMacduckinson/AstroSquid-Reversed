#include "beams.h"
#include "weapons.h"
#include <math.h>

static int point_target(int x,int y,const AstroTarget *targets,size_t count) {
    int result=-1;
    for(size_t i=0;i<count;i++) {
        const AstroTarget *t=&targets[i];
        if(t->kind==2||t->kind==999||t->kind==4) continue;
        AstroRect r=astro_target_rect(t);
        if(x>=r.left&&x<r.right&&y>=r.top&&y<r.bottom)result=(int)i;
    }
    return result;
}

static int nearest(int x,int y,int limit,int excluded,int kind,int parent,
                   const AstroTarget *targets,size_t count) {
    int result=-1;
    for(size_t i=0;i<count;i++) {
        const AstroTarget *t=&targets[i];
        if(!(t->kind==1||t->kind==5||(t->kind>19&&t->kind<30))||
           t->kind==kind||(int)i==parent||(int)i==excluded||t->remove) continue;
        AstroRect r=astro_target_rect(t);
        int width=r.right-r.left,height=r.bottom-r.top;
        int dx=x-(int16_t)(int)(t->x+width/2.0);
        int dy=y-(int16_t)(int)(t->y+height/2.0);
        int distance=dx*dx+dy*dy;
        if(distance<limit) {result=(int)i;limit=distance;}
    }
    return result;
}

static AstroBeam ray(int weapon,int damage,int x,int y,double dx,double dy,
                     int kind,int parent,const AstroTarget *targets,size_t count,
                     double left,double top,double right,double bottom,int exclude_parent) {
    double px=x,py=y;int target=-1;
    while(px<right&&px>left&&py<bottom&&py>top&&target<0) {
        px+=dx;py+=dy;
        target=point_target((int16_t)(int)px,(int16_t)(int)py,targets,count);
        if(target>=0&&(targets[target].kind==40||targets[target].kind==kind||
            (exclude_parent&&target==parent))) target=-1;
    }
    return (AstroBeam){weapon,damage,x,y,(int)px,(int)py,target};
}

int astro_beam_shots(int weapon,int x,int y,int heading,int interval,
                    int kind,int parent,const AstroTarget *targets,size_t count,
                    double left,double top,double right,double bottom,uint32_t *seed,AstroBeam out[2],
                    void (*hit)(void *,const AstroBeam *),void *context) {
    if(!out||(!targets&&count)||!seed||interval<1||left>=right||top>=bottom) return -1;
    if(weapon>=50&&weapon<=53) {
        x-=10;y++;
        int target=nearest(x,y,90000,-1,kind,parent,targets,count);
        if(target<0) return 0;
        const AstroTarget *t=&targets[target];
        AstroRect r=astro_target_rect(t);int width=r.right-r.left,height=r.bottom-r.top;
        double ex=t->x+width/4.0+astro_random(seed,(int)(width/2.0));
        double ey=t->y+height/4.0+astro_random(seed,(int)(height/2.0));
        int distance=(int)((x-ex)*(x-ex)+(y-ey)*(y-ey));
        weapon-=distance>62500?3:distance>40000?2:distance>22500?1:0;
        if(weapon<50) return 0;
        out[0]=(AstroBeam){weapon,weapon-49,x,y,(int)ex,(int)ey,target};
        if(hit) hit(context,&out[0]);
        if(weapon>50&&!targets[target].remove) {
            int second=nearest((int)ex,(int)ey,6400,target,kind,parent,targets,count);
            if(second>=0) {
                const AstroTarget *u=&targets[second];
                AstroRect r=astro_target_rect(u);int w=r.right-r.left,h=r.bottom-r.top;
                out[1]=(AstroBeam){weapon-1,weapon-49,(int)ex,(int)ey,
                    (int)(u->x+w/2.0),(int)(u->y+h/2.0),second};
                if(hit) hit(context,&out[1]);return 2;
            }
        }
        return 1;
    }
    if(weapon<40||weapon>43) return -1;
    double radians=3.14159265358979323846*(heading/180.0);
    double dx=10*cos(radians),dy=-10*sin(radians);
    if(weapon<42) {
        out[0]=ray(weapon,(int)((weapon==40?1.5:3)*interval),x+2,y+1,dx,dy,
                   kind,parent,targets,count,left,top,right,bottom,1);
        if(hit) hit(context,&out[0]);return 1;
    }
    int start_x=weapon==42?x+2:x-3;
    int y1=weapon==42?y-3:y-7,y2=weapon==42?y+4:y+9;
    int damage=(int)(4.5*interval);
    out[0]=ray(weapon,damage,start_x,y1,dx,dy,kind,parent,targets,count,left,top,right,bottom,0);
    if(hit) hit(context,&out[0]);
    out[1]=ray(weapon,damage,start_x,y2,dx,dy,kind,parent,targets,count,left,top,right,bottom,0);
    if(hit) hit(context,&out[1]);
    return 2;
}
