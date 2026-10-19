# AstroSquid reconstruction

Work in progress: recover the behavior of AstroSquid 1.1 and build a native
Intel macOS port. This is a partial playable reconstruction, not a complete
port or the original author’s source code.

The original executable is PowerPC CFM/PEF, compiled with FutureBASIC 3.
The `FCOD` resource contains the actual program. The tiny data fork is a loader.

## Inputs

Original downloads are preserved unchanged in Downloads. Working extraction
is kept outside Git. `tools/macresources.py` exports a resource inventory and
the main PEF container for analysis with REA and Ghidra.

The executable data and resource forks in `astrosquid.sit` and `astrosquid.zip`
are identical. A later archive timestamp is not evidence of newer game code.
The Ten for X build is a separate comparison and runtime reference.

## Current state

This remains a work in progress. The native host runs reconstructed gameplay,
not the original PowerPC executable or an emulator. It builds and runs on the
Intel reference iMac with macOS10.13.6 and on the ARM development Mac.

Recovered and checked against original instructions on the G5:

- Movement and drag:2000 comparisons; heading:1004.
- All29 enemy scripts:52200 controlled ticks, including shot arguments.
- Ordinary weapons:1400 cases; beam targeting/damage:800; projectile damage:2000.
- Pickups:1000; player/scenery contacts:1000; player controls/animation:3200 ticks.
- All16 special-attack tiers:320 cases, including polygon vertices/colors and RNG.
- Death effects/debris/drop generation:402 cases; sprite geometry changes:1000.
- Debris updates:5400; star movement:300000; complete beam geometry:400 streams.

These isolated oracles intercept selected world/renderer/audio operations. They
prove the compared routines, not the entire game or a complete campaign run.
Captured original traces also replay on ARM and Intel.

All74 PICT rasters now match original G5 QuickDraw pixels. The extractor selects
ImageMagick for69 images and sips for5 compressed images, then checks native
reference RGB hashes. A previous sips-only conversion silently destroyed the
font and orb masks; regression checks now catch that failure. Recovered assets
include54 atlases,295 sprite definitions,134 attributes,22 weapons,29 scripts,
8126 map objects,17 stage files, all18 sound cues and3 music tracks.

The host connects normal and special weapons, damage, pickups, effects, sprite
animation, camera, campaign markers, death and respawn. The live entity list now
preserves original prepend order and the player's insertion position; each actor
moves, collides and then runs AI before the next actor. Cleanup precedes updates.
Native original-code probes verify those ordering rules separately from gameplay.

Original menus, HUD, startup credits, volume/filter controls, key reassignment,
highscore entry, stage cards, midpoint autopilot and departure animation are
connected. Preferences and unlocked stages persist. Score defaults, tie ordering
and Classic name editing were checked against original PPC routines on G5.

The full campaign route is under automated test. A complete original-game frame
comparison, timed-special nested-world interleaving and final release packaging
remain required. No finished port or release is claimed.

## Build

Assets are generated from the original application, including its resource fork
and adjacent Data folder. On macOS with Xcode Command Line Tools, Python, Pillow,
ImageMagick (`magick`) and the built-in `sips`:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python tools/prepare_assets.py '/path/to/original/AstroSquid' assets
./build.sh
open 'build/AstroSquid Preview.app'
```

Controls: arrows move, Command fires, Option triggers a special attack, Escape
pauses. Original menus support mouse navigation, volume adjustment and key
reassignment. Settings are stored in the app preferences. Development weapon and
stage shortcuts are enabled only in the explicit self-test.

`PYTHON=.venv/bin/python ./test.sh` replays original captures and checks resources,
audio PCM integrity and all74 QuickDraw image references. The native executable's
`--self-test DIRECTORY` exercises actual key handlers, movement, all4 special
families, hits, effects, boss defeat/score, level selection, rendering and muted
music playback; it writes evidence and exits. It does not prove a full campaign.

## Reproduce binary analysis

`tools/prepare_analysis.py APPLICATION OUTPUT` exports the original PEF and an
explicitly named analysis copy. It extends the code mapping to retain existing
import stubs and clears the compiler's reserved compare bit at four sites.
Neither the downloaded archive nor the original executable is rewritten.
`tools/ppc_compare_probe.c` verified equivalent CR0 results for the legacy and
canonical compare encoding in 100 cases on the real G5.

Import the normalized analysis copy into Ghidra using `PowerPC:BE:32:default`.
Run `PrepareAstro.java` with the literal-pool path and function-names TSV path,
then `ExportAstro.java` with an output directory. The scripts are in `tools/`.
Default PEF architecture detection selected an unsuitable VLE language; do not
rely on it. Retain diagnostics and review pseudocode before translating it.

FutureBASIC also emits non-arithmetic PPC `stfs` conversions without `frsp`.
These truncate significant bits rather than following a normal C float cast.
The recovered damping routine preserves those conversions; this difference was
verified against original execution, not assumed from the decompiler cast.
See [IBM's stfs reference](https://www.ibm.com/docs/kk/ssw_aix_72/assembler/idalangref_stfs_instrs.html)
and the Power ISA `SINGLE` conversion implemented in
[QEMU's PowerPC helpers](https://github.com/qemu/qemu/blob/master/target/ppc/fpu_helper.c).

`--campaign-test DIRECTORY` runs the complete campaign through real world updates
and screens, with a controlled pilot that replenishes its shield, uses weapon53
and steers toward bosses. It writes progress/results without modifying player
preferences. This diagnoses campaign connectivity; it does not prove an unaided
playthrough or original-game frame identity. Test rendering submits every frame
to OpenGL without waiting for screen presentation, allowing accelerated checks.
