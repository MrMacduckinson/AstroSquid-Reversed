#ifndef ASTROSQUID_PPC_BRIDGE_H
#define ASTROSQUID_PPC_BRIDGE_H
#include <stdint.h>
extern uint32_t invoke_fb(void *,void *,void *,void *,void *,void *);
__asm__(
".text\n.align 2\n.globl _invoke_fb\n_invoke_fb:\n"
"mflr r0\nstw r0,8(r1)\nstwu r1,-256(r1)\n"
"stmw r13,32(r1)\nstfd f14,112(r1)\nstw r2,24(r1)\n"
"mr r12,r3\nmr r14,r4\nmr r2,r5\nmr r3,r6\nmr r4,r7\nmr r5,r8\n"
"mtctr r12\nbctrl\nlwz r2,24(r1)\nlfd f14,112(r1)\n"
"lmw r13,32(r1)\naddi r1,r1,256\nlwz r0,8(r1)\nmtlr r0\nblr\n");
#endif
