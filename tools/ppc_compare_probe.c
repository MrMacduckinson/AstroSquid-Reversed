/* Verify the FB compiler's reserved compare bit on real PowerPC hardware. */
#include <stdio.h>
#include <stdint.h>

extern uint32_t legacy_compare(const double *, const double *);
extern uint32_t canonical_compare(const double *, const double *);

__asm__(
".text\n.align 2\n.globl _legacy_compare\n_legacy_compare:\n"
"stfd f14,-8(r1)\nlfd f14,0(r3)\nlfd f2,0(r4)\n"
".long 0xfc2e1000\nmfcr r3\nlfd f14,-8(r1)\nblr\n"
".align 2\n.globl _canonical_compare\n_canonical_compare:\n"
"stfd f14,-8(r1)\nlfd f14,0(r3)\nlfd f2,0(r4)\n"
".long 0xfc0e1000\nmfcr r3\nlfd f14,-8(r1)\nblr\n");

int main(void) {
    int i,j;
    unsigned cases=0;
    const double values[]={-1000000.0,-360.0,-1.0,-0.0,0.0,0.25,1.0,2.0,360.0,1000000.0};
    for(i=0;i<10;i++) for(j=0;j<10;j++) {
        uint32_t a=legacy_compare(&values[i],&values[j])>>28;
        uint32_t b=canonical_compare(&values[i],&values[j])>>28;
        if(a!=b) { printf("FAIL at %d,%d: %u != %u\n",i,j,a,b); return 1; }
        cases++;
    }
    printf("PASS: legacy/canonical PowerPC compare CR0 agrees for %u real-hardware cases\n",cases);
    return 0;
}
