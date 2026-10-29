#include "ui_model.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>
static unsigned cases;
static void registration_validator_case(unsigned length,unsigned pattern,unsigned variant,unsigned prior,const unsigned char *name,unsigned name_length,const unsigned char *serial,unsigned serial_length,const unsigned char expected[8]){
    printf("%u,%u,%u,%u,%d,",length,pattern,variant,prior,astro_registration_valid(name,name_length,serial,serial_length));
    for(unsigned i=0;i<8;i++)printf("%02x",expected[i]);putchar('\n');cases++;
}
#include "registration_validator_cases.h"
int main(void){
    const unsigned char code[]="AAAAAAAA";
    assert(astro_registration_valid(NULL,0,code,8));assert(!astro_registration_valid(NULL,1,code,8));
    assert(!astro_registration_valid(code,256,code,8));assert(!astro_registration_valid(code,8,NULL,8));
    run_registration_validator_cases();fprintf(stderr,"PASS %u host registration validation cases\n",cases);return 0;
}
