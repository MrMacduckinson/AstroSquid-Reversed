/* Run original preference IO wrappers; every filesystem import is replaced. */
#define main unused_hud_oracle_main
#include "ppc_hud_oracle.c"
#undef main
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
static unsigned char *g;static int mode,res_result,df_result,io_result;static unsigned transferred,events,cases;static unsigned char source[542],captured[542];
static void event(unsigned e){events=events*10+e;}
void pref_path(const unsigned char *name,const void *folder,unsigned creator){assert(name[0]==4&&!memcmp(name+1,"TEST",4));(void)folder;assert(creator==0x3f3f3f3f);event(1);}
BRIDGE(pref_path)
static short open_res(const void *spec,signed char permission){assert(spec==g+0x11c4&&permission==mode);event(2);return res_result;}
static short open_df(const void *spec,signed char permission,short *ref){assert(spec==g+0x11c4&&permission==mode&&ref==(short *)(g+0x120c));event(3);if(!df_result)*ref=17;return df_result;}
static short read_df(short ref,long *n,void *p){assert(mode==1&&ref==17&&*n==542&&p==g+0xab8);event(4);*n=transferred;memcpy(p,source,transferred);return io_result;}
static short write_df(short ref,long *n,const void *p){assert(mode==2&&ref==17&&*n==542&&p==g+0xab8);event(4);*n=transferred;memcpy(captured,p,transferred);return io_result;}
static void close_res(short ref){assert(ref==res_result);event(5);}
static short close_df(short ref){assert(ref==17);event(6);return -36;}
int main(int argc,char **argv){
 if(argc!=3)return 2;alarm(60);struct stat st;assert(!stat(argv[1],&st)&&st.st_size==455780&&!stat(argv[2],&st)&&st.st_size==11812);
 unsigned char *code=read_file(argv[1])+128,*lit=read_file(argv[2]),*heap=calloc(1,0x100000);g=calloc(1,0x1400);assert(g&&heap);
 uint32_t toc[489]={0};for(unsigned i=0;i<484;i++){
  void *fn=missing_import;
  if(!strcmp(import_names[i],"FSpOpenResFile"))fn=open_res;
  if(!strcmp(import_names[i],"FSpOpenDF"))fn=open_df;
  if(!strcmp(import_names[i],"FSRead"))fn=read_df;
  if(!strcmp(import_names[i],"FSWrite"))fn=write_df;
  if(!strcmp(import_names[i],"CloseResFile"))fn=close_res;
  if(!strcmp(import_names[i],"FSClose"))fn=close_df;
  descriptors[i][0]=(uint32_t)(uintptr_t)fn;toc[i]=(uint32_t)(uintptr_t)descriptors[i];
 }toc[0]=(uint32_t)(uintptr_t)g;toc[1]=(uint32_t)(uintptr_t)lit;
 *(void **)(g+0x21c)=lit;*(void **)(g+0x388)=heap;jump_to(code+0x65fbc,pref_path_fb);MakeDataExecutable(code,433284);
 const int resources[]={-1,0,7};
 for(mode=1;mode<=2;mode++)for(unsigned r=0;r<3;r++)for(unsigned failed=0;failed<2;failed++)for(transferred=0;transferred<=542;transferred++)for(unsigned err=0;err<2;err++){
  res_result=resources[r];df_result=failed?-43:0;io_result=err?-39:0;events=0;*(short *)(g+0x120a)=*(short *)(g+0x120c)=0;
  for(unsigned i=0;i<542;i++)source[i]=(i*17+transferred)&255;memset(g+0xab8,0xa5,542);memset(captured,0x5a,542);heap[0]=4;memcpy(heap+1,"TEST",4);*(void **)(g+0x38c)=heap;
  int result=(int)invoke_fb(code+(mode==1?0x66ad0:0x66b54),g,toc,g+0xab8,(void *)542,NULL);
  assert(result==(failed?df_result:io_result));assert(events==(failed?123u:(res_result?123456u:12346u)));
  if(failed){assert(*(short *)(g+0x120a)==res_result);assert(!*(short *)(g+0x120c));}
  else{assert(!*(short *)(g+0x120a)&&!*(short *)(g+0x120c));}
  for(unsigned i=0;i<542;i++){assert(g[0xab8+i]==(mode==1&&!failed&&i<transferred?source[i]:0xa5));assert(captured[i]==(mode==2&&!failed&&i<transferred?0xa5:0x5a));}
  cases++;
 }
 printf("PASS %u original preference IO transactions: open failure, partial read/write, returned error, close order and live bytes; all filesystem imports intercepted\n",cases);return 0;
}
