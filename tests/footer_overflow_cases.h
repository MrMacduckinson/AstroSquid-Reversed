static void run_footer_overflow_cases(void){
    unsigned char name[255];
    for(unsigned length=0;length<256;length++)for(unsigned pattern=0;pattern<3;pattern++){
        for(unsigned i=0;i<length;i++)name[i]=pattern==0?0:pattern==1?255:32+(i*17)%224;
        for(unsigned choice=0;choice<=2;choice++){footer_case(length,pattern,choice,name);if(choice==2&&length>240)footer_case(length,pattern,choice,name);}
    }
}
