# Original plasma phase timing

The old phase host test expected30 nested plasma updates and action192 at
interval3. It failed before and after the pause change. A private original G5
capture with the same controlled clock boundaries instead gives31/action193,
and matches the existing host. Production logic was not changed for this fix.

Compile/run tools/ppc_special_phase_oracle.c only on the G5:

```
gcc -std=gnu99 -O2 -mno-fused-madd -I analysis/script-oracle \
 tools/ppc_special_phase_oracle.c -framework Carbon -lm -o phase_oracle
./phase_oracle original.pef original.literals.bin original_resource_app \
 analysis/script-oracle 1
```

Supply the unchanged6884-byte STR#25000 payload as original.pef.strings, extracted
using tools/macresources.py. Before running, the oracle compares it byte-for-byte
with the resource opened read-only from original_resource_app. Original PEF MD5
is b93ca67a59bbc3cbcad434402bfa7bca; literals MD5 is
da53d77004bb595663b57f260f7776c7. Input/table sizes, case0..6, two trampoline
prologues and final state invariants are checked; a20-second alarm bounds errors.
Dependencies are ppc_active_special_world_oracle.c, ppc_bridge.h and imports.h.

The native entry is FIREWEAPONSPECIAL1005bd0c, weapon40, source player with HP200,
position100/180, velocity2/0, update99, animation100, action0. Original beam/LM
creation, temporary beam deletion, forced flashes, nested CALC, player tails and
LM animation execute. Separate clocks inside CALC and LMHANDLE are held at the
latest tick, matching this host probe's explicit fixedWorldClock hooks. Checked
16-byte save/link/stack prologues are copied to private trampolines; callbacks
set the clock mode then execute the complete original function bodies. No live
game, original on-disk program, preferences or user files are patched.

Advancing clock values are100+readOrdinal/1000, beginning with ordinal0. Case6
instead supplies exactly100/100/100/131, producing no CPU pass. Cases use
intervals2/3/0/-1/3/3/3; initial render clock is99 for case0,98 for case5 and100
otherwise. Native cases1/4 intentionally repeat the same timing inputs; host
case4 additionally verifies its pending-invulnerability marker does not suppress
the special's unconditional kind1 restoration. This is not a native capture of
the full NEWPLAYERSTART caller.

Rendering counts frames, swapping counts presentations, and GL/audio/HUD drawing
are observers. The host renderer probe also consumes a synthetic RNG draw; RNG
and graphics state are outside this timing comparison. No advancing clock is
consumed by those render observers. Native temporary allocations retain retired
storage as in the existing oracle; there is no freed-node continuation here.

Two native captures repeated exactly, then the final input-size-checked build
reproduced them again. tests/special_phase_native.csv records7 summaries of
186082 advancing clock queries. Frozen queries and original callsite identities
are not enumerated in this fixture. Intel special_phase_host_test checks exact
update/beam counts, advancing clock totals, final action/CPU/render/tick values
and frame/swap counts, plus its existing connected order/continuation assertions.
A further host-only variant reuses case1's timing while injecting Command-Q in
actual nested raw input: all31 updates complete, the latch persists, and the
ordinary tail then cleans the world. It is not an additional native quit capture.
Compile with build.sh sources/frameworks, replacing src/preview.m with that test;
run from the repository root:

```
build/special_phase_host_test assets
```

The subsequent outer render eligibility and separate fresh-clock sequence in the
host test are source-backed checks, not a native GAMELOOP capture. Full gameplay,
renderer/music/mouse and all-opcode equivalence remain open.
