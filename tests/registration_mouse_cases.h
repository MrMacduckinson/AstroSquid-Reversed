static void run_registration_mouse_cases(void){
    const double camera[][2]={{0,0},{-100.25,-900.75},{-512.875,-950.125}};
    const int dx[]={-1,0,1,2,10,199,200},dy[]={-1,0,21,22};
    for(unsigned n=0;n<sizeof(text_cursor_names)/sizeof(text_cursor_names[0]);n++)for(unsigned c=0;c<3;c++)
        for(int focus=-1;focus<2;focus++)for(unsigned latch=0;latch<2;latch++)for(unsigned target=0;target<2;target++)
            for(unsigned x=0;x<7;x++)for(unsigned y=0;y<4;y++)
                registration_mouse_case(n,c,camera[c][0],camera[c][1],focus,latch,target,dx[x],dy[y]);
}
