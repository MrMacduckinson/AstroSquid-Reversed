# Original debris clock oracle

Run on the reference G5 with a private copy of download-3 code:

```
gcc -std=gnu99 -O2 -mno-fused-madd -I analysis/script-oracle \
 tools/ppc_debris_clock_oracle.c src/script.c src/physics.c src/ppc_math.c \
 -framework Carbon -lm -o debris_oracle
./debris_oracle analysis/download-3/AstroSquid.pef \
 analysis/download-3/AstroSquid.literals.bin > native.csv
```

Include src/ppc_atan_table.h when copying build dependencies to the G5. The
renamed script-oracle main is linked but never called by the debris oracle.
The tested state and arithmetic execute in original DOSHRAPNELSPRITE100636a0
or CALCSPRITES10054c64, with a single kind20 entity.

The input PEF MD5 is `b93ca67a59bbc3cbcad434402bfa7bca`. Original disk files and
the live game are untouched. TickCount is scripted in the private loaded code;
MOVESTARS10042234 and CHECKSPRITECOLLISION100549e8 return immediately. No game
window, renderer, sound playback or original preference changes are requested.

The12 cases cover inactive shrapnel, strict animation/update/lifetime gates,
independent comparison/store values, signed wrap boundaries, left-edge removal
and an already removed entity. Each clock record includes its actual original
call-site address and the entity's update, animation and removal fields before
the read. Final records retain raw double bits for both velocity components.

`tests/debris_clock_vectors.csv` is the new2026-10-28 capture:12cases,32reads.
The older remote2026-10-19 output was unavailable and was not recovered.
`tests/debris_clock_test.c` replays the native file; test.sh runs it by default
alongside separately labelled source-derived cases. These isolated comparisons
do not prove full world, collision, rendering or allocator equivalence.
