# Coupled native beam lifetime capture

Captured on the original PowerPC G5, 2026-10-28. This complements the older
beam formula/GL-stream probes: FIREWEAPON, NEWSPRITE/NEWBEAMSPRITE,
RESOLVESPRITECOLLISION, RENDERBEAM, LMNEWSPRITE/LMKILLSPRITE and cleanup all
execute original machine code in an isolated private process.

Compile on G5 from the repository:

```sh
gcc -g -std=gnu99 -O2 -mno-fused-madd -I analysis/script-oracle \
  tools/ppc_beam_world_oracle.c src/script.c src/physics.c src/ppc_math.c \
  -framework Carbon -lm -o beam_world
./beam_world ORIGINAL.pef LITERALS.bin TABLES_DIR STR25000.bin 40 0 clocks.tsv
```

Arguments 6/7 select weapon (40..43 or 50..53) and whether cleanup precedes rendering
(0 or 1). Optional final `kill` adds two HP1 targets; `chain` adds two HP100 targets. Stdout is the canonical G/E/R/S world trace accepted by
`tools/world_trace.py`; the final argument receives Q clock observations.
Q fields: phase, zero-based clock ordinal, returned tick, RNG, world-head ID,
head kind, head update/animation/action clocks, latest render allocation ID.
All constructor clocks advance, including setup and the final bullet, even
when their Q observations are omitted.

Fixture inputs: original download #3 PEF MD5 b93ca67a59bbc3cbcad434402bfa7bca;
literal pool MD5 da53d77004bb595663b57f260f7776c7; original Attr/sprt/Wpns
resources; STR#25000 (6884 bytes), SHA256
e08c3f406f8543edd4d909eb7d83a006b298663fb57e627f9eed32598807504a.
No original executable/resources on disk are changed.

## Observed

All 32 fixtures in `tests/beam_world_native` reproduced byte-for-byte in a
second fresh process, both world and clock streams. The original four remain
unchanged. Sixteen base cases cover all eight weapon levels in both cleanup
orders; eight `kill` cases cover lethal hits/death effects, and eight `chain`
cases cover two surviving targets. Levels51..53 create two beams in the latter
cases; level50 is the one-beam control. Canonical linked lists
and payload lengths pass `world_trace.py` validation.

* Beam allocation is world entity 3, linked before its three entity clocks;
  its head kind is initially 2 and becomes 999 after construction. A temporary
  render object consumes birth 3 and the fourth clock, then is destroyed.
* The real hit leaves beam HP -499 and remove flag -1 for both fixtures;
  target HP becomes 99. A projection containing only endpoints loses state.
* Rendering sets beam remove flag to 1. Rendering ray 40 consumes two fresh
  LM constructor clocks/births; lightning 50 consumes five, with RNG changes
  visible between constructors. The final bullet exposes those skipped births.
* Cleanup before rendering removes the beam and consumes two RNG steps:
  ray 12345678 -> cd305e6a; lightning cd305e6a -> 4b5c952c.
  Render-first cleanup consumes no additional RNG in these fixtures.

## Limits / next comparison

The production host uses real kind999 world entities. The original four
captured scenarios matched byte-for-byte (121 state records,23 clock observations).
The expanded gate additionally compares all32 scenarios (1905 state records,255
clock observations). Run `bash tests/beam_world_host.sh` on the Intel reference Mac.
The driver uses production creation, hit, rendering lifecycle and cleanup;
only drawing/audio output is observed. It additionally asserts that an AppKit
redraw does not mutate RNG, constructor clocks, births or persistent effects.
The captures do not establish edge coordinates, an intervening ordinary CALC pass,
nested specials or allocator reuse; this is not whole-game equality proof.
Importantly, native FIREWEAPON chains only when the first target remains alive
(remove flag0); killing it prevents the second beam. Lethal-hit fixtures are
therefore labelled `kill`, not treated as chain coverage.

GPU imports and LMDRAWSPRITE are observers/no-ops; texture 0 is represented as
already loaded. Audio is a semantic cue/pan observer. These traces prove no
pixels or audio output. Clock is scripted (1000 + read ordinal). Disposed
allocations retain storage to avoid pointer reuse. Sound channels are idle.
Initial harness failures were missing sound-channel storage and unloaded texture
0; both were diagnosed before capturing the successful fixture set. Neither
failure was evidence of a game bug or host mismatch.
