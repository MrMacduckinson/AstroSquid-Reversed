# Separate Intel / Mac OS X 10.4 port

`Applications/i386-SDK10.4u-min10.4/AstroSquid.app` is a 32-bit i386 application built with
an actual MacOSX10.4u SDK and deployment target 10.4, including first-generation
Intel Core Duo machines. It is native and needs neither Classic nor Rosetta.
macOS 10.15 and later cannot run 32-bit applications; choose another variant there.

**Status: compatibility candidate. Intel Tiger itself has not been tested.**
Component tests ran in an i386 process on Intel macOS 10.13.6. After the launch
fix, the ready-made bundle also launched through LaunchServices, rendered its
splash and remained alive. This muted launch test is not a campaign playthrough.
The compatibility layer adds only missing methods, retaining native methods on
newer systems. This fixes dictionary/filesystem recursion on 10.13.6; installation,
preservation and fallback enumeration are tested separately. A PowerPC G5 running
Tiger does not validate i386 compatibility.

## Differences

- Separate `src/tiger/` host: legacy Objective-C ABI, manual reference counting,
  Cocoa/OpenGL, OpenAL effects and QTKit/QuickTime music.
- All 21 C gameplay modules are shared with modern builds.
- Resource tables are converted from JSON into XML plists without changing values.
  A private representation of JSON null is restored to NSNull when loading.
- LLVM BlocksRuntime is statically linked for callbacks; users install no extra library.
- Fullscreen retains the display resolution and 4:3 aspect ratio. Control–Command–F
  restores a 640×480 window. Shared `src/presentation.h` uses APIs present in SDK 10.4.
- Settings and scores use the same bundle ID as the other variants.

The host is separate to avoid spreading MRC requirements through modern sources.
When modifying preview.m, UI, HUD or the older OpenAL backend, review the matching
file in `src/tiger/`. C gameplay changes are already shared.

## Reproducible build

Requires a Mac toolchain/linker supporting i386, Python 2.7 or 3, and a lawfully
obtained Apple MacOSX10.4u SDK. The SDK is not included. The build used Intel
10.13.6 with Apple LLVM 10; the modern ARM linker no longer supports i386.

Old prebound SDK stubs are rejected by newer ld64. The preparation tool makes
an isolated SDK copy: selects i386, strips obsolete prebinding commands and fixes
the __LINKEDIT range. Symbol tables and the original installed SDK are unchanged.

```sh
python tools/prepare_tiger_sdk.py /path/MacOSX10.4u.sdk /tmp/astrosquid-sdk/MacOSX10.4u.sdk
export TIGER_SDK=/tmp/astrosquid-sdk/MacOSX10.4u.sdk
bash tools/build_tiger.sh
bash tests/tiger_host.sh
# On a machine with Python 3:
python3 tests/tiger_tools_test.py
```

Output: `build/tiger-intel/AstroSquid.app`. Distribute the entire bundle or
`AstroSquid-i386-SDK10.4u-min10.4.zip`; users need no SDK or separate assets directory.

## Checks and limits

- Seven world insertion/removal cases with NSZombieEnabled.
- All 17 sections loaded, with 20 object steps each and temporary memory released
  between steps. This is not a full campaign run.
- Eighteen sound buffers, six-channel limit, 100 stop/pause cycles, effect
  completion, QuickTime music playback/pause; all muted.
- Both transition paths: 185 frames of player/beam geometry.
- Offscreen OpenGL: ten menu/HUD screens, font, alpha, caret, hover, frame
  intervals 1/2/3, and point/line/beam thickness.
- Every converted resource value, including null and CR, checked against JSON.
- The native C test suite is also checked as i386; see VALIDATION.md.

Actual 10.4 startup, a full campaign in this variant, all older GPUs, exact audio
relative to the original, and every intervening OS are unverified. There is no
Developer ID/notarization. QuickTime is a normal Tiger dependency but another
reason to prefer a modern variant on a newer OS.
