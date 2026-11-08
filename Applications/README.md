# Ready-to-run applications

These checked-in bundles are development candidates for **0.0.2**, awaiting user
validation. Published 0.0.1 release archives have not been replaced. See BUILD_INFO.json
for the exact source revision; bundle version numbers will change at release time.

- `arm64-SDK27.0-min11.0/AstroSquid.app`: Apple Silicon, macOS **11.0+**.
- `x86_64-SDK10.13-min10.13/AstroSquid.app`: Intel x86_64, macOS **10.13+**.
- `x86_64-SDK10.13-min10.7/AstroSquid.app`: Intel x86_64, target **10.7+**, separate OpenAL backend; not tested on Lion itself.
- `i386-SDK10.4u-min10.4/AstroSquid.app`: i386, target **10.4+**; not tested on Tiger itself. Requires 32-bit application support (through macOS 10.14).

Each `.app` is a self-contained macOS application bundle with resources. Transfer
the whole bundle, not just Contents/MacOS/AstroSquid. Use the application ZIPs
when the transfer service does not preserve directories or permissions.
Architectures are intentionally separate; the ARM application does not need Rosetta.

BUILD_INFO.json records source revisions, architectures, deployment targets,
validation hosts and executable SHA-256 hashes. SHA256SUMS covers every bundle
file. Verify from the repository root:

```sh
shasum -a 256 -c Applications/SHA256SUMS
```

A deployment target is not proof of testing on every OS version. Runtime checks
used ARM macOS 27.0 and Intel 10.13.6. No Developer ID signing or notarization is
provided. See ../STATUS.md and ../CHANGELOG.md for fixes and limitations.

All variants retain `local.astrosquid.reconstruction-preview` as the bundle ID
so updates preserve settings and scores. User saves are not included. Different
copies run by the same macOS account share settings; they are not separate profiles.

Control–Command–F toggles fullscreen without changing display resolution in all
variants. Hold left Option at launch for a 640×480 window. Original fonts remain.
