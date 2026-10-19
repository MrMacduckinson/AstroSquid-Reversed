/* Original DOSHRAPNELSPRITE and CALCSPRITES kind20 branch, isolated. */
#define main script_oracle_main
#include "ppc_script_oracle.c"
#undef main
#include "../src/debris.h"
static void fields(unsigned char *e,const AstroDebris *s) {
    set_short(e,0,s->kind);set_short(e,4,s->state);set_short(e,24,s->frame);set_short(e,70,s->remove);
    *(uint32_t *)(e+8)=s->update_tick;*(uint32_t *)(e+12)=s->animation_tick;*(uint32_t *)(e+16)=s->action_tick;
    set_double(e,72,s->velocity.x);set_double(e,80,s->velocity.y);
}
static AstroDebris get_fields(unsigned char *e) {
    AstroDebris s={*(int16_t *)e,*(int16_t *)(e+4),*(int16_t *)(e+24),*(int16_t *)(e+70),
        *(uint32_t *)(e+8),*(uint32_t *)(e+12),*(uint32_t *)(e+16),{*(double *)(e+72),*(double *)(e+80)}};return s;
}
static void row(FILE *f,const AstroDebris *s){fprintf(f,"%d,%d,%d,%d,%u,%u,%u,%.17g,%.17g",s->kind,s->state,s->frame,s->remove,s->update_tick,s->animation_tick,s->action_tick,s->velocity.x,s->velocity.y);}
int main(int argc,char **argv) {
    if(argc!=3)return 2;
    unsigned char *pef=read_file(argv[1]),*code=pef+128,*literals=read_file(argv[2]);
    unsigned char *globals=calloc(1,0x1300),*heap=calloc(1,0x10000),*attributes=calloc(441,30);
    uint32_t toc[489];memset(toc,0,sizeof(toc));
    for(int i=0;i<484;i++) {
        void *function=dlsym(RTLD_DEFAULT,import_names[i]);
        if(!strcmp(import_names[i],"TickCount"))function=(void *)controlled_tick;
        descriptors[i][0]=(uint32_t)(uintptr_t)(function?function:(void *)missing_import);
        toc[i]=(uint32_t)(uintptr_t)descriptors[i];
    }
    set_pointer(globals,0x21c,literals);set_double(globals,0x368,3.14159265358979323846);
    set_double(globals,0x378,4503601774854144.0);*(uint32_t *)(globals+0x380)=0x43300000;
    set_pointer(globals,0x388,heap);set_pointer(globals,0x38c,heap);set_pointer(globals,0xa94,attributes);
    toc[0]=(uint32_t)(uintptr_t)globals;
    *(uint32_t *)(code+0x42234)=0x4e800020; /* Oracle-only MOVESTARS no-op. */
    *(uint32_t *)(code+0x549e8)=0x4e800020; /* Oracle-only collision no-op. */
    MakeDataExecutable(code,433284);
    FILE *f=getenv("ASTRO_DEBRIS_FIXTURE")?fopen(getenv("ASTRO_DEBRIS_FIXTURE"),"w"):NULL;
    unsigned cases=0;
    for(int kind_index=0;kind_index<2;kind_index++)for(int n=0;n<300;n++) {
        unsigned char entity[128]={0},render[312]={0};
        AstroDebris s={kind_index?20:4,n%3==0?2:1,n%3+1,n%11==0?-1:0,
            90+n%30,80+n%30,70+n%50,{((n*37)%600-300)/17.0,((n*13)%400-200)/19.0}};
        fields(entity,&s);set_pointer(entity,62,render);set_pointer(globals,0xa76,entity);
        set_short(entity,68,kind_index?200:42);
        int stage=n%10;double gravity=astro_debris_gravity(stage);set_double(globals,0xaa0,gravity);
        for(int step=0;step<9;step++) {
            tick=100+n%60+step/2;int right=n%7==0?99:100+n%3;double left=100;
            set_short(entity,42,right);set_double(globals,0xa1e,left);
            if(kind_index) {
                set_double(render,0,300);set_double(render,8,200);set_double(render,16,20);set_double(render,24,20);
                set_double(globals,0xea2,0);set_double(globals,0xeaa,0);right=320;left=0;
            }
            AstroDebris before=s;
            invoke_fb(code+(kind_index?0x54c64:0x636a0),globals,toc,entity,NULL,NULL);
            astro_debris_step(&s,tick,right,left,gravity);AstroDebris native=get_fields(entity);
            if(native.kind!=s.kind||native.state!=s.state||native.frame!=s.frame||native.remove!=s.remove||
               native.update_tick!=s.update_tick||native.animation_tick!=s.animation_tick||native.action_tick!=s.action_tick||
               fabs(native.velocity.x-s.velocity.x)>1e-10||fabs(native.velocity.y-s.velocity.y)>1e-10) {
                printf("FAIL kind%d case%d step%d original v%.17g,%.17g port%.17g,%.17g timers%u,%u/%u,%u remove%d/%d\n",s.kind,n,step,
                    native.velocity.x,native.velocity.y,s.velocity.x,s.velocity.y,native.update_tick,native.animation_tick,s.update_tick,s.animation_tick,native.remove,s.remove);return 1;
            }
            if(f&&n<25){row(f,&before);fprintf(f,",%u,%d,%.17g,%.17g,",tick,right,left,gravity);row(f,&native);fputc('\n',f);}
            cases++;
        }
    }
    if(f)fclose(f);printf("PASS %u original/portable debris+kind20 tick updates, states,timers,frame,remove,velocity\n",cases);return 0;
}
