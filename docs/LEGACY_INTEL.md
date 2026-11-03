# Intel Legacy: Mac OS X 10.7 Lion target

`Applications/Intel-Legacy/AstroSquid.app`, also distributed as
`AstroSquid-Intel-Legacy.zip`, is an additional **x86_64** application, not i386.
It requires a 64-bit Intel CPU; first-generation 32-bit Core Duo, 10.4–10.6 and
PowerPC are not covered by this variant.

## Why a separate implementation is necessary

Changing the deployment target does not supply missing system classes. The normal
backend uses AVAudioEngine (introduced in 10.10), buffer-completion behavior and
output-latency facilities from 10.13. See
[Apple: AVAudioEngine in Practice](https://devstreaming-cdn.apple.com/videos/wwdc/2014/502xxvo7vov799k/502/502_avaudioengine_in_practice.pdf).

Legacy links `src/audio_legacy.m`: all 18 WAVs are decoded into mono 16-bit PCM
in advance, OpenAL provides six pairs of voices, and music uses AVAudioPlayer.
Original sample rates, the six logical-channel limit, volume coefficients and
left/right behavior are retained. Playback is protected against replaying a
completed effect after pause. The system's OpenAL mixer can behave differently;
exact acoustic output, panning and loudness equivalence have not been proved.

The debug journal's 10.9 calendar constructor was replaced with an older
API. Apple's statically linked libarclite provides collection-subscripting
compatibility on Lion. This variant does not replace Foundation methods.
The build.sh availability check permits only those four known subscript methods;
other availability warnings stop the Legacy build.

## Build

```sh
./build.sh --legacy-intel
# Output: build/legacy-intel/AstroSquid.app
bash tests/audio_legacy_host.sh
bash tests/legacy_geometry_host.sh
python3 tests/legacy_binary_test.py build/legacy-intel/AstroSquid.app
```

The release used an Intel iMac running 10.13.6, Apple LLVM 10.0.0, and records SDK
10.13 in Mach-O. A toolchain supporting deployment to 10.7, including Apple's
libarclite, is required. The installed Xcode 27 toolchain lacks that library;
selecting an old SDK alone does not resolve the link error. An older available
Intel toolchain was used; no third-party library was installed into Xcode.

## Validation and limits

- Mach-O: x86_64, minimum 10.7; Info.plist: 10.7. No AVAudioEngine class imports.
- The binary includes collection-subscripting support from libarclite.
- Muted 10.13.6 checks cover 18 buffers, six channels, 100 stop/pause cycles,
  completed effects, music pause and collection subscripting.
- Both transition geometries are checked offscreen without a window or sound.
- **The application has not been run on Lion 10.7 itself.** This does not establish
  compatibility with all old drivers/GPUs or a full campaign on the new backend.
  On Lion, first test startup, menus, combat, audio, pause and exit, then transitions.

OS X 10.4 lacks JSON and AVAudioPlayer APIs used here and has a different
Objective-C runtime. The first Intel machines also need i386 support. That work
is provided by the separate [Intel-Tiger port](TIGER_INTEL.md), not this variant.
