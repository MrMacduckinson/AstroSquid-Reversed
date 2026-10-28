#include "scores.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
static AstroScoreEditor fields[2];static double widths[2];static int focus;static unsigned count,alerts;
static void registration_reset(unsigned length,int cursor,int active,double width){
    memset(fields,0,sizeof(fields));focus=active;alerts=0;widths[0]=widths[1]=width;
    for(unsigned f=0;f<2;f++){for(unsigned i=0;i<length;i++)fields[f].name[i]=(char)(32+(i*17+f*3)%224);fields[f].cursor=cursor;}
}
static void registration_key(unsigned key){
    int active=focus;int result=astro_registration_editor_key(fields,widths,&focus,key);
    if(result==ASTRO_SCORE_EDIT_ALERT){alerts++;assert(active>=0);astro_score_editor_resolve_alert(&fields[active],1);}
}
static void registration_snapshot(void){
    printf("%u,%d,%u",count++,focus,alerts);
    for(unsigned f=0;f<2;f++){printf(",%d,%d,",fields[f].cursor,fields[f].submitted);for(unsigned i=0;i<strlen(fields[f].name);i++)printf("%02x",(unsigned char)fields[f].name[i]);}putchar('\n');
}
#include "registration_field_cases.h"
int main(void){run_registration_field_cases();fprintf(stderr,"PASS %u host registration field input states\n",count);return 0;}
