# Working with the reconstructed source

This is a C/Objective-C reconstruction, not recovered FutureBASIC source. The
application executes the code in `src/`; the PowerPC executable and analysis
tools are not runtime dependencies. The source distribution includes `assets/`.

## Build and check

On macOS with Xcode Command Line Tools, run `./build.sh`. It produces
`build/AstroSquid.app` for the build Mac's architecture. Build on Intel for the
Intel release; compiling on Apple Silicon does not produce an Intel release.
The deployment targets are macOS 11.0 on ARM64 and 10.13 on Intel.
The build sets both the executable target and Info.plist minimum.
Command Line Tools suffice to build; portable tests additionally need Python
for their picture fixture (python3 preferred; the native fixture also supports
the system Python on the Intel 10.13 reference machine).

Run `./test.sh --native-only` for the portable logic tests and saved original
reference cases. This command does not launch the game, OpenGL or audio. The
additional asset checks in `./test.sh` require the Python dependencies described
in README.md. Tests ending in `_host.sh` are separate integration checks; some
open windows or use graphics/audio and belong on the designated test Mac.

## Code map

| Files in `src/` | Responsibility |
| --- | --- |
| `preview.m` | macOS application, world ownership, input, frame scheduling and integration of the game systems |
| `physics.c`, `ppc_math.c`, `player.c` | movement, original numeric behavior and player updates |
| `script.c`, `weapons.c`, `combat.c`, `beams.c`, `special.c` | enemy behavior, shots, collisions, damage and special attacks |
| `campaign.c`, `flow.c`, `transition.c` | stage progression, game flow and transition calculations |
| `visual.c`, `hit_visual.c`, `effects.c`, `debris.c`, `scene.c` | animation, effects, debris and scene calculations |
| `ui_model.c`, `scores.c`, `preferences.c`, `hud.c` | menu model, score/name editing, saved settings and HUD state |
| `ui_renderer.m`, `hud_renderer.m`, `audio.m`, `picture.c` | rendering, audio and original picture format support |

Headers beside these files define their interfaces. `assets/game.json` contains
the recovered gameplay/resource tables and stages; `assets/ui/ui.json` contains
menu resources. `tools/prepare_assets.py` regenerates assets from an original
installation. `tools/ppc_*` are original-machine investigation tools, not files
that must be compiled into the game.

## Verification policy

Investigate a specific mechanic by following the original function and its
callers, then compare a small set of meaningful boundary cases with the port.
Reuse the existing reference fixtures. Add or extend a focused test when a
concrete defect is found; do not change original reference output merely to
match the port.

Use application smoke tests for startup, menus/settings, movement and weapons,
pause, damage/respawn, stage progression and Game Over. Use the existing controlled
campaign test for end-to-end connectivity. It replenishes health and strengthens
the player, so it does not demonstrate an unaided win. Long detailed traces are
optional diagnostics for unresolved integration defects, not a prerequisite for
every change or a measure of source completeness.

Two intentional safety corrections retain the user's approved behavior: avoid
the original allocator-dependent use-after-free, and respawn or enter Game Over
instead of crashing when the player dies during a scripted transition.

The historical validation record contains bounded comparisons, not a proof of
all inputs or pixel identity across GPUs. A fresh Intel application check and
current release packaging must be reported separately from those older results.

For a silent background check of departure alignment, run
`bash tests/departure_geometry_host.sh`; it observes geometry through both
production transition paths without opening a window or audio engine.
`bash tests/pellet_audio_host.sh` checks muted effects and 100 rapid
stop/pause/resume cycles without a game window. The full application's
`--self-test` is a foreground graphics test; do not run it while the user
needs the desktop uninterrupted.
Additional noninterrupting checks:

- `bash tests/retina_primitives_host.sh`: offscreen OpenGL pixels at 1x/2x, no window.
- `bash tests/audio_reconfiguration_host.sh`: muted engine-stop/recovery and pause,
  without switching the system audio device.

Audio output regression: `bash tests/audio_waveform_host.sh` is silent and
checks rendered PCM before and after an internal mixer rate change.
The application's `--self-test` mutes combat and exercises settings clicks;
use ordinary gameplay to listen to effects, not that technical test.

## Updating the packaged applications

Build the same committed revision on each target architecture. Copy the entire
bundle (not only its executable) into `Applications/ARM/AstroSquid.app` or
`Applications/Intel/AstroSquid.app` with macOS `ditto`. Recheck architecture,
Mach-O minimum and Info.plist; keep executable permissions and all resources.
Update `Applications/BUILD_INFO.json` with the source revision, build/test hosts,
and SHA-256 of each executable; update `Applications/SHA256SUMS` for all bundle
files. Keep source revision separate from the later commit adding the binaries.
Commit the applications and metadata. Do not commit player preferences, logs,
local access data or disposable probes.

Run `bash tools/package_release.sh [OUTPUT_DIRECTORY]` from a clean committed
checkout. It uses the Applications bundles, verifies their checksums, architectures
and declared Info.plist minima, and produces ARM/Intel ZIPs, a source ZIP with assets, and
a full repository-file ZIP containing all applications. It never substitutes
one architecture into build/AstroSquid.app. SOURCE_COMMIT.txt in snapshots
identifies the packaging revision; BUILD_INFO.json identifies binary sources.
No Git remote is configured in the original working checkout; no push has been
performed. The ZIP is a snapshot without .git; the local repository retains history.

## Older Intel systems

`./build.sh --legacy-intel` builds x86_64 with target10.7 into
`build/legacy-intel/AstroSquid.app`. It links src/audio_legacy.m instead of the
modern audio.m. Use an Apple toolchain with Lion deployment support and its
libarclite; tested with Apple LLVM10 / SDK10.13 on the Intel reference Mac.
The current Xcode27 toolchain lacks libarclite and cannot perform this build
unmodified, even with SDK10.15 selected. See docs/LEGACY_INTEL.md.

## Intel Tiger

`src/tiger/` содержит отдельную оболочку MRC/fragile ABI, UI, HUD и звук для i38610.4.
Общая логика — `src/*.c`; сборка — `tools/build_tiger.sh`. После изменения современной
оболочки сверяйте Tiger-копию. Инструкции и границы проверок: docs/TIGER_INTEL.md.
