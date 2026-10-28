/* Original GAMELOOP terminal tail; private G5 image, UI/audio/GL observers. */
#define main existing_active_world_oracle_main
#include "ppc_active_special_world_oracle.c"
#undef main
static unsigned quit_case,quit_reads,quit_polls,quit_menu;
static int quit_enabled;
static void quit_event(const char *name){
 printf("%u,%s,%u,%u,%d,%d,%d,%d,%d,%u,%u\n",quit_case,name,quit_reads,quit_polls,
  *(int16_t *)(world_globals+0x58e),*(int16_t *)(world_globals+0x58c),*(int16_t *)(world_globals+0x590),
  *(void **)(world_globals+0xa76)!=NULL,*(void **)(world_globals+0x5ae)!=NULL,disposed,quit_menu);
}
static uint32_t quit_tick(void){if(quit_enabled){if(++quit_reads>30)exit(3);quit_event("clock");}return 100;}
static void quit_keys(void *out){
 memset(out,0,16);if(++quit_polls>2)exit(3);
 int delayed=quit_case==2||quit_case==4||quit_case==6;
 int pressed=quit_case==0||quit_case==5||(delayed&&quit_polls==2);
 if(pressed){((unsigned char *)out)[6]=0x80;((unsigned char *)out)[1]=0x10;}
 else if(quit_case==6){((unsigned char *)out)[6]=1;((unsigned char *)out)[1]=8;}
 quit_event("keys");
}
static void quit_dispose(void *p){Allocation *a=allocation(p);if(!a)exit(3);unsigned bytes=a->size;world_dispose(p);quit_event(bytes==106?"dispose_entity":bytes==308?"dispose_image":"dispose_map");}
void quit_music(void){quit_event("music");}
void quit_controls(void){quit_event("controls");}
void quit_move(unsigned char *name){
 if(name[0]==9&&!memcmp(name+1,"Play Menu",9))quit_menu=1;
 else if(name[0]==15&&!memcmp(name+1,"Highscores Menu",15))quit_menu=2;
 else exit(3);quit_event("menu");
}
void quit_stars(void){quit_event("stars");}
void quit_draw_menu(void){quit_event("draw_menu");}
void quit_draw_sprites(void){quit_event("draw_sprites");}
void quit_swap(void){quit_event("swap");}
void quit_stop(void){quit_event("stop_track");}
void quit_play(void){quit_event("play_track");}
static void quit_flush(unsigned mask,unsigned stop){(void)mask;(void)stop;quit_event("flush");}
static void quit_cursor(void){quit_event("cursor");}
OBSERVER(quit_music) OBSERVER(quit_controls) OBSERVER(quit_move) OBSERVER(quit_stars) OBSERVER(quit_draw_menu) OBSERVER(quit_draw_sprites) OBSERVER(quit_swap) OBSERVER(quit_stop) OBSERVER(quit_play)
static unsigned char *quit_input(const char *path,long expected){
 FILE *f=fopen(path,"rb");if(!f){perror(path);exit(2);}if(fseek(f,0,SEEK_END)||ftell(f)!=expected){fclose(f);exit(2);}fclose(f);return read_file(path);
}
int main(int argc,char **argv){
 if(argc!=6||argv[5][0]<'0'||argv[5][0]>'7'||argv[5][1])return 2;quit_case=argv[5][0]-'0';storm=1;alarm(15);
 unsigned char *pef=quit_input(argv[1],455780),*code=pef+128,*lit=quit_input(argv[2],11812),*g=calloc(1,0x1300),*heap=calloc(1,65536);world_globals=g;
 uint32_t toc[489]={0};for(int i=0;i<484;i++){void *f=dlsym(RTLD_DEFAULT,import_names[i]);
  if(!strcmp(import_names[i],"TickCount"))f=quit_tick;if(!strcmp(import_names[i],"GetKeys"))f=quit_keys;
  if(!strcmp(import_names[i],"NewPtrClear"))f=world_alloc;if(!strcmp(import_names[i],"DisposePtr"))f=quit_dispose;
  if(!strcmp(import_names[i],"FlushEvents"))f=quit_flush;if(!strcmp(import_names[i],"ShowCursor"))f=quit_cursor;if(!strncmp(import_names[i],"gl",2))f=noop_gl;
  descriptors[i][0]=(uint32_t)(uintptr_t)(f?f:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 const char *files[]={"Attr.bin","sprt.bin","Wpns.bin"};int offsets[]={0xa94,0xe82,0xa98},sizes[]={13230,14014,12532};char path[2048];
 for(int i=0;i<3;i++){snprintf(path,sizeof(path),"%s/%s",argv[4],files[i]);set_pointer(g,offsets[i],quit_input(path,sizes[i]));}
 set_pointer(g,0x21c,lit);set_double(g,0x378,4503601774854144.);*(uint32_t *)(g+0x380)=0x43300000;set_pointer(g,0x388,heap);set_pointer(g,0x38c,heap);set_short(g,0xa52,1);set_short(g,0xed6,640);set_short(g,0xed8,480);
 jump_to(code+0x334bc,quit_music_fb);jump_to(code+0x64154,quit_controls_fb);jump_to(code+0x4b3a4,quit_move_fb);jump_to(code+0x45af0,quit_stars_fb);jump_to(code+0x46394,quit_draw_menu_fb);jump_to(code+0x3aaf8,quit_draw_sprites_fb);jump_to(code+0x35eb8,quit_swap_fb);jump_to(code+0x31af4,quit_stop_fb);jump_to(code+0x31edc,quit_play_fb);MakeDataExecutable(code,433284);
 FSRef ref;ResFileRefNum rf;HFSUniStr255 fork;OSStatus err=FSPathMakeRef((const UInt8*)argv[3],&ref,NULL);if(!err)err=FSGetResourceForkName(&fork);if(!err)err=FSOpenResourceFile(&ref,fork.length,fork.unicode,fsRdPerm,&rf);if(err)return 2;UseResFile(rf);
 snprintf(path,sizeof(path),"%s.strings",argv[1]);unsigned char *expected=quit_input(path,6884);Handle actual=GetResource('STR#',25000);if(!actual||GetHandleSize(actual)!=6884||memcmp(*actual,expected,6884))return 2;
 void *player=spawn(code,toc,1,1,100,180);set_pointer(g,0xa7a,player);set_pointer(g,0x5ae,world_alloc(50));
 set_short(g,0x58e,quit_case==1||quit_case==7?1:quit_case==2?-1:0);set_short(g,0x58c,quit_case==3||quit_case==7?1:quit_case==4?-1:0);set_short(g,0x590,1);set_short(g,0xa06,quit_case==5?1:0);
 quit_enabled=1;quit_event("entry");invoke_fb(code+0x51a68,g,toc,NULL,NULL,NULL);quit_event("return");
 unsigned polls=quit_case==2||quit_case==4||quit_case==6?2:1;
 if(quit_polls!=polls||quit_reads!=3+2*polls||disposed!=3||*(void **)(g+0xa76)||*(void **)(g+0x5ae)||*(void **)(g+0xa7a)||*(int16_t *)(g+0x590)||quit_menu!=(quit_case==5?2u:1u))return 3;
 return 0;
}
