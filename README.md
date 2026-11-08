# AstroSquid Reversed 0.0.1

A buildable C/Objective-C project with **four ready-to-run applications**. This
reconstructs the behavior of Lost Minds' original game; it is not recovered
FutureBASIC source. Playing requires no emulator, Classic Environment, or original
executable.

This port is version **0.0.1**, based on the original AstroSquid 1.1.
`main` has no player cheats; `with-cheats` adds the optional `weapons` cheat.
Download complete application bundles from [Releases](https://github.com/MrMacduckinson/AstroSquid-Reversed/releases).

## Choose an application

| Mac | Application | Minimum macOS target | Runtime validation |
| --- | --- | --- | --- |
| Apple Silicon, ARM64 | [Applications/arm64-SDK27.0-min11.0/AstroSquid.app](Applications/arm64-SDK27.0-min11.0/) | **11.0 Big Sur** | ARM macOS 27.0, OS build 26A5406e |
| Intel, x86_64 | [Applications/x86_64-SDK10.13-min10.13/AstroSquid.app](Applications/x86_64-SDK10.13-min10.13/) | **10.13 High Sierra** | Intel macOS 10.13.6 |
| Older Intel, x86_64 | [Applications/x86_64-SDK10.13-min10.7/AstroSquid.app](Applications/x86_64-SDK10.13-min10.7/) | **10.7 Lion** | Tested on 10.13.6; Lion itself untested |
| Intel i386, including Core Duo | [Applications/i386-SDK10.4u-min10.4/AstroSquid.app](Applications/i386-SDK10.4u-min10.4/) | **10.4 Tiger** | i386 tests on 10.13.6; Tiger itself untested |

Minimums are recorded in both Mach-O and Info.plist. They are deployment targets,
not proof of runtime compatibility with every intervening OS. ARM has not been
run on 11.0 itself. Legacy uses OpenAL instead of AVAudioEngine; it is not an i386,
PowerPC, or 10.4–10.6 build. See [docs/LEGACY_INTEL.md](docs/LEGACY_INTEL.md).
Intel-Tiger requires an OS that still runs 32-bit applications: 10.14 or earlier.
No new PowerPC build is provided. A G5 running 10.4.11 served as the original-game
reference machine.

Copy the entire appropriate `AstroSquid.app` into your Applications folder and
open it. Graphics, levels, effects and music are included. The applications have
no Developer ID signature or Apple notarization. If macOS blocks a downloaded
copy, verify its source and use the normal per-application opening exception;
there is no need to disable system-wide security.

All four variants start fullscreen without changing the display resolution.
The game retains its 4:3 aspect ratio with black bars. **Control–Command–F** or
**Toggle Full Screen** switches between fullscreen and a window. Hold **left
Option at launch** for a 640×480 window. The original font is retained; Retina
uses a full-resolution OpenGL surface.

- Arrow keys: movement; Command: fire; Option: special attack.
- Escape: pause; any key: resume. An already-held key can immediately resume.
- Settings: controls, sound, music and filtering. Settings, scores and unlocked stages persist.
- Command-Q or closing the window: quit. An active special attack or transition can defer exit.

## Scope and completion

Implemented: all **17 stage sections**, enemies and bosses, regular weapons,
**16 special-attack variants**, pickups, damage, lives, respawn, menus, high scores
and the ending. A controlled route reached the ending with an assisted player.
A complete unassisted human playthrough and exact agreement of every frame on
every GPU are **not established**. Trace counts are not a percentage of completion.

Read [STATUS.md](STATUS.md) for scope, known issues, intentional differences and
remaining checks; [CHANGELOG.md](CHANGELOG.md) describes recent fixes.

## Build

Requires a Mac with Xcode Command Line Tools. All build resources are tracked in
Git; a normal clone or repository ZIP is sufficient. Git LFS is not required.

```sh
./build.sh
```

The result is `build/AstroSquid.app` for the build machine's architecture: ARM
on Apple Silicon, Intel on Intel. This does not automatically replace the copies
under `Applications/`; see [SOURCE_GUIDE.md](SOURCE_GUIDE.md) for release steps.

## Project map

| Path | Contents |
| --- | --- |
| `src/` | Game source and macOS integration |
| `assets/` | Build resources and original raster/audio verification inputs |
| `Applications/` | Four applications, provenance and checksums |
| `tests/` | Regressions and saved original-game reference data |
| `tools/` | Extraction, analysis, PowerPC oracle probes and packaging |
| `validation/` | Selected historical results and comparison images |
| [SOURCE_GUIDE.md](SOURCE_GUIDE.md) | Architecture, builds, tests and releases |
| [VALIDATION.md](VALIDATION.md) | Detailed historical checks and their limits |
| [docs/REVERSE_ENGINEERING.md](docs/REVERSE_ENGINEERING.md) | Reproducing analysis and resource extraction |
| [THIRD_PARTY.md](THIRD_PARTY.md) | Resource and third-party code provenance |

`AstroSquid-Repository.zip` contains source, resources, tests, documentation and
all four applications. It is a tracked-file snapshot with `SOURCE_COMMIT.txt`,
without the `.git` database or private working materials. The working repository
retains its commit history. Application ZIPs are for players who do not need source.
Large external research traces, the original PEF and Infini-D models are neither
required for building/playing nor included in the repository package.

See [docs/SAM_COMPARISON.md](docs/SAM_COMPARISON.md) and
[docs/SAM_COMPARISON.txt](docs/SAM_COMPARISON.txt) for the independent Sam port.

For the original shareware gate, byte-verified PowerPC disassembly and both
unlock approaches, see [docs/LEVEL_UNLOCK_EXPLAINED.txt](docs/LEVEL_UNLOCK_EXPLAINED.txt).
