/* Original LMHANDLE/LMCHANGE/LMKILL with clock-consuming changes and diagnostic
 * tail. Traversal snapshots next before deletion; comparison tick is shared. */
#include "../src/visual.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef struct {AstroVisual v;int next,prev,deleted;} Image;
static void row(FILE*f,char*line,char tag){assert(fgets(line,256,f));assert(line[0]==tag);}
static uint64_t word(double v){uint64_t u;memcpy(&u,&v,8);return u;}
static double value(unsigned long long x){uint64_t u=x;double d;memcpy(&d,&u,8);return d;}
static uint32_t clock_read(FILE*f,unsigned*reads,unsigned site){char line[256];unsigned index,address,tick;row(f,line,'T');assert(sscanf(line,"T,%u,%x,%u",&index,&address,&tick)==3);assert(index==(*reads)++&&address==site);return tick;}
int main(int argc,char**argv){
 assert(argc==2);FILE*f=fopen(argv[1],"r");assert(f);char line[256];unsigned cases=0,total_reads=0,changes=0,kills=0;
 AstroSpriteInfo info[6]={{0,0,0,0},{10,20,2,7},{24,12,0,3},{10,20,-1,7},{10,20,0,7},{10,20,2,7}};
 while(fgets(line,sizeof(line),f)){
  int scenario;unsigned diagnostic_deadline;assert(sscanf(line,"CASE,%d,%u",&scenario,&diagnostic_deadline)==2);assert(scenario==(int)cases);Image images[5];
  for(int i=0;i<5;i++){int index,id;unsigned deadline;unsigned long long x,y,w,h;row(f,line,'I');assert(sscanf(line,"I,%d,%d,%u,%llx,%llx,%llx,%llx",&index,&id,&deadline,&x,&y,&w,&h)==7&&index==i);images[i]=(Image){{id,value(x),value(y),value(w),value(h),deadline},i==4?-1:i+1,i?i-1:-1,0};}
  unsigned reads=0;uint32_t comparison=clock_read(f,&reads,0x1003b570);int head=scenario==5?-1:0;
  for(int i=head;i>=0;){int next=images[i].next;AstroVisual*v=&images[i].v;int frame=info[v->sprite].next_frame;int due=frame&&(int32_t)v->next_tick<(int32_t)comparison;uint32_t store=0;
   if(due&&frame>0){store=clock_read(f,&reads,0x100343f0);changes++;}
   int alive=astro_visual_step_clocked(v,info,6,comparison,store);assert(alive>=0);
   if(!alive){int id;row(f,line,'D');assert(sscanf(line,"D,%d",&id)==1&&id==i&&due&&frame<0);images[i].deleted=1;if(images[i].next>=0)images[images[i].next].prev=images[i].prev;if(images[i].prev>=0)images[images[i].prev].next=images[i].next;if(head==i)head=images[i].next;kills++;}
   i=next;
  }
  row(f,line,'K');row(f,line,'B');unsigned bit,debug;assert(sscanf(line,"B,%u,%u",&bit,&debug)==2&&bit==125&&debug==(unsigned)(scenario&1));
  int counter=-7;double rate=1.25;uint32_t diagnostic=clock_read(f,&reads,0x1003b748);
  if((int32_t)(diagnostic_deadline+60u)<=(int32_t)diagnostic){rate=counter;counter=0;diagnostic_deadline=clock_read(f,&reads,0x1003b788);}
  for(int i=0;i<5;i++){int index,deleted,id,next,prev;unsigned deadline;unsigned long long x,y,w,h;row(f,line,'O');assert(sscanf(line,"O,%d,%d,%d,%u,%llx,%llx,%llx,%llx,%d,%d",&index,&deleted,&id,&deadline,&x,&y,&w,&h,&next,&prev)==10&&index==i);Image*a=images+i;assert(a->deleted==deleted&&a->v.sprite==id&&a->v.next_tick==deadline&&word(a->v.x)==x&&word(a->v.y)==y&&word(a->v.width)==w&&word(a->v.height)==h&&a->next==next&&a->prev==prev);}
  int expected_head,expected_counter,expected_debug;unsigned expected_deadline;unsigned long long expected_rate;row(f,line,'G');assert(sscanf(line,"G,%d,%d,%u,%d,%llx",&expected_head,&expected_counter,&expected_deadline,&expected_debug,&expected_rate)==5);assert(head==expected_head&&counter==expected_counter&&diagnostic_deadline==expected_deadline&&debug==(unsigned)expected_debug&&word(rate)==expected_rate);
  row(f,line,'E');unsigned expected_reads;assert(sscanf(line,"END,%u",&expected_reads)==1&&reads==expected_reads);total_reads+=reads;cases++;
 }
 assert(feof(f));fclose(f);assert(cases==6&&total_reads==25&&changes==9&&kills==4);printf("PASS:%u original LM lifecycle scripts,%u clockreads,%u exact geometry/deadline changes,%u unlink/kills +signedwrap/diagnostic tail\n",cases,total_reads,changes,kills);return 0;
}
