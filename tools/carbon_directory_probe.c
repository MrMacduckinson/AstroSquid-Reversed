/* Read-only directory identity helper for the G5 launch-context reference. */
#include <Carbon/Carbon.h>
#include <stdio.h>
int main(int argc,char **argv){
 if(argc<2)return 2;
 for(int i=1;i<argc;i++){
  FSRef ref;FSCatalogInfo info;
  if(FSPathMakeRef((const UInt8 *)argv[i],&ref,NULL)||FSGetCatalogInfo(&ref,kFSCatInfoNodeID|kFSCatInfoVolume,&info,NULL,NULL,NULL))return 3;
  printf("directory,%s,volume%d,node%u\n",argv[i],info.volume,(unsigned)info.nodeID);
 }
 return 0;
}
