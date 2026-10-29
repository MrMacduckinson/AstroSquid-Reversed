/* Execute original GETPREFS/SAVEPREFS with private memory and observed IO. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g,*heap,*raw,source[542],written[542];
static unsigned count,loads,saves;static Handle strings;static FILE *fixture;
static void emit(const unsigned char *p){if(fixture)assert(fwrite(p,1,542,fixture)==542);}
static Handle pref_resource(ResType type,short id){assert(type=='STR#'&&id==25000);return strings;}
void pref_load(void *p,unsigned n){assert(p==g+0xab8&&n==542);memcpy(p,source,count);loads++;}
void pref_save(void *p,unsigned n){assert(p==g+0xab8&&n==542);memcpy(written,p,n);saves++;}
BRIDGE(pref_load) BRIDGE(pref_save)
static void put16(unsigned char *p,unsigned v){p[0]=v>>8;p[1]=v;}
static int get16(const unsigned char *p){unsigned n=(p[0]<<8)|p[1];return n<32768?(int)n:(int)n-65536;}
/* FBSetPascalStr copies words, including the following byte for even lengths. */
static void label(unsigned char *p,unsigned index){unsigned char *s=raw+2;while(--index)s+=s[0]+1;memcpy(p,s,2+2*(s[0]/2));}
static void defaults(unsigned char *p){put16(p,1);put16(p+2,60);put16(p+4,10);put16(p+6,6);label(p+10,165);label(p+266,141);unsigned keys[]={48,61,121,122,123,124};for(unsigned i=0;i<6;i++)put16(p+522+i*2,keys[i]);put16(p+534,1);put16(p+536,1);}
int main(int argc,char **argv){
 if(argc!=4&&argc!=5)return 2;alarm(60);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812&&!stat(argv[3],&st)&&st.st_size==6884);unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]);raw=read_file(argv[3]);g=calloc(1,0x1400);heap=calloc(1,0x100000);strings=NewHandle(6884);assert(g&&heap&&strings);memcpy(*strings,raw,6884);
 uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){void *fn=dlsym(RTLD_DEFAULT,import_names[i]);if(!strcmp(import_names[i],"GetResource"))fn=pref_resource;descriptors[i][0]=(uint32_t)(uintptr_t)(fn?fn:missing_import);toc[i]=(uint32_t)(uintptr_t)descriptors[i];}toc[0]=(uint32_t)(uintptr_t)g;toc[1]=(uint32_t)(uintptr_t)lit;
 *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;*(double *)(g+0x378)=4503601774854144.;*(uint32_t *)(g+0x380)=0x43300000;
 jump_to(code+0x66ad0,pref_load_fb);jump_to(code+0x66b54,pref_save_fb);MakeDataExecutable(code,433284);
 if(argc==5){struct stat out;if(!stat(argv[4],&out))for(unsigned i=1;i<4;i++){assert(!stat(argv[i],&st));assert(st.st_dev!=out.st_dev||st.st_ino!=out.st_ino);}fixture=fopen(argv[4],"wb");assert(fixture);}
 unsigned cases=0;unsigned char expected[542],before[542];
 for(unsigned pattern=0;pattern<3;pattern++)for(count=0;count<=542;count++){
  for(unsigned i=0;i<542;i++)source[i]=pattern==0?0:pattern==1?255:(i*17+31)&255;
  memset(g+0xab8,0xa5,542);memset(expected,0xa5,542);defaults(expected);memcpy(expected,source,count);int unlocked=(short)(get16(expected+534)-100);if(unlocked<1)unlocked=1;put16(expected+534,unlocked);
  *(void **)(g+0x38c)=heap;invoke_fb(code+0x3dda8,g,toc,NULL,NULL,NULL);for(unsigned j=0;j<542;j++)if(expected[j]!=g[0xab8+j]){fprintf(stderr,"Mismatch pattern%u read%u offset%u expected%02x actual%02x\n",pattern,count,j,expected[j],g[0xab8+j]);return 1;}assert(get16(g+0xee6)==get16(expected+536));emit(g+0xab8);cases++;
 }
 count=542;for(unsigned value=0;value<65536;value++){
  for(unsigned i=0;i<542;i++)source[i]=(i*23+value)&255;put16(source+534,value);
  *(void **)(g+0x38c)=heap;invoke_fb(code+0x3dda8,g,toc,NULL,NULL,NULL);memcpy(expected,source,542);int v=(short)(value-100);if(v<1)v=1;put16(expected+534,v);assert(!memcmp(expected,g+0xab8,542));assert(get16(g+0xee6)==get16(source+536));emit(g+0xab8);
  /* Saving must restore the live signed word even when adding100 wraps. */
  put16(g+0xcce,value);memcpy(before,g+0xab8,542);memcpy(expected,before,542);put16(expected+534,value+100);
  *(void **)(g+0x38c)=heap;invoke_fb(code+0x3dee8,g,toc,NULL,NULL,NULL);assert(!memcmp(expected,written,542));assert(!memcmp(before,g+0xab8,542));emit(written);cases+=2;
 }
 if(fixture)assert(!fclose(fixture));assert(loads==3*543+65536&&saves==65536);printf("PASS %u original preference transactions: all signed16 level words, all543 partial-read boundaries, three byte patterns; exact542-byte payload and live restoration; no filesystem IO\n",cases);return 0;
}
