# Comparison with the independent Sam port — 2026-11-03

The detailed English report is [SAM_COMPARISON.txt](SAM_COMPARISON.txt). It covers
architecture, shared original resources, numerical fidelity, deliberate bug fixes,
rendering, audio, persistence, platform support and the separately prepared Intel
10.7 adaptation. Sam's source is not merged into this repository.

Sam's original archive SHA-256:
`fa8e5bc2bc5496b22ba2bafe11f5e952123c025bba118ddd7de73deff966f7b6`.

| Area | Our reconstruction | Sam's port |
| --- | --- | --- |
| Approach | Named C gameplay systems and Objective-C hosts | Static PowerPC-to-C translation and replacement Toolbox runtime |
| Maintenance | Direct edits to semantic gameplay modules | Generator/runtime edits or changes to register-level translated code |
| Original evidence | Saved PPC fixtures and a bounded controlled campaign trace | Original control flow retained; no comparable standalone fixture suite found in the submission |
| Mac windowing | Native-resolution fullscreen, fixed 640x480 window, all four variants | Resizable 4:3 window, Retina, Cocoa fullscreen with persisted choice |
| Audio | AVAudioEngine; OpenAL for Legacy/Tiger | Software Sound Manager mixer through AudioQueue; AVAudioPlayer music |
| Older Intel | Separate x86_64/10.7 and i386/10.4 candidates | Submission targets x86_64/10.9; separate adaptation targets x86_64/10.7 |
| Other platforms | Windows work cancelled; no Windows release | Independent Win32 runtime is present in the original source |

Earlier resource comparison matched all 731 resource payloads and 73 equally named
PNG exports. A bounded MinGW/Wine math comparison differed from saved PPC results
in 563 of 10,192 sampled sin/cos/asin/atan calls; this is not a measurement of
incorrect gameplay frames or of the new Mac build's libm. See the full report for
sample counts, compiler/rounding caveats and evidence limits.

Sam offers an efficient preservation strategy; our implementation offers more
readable gameplay systems and explicit tests of selected safety fixes. Neither
is established as universally superior or a perfect copy for every possible input.
