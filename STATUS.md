# Project status — 2026-11-03

## Fullscreen update

All four Mac variants use the current display resolution, preserve 4:3 with black
bars, and toggle with Control–Command–F. Left Option at launch keeps a 640×480
window. Display-mode switching has been removed. OpenGL requests a Retina surface
matching the viewport, avoiding an extra system scaling step. Original glyphs and
metrics are retained. Only faint bottom-row noise (RGBA <= 5) in font cells is
cleared at load time; the source atlas is unchanged. Internal PICT screenshots
now capture the entire game frame. Minimum OS targets are unchanged. The user has
not yet confirmed that the previously reported visual issue is fully resolved
on their problem display.

## Intel-Tiger launch fix on 10.13.6

The Tiger compatibility layer installs only missing Foundation methods, retaining
native implementations on newer systems. This fixes NSDictionary/allKeys and
NSFileManager/changeFileAttributes recursion at startup. Fallback dictionary
iteration uses keyEnumerator. Regressions cover installation, preservation of
native methods, enumeration and filesystem operations.

## Older Intel variants

Intel-Tiger is a separate i386 port using SDK 10.4u, Cocoa without ARC, OpenAL,
QuickTime and XML plists. Window and fullscreen are supported. Components and
launch were tested on Intel 10.13.6; actual 10.4 execution is unconfirmed.
See [docs/TIGER_INTEL.md](docs/TIGER_INTEL.md).

Intel-Legacy targets x86_64 / OS X 10.7. Effects use preloaded OpenAL buffers and
music uses AVAudioPlayer; modern ARM/Intel retain AVAudioEngine. Checks on 10.13.6
cover all 18 sounds, six channels, pause/stop/completion, 100 cycles and music;
transition geometry is tested offscreen. Lion itself is untested. This is a
compatibility candidate, not a promise of complete Lion support. Legacy volume
and panning have not been compared precisely against the original.
See [docs/LEGACY_INTEL.md](docs/LEGACY_INTEL.md).

## Implemented scope

A native C/Objective-C project for ARM64 and Intel with assets and applications.
All 17 stage files are linked into a campaign, including transitions, bosses and
four ending pages. Implemented: 29 enemy behavior scripts, normal weapons,
16 special-attack tiers, collisions, pickups, damage, death/respawn, menus, HUD,
name entry, scores and settings. Resources include 54 atlases, 295 sprite
specifications, 22 weapon specifications, 8,126 map objects, 18 effects and three
music tracks.

The 74 source rasters were compared with QuickDraw on a G5. Movement, AI,
weapons, collisions, special attacks and UI have focused original-runtime checks.
A controlled continuous New Game-to-ending trace matched 405,789 compared G5/Intel
records, with diagnostic-field normalization documented in VALIDATION.md.
The pilot replenished health, upgraded weapons and weakened targets: this checks
campaign integration, not ordinary difficulty.

This is a working reconstructed project, not proof of an exact copy for every
input. Record counts measure specific comparisons, not a percentage of code or
remaining levels. They do not justify an estimate of hours until "100%".

## Fixed defects

See CHANGELOG.md for revisions and recent work, including:

- Completed effects replaying after pause, and an AVFAudio deadlock on Intel 10.13.
- Firing delays caused by allocating audio nodes during combat.
- Incorrect scheduling after stop/pause, and unused sounds disappearing after mixer-rate changes.
- Boost-trail displacement relative to the player in both transition paths.
- Inconsistent Retina line, star and trail thickness.
- Non-numeric velocity when colliding exactly at an obstacle's center.
- Font/object-mask extraction errors checked against reference rasters.

## Intentional departures from undefined or crashing original behavior

1. Deleted objects are not read after their memory is freed. Behavior is defined
   rather than dependent on allocator leftovers.
2. Death during a scripted transition causes respawn or Game Over, rather than
   accessing a missing player and crashing.
3. A zero collision direction produces zero impulse while retaining damage;
   velocity does not become NaN.

Reference traces after invalid memory access were not rewritten to fit the port;
see tests/known_gaps/README.md. These are explicit exceptions to reproducing bugs.

## Known issues and limits

| Area | Evidence | Useful next check |
| --- | --- | --- |
| Partial Intel iMac hang | During extended research the user restarted the machine while parts of the GUI still responded. The cause is unknown; fixing an audio deadlock does not prove it caused that incident. | If repeated, capture live stacks and WindowServer state; keep diagnostics bounded. |
| macOS/GPU compatibility | Intel was tested on 10.13.6 and ARM on 27.0. ARM's 11.0 minimum was not tested separately. Rendering uses OpenGL. | Check clean launch, menus, combat, pause and exit on the recipient's OS/GPU. |
| Ordinary campaign | The controlled pilot traversed all sections; a complete unassisted playthrough is not recorded. | Play normally through later stages, deaths and transitions. |
| Input/graphics | Many bounded traces and frame comparisons exist, but not every keyboard, focus/event combination or GPU frame is covered. | Reproduce specific differences and add small regressions. |
| Audio | Nine checks cover full waveforms of four effects and an unused Click after format changes on ARM/Intel. | Listen during normal play and test real device changes/disconnection. These checks do not prove exact volume or stereo placement. |
| Distribution | No Developer ID/notarization; third-party assets are described in THIRD_PARTY.md. | Do not present this as an official Lost Minds release. |

## Why the automated demo clicked

`--self-test` is a technical test: combat audio and music are initially muted,
then settings checks trigger Click. It is unsuitable for evaluating normal game
audio. That behavior does not show that all combat effects have become clicks.
The normal audio path was checked using complete PCM signals; a separate mixer
sample-rate recovery defect was fixed.

## Handoff

There is no list of unimplemented levels. Remaining work is targeted verification,
fixing observed deviations, compatibility and release quality. Start with
SOURCE_GUIDE.md, a normal build and portable tests. Do not indiscriminately run
all graphical tests on a primary workstation: some switch display modes, open
windows, use sound or physical input. Avoid enormous default traces; existing
fixtures already retain useful checks. External audit files cited in historical
notes are not automatically included and are unnecessary for a normal build.
