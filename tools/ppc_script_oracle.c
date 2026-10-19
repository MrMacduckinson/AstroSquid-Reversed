/* Isolated original DOSCRIPTEDSPRITE oracle. Tick, fire and hit callbacks are
 * controlled test doubles; game archives and the live game are never patched.
 */
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../src/script.h"
#include "ppc_bridge.h"
#include "imports.h"

static uint32_t descriptors[484][2];
static uint32_t tick;
static uint64_t ieee_word(double x){uint64_t u;memcpy(&u,&x,8);return u;}
static unsigned native_shots,ported_shots;
static unsigned native_hits,ported_hits;
typedef struct {int weapon,x,y,heading;} Shot;
static Shot native_log[1024],ported_log[1024];
static uint32_t controlled_tick(void) { return tick; }
void report_missing(uint32_t *descriptor) {
    int i=(int)(descriptor-&descriptors[0][0])/2;
    fprintf(stderr,"Unresolved oracle import %d %s\n",i,i>=0&&i<484?import_names[i]:"unknown");exit(2);
}
extern void missing_import(void);
__asm__(".text\n.align 2\n.globl _missing_import\n_missing_import:\nmr r3,r12\nb _report_missing\n");
void native_fire(int weapon,int x,int y,int direction,void *source) {
    (void)source;
    if(native_shots>=1024) exit(2);
    native_log[native_shots++]=(Shot){weapon,x,y,direction};
}
void native_hit(void *a,void *b) { (void)a;(void)b;native_hits++; }
extern void native_fire_fb(void),native_hit_fb(void);
__asm__(
".text\n.align 2\n.globl _native_fire_fb\n_native_fire_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_fire\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n"
".align 2\n.globl _native_hit_fb\n_native_hit_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-64(r1)\nstw r2,20(r1)\n"
"bl _native_hit\nlwz r2,20(r1)\naddi r1,r1,64\nlwz r0,8(r1)\nmtlr r0\nblr\n");
static void port_fire(void *p,int weapon,int x,int y,int direction) {
    (void)p;
    if(ported_shots>=1024) exit(2);
    ported_log[ported_shots++]=(Shot){weapon,x,y,direction};
}
static void port_hit(void *p) { (void)p;ported_hits++; }
static unsigned char *read_file(const char *name) {
    FILE *f=fopen(name,"rb");if(!f) {perror(name);exit(2);}
    fseek(f,0,SEEK_END);long size=ftell(f);rewind(f);
    unsigned char *b=malloc((size_t)size);if(!b||fread(b,1,(size_t)size,f)!=(size_t)size) exit(2);
    fclose(f);return b;
}
static void jump_to(unsigned char *at,void *destination) {
    uintptr_t p=(uintptr_t)destination;
    uint32_t *w=(uint32_t *)at;
    w[0]=0x3d800000|(uint32_t)(p>>16);w[1]=0x618c0000|(uint32_t)(p&65535);
    w[2]=0x7d8903a6;w[3]=0x4e800420;
}
static void set_short(unsigned char *p,int offset,int value) { *(int16_t *)(p+offset)=(int16_t)value; }
static void set_double(unsigned char *p,int offset,double value) { *(double *)(p+offset)=value; }
static void set_pointer(unsigned char *p,int offset,void *value) { *(void **)(p+offset)=value; }

int main(int argc,char **argv) {
    if(argc!=5) {fputs("usage: script_oracle original.pef literals.bin original-app tables-directory\n",stderr);return 2;}
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
    jump_to(code+0x58f40,(void *)native_fire_fb);jump_to(code+0x60430,(void *)native_hit_fb);
    MakeDataExecutable(code,433284);
    FSRef ref;ResFileRefNum resourceFile;
    HFSUniStr255 forkName;
    OSStatus error=FSPathMakeRef((const UInt8 *)argv[3],&ref,NULL);
    if(!error) error=FSGetResourceForkName(&forkName);
    if(!error) error=FSOpenResourceFile(&ref,forkName.length,forkName.unicode,fsRdPerm,&resourceFile);
    if(error) {fprintf(stderr,"Cannot open original resources: %ld\n",(long)error);return 2;}
    UseResFile(resourceFile);
    unsigned scripts_checked=0,cases_checked=0;
    for(int scriptID=200;scriptID<=308;scriptID++) {
        Handle h=GetResource('STR#',(short)scriptID);
        if(!h) continue;
        AstroInstruction script[256];
        unsigned char *text=(unsigned char *)*h;
        size_t count=*(uint16_t *)text;text+=2;
        if(count>256) return 2;
        for(size_t i=0;i<count;i++) {
            char line[256];unsigned length=*text++;
            memcpy(line,text,length);line[length]=0;text+=length;
            if(!astro_parse_instruction(line,&script[i])) {fprintf(stderr,"Bad original instruction %s\n",line);return 2;}
        }
        int attribute=-1;
        for(int i=0;i<441;i++) if(*(int16_t *)(attributes+i*30+12)==scriptID) {attribute=i;break;}
        if(attribute<0) {fprintf(stderr,"No attribute uses script %d\n",scriptID);return 2;}
        int first_frame=*(int16_t *)(attributes+attribute*30+22);
        int width=*(int16_t *)(sprites+first_frame*14+6);
        int height=*(int16_t *)(sprites+first_frame*14+8);
        for(int variant=0;variant<6;variant++) {
            double visual_width=variant>=3?125:width,visual_height=variant>=3?186:height;
            int player_variant=variant%3;
            unsigned char entity[128],render[312],player[128],player_render[312];
            memset(entity,0,sizeof(entity));memset(render,0,sizeof(render));
            memset(player,0,sizeof(player));memset(player_render,0,sizeof(player_render));
            set_short(entity,0,5);set_short(entity,2,attribute%10);set_short(entity,4,1);
            set_short(entity,20,scriptID);set_short(entity,22,1);set_short(entity,24,1);set_short(entity,26,1);
            set_short(entity,60,first_frame-1);set_short(entity,68,attribute);
            set_pointer(entity,62,render);set_double(entity,44,700);set_double(entity,52,200);
            set_double(render,0,700);set_double(render,8,200);set_double(render,16,visual_width);set_double(render,24,visual_height);set_short(render,38,first_frame);
            set_short(entity,36,200);set_short(entity,38,700);set_short(entity,40,200+visual_height);set_short(entity,42,700+visual_width);
            set_pointer(globals,0xa76,entity);set_pointer(globals,0x38c,heap);
            double px=player_variant==1?-1500:730,py=player_variant==1?100:215;
            set_pointer(player,62,player_render);set_double(player,44,px);set_double(player,52,py);
            set_double(player_render,16,71);set_double(player_render,24,20);set_short(player_render,38,1);
            set_short(player,36,(int)py);set_short(player,38,(int)px);
            set_short(player,40,(int)py+20);set_short(player,42,(int)px+71);
            set_pointer(globals,0xa7a,player_variant?player:NULL);
            AstroScriptState state;memset(&state,0,sizeof(state));
            state.frame=1;state.tilt=1;state.state=1;state.x=700;state.y=200;
            AstroScriptContext context;memset(&context,0,sizeof(context));
            context.animated=*(int16_t *)(attributes+attribute*30+20);context.fire=port_fire;context.hit_player=port_hit;
            context.player_present=player_variant!=0;context.player_x=px;context.player_y=py;
            context.weapon=*(int16_t *)(attributes+attribute*30+4);
            context.gun_x=astro_script_gun_coordinate(700,*(int16_t *)(attributes+attribute*30+14),visual_width,width);
            context.gun_y=astro_script_gun_coordinate(200,*(int16_t *)(attributes+attribute*30+16),visual_height,height);
            if(player_variant) context.target_heading=(int)invoke_fb(code+0x58978,globals,toc,entity,player,NULL);
            native_shots=0;ported_shots=0;native_hits=0;ported_hits=0;
            for(tick=1;tick<=600;tick++) {
                invoke_fb(code+0x61c40,globals,toc,entity,NULL,NULL);
                if(!astro_script_step(&state,script,count,tick,&context)) {fprintf(stderr,"Portable interpreter rejected line\n");return 1;}
                double x=*(double *)(entity+72),y=*(double *)(entity+80);
                int line=*(int16_t *)(entity+22),frame=*(int16_t *)(entity+24);
                int tilt=*(int16_t *)(entity+26),status=*(int16_t *)(entity+4),remove=*(int16_t *)(entity+70);
                uint32_t next=*(uint32_t *)(entity+16);
                if(ieee_word(x)!=ieee_word(state.velocity.x)||ieee_word(y)!=ieee_word(state.velocity.y)||line!=(int)state.line+1||frame!=state.frame||tilt!=state.tilt||status!=state.state||remove!=state.remove||next!=state.action_tick||*(uint32_t *)(entity+8)!=state.update_tick||*(uint32_t *)(entity+12)!=state.animation_tick||native_shots!=ported_shots||native_hits!=ported_hits||memcmp(native_log,ported_log,native_shots*sizeof(Shot))) {
                    printf("Mismatch script %d variant %d heading %d tick %u\n",scriptID,variant,context.target_heading,tick);
                    printf(" original v=(%.9g,%.9g) line=%d frame=%d tilt=%d state=%d remove=%d next=%u shots=%u\n",x,y,line,frame,tilt,status,remove,next,native_shots);
                    printf(" port     v=(%.9g,%.9g) line=%lu frame=%d tilt=%d state=%d remove=%d next=%u shots=%u\n",state.velocity.x,state.velocity.y,(unsigned long)state.line+1,state.frame,state.tilt,state.state,state.remove,state.action_tick,ported_shots);return 1;
                }
            }
            cases_checked++;
        }
        scripts_checked++;
        printf("PASS script %d: absent/far/near player, natural/scaled visuals, 600 ticks each\n",scriptID);
    }
    CloseResFile(resourceFile);
    printf("PASS: %u scripts, %u cases, %u original/portable ticks (controlled clock/fire callbacks)\n",scripts_checked,cases_checked,cases_checked*600);
    return 0;
}
