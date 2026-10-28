/* Shared inputs only; each runner supplies reset/key/snapshot for its own implementation. */
static void run_registration_field_cases(void){
    const unsigned lengths[]={0,1,7,254,255};
    const int cursors[]={-32768,-1,0,3,255,32767};
    const double widths[]={-1,0,200};
    for(int focus=-1;focus<2;focus++)for(unsigned w=0;w<3;w++)
        for(unsigned l=0;l<5;l++)for(unsigned c=0;c<6;c++)for(unsigned key=0;key<256;key++){
            registration_reset(lengths[l],cursors[c],focus,widths[w]);
            registration_key(key);registration_snapshot();
        }
    unsigned random=12345;
    for(unsigned episode=0;episode<30;episode++){
        registration_reset(episode%3?0:254,0,episode%2,200);
        for(unsigned step=0;step<400;step++){
            random=random*1664525u+1013904223u;
            unsigned key=(random&3)?32+(random>>16)%224:(unsigned[]){8,127,28,29,30,31,9,13,3}[(random>>16)%9];
            registration_key(key);registration_snapshot();
        }
    }
}
