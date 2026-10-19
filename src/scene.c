#include "scene.h"
#include "weapons.h"
#include <math.h>
#include "ppc_math.h"

void astro_stars_init(AstroStar stars[3000],int menu,uint32_t *seed) {
    int split=menu?2199:699,total=menu?3000:1000;
    // Both original loops include the split entry: overwrite it and retain its RNG draws.
    for(int phase=0;phase<2;phase++) for(int i=phase?split:0;i<(phase?total:split+1);i++) {
        stars[i].brightness=astro_random(seed,50)+(phase?50:menu?2:0);
        stars[i].x=astro_random(seed,640);
        stars[i].y=astro_random(seed,menu?480:380)+(menu?0:70);
        stars[i].speed=astro_random(seed,phase?(menu?100:70):30);
    }
}
void astro_stars_move(AstroStar stars[3000],double cx,double cy,
                      double left,double top,double right,double bottom,
                      double sx,double sy,double ix,double iy,int interval,uint32_t *seed,
                      AstroParallax *layers,size_t count,int menu) {
    double l=cx+left-10,r=cx+right+10,t=cy+top-10,b=cy+bottom+10;
    double dx=(-ix*interval*.5+sx*interval*.5)*.005;
    double dy=(-iy*interval*.5+sy*interval*.5)*.005;
    for(int i=0;i<3000;i++) {
        AstroStar *s=&stars[i];s->x-=dx*s->speed;s->y-=dy*s->speed;
        if(s->x<l) {s->x=(s->x-l)+r;s->y=t+astro_random(seed,astro_ppc_i32(b-t));}
        if(s->x>r) {s->x=(s->x-r)+l;s->y=t+astro_random(seed,astro_ppc_i32(b-t));}
        if(s->y<t) {s->y=(s->y-t)+b;s->x=l+astro_random(seed,astro_ppc_i32(r-l));}
        if(s->y>b) {s->y=(s->y-b)+t;s->x=l+astro_random(seed,astro_ppc_i32(r-l));}
    }
    if(!menu) for(size_t i=0;i<count;i++) if(layers[i].depth) {
        layers[i].x=sx+(layers[i].x-dx*layers[i].depth);
        layers[i].y=sy+(layers[i].y-dy*layers[i].depth);
    }
}
void astro_stars_draw(const AstroStar stars[3000],int menu,int stage,double sx,const AstroSceneSink *sink) {
    if(!menu&&!(stage<4||stage==7)) return;
    int total=menu?3000:1000;
    for(int i=0;i<total;i++) {
        const AstroStar *s=&stars[i];double gray=s->brightness/100;
        if(!menu&&sx>200) {if(sink->star_trail)sink->star_trail(sink->context,s->x,s->y,s->x+s->speed*3,gray);}
        else if(sink->point) sink->point(sink->context,s->x,s->y,gray);
    }
}
static void line(const AstroSceneSink *sink,double x,double y,double ex,double ey,AstroLineStyle style) {
    if(sink->line)sink->line(sink->context,x,y,ex,ey,style);
}
static void sprite(const AstroSceneSink *sink,int id,double x,double y,double w,double h,double angle,
                   double pivot_x,double pivot_y,double alpha,int persistent,double camera_x,double camera_y) {
    if(!sink->sprite)return;
    x=(x-camera_x)+camera_x;y=(y-camera_y)+camera_y;
    AstroSceneSprite s={0};s.sprite=id;s.alpha=alpha;s.persistent=persistent;
    s.rect[0]=x;s.rect[1]=y;s.rect[2]=w;s.rect[3]=h;s.angle=angle;s.pivot_x=pivot_x;s.pivot_y=pivot_y;
    double c=astro_ppc_cos(angle*3.14159265358979323846/180),sn=astro_ppc_sin(angle*3.14159265358979323846/180);
    double xx[4]={x,x+w,x+w,x},yy[4]={y,y,y+h,y+h};
    for(int i=0;i<4;i++) {s.xy[2*i]=pivot_x+xx[i]*c-yy[i]*sn;s.xy[2*i+1]=pivot_y+xx[i]*sn+yy[i]*c;}
    sink->sprite(sink->context,&s);
}
static void glow(const AstroSceneSink *sink,int id,double x,double y,double size,double cx,double cy) {
    sprite(sink,id,x-size/2,y-size/2,size,size,0,0,0,1,0,cx,cy);
}
void astro_beam_render(const AstroBeam *beam,double cx,double cy,double left,double top,
                       double right,double bottom,uint32_t *seed,const AstroSceneSink *sink) {
    if(!beam||!sink||!seed)return;
    int w=beam->weapon,x=astro_ppc_i32(cx+beam->x),y=astro_ppc_i32(cy+beam->y);
    int ex=astro_ppc_i32(cx+beam->end_x),ey=astro_ppc_i32(cy+beam->end_y);
    if(w>=40&&w<=43) {
        double width=w==40?2:w==43?6:3;
        if(x==ex||y==ey) line(sink,x,y,ex,ey,(AstroLineStyle){1,0,0,.7,width});
        else for(int i=(int)(-width*2);i<=(int)(width*2);i++) {
            double d=i/3.5;line(sink,x+d,y+d,ex+d,ey+d,(AstroLineStyle){1,0,0,.25,1});
        }
        sprite(sink,88,x-20+(w==40?5:0),y-22+(w==40?5:0),w==40?29:39,w==40?31:41,0,0,0,1,0,cx,cy);
        if(beam->end_x<right-5&&beam->end_x>left+5&&beam->end_y<bottom-5&&beam->end_y>top+5)
            sprite(sink,w==43?89:90,ex-20,ey-20,39,41,0,0,0,1,1,cx,cy);
        return;
    }
    if(w<50||w>53)return;
    double dx=(double)x-ex,dy=(double)y-ey;
    double distance=sqrt(dy*dy+dx*dx);
    int16_t segments=(int16_t)astro_ppc_i32(trunc(distance/((w-50)*3+12)));
    int passes=w==50?2:w==53?3:w-49;
    for(int pass=1;pass<=passes;pass++) {
        AstroLineStyle style={.7,.7,1,.4,1};int thickness=1;
        int jitter=(pass+w-50)*4+12;
        if(pass==2) {jitter=(w-49)*4+8;style=(AstroLineStyle){1,1,.6,.5,2};thickness=2;}
        double tail_x=astro_random(seed,jitter*3)-1.5*jitter;
        double tail_y=astro_random(seed,jitter*3)-1.5*jitter;
        int16_t px=(int16_t)x,py=(int16_t)y;
        /* Original FB loop is post-tested, including wrapped negative counts. */
        int limit=segments+3;
        for(int i=1;i<=(limit<1?1:limit);i++) {
            int16_t nx=(int16_t)astro_ppc_i32(astro_random(seed,jitter)+(segments?(double)(int32_t)((uint32_t)ex-(uint32_t)x)/segments*i:0)+x-jitter/2.0);
            int16_t ny=(int16_t)astro_ppc_i32(astro_random(seed,jitter)+(segments?(double)(int32_t)((uint32_t)ey-(uint32_t)y)/segments*i:0)+y-jitter/2.0);
            if(i>segments) {
                nx=(int16_t)astro_ppc_i32(astro_random(seed,10)+(tail_x*((i-segments)/3.0)+ex-5));
                ny=(int16_t)astro_ppc_i32(astro_random(seed,10)+(tail_y*((i-segments)/3.0)+ey-5));
            }
            for(int j=-thickness;j<=thickness;j++) {
                double d=j/3.0;line(sink,px+d,py+d,nx+d,ny+d,style);
            }
            px=nx;py=ny;
        }
    }
    int size=(int)(((w-49)*4+12)*.4);
    /* PPC invalid0/0 produces a positive quietNaN; Intel produces negative. */
    double slope=distance==0?NAN:dy/distance;
    double angle=(astro_ppc_asin(slope)/3.14159265358979323846)*180;
    if((int32_t)((uint32_t)x-(uint32_t)ex)>0)angle=180-angle;
    sprite(sink,116,0,-size*2,distance,size*4,-angle,x,y,.5,0,cx,cy);
    glow(sink,115,x,y,25+(w-50)*3,cx,cy);
    glow(sink,115,x,y,35+(w-50)*6,cx,cy);
    glow(sink,115,ex,ey,25*((astro_random(seed,10)+5)/10.0)+(w-50)*10,cx,cy);
    glow(sink,115,ex,ey,45*((astro_random(seed,10)+5)/10.0)+(w-50)*6,cx,cy);
}
