/* Original ADDSPRITEDEATHEFFECTS; allocation/audio captured in an isolated process. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/effects.h"
#include "../src/visual.h"
static unsigned char *attr_table,*sprite_table,*oracle_globals;
typedef struct {unsigned char entity[128],render[312];int type,attribute;} OriginalEffect;
static OriginalEffect original[4096];static size_t original_count;
static AstroDeathEffect portable[4096];static size_t portable_count;
static unsigned sounds,portable_sounds;
static void init_render(unsigned char *r,int sprite,double x,double y) {
    set_double(r,0,x);set_double(r,8,y);
    set_double(r,16,*(int16_t *)(sprite_table+sprite*14+6));
    set_double(r,24,*(int16_t *)(sprite_table+sprite*14+8));
    set_short(r,38,sprite);*(uint32_t *)(r+34)=tick+*(int16_t *)(sprite_table+sprite*14+12);
}
void *effect_lm(int sprite,int layer,double *x,double *y,void *name) {
    (void)layer;(void)name;if(original_count>=4096) exit(2);
    OriginalEffect *e=&original[original_count++];memset(e,0,sizeof(*e));e->type=ASTRO_EFFECT_EXPLOSION;
    init_render(e->render,sprite,*x,*y);return e->render;
}
void *effect_new(int kind,int subtype,int x,int y,void *parent) {
    (void)parent;if(original_count>=4096) exit(2);
    OriginalEffect *e=&original[original_count++];memset(e,0,sizeof(*e));
    e->attribute=kind*10+subtype;e->type=kind==40?ASTRO_EFFECT_PICKUP:ASTRO_EFFECT_DEBRIS;
    int sprite=*(int16_t *)(attr_table+e->attribute*30+22);
    init_render(e->render,sprite,x,y);set_pointer(e->entity,62,e->render);
    set_short(e->entity,0,kind);set_short(e->entity,2,subtype);set_short(e->entity,24,1);
    set_short(e->entity,68,e->attribute);set_double(e->entity,44,x);set_double(e->entity,52,y);
    set_short(e->entity,36,y);set_short(e->entity,38,x);
    set_short(e->entity,40,y+(int)*(double *)(e->render+24));
    set_short(e->entity,42,x+(int)*(double *)(e->render+16));
    *(uint32_t *)(e->entity+12)=tick;*(uint32_t *)(e->entity+16)=tick;return e->entity;
}
void effect_sound(void *name,double *pan) {(void)name;(void)pan;sounds++;}
extern void effect_lm_fb(void),effect_new_fb(void),effect_sound_fb(void);
__asm__(".text\n.align 2\n.globl _effect_lm_fb\n_effect_lm_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _effect_lm\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
__asm__(".text\n.align 2\n.globl _effect_new_fb\n_effect_new_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _effect_new\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
__asm__(".text\n.align 2\n.globl _effect_sound_fb\n_effect_sound_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _effect_sound\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
extern uint32_t invoke_effect(void *,void *,void *,void *,int,int);
__asm__(
".text\n.align 2\n.globl _invoke_effect\n_invoke_effect:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\n"
"stmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r3,r6\nmr r21,r7\nmr r20,r8\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\n"
"lmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void port_emit(void *unused,const AstroDeathEffect *effect) {
    (void)unused;if(effect->type==ASTRO_EFFECT_SOUND) {portable_sounds++;return;}
    if(portable_count>=4096) exit(2);portable[portable_count++]=*effect;
}
int main(int argc,char **argv) {
    if(argc!=5) return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    unsigned char *globals=calloc(1,0x1300),*heap=calloc(1,0x10000);
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++) {
        void *function=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"TickCount")) function=(void *)controlled_tick;
        descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:(void *)missing_import);
        toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    char path[2048];
    snprintf(path,sizeof(path),"%s/Attr.bin",argv[4]);unsigned char *attributes=read_file(path);
    snprintf(path,sizeof(path),"%s/sprt.bin",argv[4]);unsigned char *sprites=read_file(path);
    snprintf(path,sizeof(path),"%s/Wpns.bin",argv[4]);unsigned char *weapons=read_file(path);
    set_pointer(globals,0x21c,literals);set_double(globals,0x368,3.14159265358979323846);
    set_double(globals,0x378,4503601774854144.0);*(uint32_t *)(globals+0x380)=0x43300000;
    set_pointer(globals,0x388,heap);set_pointer(globals,0x38c,heap);
    set_pointer(globals,0xa94,attributes);set_pointer(globals,0xe82,sprites);set_pointer(globals,0xa98,weapons);
    toc[0]=(uint32_t)(uintptr_t)globals;
    attr_table=attributes;sprite_table=sprites;oracle_globals=globals;
    jump_to(code+0x34a34,(void *)effect_lm_fb);
    jump_to(code+0x53bf4,(void *)effect_new_fb);
    jump_to(code+0x3ce84,(void *)effect_sound_fb);
    *(uint32_t *)(code+0x3b260)=0x38600001; // Return a non-null shield marker; no dereference follows.
    *(uint32_t *)(code+0x3b264)=0x4e800020;


    MakeDataExecutable(code,433284);

    AstroSpriteInfo metrics[1001];
    for(int i=0;i<1001;i++) metrics[i]=(AstroSpriteInfo){*(int16_t *)(sprites+i*14+6),
        *(int16_t *)(sprites+i*14+8),*(int16_t *)(sprites+i*14+10),*(int16_t *)(sprites+i*14+12)};
    FILE *visual_fixture=getenv("ASTRO_VISUAL_FIXTURE")?fopen(getenv("ASTRO_VISUAL_FIXTURE"),"w"):NULL;
    for(int n=0;n<1000;n++) {
        unsigned char render[312]={0};int from=n%25+1,to=n*7%25+1;tick=n+100;
        init_render(render,from,n/3.0,-n/7.0);set_double(render,16,n/5.0+10);set_double(render,24,n/9.0+8);
        AstroVisual v={from,*(double *)render,*(double *)(render+8),*(double *)(render+16),*(double *)(render+24),tick};
        AstroVisual before=v;
        invoke_fb(code+0x343b4,globals,toc,render,(void *)(intptr_t)to,NULL);
        if(visual_fixture&&n<100) fprintf(visual_fixture,"%d,%d,%.17g,%.17g,%.17g,%.17g,%u,%.17g,%.17g,%.17g,%.17g,%u\n",
            from,to,before.x,before.y,before.width,before.height,tick,*(double *)render,*(double *)(render+8),
            *(double *)(render+16),*(double *)(render+24),*(uint32_t *)(render+34));
        if(!astro_visual_change(&v,to,metrics,1001,tick)||fabs(v.x-*(double *)render)>1e-10||
            fabs(v.y-*(double *)(render+8))>1e-10||fabs(v.width-*(double *)(render+16))>1e-10||
            fabs(v.height-*(double *)(render+24))>1e-10||v.next_tick!=*(uint32_t *)(render+34)) {
            printf("FAIL visual case%d\n",n);return 1;
        }
    }
    if(visual_fixture) fclose(visual_fixture);
    puts("PASS: 1000 original/portable sprite-frame changes and animation deadlines");
    unsigned cases=0;
    FILE *fixture=getenv("ASTRO_EFFECTS_FIXTURE")?fopen(getenv("ASTRO_EFFECTS_FIXTURE"),"w"):NULL;
    for(int attribute=0;attribute<441;attribute++) {
        unsigned char *a=attributes+attribute*30;
        int sprite=*(int16_t *)(a+22);
        if(sprite==0&&*(int16_t *)(a+18)==0) continue;
        int height=*(int16_t *)(sprites+sprite*14+8);if(height<=0) continue;
        for(int variant=0;variant<3;variant++) {
            unsigned char entity[128]={0},render[312]={0};
            tick=100;
            int kind=attribute/10;if(kind>5&&kind<20) kind=5;
            int w=20+variant*35,h=15+variant*25;
            int explosion=*(int16_t *)(a+24),debris=*(int16_t *)(a+6);
            int debris_sprite=*(int16_t *)(attributes+debris*30+22);
            AstroDeathSource source={.kind=kind,.tag=variant==2?1:0,.left=700,.top=180,.right=700+w,.bottom=180+h,
                .width=w,.height=h,.original_height=height,.velocity={1.5,-2.5},
                .explosion_sprite=explosion,.explosion_width=*(int16_t *)(sprites+explosion*14+6),
                .explosion_height=*(int16_t *)(sprites+explosion*14+8),.explosion_delay=*(int16_t *)(sprites+explosion*14+12),.debris_attribute=debris,
                .debris_sprite=debris_sprite,.debris_width=*(int16_t *)(sprites+debris_sprite*14+6),
                .debris_height=*(int16_t *)(sprites+debris_sprite*14+8),.debris_count=*(int16_t *)(a+8)};
            set_short(entity,0,kind);set_short(entity,68,attribute);set_short(entity,96,source.tag);
            set_short(entity,36,180);set_short(entity,38,700);set_short(entity,40,180+h);set_short(entity,42,700+w);
            set_double(entity,72,1.5);set_double(entity,80,-2.5);set_pointer(entity,62,render);
            init_render(render,sprite,700,180);set_double(render,16,w);set_double(render,24,h);
            uint32_t seed=123456789u*(attribute+variant);*(uint32_t *)(globals+0x244)=seed;
            original_count=portable_count=0;sounds=portable_sounds=0;
            invoke_effect(code+0x52a94,globals,toc,entity,w,h);
            if(!astro_death_effects(&source,tick,&seed,port_emit,NULL)) {printf("Bad source%d\n",attribute);return 1;}
            if(original_count!=portable_count||seed!=*(uint32_t *)(globals+0x244)||sounds!=portable_sounds) {
                printf("FAIL effect attr%d variant%d count%lu/%lu seed%u/%u sounds%u/%u\n",attribute,variant,
                    (unsigned long)original_count,(unsigned long)portable_count,*(uint32_t *)(globals+0x244),seed,sounds,portable_sounds);return 1;
            }
            for(size_t i=0;i<original_count;i++) {
                OriginalEffect *e=&original[i];AstroDeathEffect *p=&portable[i];
                double x=*(double *)(e->render),y=*(double *)(e->render+8),ew=*(double *)(e->render+16),eh=*(double *)(e->render+24);
                int type=e->type;
                if(type!=p->type||fabs(x-p->x)>1e-9||fabs(y-p->y)>1e-9||
                   (type!=ASTRO_EFFECT_PICKUP&&(fabs(ew-p->width)>1e-9||fabs(eh-p->height)>1e-9))||
                   (type==ASTRO_EFFECT_DEBRIS&&(fabs(*(double *)(e->entity+72)-p->velocity.x)>1e-9||
                    fabs(*(double *)(e->entity+80)-p->velocity.y)>1e-9||*(int16_t *)(e->entity+24)!=p->frame||
                    *(uint32_t *)(e->entity+16)!=p->action_tick||*(int16_t *)(e->entity)!=p->kind))||
                   (type==ASTRO_EFFECT_EXPLOSION&&*(uint32_t *)(e->render+34)!=p->animation_tick)) {
                    printf("FAIL effect attr%d variant%d item%lu type%d/%d xy%.9g,%.9g/%.9g,%.9g wh%.9g,%.9g/%.9g,%.9g\n",
                        attribute,variant,(unsigned long)i,type,p->type,x,y,p->x,p->y,ew,eh,p->width,p->height);return 1;
                }
            }
            if(fixture&&(attribute==11||attribute==27||attribute==62||attribute==150||attribute==401)) {
                fprintf(fixture,"C,%d,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%d,%d,%d,%d,%d,%d,%d,%d,%u,%u,%u,%lu,%u\n",
                    source.kind,source.tag,source.left,source.top,source.right,source.bottom,
                    source.width,source.height,source.original_height,source.velocity.x,source.velocity.y,
                    source.explosion_sprite,source.explosion_width,source.explosion_height,source.explosion_delay,
                    source.debris_attribute,source.debris_sprite,source.debris_width,source.debris_height,source.debris_count,
                    123456789u*(attribute+variant),tick,*(uint32_t *)(globals+0x244),(unsigned long)original_count,sounds);
                for(size_t i=0;i<original_count;i++) {
                    OriginalEffect *e=&original[i];unsigned char *r=e->render,*b=e->entity;
                    fprintf(fixture,"E,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%u,%u\n",
                        e->type,e->type==ASTRO_EFFECT_EXPLOSION?8:*(int16_t *)b,e->attribute,*(int16_t *)(r+38),
                        e->type==ASTRO_EFFECT_EXPLOSION?1:*(int16_t *)(b+24),*(double *)r,*(double *)(r+8),
                        *(double *)(r+16),*(double *)(r+24),*(double *)(b+72),*(double *)(b+80),
                        *(uint32_t *)(r+34),*(uint32_t *)(b+16));
                }
            }
            cases++;
        }
    }
    if(fixture) fclose(fixture);
    printf("PASS: %u original/portable death-effect cases, all particles/debris/drop positions, sizes, velocity, RNG and timing\n",cases);return 0;
}
