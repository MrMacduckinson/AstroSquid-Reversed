#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
int main(){double a[]={0.,-0.,1.9,-1.9,2147483647.,2147483647.9,2147483648.,-2147483648.,-2147483648.9,-2147483649.,INFINITY,-INFINITY,NAN};unsigned i;for(i=0;i<sizeof(a)/sizeof(*a);i++){double out;uint64_t u,v;__asm__("fctiwz %0,%1":"=f"(out):"f"(a[i]));memcpy(&u,&a[i],8);memcpy(&v,&out,8);printf("%016llx,%08x\n",(unsigned long long)u,(unsigned)v);}return 0;}
