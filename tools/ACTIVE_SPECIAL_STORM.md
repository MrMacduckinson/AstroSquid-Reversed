# Coupled nested storm with real beam/LM allocation

The `storm` variant of `ppc_active_special_world_oracle.c` runs original CALC,
player logic, timed special50, nested cleanup/CALC, beam creation/collision,
beam rendering, FORCEDRAWSPRITENOW, LM updates, swap and resumed outer traversal.
Original download3 code/literals/tables are privately loaded on G5. The original
reference application's STR#25000 is checked byte-for-byte against the extracted
download3 resource before execution; supply its6884 bytes as PEF_PATH.strings.
The original file/game/preferences are never patched.

Compile on G5 with `-std=gnu99 -O2 -mno-fused-madd`, imports.h include directory,
`-framework Carbon -lm`. Arguments are PEF, literals, original resource-fork app,
tables directory, output state.tsv, output clocks.csv, `storm`.

The fixture adds NEWSPRITE20/4 at300,180 HP30000 before the player, so it also
exercises resuming a surviving tail. Other clocks/keys/setup follow the older
base/tail active-special fixtures. Clock is100+readOrdinal/4096; every native
read retains its original PPC callsite. Disposed allocations are logically dead
but retain storage: allocator address reuse is outside this evidence.

RENDERGAMEWINDOW is an observer which executes real original RENDERBEAM for all
world beams in original head order. Other drawing is omitted. GL imports and
LMDRAWSPRITE are no-ops; texture0 is already loaded. Original LM creation,
mutation, clocks and deletion remain real. FORCEDRAWSPRITENOW is original here,
not the flash observer used by the old no-target fixtures. Thus the historical
`flashes0` stderr field counts observer callbacks, not actual flashes.
Audio observes cue/pan. Two HUD observer records remain explicitly outside the
host presentation boundary in `active_special_trace.py`; there is no pixel,
GPU, acoustic or full HUD equivalence claim.

## Verified result

Two fresh native runs reproduced state and callsite/clock streams byte-for-byte.
Intel production host matches1324 Q/G/E/R/S records and127087 clock values.
Original374 entity creations and2420 LM creations match host totals. There are
372 beam entities (two per successful storm hit), and2780 native disposal calls.
A timed storm ran31 render/swap/LM passes, returned at131 and resumed its tail.
Final RNG9ed47e4e and player action191 match. Golden native state and compressed
callsite clocks are in tests/active_special_world_storm_*.

This exposed a production gap: one-frame special flashes were drawn without
consuming their LM birth and fresh TickCount. `addSpecialSprite` now consumes
both and stores the original sprite-delay deadline; redraw remains side-effect
free. Before the fix, first swap used4196 instead of4201 clock reads and the
whole call ended at127081 instead of127087 reads.

Run `bash tests/active_special_world_host.sh` only on the Intel reference Mac.
It checks base, tail and storm against independent original fixtures. It omits
only the explicit native HUD observer rows and original PC column (the host
has no PPC addresses). Existing comparator negative tests also reject changed
state words and clocks. The latest Intel app build/self-test passed all four
special attacks; that controlled self-test is not original campaign equality.

Remaining: other special weapon levels/targets and real deletion/reuse cases,
longer ordinary campaign sequences, complete rendering/HUD/input equivalence.
