#include "../src/special.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#define MAX_EVENTS 5000
typedef struct {int id;double x,y,w,h;} Flash;
static AstroSpecialSpawn spawns[200];static AstroShot bullets[32];
static AstroBeam beams[MAX_EVENTS];static Flash flashes[MAX_EVENTS];
static AstroSpecialVertex vertices[MAX_EVENTS];
static int ns,nb,ne,nf,nv,kill;
static void spawn(void *c,const AstroSpecialSpawn *s){(void)c;assert(ns<200);spawns[ns++]=*s;}
static void bullet(void *c,const AstroShot *b){(void)c;assert(nb<32);bullets[nb++]=*b;}
static void beam(void *c,const AstroBeam *b,int temporary){
    (void)temporary;assert(ne<MAX_EVENTS);beams[ne++]=*b;
    if(kill&&b->target>=0)((AstroTarget *)c)[b->target].remove=-1;
}
static void flash(void *c,int id,double x,double y,double w,double h){(void)c;assert(nf<MAX_EVENTS);flashes[nf++]=(Flash){id,x,y,w,h};}
static void polygon(void *c,const AstroSpecialVertex *v,size_t count){(void)c;assert(nv+(int)count<MAX_EVENTS);for(size_t i=0;i<count;i++)vertices[nv++]=v[i];}
static void equal(double a,double b){if(fabs(a-b)>1e-10){fprintf(stderr,"expected %.17g actual %.17g\n",a,b);assert(0);}}
int main(int argc,char **argv){
    FILE *f=fopen(argc>1?argv[1]:"tests/special_vectors.csv","r");assert(f);
    char line[512];unsigned cases=0;
    while(fgets(line,sizeof(line),f)) {
        int id,n,es,eb,ee,ef,ev;unsigned expected_seed;
        assert(sscanf(line,"C,%d,%d,%u,%d,%d,%d,%d,%d",&id,&n,&expected_seed,&es,&eb,&ee,&ef,&ev)==8);
        AstroTarget targets[6];
        for(int i=0;i<6;i++) {
            double x=200+(n*13+i*37)%350,y=100+(n*7+i*17)%130,w=20+i*3,h=25+i*5;
            if(n>=20){x+=.25*(i%3);y+=.5*(i%2);}
            targets[i]=(AstroTarget){.kind=i%3==0?1:i%3==1?5:20,.parent=-1,.x=x,.y=y,.width=w,.height=h};
            if(n>=20) {
                int left=(int)x-11+i,top=(int)y+3-i;
                targets[i].width=w+20;targets[i].height=h+17;targets[i].bounds_valid=1;
                targets[i].bounds=(AstroRect){left,top,left+(int)w-7,top+(int)h+5};
            }
        }
        uint32_t seed=(uint32_t)n*123456789u;ns=nb=ne=nf=nv=0;kill=n%4==0;
        AstroSpecialContext c={.context=targets,.seed=&seed,.targets=targets,.target_count=6,.source_parent=-1,
            .gun_x=234,.gun_y=192,.frame_interval=n%3+1,.left=0,.top=0,.right=640,.bottom=380,
            .spawn=spawn,.bullet=bullet,.beam=beam,.sprite=flash,.polygon=polygon};
        AstroSpecial special={0};assert(astro_special_start(&special,id,234,192,n*17,100,&c));
        for(uint32_t t=100;special.active&&t<=131;t++) {
            astro_special_step(&special,t,&c);
            int before=ne;astro_special_step(&special,t,&c);assert(ne==before);
        }
        assert(!special.active);assert(special.action_until==(uint32_t)((id>=40?130:100)+(n%3+1)+59));assert(ns==es&&nb==eb&&ne==ee&&nf==ef&&nv==ev&&seed==expected_seed);
        for(int i=0;i<es;i++) {
            AstroSpecialSpawn e={0},*a=spawns+i;double w,h;
            assert(fgets(line,sizeof(line),f));assert(sscanf(line,"S,%d,%d,%d,%d,%d,%d,%d,%d,%lf,%lf,%lf,%lf",
                &e.kind,&e.subtype,&e.x,&e.y,&e.hit_points,&e.layer,&e.frame,&e.action_offset,&e.velocity.x,&e.velocity.y,&w,&h)==12);
            assert(e.kind==a->kind&&e.subtype==a->subtype&&e.x==a->x&&e.y==a->y&&e.hit_points==a->hit_points&&e.layer==a->layer&&e.frame==a->frame&&e.action_offset==a->action_offset);
            equal(e.velocity.x,a->velocity.x);equal(e.velocity.y,a->velocity.y);
            double original_w=a->kind==4?15:a->subtype==1?5:a->subtype==5?15:48;
            double original_h=a->kind==4?14:a->subtype==1?5:a->subtype==5?17:23;
            equal(w,a->width?a->width:original_w*a->scale);equal(h,a->height?a->height:original_h*a->scale);
        }
        for(int i=0;i<eb;i++) {
            AstroShot b;assert(fgets(line,sizeof(line),f));assert(sscanf(line,"B,%d,%d,%d,%d",&b.type,&b.heading,&b.x,&b.y)==4);
            assert(!memcmp(&b,bullets+i,sizeof(b)));
        }
        for(int i=0;i<ee;i++) {
            AstroBeam b;assert(fgets(line,sizeof(line),f));assert(sscanf(line,"E,%d,%d,%d,%d,%d,%d,%d",&b.weapon,&b.damage,&b.x,&b.y,&b.end_x,&b.end_y,&b.target)==7);
            if(memcmp(&b,beams+i,sizeof(b))) {
                fprintf(stderr,"case%d n%d beam%d expected%d,%d,%d,%d,%d,%d,%d actual%d,%d,%d,%d,%d,%d,%d\n",id,n,i,
                    b.weapon,b.damage,b.x,b.y,b.end_x,b.end_y,b.target,
                    beams[i].weapon,beams[i].damage,beams[i].x,beams[i].y,beams[i].end_x,beams[i].end_y,beams[i].target);assert(0);
            }
        }
        for(int i=0;i<ef;i++) {
            Flash e,*a=flashes+i;assert(fgets(line,sizeof(line),f));assert(sscanf(line,"F,%d,%lf,%lf,%lf,%lf",&e.id,&e.x,&e.y,&e.w,&e.h)==5);
            assert(e.id==a->id);equal(e.x,a->x);equal(e.y,a->y);equal(e.w,a->w);equal(e.h,a->h);
        }
        for(int i=0;i<ev;i++) {
            AstroSpecialVertex e,*a=vertices+i;assert(fgets(line,sizeof(line),f));assert(sscanf(line,"V,%lf,%lf,%lf,%lf,%lf,%lf",&e.x,&e.y,&e.r,&e.g,&e.b,&e.a)==6);
            equal(e.x,a->x);equal(e.y,a->y);equal(e.r,a->r);equal(e.g,a->g);equal(e.b,a->b);equal(e.a,a->a);
        }
        cases++;
    }
    fclose(f);assert(cases==48);
    uint32_t seed=0;AstroSpecial s={0};AstroSpecialContext c={.seed=&seed,.frame_interval=1,.left=0,.top=0,.right=640,.bottom=380};
    assert(!astro_special_start(&s,20,0,0,0,1,&c));assert(!astro_special_start(NULL,10,0,0,0,1,&c));
    assert(astro_special_start(&s,40,20,20,0,1,&c));assert(!astro_special_start(&s,50,20,20,0,1,&c));
    c.seed=NULL;assert(!astro_special_step(&s,1,&c));
    printf("PASS: %u original special-attack traces (all16 tiers), spawn/beam/flash/polygon/RNG, duplicate-tick and invalid-input checks\n",cases);
    return 0;
}
