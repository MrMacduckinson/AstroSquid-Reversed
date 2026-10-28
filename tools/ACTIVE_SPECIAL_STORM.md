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

## Expanded timed levels40..43 and50..53

Pass a final weapon number after `storm` to both native and host drivers.
All eight timed levels now match6746 state/event records and1016027 clock
values across the coupled nested attacks; all native traces repeated exactly.
Golden files for40..43/51..53 are in tests/active_special_levels; level50 reuses
its existing fixture unchanged. The four plasma native callsite streams are
byte-identical and share one compressed fixture; state streams retain their
individual weapon inventories. Host assertions also check native creation totals:
plasma33entities/188images; level50374/2420; upgrades51..53366/2368.
The gate now includes these seven added cases as well as base/tail/storm50.

This revealed two additional lifecycle gaps. The plasma callback's `temporary`
flag means NEWBEAMSPRITE→hit→immediate DELETESPRITE, not stack-only storage.
Each plasma attack really constructs31short-lived world entities and their
initial LM images. The host now runs the same constructors and shared unlink
path, without cleanup death effects on deletion. Separately, BULLETHITSENEMY
calls ADDSPRITEDEATHEFFECTS when the attacking beam's residual HP remains>=40.
For a null-render beam this still consumes two RNG draws. The host now honors
that collision return value and invokes the effect path. These draws happen
on impact, not on deletion. All retained beam endpoints and live world lists
continue to match the native captures.

The target survives these cases. Multi-target special chains, destructive
cached-tail cases, allocator reuse and full rendering/campaign proof remain open.

## Two-target chains and destruction

For levels51..53, append `pair` or `kill` after the weapon number in both drivers.
The two rocks are20/4 at300,180 and350,190; both HP30000 for pair, older rock HP1
for kill. Native creation order is rock1→rock2→player3, so rock2 is the cached
outer tail and survives in both modes. This verifies resuming that tail after
older-target deletion; it does not prove behavior with a freed cached tail.

All six added traces repeat natively and match the production host:24910 complete
state/event records and762900 clock values. Lower-level chain beam entities
occur in every case. Kill cases remove rock1, generate fragments, hit/kill some
fragments and accrue a positive score. These paths include original cleanup,
effect construction/scale/deadlines and late RNG. The native HUD observer records
(2..9 per case) remain explicitly outside the presentation boundary. Golden state
and callsite clocks are in tests/active_special_pairs. The full gate now checks
16 scenarios, including all older base/tail/single-target cases. Allocation total
assertions cover each pair/death scenario as well as the single-target cases.

This exposed fractional death-sound positioning. ADDSPRITEDEATHEFFECTS reads
render_sprite.x, whereas the generator previously emitted bounds.left as sound
x. AstroDeathSource now carries render_x separately, supplied from the actual
visual; all test/oracle constructors initialize it explicitly. Geometric bounds
remain integers for collision/effect placement. Three native destruction cases
prove the resulting sound pan IEEE words alongside the rest of the world trace.
No API for sound output or GPU rendering was replaced in the production app.

## Actual Carbon allocation and an open freed-tail mismatch

Compile the native oracle with `-DASTRO_NATIVE_ALLOCATOR` to call real
NewPtrClear/DisposePtr. The default retains disposed storage for stable legacy
fixtures. Canonical pointer lookup selects the latest allocation generation,
so actual address reuse cannot resurrect an old canonical identity. Allocation
and reuse counters are observation only; they never choose an allocation.

All six existing pair/kill cases repeated with actual Carbon allocation and
matched their committed state AND original callsite/clock streams byte-for-byte.
They exercised18924 reused addresses (2549 entity and16375 image reuses). This
is evidence for those private-process traces, not a claim that the harness has
the full running game's heap layout.

The optional `tailkill` mode (levels51..53; first reference captured for51) makes
older target1 survive and immediate cached tail target2 die. It has a20-second
process-local alarm guard. Original CALC caches next before calling player;
the nested attack deletes target2. In the real Carbon run, that address was
reused twice and belonged to new shrapnel49 (kind4,next27) when outer CALC resumed.
The original consequently updates additional live fragments. The host currently
processes its retained old target object instead. All state/event records match
until the return boundary; then native clocks127215/visits49 differ from host
127206/visits43 and six live fragment/entity positions differ. Retained-storage
native execution matches the host exactly (5290records,127206clockvalues),
isolating this discrepancy to freed-address semantics.

This case is **OPEN**, not a passing host fixture. Independent real-allocator
reference is in tests/known_gaps/freed_tail_51_native.tsv and its compressed PC
clock stream. Reproduce host with `storm 51 tailkill`; the normal comparator
correctly fails. The16-case passing gate deliberately does not claim this case.
Do not mark whole-game fidelity complete while this known mismatch remains.

A same-size last-freed-first hypothesis was measured without changing allocator
selection: only63/460 entity selections and2358/2768 image selections matched it.
Thus replacing the allocator with a simple LIFO pool would not reproduce the
observed Carbon allocation sequence. No such emulation or production shortcut
was added. The exact portable treatment of the original stale pointer remains
unresolved; no original disk executable, live game or approval settings changed.
