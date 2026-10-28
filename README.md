# AstroSquid 1.1 — native reconstruction

A reconstructed C/Objective-C port of Lost Minds' AstroSquid 1.1 for Intel Macs
running macOS 10.13 or later. It runs natively, without Classic or a PowerPC
emulator. This is newly reconstructed source, not the author's FutureBASIC
project. Original art, levels, sounds and music belong to their original authors.

Bitwise fidelity verification is in progress. The earlier packaged release is
playable; full original-logic equivalence has not yet been proved. See
[VALIDATION.md](VALIDATION.md) for the verified scope and remaining limits.
Fidelity targets defined gameplay behavior; allocator-dependent use-after-free
from the original is intentionally excluded.

## Play

Extract `AstroSquid-Intel.zip`, then open `AstroSquid.app`. The application contains
all runtime assets. No Python, developer tools or original installation is needed.
The build is unsigned. Tested on the Intel reference iMac with macOS 10.13.6;
newer macOS releases have not been tested on Intel hardware.

The game starts fullscreen at 640×480; hold left Option during startup for a
fixed 640×480 window. If the display mode is unavailable, it uses the window.
The previous display mode is restored on exit. The loading picture is shown
before the 54 texture maps are preloaded. Sound and music are then prepared
before the credits appear.

Arrows move, Command fires, Option uses a special attack. Escape pauses; any key
resumes at the next eligible input poll. As in the original, a key still held
while entering pause (including Escape) can immediately dismiss it. Use Settings
to reassign keys, adjust sound/music and
change filtering. Control/audio/filter changes apply immediately and are saved
on Back or normal quit. Keys, settings, scores and unlocked stages persist between
launches. Close the window or use Command-Q to request quit. Like the original,
quit waits for the active special, respawn or card/score interaction to return
before clearing the world and closing the application.

The game includes all 17 stage files, all four special-attack families and their
upgrades, enemies, bosses, pickups, deaths/respawns, menus, score entry, stage
transitions and the four ending pages. The optional graphics archive contains the
original Infini-D models; it is not required to play or compile this port.

Hold left Command during startup to enable the original diagnostic screenshot
key: keypad multiply saves `Screenshots/Screen <seconds>.pict` beside the app.
It repeats on every input poll while held and overwrites the same-second file.
Fullscreen saves the currently presented OpenGL frame. In windowed mode (left
Option at startup), the original instead captures its white QuickDraw backing;
this behavior is preserved. This mode also creates `LMEngine Debug file` beside
the app with startup, level-load and shutdown diagnostics.

## Build from the source archive

`AstroSquid-Source.zip` includes the extracted runtime assets. On a Mac with Xcode
Command Line Tools installed:

```sh
./build.sh
```

The result is `build/AstroSquid.app`. The compiler builds for the host architecture;
the distributed application was built on the Intel iMac. Python and image tools
are needed only to regenerate assets or run the additional resource checks below.

## Inputs

Original downloads are preserved unchanged in Downloads. Working extraction
is kept outside Git. `tools/macresources.py` exports a resource inventory and
the main PEF container for analysis with REA and Ghidra.

The executable data and resource forks in `astrosquid.sit` and `astrosquid.zip`
are identical. A later archive timestamp is not evidence of newer game code.
The Ten for X build is a separate comparison and runtime reference.

## Current state

The native host runs reconstructed gameplay, not the original PowerPC executable.
Runtime verification is performed on the Intel iMac; original-code probes run on
the G5. Development builds on ARM are not the distributed Intel application.

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

On the Intel reference Mac, `bash tests/menu_transition_host.sh` compares six
controlled menu transitions against whole original `MOVEMENUTO` execution:
164 frames, 10,684 ordered records and all 1,968,000 canonical IEEE star words.
The fixture retains 52 scene objects and 3,000 stars, observes GPU/audio boundaries,
and checks that static repaints do not advance clocks or RNG. Mouse-click dispatch
and the original startup randomization are outside this fixture.

The complete controlled campaign route passed on the Intel iMac: all 17 stages
and the ending, through normal world updates and stage transitions. The pilot
replenishes its shield and uses weapon 53; this proves route connectivity, not an
unaided playthrough. Nested timed-special world interleaving is checked against
an original PPC actor trace, including the terminal same-tick outer-loop resume.

Ordinary host checks also cover nonfatal hits, scenery hit effects, death,
respawn, weapon retention, invulnerability, pause/resume, modifier-key release,
new-game transition reset and wall-clock aging while paused. Original PPC probes
check 1980 mixed projectile/scenery shield-effect lifecycle ticks. Preferences
are tested through a write process and a separate reload process in an isolated
test bundle, without changing player preferences.

The validation does not establish pixel-identical live campaign frames across
GPUs or an unaided full playthrough. The original painter order and all 74 source
rasters have separate original-machine checks. Twelve controlled full playfields
also compare the actual production renderer on Intel against original code on
the G5, including a focused HUD-edge regression test. See `VALIDATION.md` for the
release evidence and its scope.

## Regenerate assets from the original

Assets are generated from the original application, including its resource fork
and adjacent Data folder. On macOS with Xcode Command Line Tools, Python, Pillow,
ImageMagick (`magick`) and the built-in `sips`:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python tools/prepare_assets.py '/path/to/original/AstroSquid' assets
./build.sh
# Run build/AstroSquid.app on the target test Mac.
```

Development weapon and stage shortcuts are enabled only in the explicit
self-test. They are disabled during ordinary play.

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

## Package

After building and checking the Intel application, `tools/package_release.sh`
writes `AstroSquid-Intel.zip` and `AstroSquid-Source.zip` into
`~/Downloads/AstroSquid-Release`. It checks that the executable contains x86_64.
The source archive includes runtime assets and the Git source revision, but no
private analysis files, access credentials or original executable.
