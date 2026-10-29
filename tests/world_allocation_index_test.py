#!/usr/bin/env python3
"""Exercise the actual oracle allocation index without PPC/runtime dependencies."""
import pathlib, subprocess, tempfile
root = pathlib.Path(__file__).resolve().parents[1]
source = (root / "tools/ppc_world_oracle.c").read_text()
body = source[source.index("typedef struct {unsigned char *p;"):source.index("void world_sound(")]
check = r"""
int main(void){
 assert(!allocation(NULL)&&identity(NULL)==0);
 for(unsigned i=0;i<100000;i++){
  long size=i%3==0?106:i%3==1?308:1;
  void *p=world_alloc(size);
  assert(allocation(p)==&allocations[i]);
  assert(identity(p)==(i%3==2?i+1:i/3+1));
  if(i%2==0)world_dispose(p);
 }
 for(unsigned i=100000;i>0;i--){
  Allocation *a=&allocations[i-1];assert(allocation(a->p)==a);
  assert(a->alive==((i-1)%2!=0));
 }
 int unknown;assert(!allocation(&unknown));
 entity_birth=render_birth=0;
 void *p=world_alloc(106);assert(identity(p)==1);
 for(unsigned i=0;i<allocation_count;i++)free(allocations[i].p);
 puts("PASS allocation IDs, disposed pointers, reverse lookup, unknown pointers and rebasing");
}
"""
with tempfile.TemporaryDirectory() as directory:
 path = pathlib.Path(directory)
 (path / "check.c").write_text("#include <stdint.h>\n#include <stdlib.h>\n#include <stdio.h>\n#include <assert.h>\n" + body + check)
 subprocess.run(["cc", "-std=c99", "-O2", str(path / "check.c"), "-o", str(path / "check")], check=True)
 subprocess.run([str(path / "check")], check=True)
