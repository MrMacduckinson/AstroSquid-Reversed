/* Isolated original FIREWEAPONSPECIAL. Only external world/render/creation calls
 * are captured; special code, math, RNG, target lookup and scaling are original. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/special.h"
extern uint32_t invoke5(void *,void *,void *,void *,void *,void *,void *,void *);
__asm__(
".text\n.align 2\n.globl _invoke5\n_invoke5:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\n"
"stmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r3,r6\nmr r4,r7\nmr r5,r8\nmr r6,r9\nmr r7,r10\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\n"
"lmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
#define MAX_EVENTS 5000
static unsigned char entities[200][128],renders[200][312],world[6][128],beam_marker[128];
static AstroSpecialSpawn port_spawns[200];
static AstroBeam native_beams[MAX_EVENTS],port_beams[MAX_EVENTS];
static AstroShot native_bullets[32],port_bullets[32];
static int nspawn,pspawn,nbeam,pbeam,nbullet,pbullet,nflash,pflash,nvertex,pvertex;
typedef struct {int id;double x,y,w,h;} Flash;
static Flash native_flashes[MAX_EVENTS],port_flashes[MAX_EVENTS];
static AstroSpecialVertex native_vertices[MAX_EVENTS],port_vertices[MAX_EVENTS];
static double cr,cg,cb,ca;
static void capture_color(double r,double g,double b,double a){cr=r;cg=g;cb=b;ca=a;}
static void capture_vertex(double x,double y){native_vertices[nvertex++]=(AstroSpecialVertex){x,y,cr,cg,cb,ca};}
static unsigned char *attrs,*sprt;
static int kill_on_hit;
void *new_entity(int kind,int subtype,int x,int y,void *parent) {
    (void)parent;if(nspawn>=200)exit(3);int i=nspawn++,id=kind*10+subtype;
    unsigned char *e=entities[i],*r=renders[i];
    memset(e,0,128);memset(r,0,312);
    int sprite=*(int16_t *)(attrs+id*30+22);
    int w=*(int16_t *)(sprt+sprite*14+6),h=*(int16_t *)(sprt+sprite*14+8);
    set_short(e,0,kind);set_short(e,2,subtype);set_short(e,24,1);set_short(e,68,id);
    set_short(e,36,y);set_short(e,38,x);set_short(e,40,y+h);set_short(e,42,x+w);
    set_double(e,44,x);set_double(e,52,y);set_pointer(e,62,r);
    set_short(e,88,*(int16_t *)(attrs+id*30+18));*(uint32_t *)(e+16)=tick;
    set_double(r,16,w);set_double(r,24,h);return e;
}
void new_bullet(int type,int x,int y,int heading,void *source) {
    (void)source;native_bullets[nbullet++]=(AstroShot){type,heading,x,y};
}
void *new_beam(int weapon,int damage,int x,int y,int ex,int ey,void *source) {
    (void)source;if(nbeam>=MAX_EVENTS)exit(3);
    native_beams[nbeam++]=(AstroBeam){weapon,damage,x,y,ex,ey,-1};return beam_marker;
}
void resolve(void *b,int kind,void *target,int target_kind) {
    (void)b;(void)kind;(void)target_kind;
    for(int i=0;i<6;i++)if(target==world[i]) {
        native_beams[nbeam-1].target=i;if(kill_on_hit)set_short(world[i],70,-1);
    }
}
void forced(int id,double *x,double *y,double *w,double *h) {
    native_flashes[nflash++]=(Flash){id,*x,*y,*w,*h};
}
void next_tick(void){tick++;}
static void nothing(void){}
#define BRIDGE(name) \
extern void name##_fb(void); \
__asm__(".text\n.align 2\n.globl _" #name "_fb\n_" #name "_fb:\n" \
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n" \
"bl _" #name "\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
BRIDGE(new_entity) BRIDGE(new_bullet) BRIDGE(new_beam) BRIDGE(resolve) BRIDGE(forced) BRIDGE(next_tick)
static void port_spawn(void *ctx,const AstroSpecialSpawn *s){(void)ctx;port_spawns[pspawn++]=*s;}
static void port_bullet(void *ctx,const AstroShot *s){(void)ctx;port_bullets[pbullet++]=*s;}
static void port_beam(void *ctx,const AstroBeam *b,int temp){(void)temp;AstroTarget *t=ctx;port_beams[pbeam++]=*b;if(kill_on_hit&&b->target>=0)t[b->target].remove=-1;}
static void port_flash(void *ctx,int id,double x,double y,double w,double h){(void)ctx;port_flashes[pflash++]=(Flash){id,x,y,w,h};}
static void port_polygon(void *ctx,const AstroSpecialVertex *v,size_t count){(void)ctx;for(size_t i=0;i<count;i++)port_vertices[pvertex++]=v[i];}
int main(int argc,char **argv) {
    if(argc!=5)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    unsigned char *globals=calloc(1,0x1300),*heap=calloc(1,0x10000);
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++) {
        void *function=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"TickCount"))function=(void *)controlled_tick;
        if(!strncmp(import_names[i],"gl",2))function=(void *)nothing;
        if(!strcmp(import_names[i],"glColor4d"))function=(void *)capture_color;
        if(!strcmp(import_names[i],"glVertex2d"))function=(void *)capture_vertex;
        descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:(void *)missing_import);
        toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    char path[2048];snprintf(path,sizeof(path),"%s/Attr.bin",argv[4]);attrs=read_file(path);
    snprintf(path,sizeof(path),"%s/sprt.bin",argv[4]);sprt=read_file(path);
    set_pointer(globals,0x21c,literals);set_double(globals,0x368,3.14159265358979323846);
    set_double(globals,0x378,4503601774854144.0);*(uint32_t *)(globals+0x380)=0x43300000;
    set_pointer(globals,0x388,heap);set_pointer(globals,0x38c,heap);
    set_pointer(globals,0xa94,attrs);set_pointer(globals,0xe82,sprt);toc[0]=(uint32_t)(uintptr_t)globals;
    jump_to(code+0x53bf4,(void *)new_entity_fb);jump_to(code+0x54248,(void *)new_bullet_fb);
    jump_to(code+0x54594,(void *)new_beam_fb);jump_to(code+0x547b4,(void *)resolve_fb);
    jump_to(code+0x55878,(void *)forced_fb);jump_to(code+0x4cb28,(void *)next_tick_fb);
    int noops[]={0x3ce84,0x539b8,0x54c64,0x57afc,0x35eb8,0x3b55c,0x43134,0x528b4};
    for(unsigned i=0;i<sizeof(noops)/sizeof(noops[0]);i++)*(uint32_t *)(code+noops[i])=0x4e800020;
    MakeDataExecutable(code,433284);
    FILE *fixture=getenv("ASTRO_SPECIAL_FIXTURE")?fopen(getenv("ASTRO_SPECIAL_FIXTURE"),"w"):NULL;
    unsigned cases=0;
    for(int family=1;family<=5;family++)if(family!=2)for(int tier=0;tier<4;tier++)for(int n=0;n<20;n++) {
        int id=family*10+tier;nspawn=pspawn=nbeam=pbeam=nbullet=pbullet=nflash=pflash=nvertex=pvertex=0;
        tick=100;uint32_t seed=(uint32_t)n*123456789u;*(uint32_t *)(globals+0x244)=seed;
        memset(entities,0,sizeof(entities));memset(world,0,sizeof(world));
        unsigned char player[128]={0};set_short(player,0,1);set_short(player,68,11);
        set_short(player,36,180);set_short(player,38,160);set_pointer(globals,0xa7a,player);
        AstroTarget targets[6];
        for(int i=0;i<6;i++) {
            int kind=i%3==0?1:i%3==1?5:20;
            double x=200+(n*13+i*37)%350,y=100+(n*7+i*17)%130,w=20+i*3,h=25+i*5;
            targets[i]=(AstroTarget){kind,-1,0,x,y,w,h};
            set_short(world[i],0,kind);set_short(world[i],36,(int)y);set_short(world[i],38,(int)x);
            set_short(world[i],40,(int)(y+h));set_short(world[i],42,(int)(x+w));
            set_double(world[i],44,x);set_double(world[i],52,y);set_pointer(world[i],102,i<5?world[i+1]:NULL);
        }
        set_pointer(globals,0xa76,world[0]);set_short(globals,0xa52,n%3+1);
        *(uint32_t *)(globals+0xa4a)=99;*(uint32_t *)(globals+0xa4e)=99;
        set_double(globals,0xa1e,0);set_double(globals,0xa26,640);
        set_double(globals,0xa2e,0);set_double(globals,0xa36,380);
        kill_on_hit=n%4==0;
        int gunx=160+*(int16_t *)(attrs+11*30+14),guny=180+*(int16_t *)(attrs+11*30+16);
        invoke5(code+0x5bd0c,globals,toc,(void *)(intptr_t)id,(void *)234,(void *)192,(void *)(intptr_t)(n*17),player);
        AstroSpecialContext c={.context=targets,.seed=&seed,.targets=targets,.target_count=6,.source_parent=-1,
            .gun_x=gunx,.gun_y=guny,.frame_interval=n%3+1,.left=0,.top=0,.right=640,.bottom=380,
            .spawn=port_spawn,.bullet=port_bullet,.beam=port_beam,.sprite=port_flash,.polygon=port_polygon};
        AstroSpecial s={0};astro_special_start(&s,id,234,192,n*17,100,&c);
        for(uint32_t t=100;s.active&&t<=131;t++)astro_special_step(&s,t,&c);
        if(id>=40&&(*(int16_t *)player!=1||s.action_until!=*(uint32_t *)(player+16))) {
            printf("FAIL kind/cooldown id%d n%d kind%d deadline%u/%u\n",id,n,*(int16_t *)player,*(uint32_t *)(player+16),s.action_until);return 1;
        }
        if(nspawn!=pspawn||nbullet!=pbullet||nbeam!=pbeam||nflash!=pflash||seed!=*(uint32_t *)(globals+0x244)) {
            printf("FAIL id%d n%d counts spawn%d/%d bullet%d/%d beam%d/%d flash%d/%d seed%u/%u\n",id,n,nspawn,pspawn,nbullet,pbullet,nbeam,pbeam,nflash,pflash,*(uint32_t *)(globals+0x244),seed);return 1;
        }
        for(int i=0;i<nspawn;i++) {
            unsigned char *e=entities[i],*r=renders[i];AstroSpecialSpawn *s=port_spawns+i;
            int attr=*(int16_t *)(e+68),sid=*(int16_t *)(attrs+attr*30+22);
            int w=*(int16_t *)(sprt+sid*14+6),h=*(int16_t *)(sprt+sid*14+8);
            double expected_w=s->width?s->width:w*s->scale,expected_h=s->height?s->height:h*s->scale;
            if(*(int16_t *)e!=s->kind||*(int16_t *)(e+2)!=s->subtype||*(double *)(e+44)!=s->x||*(double *)(e+52)!=s->y||
               *(int16_t *)(e+88)!=s->hit_points||*(int16_t *)(e+90)!=s->layer||*(int16_t *)(e+24)!=s->frame||
               *(uint32_t *)(e+16)!=100+s->action_offset||fabs(*(double *)(e+72)-s->velocity.x)>1e-10||
               fabs(*(double *)(e+80)-s->velocity.y)>1e-10||fabs(*(double *)(r+16)-expected_w)>1e-10||fabs(*(double *)(r+24)-expected_h)>1e-10) {
                printf("FAIL id%d n%d spawn%d v%.12g,%.12g/%.12g,%.12g frame%d/%d hp%d/%d dims%.12g,%.12g/%.12g,%.12g\n",id,n,i,
                    *(double *)(e+72),*(double *)(e+80),s->velocity.x,s->velocity.y,*(int16_t *)(e+24),s->frame,
                    *(int16_t *)(e+88),s->hit_points,*(double *)(r+16),*(double *)(r+24),expected_w,expected_h);return 1;
            }
        }
        if(memcmp(native_bullets,port_bullets,nbullet*sizeof(AstroShot))){printf("FAIL bullets id%d n%d\n",id,n);return 1;}
        if(memcmp(native_beams,port_beams,nbeam*sizeof(AstroBeam))){
            for(int i=0;i<nbeam;i++)if(memcmp(native_beams+i,port_beams+i,sizeof(AstroBeam))) {
                int *a=(int *)(native_beams+i),*b=(int *)(port_beams+i);printf("FAIL beams id%d n%d index%d\n",id,n,i);
                for(int j=0;j<7;j++)printf("%d %d/%d\n",j,a[j],b[j]);break;
            }return 1;
        }
        if(nvertex!=pvertex){printf("FAIL vertices count id%d n%d %d/%d\n",id,n,nvertex,pvertex);return 1;}
        for(int i=0;i<nvertex;i++)if(memcmp(native_vertices+i,port_vertices+i,sizeof(AstroSpecialVertex))){printf("FAIL vertex id%d n%d index%d\n",id,n,i);return 1;}
        for(int i=0;i<nflash;i++)if(native_flashes[i].id!=port_flashes[i].id||memcmp(&native_flashes[i].x,&port_flashes[i].x,4*sizeof(double))){printf("FAIL flash id%d n%d index%d\n",id,n,i);return 1;}
        if(fixture&&n<3) {
            fprintf(fixture,"C,%d,%d,%u,%d,%d,%d,%d,%d\n",id,n,*(uint32_t *)(globals+0x244),nspawn,nbullet,nbeam,nflash,nvertex);
            for(int i=0;i<nspawn;i++){unsigned char *e=entities[i],*r=renders[i];
                fprintf(fixture,"S,%d,%d,%d,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g\n",
                    *(int16_t *)e,*(int16_t *)(e+2),(int)*(double *)(e+44),(int)*(double *)(e+52),
                    *(int16_t *)(e+88),*(int16_t *)(e+90),*(int16_t *)(e+24),(int)(*(uint32_t *)(e+16)-100),
                    *(double *)(e+72),*(double *)(e+80),*(double *)(r+16),*(double *)(r+24));}
            for(int i=0;i<nbullet;i++){AstroShot *b=native_bullets+i;fprintf(fixture,"B,%d,%d,%d,%d\n",b->type,b->heading,b->x,b->y);}
            for(int i=0;i<nbeam;i++){AstroBeam *b=native_beams+i;fprintf(fixture,"E,%d,%d,%d,%d,%d,%d,%d\n",b->weapon,b->damage,b->x,b->y,b->end_x,b->end_y,b->target);}
            for(int i=0;i<nflash;i++){Flash *f=native_flashes+i;fprintf(fixture,"F,%d,%.17g,%.17g,%.17g,%.17g\n",f->id,f->x,f->y,f->w,f->h);}
            for(int i=0;i<nvertex;i++){AstroSpecialVertex *v=native_vertices+i;fprintf(fixture,"V,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n",v->x,v->y,v->r,v->g,v->b,v->a);}
        }
        cases++;
    }
    if(fixture)fclose(fixture);
    printf("PASS %u original/portable special cases: all16 weapons, spawn fields, bullets, beam arguments, flash positions, polygon vertices/RGBA, RNG\n",cases);return 0;
}
