# Working with the reconstructed source

This is a C/Objective-C reconstruction, not recovered FutureBASIC source. The
application executes the code in `src/`; the PowerPC executable and analysis
tools are not runtime dependencies. The source distribution includes `assets/`.

## Build and check

On macOS with Xcode Command Line Tools, run `./build.sh`. It produces
`build/AstroSquid.app` for the build Mac's architecture. Build on Intel for the
Intel release; compiling on Apple Silicon does not produce an Intel release.
The minimum deployment target is macOS 10.13.

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
