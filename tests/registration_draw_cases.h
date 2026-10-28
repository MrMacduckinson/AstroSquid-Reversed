static void run_registration_draw_cases(void){
    const double cameras[][2]={{0,0},{-100.25,-900.75},{-512.875,-950.125}};
    for(unsigned n=0;n<sizeof(text_cursor_names)/sizeof(text_cursor_names[0]);n++){
        unsigned length=strlen(text_cursor_names[n]);int cursors[]={-1,0,length/2,length,length+5};
        for(unsigned c=0;c<5;c++)for(unsigned visible=0;visible<2;visible++)
            for(int focus=-1;focus<2;focus++)for(unsigned camera=0;camera<3;camera++)
                registration_draw_case(text_cursor_names[n],cursors[c],visible,focus,cameras[camera][0],cameras[camera][1]);
    }
}
