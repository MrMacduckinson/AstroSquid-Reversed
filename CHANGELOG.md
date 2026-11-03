# Changes

## English-language distribution and Sam comparison — 2026-11-03

- Translated the remaining Russian documentation into English; retained technical
  evidence, known issues, attribution and compatibility limits.
- Added a detailed plain-text comparison with the independently supplied Sam port.
- Reviewed distributable files for credentials and private operational material;
  release ZIPs omit Git history and nonessential macOS extended metadata.
- Our application code and game assets are unchanged by this documentation update.

## Fullscreen — 2026-11-03

All four Mac variants retain the current display resolution and 4:3 aspect ratio
with black bars. Control–Command–F toggles fullscreen; left Option at launch keeps
a 640×480 window. Physical display-mode switching was removed. The OpenGL surface
matches Retina backing dimensions. Original fonts and spacing remain; only faint
bottom-row glyph-cell noise (RGBA <= 5) is removed at texture load. The original
atlas is unchanged. Internal PICT capture now samples the whole game frame.
Minimum OS targets are unchanged. User confirmation on the previously affected
display remains distinct from successful framebuffer checks.

## Intel-Tiger launch on 10.13.6 — 2026-11-03

The compatibility layer now installs only missing Foundation methods, preserving
native implementations on newer macOS. This fixes recursion through dictionary
allKeys and file-attribute methods at startup. Fallback enumeration uses
keyEnumerator. Tests cover method installation/preservation, iteration and files.

## Separate Intel-Tiger port — 2026-11-03

Added an i386 port built using SDK 10.4u: non-ARC Cocoa, OpenAL, QuickTime and
XML plists. This separate application supports windowed and fullscreen modes.
Components were tested on Intel 10.13.6; actual 10.4 execution is unconfirmed.
See [docs/TIGER_INTEL.md](docs/TIGER_INTEL.md).

## Additional Intel-Legacy build — 2026-11-03

- Target 10.7/x86_64 with an OpenAL backend, 18 preloaded buffers and six paired
  voices. Music, voice limits, volume quantization, pause and serviceMusic repeats
  preserve the game interface. Players are not created per shot.
- Replaced the single 10.9 calendar constructor with an older equivalent API.
- Added `./build.sh --legacy-intel`, focused tests and a separate archive while
  retaining modern backends. Apple LLVM 10 on Intel supplies libarclite for Lion.
- Tested on 10.13.6, not 10.7. This variant does not support i386/PPC or 10.4–10.6.

## Initial handoff preparation — 2026-11-03

- Tracked resources and the initial two application variants: ARM64 (11.0+) and Intel (10.13+).
- build.sh sets matching compiler and Info.plist deployment targets.
- Made README, status, limitations and release instructions self-contained; retained historical validation separately.
- The repository snapshot included both then-current apps; Git history remained in the working repository.

## Recent game fixes — 2026-11-03

| Commit | Change | Validation |
| --- | --- | --- |
| 878c96d | Reset unused prepared audio-node timelines after format changes | Nine muted PCM checks on ARM/Intel; unused Click previously rendered silence |
| 269d6c8 | Retina primitives, zero-direction collisions, audio-engine recovery and Intel scheduling | ARM/Intel offscreen frames; collision also checked on G5; muted lifecycle/stress |
| 4c89536 | Completed sounds after pause, AVFAudio deadlock, prepared voices and centered boost trail | ARM/Intel lifecycle and both transition geometries |
| 808bec1 | Decoupled audio playback from game firing clocks | Starting-gun cadence and original sound calls |
| 01dd009 | Modern SDK compatibility and source guide | Project build and portable checks |

## Earlier work

Reconstructed the game loop, 17 sections, weapons/AI, menus, persisted settings,
resources and PPC numerical behavior. Fixed invalid original accesses during
object deletion and transition death while retaining evidence and separate safe
regressions. See `git log` for history and VALIDATION.md for bounded comparisons;
this document does not enumerate every historical commit.
