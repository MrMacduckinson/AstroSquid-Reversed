/* Whole MOVEMENUTO: real camera/gate/stars/RNG/LMHANDLE/MOUSEOVER/ANIMATEMENU.
   Original Data B2 records seed the 52-node list; GPU/audio OS boundaries observed. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned profile,route,reads,frame,recording;
static int dispatch_mode,routes_mode,returns_mode,startup_mode,startup_input,click_pending,held_button;static unsigned char *clicked_node;
static Point held_point;
static const char *route_buttons[]={"Play","Continue","Back7","Back2","Highscores","Back4","Settings","SetKeys","Back6","Back","Register","Back3"};
static const char *return_buttons[]={"Yeah","Back5"};
static unsigned char *gref,*nodes[52];static double *stars;static Handle strings;static FILE *star_dump;
static uint64_t word(double x){uint64_t b;memcpy(&b,&x,8);return b;}
static uint32_t tick(void){if(!recording)return 1000;assert(reads<10000);uint32_t t=1000+reads++;printf("T,%u,%u,%u",profile,route,t);if(dispatch_mode)printf(",%d",*(short *)(gref+0x5aa));putchar('\n');return t;}
static void keys(void *p){memset(p,0,16);if(startup_input&&profile<3)((unsigned char *)p)[4]=0x10;if(recording)printf("K,%u,%u,%u\n",profile,route,frame);}
static void mouse(Point *p){if(click_pending){p->h=(short)(*(double *)(gref+0xea2)+*(double *)clicked_node+*(double *)(clicked_node+16)/2);p->v=(short)(*(double *)(gref+0xeaa)+*(double *)(clicked_node+8)+*(double *)(clicked_node+24)/2);click_pending=0;held_point=*p;}else if(profile>=6)*p=held_point;else {p->h=-30000;p->v=-30000;}}
static int zero(void){return 0;}
static int button(void){return held_button;}
static Handle resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
static void snapshot(unsigned f){for(unsigned i=0;i<52;i++){unsigned char *n=nodes[i];printf("N,%u,%u,%u,%u,%d,%d,%u",profile,route,f,i,*(short *)(n+38),*(int *)(n+296),*(uint32_t *)(n+34));for(unsigned a=0;a<4;a++)printf(",%016llx",word(*(double *)(n+a*8)));putchar('\n');}}
void star_draw(void){assert(fwrite(stars+4,8,3000*4,star_dump)==3000*4);printf("S,%u,%u,%u,%u,%016llx,%016llx",profile,route,frame,*(uint32_t *)(gref+0x244),word(*(double *)(gref+0xea2)),word(*(double *)(gref+0xeaa)));for(unsigned i=0;i<4;i++)printf(",%016llx",word(stars[4+i]));putchar('\n');}
void sprite_draw(void){snapshot(frame);printf("D,%u,%u,%u\n",profile,route,frame);}
void menu_draw(void){printf("O,%u,%u,%u\n",profile,route,frame);}
void swap(void){*(short *)(gref+0xec6)=(short)((unsigned short)*(short *)(gref+0xec6)+1u);printf("W,%u,%u,%u\n",profile,route,frame++);assert(frame<1000);}
void music(void){printf("U,%u,%u,%u\n",profile,route,frame);}
void sound(unsigned char *name,double *position){assert(name[0]==5&&!memcmp(name+1,"Click",5));printf("P,%u,%u,%016llx,%d\n",profile,route,word(*position),*(short *)(gref+0x5aa));}
void saved(void){assert(dispatch_mode&&route==(routes_mode?9u:1u));printf("I,%u,%u,%d,%u,%016llx,%016llx\n",profile,route,*(short *)(clicked_node+38),*(uint32_t *)(clicked_node+34),word(*(double *)(gref+0xea2)),word(*(double *)(gref+0xeaa)));}
BRIDGE(sound) BRIDGE(saved) BRIDGE(star_draw) BRIDGE(sprite_draw) BRIDGE(menu_draw) BRIDGE(swap) BRIDGE(music)
static unsigned char *find(const char *name){for(unsigned i=0;i<52;i++)if(nodes[i][40]==strlen(name)&&!memcmp(nodes[i]+41,name,strlen(name)))return nodes[i];abort();}
int main(int argc,char **argv){
 if(argc!=7&&argc!=8)return 2;dispatch_mode=argc==8;routes_mode=dispatch_mode&&!strcmp(argv[7],"routes");returns_mode=dispatch_mode&&!strcmp(argv[7],"returns");startup_mode=dispatch_mode&&!strcmp(argv[7],"startup");assert(!dispatch_mode||routes_mode||returns_mode||startup_mode||!strcmp(argv[7],"dispatch"));alarm(60);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884&&!stat(argv[4],&st)&&st.st_size==14014&&!stat(argv[5],&st)&&st.st_size==52*308);
 struct stat output;if(!stat(argv[6],&output))for(unsigned i=1;i<=5;i++){assert(!stat(argv[i],&st));assert(st.st_dev!=output.st_dev||st.st_ino!=output.st_ino);}star_dump=fopen(argv[6],"wb");assert(star_dump);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*raw=read_file(argv[3]),*table=read_file(argv[4]),*scene=read_file(argv[5]),*g=calloc(1,0x1400),*heap=calloc(1,0x100000);assert(g&&heap);gref=g;stars=calloc(3001*4,8);assert(stars);strings=NewHandle(6884);assert(strings);memcpy(*strings,raw,6884);for(unsigned i=0;i<52;i++){nodes[i]=calloc(1,308);assert(nodes[i]);}
 uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"TickCount"))fn=tick;if(!strcmp(import_names[i],"GetKeys"))fn=keys;if(!strcmp(import_names[i],"GetMouse"))fn=mouse;if(!strcmp(import_names[i],"Button"))fn=button;if(!strcmp(import_names[i],"GetResource"))fn=resource;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;
 const struct{unsigned at;void *fn;} hooks[]={{0x3ce84,sound_fb},{0x3dee8,saved_fb},{0x24248,zero},{0x45af0,star_draw_fb},{0x3aaf8,sprite_draw_fb},{0x46394,menu_draw_fb},{0x35eb8,swap_fb},{0x334bc,music_fb}};
 for(unsigned i=0;i<sizeof(hooks)/sizeof(*hooks);i++)jump_to(code+hooks[i].at,hooks[i].fn);// Bounded original Main frame permits an eligible released poll between clicks.
 uint32_t *entry=(uint32_t *)(code+0x66cf8-12),*tail=(uint32_t *)(code+0x66e90);entry[0]=0x7c0802a6;entry[1]=0x90010010;entry[2]=0x90410014;tail[0]=0x80010010;tail[1]=0x7c0803a6;tail[2]=0x4e800020;
 MakeDataExecutable(code,433284);
 for(profile=0;profile<(dispatch_mode?9u:3u);profile++){
  memset(g,0,0x1400);recording=reads=0;*(void **)(g+0x21c)=lit;*(void **)(g+0xe82)=table;*(void **)(g+0x388)=heap;*(void **)(g+0x38c)=heap;*(void **)(g+0xa54)=stars;*(void **)(g+0xe86)=nodes[0];*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;*(short *)(g+0xed6)=640;*(short *)(g+0xed8)=480;*(short *)(g+0xa52)=profile%3+1;*(short *)(g+0x58c)=1;*(uint32_t *)(g+0xec8)=1000;*(uint32_t *)(g+0x244)=0x12345678;*(double *)(g+0xea2)=-599.5;*(double *)(g+0xeaa)=-344;*(double *)(g+0xa58)=2;*(double *)(g+0xa60)=-1;
  for(unsigned i=0;i<52;i++){memcpy(nodes[i],scene+i*308,308);*(uint32_t *)(nodes[i]+34)=1000;*(void **)(nodes[i]+300)=i<51?nodes[i+1]:NULL;*(void **)(nodes[i]+304)=i?nodes[i-1]:NULL;}
  for(unsigned i=1;i<=3000;i++){stars[i*4]=80;stars[i*4+1]=(i*17)%640;stars[i*4+2]=(i*29)%480;stars[i*4+3]=i%5+1;}
  if(startup_mode){*(double *)(g+0xea2)=*(double *)(g+0xeaa)=0;unsigned char name[256]={0};name[0]=9;memcpy(name+1,"Main Menu",9);invoke_fb(code+0x4b3a4,g,toc,name,NULL,NULL);name[0]=12;memcpy(name+1,"Credits Menu",12);assert(!invoke_fb(code+0x3b260,g,toc,name,NULL,NULL));invoke_fb(code+0x4b3a4,g,toc,name,NULL,NULL);}
  recording=1;
  for(route=0;route<(startup_mode?1u:routes_mode?12u:2u);route++){
   frame=0;const char *button=returns_mode?return_buttons[route]:routes_mode?route_buttons[route]:route?"Back":"Settings",*destination=route?"Main Menu":"Settings Menu";clicked_node=find(button);
   if(returns_mode){recording=0;unsigned char name[256]={0};const char *origin=route?"Reg Thanks":"CreditsMenu";name[0]=strlen(origin);memcpy(name+1,origin,name[0]);invoke_fb(code+0x4b3a4,g,toc,name,NULL,NULL);recording=1;}
   if(startup_mode){held_button=profile>=3;held_point.h=369;held_point.v=175;click_pending=0;startup_input=1;music();invoke_fb(code+0x4cb28,g,toc,NULL,NULL,NULL);assert(held_button||*(short *)(g+0xab6));startup_input=0;*(short *)(g+0x5aa)=1;unsigned char name[256]={0};name[0]=9;memcpy(name+1,"Main Menu",9);invoke_fb(code+0x4b3a4,g,toc,name,(void *)1,NULL);}
   else if(dispatch_mode){held_button=profile>=3;click_pending=1;unsigned char empty[256]={0};invoke_fb(code+0x3f178,g,toc,empty,NULL,NULL);assert(!click_pending);}
   else {invoke_fb(code+0x343b4,g,toc,clicked_node,(void *)901,NULL);unsigned char name[256]={0};name[0]=strlen(destination);memcpy(name+1,destination,name[0]);invoke_fb(code+0x4b3a4,g,toc,name,(void *)1,NULL);invoke_fb(code+0x343b4,g,toc,clicked_node,(void *)900,NULL);}
   snapshot(999);printf("Z,%u,%u,%u,%u,%016llx,%016llx",profile,route,frame,reads,word(*(double *)(g+0xea2)),word(*(double *)(g+0xeaa)));if(dispatch_mode){assert(*(short *)(g+0x5aa)==(startup_mode?(profile>=3):1));printf(",%d",*(short *)(g+0x5aa));}putchar('\n');
   if(dispatch_mode&&route<(routes_mode?11u:1u)){if(held_button){unsigned before=frame;printf("H,%u,%u\n",profile,route);invoke_fb(code+0x66cf8-12,g,toc,NULL,NULL,NULL);printf("F,%u,%u,%d\n",profile,route,*(short *)(g+0x5aa));assert(frame==before+1&&*(short *)(g+0x5aa)==1);held_button=0;}unsigned before=frame;printf("B,%u,%u\n",profile,route);invoke_fb(code+0x66cf8-12,g,toc,NULL,NULL,NULL);printf("E,%u,%u,%d\n",profile,route,*(short *)(g+0x5aa));assert(frame==before+1&&*(short *)(g+0x5aa)==0);}

  }recording=0;
 }
 assert(!fclose(star_dump));fputs(returns_mode?"PASS9 actual DOMOUSE Yeah/Back5 return paths\n":startup_mode?"PASS9 original startup acceptance camera/frame/latch profiles\n":routes_mode?"PASS9 actual DOMOUSE12route menu chains with held/release schedules\n":dispatch_mode?"PASS9 actual DOMOUSE two-way navigation profiles,save order,held drag/stationary hover and released poll\n":"PASS3 whole MOVEMENUTO profiles, two-way52node scenes and3000realstars/RNG, no GPU window\n",stderr);return 0;
}
