# Original ordinary-bullet clocks

Run on the G5:

```
gcc -std=gnu99 -O2 -I tools tools/ppc_bullet_clock_oracle.c \
 -framework Carbon -o bullet_oracle
./bullet_oracle analysis/download-3/AstroSquid.pef > native.csv
```

PEF MD5: `b93ca67a59bbc3cbcad434402bfa7bca`.
The full DOBULLETSPRITE10061a48 runs in a private loaded original-code copy.
Only its TickCount import glue is redirected to a finite clock provider. No
game window, renderer, sound, live-game patch or preference write is requested.

The8 cases exercise equality, fresh comparison/store, unsigned wrap interpreted
through signed elapsed time, a negative half-range, a backward tick and states
0/2/-1. The7 reads record actual call sites10061a9c/10061ae0 and update_tick before
the read. All entity bytes outside update_tick must remain unchanged.

tests/bullet_clock_native.csv is the original output. The existing Intel test
tests/bullet_clock_host_test.m now replays it by default, alongside explicitly
source-derived common movement checks. Compile with the same sources/frameworks
as build.sh, substituting that test for src/preview.m, then run from the repo
root with `assets` (or `assets tests/bullet_clock_native.csv`). This proves the
bounded timer routine, not a complete coupled bullet/collision/render trace.
