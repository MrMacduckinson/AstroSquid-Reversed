# Provenance and notices

- Original AstroSquid 1.1: Lost Minds. Graphics, levels, music and effects were
  extracted from the original application and retain their creators' authorship.
  This project is not an official Lost Minds release. Archive source:
  https://macintoshgarden.org/games/astrosquid . The .sit and .zip versions examined
  during reconstruction contained the same code and resource fork; a later
  archive timestamp alone does not establish a newer game revision.
- These sources are a C/Objective-C reconstruction, not the original FutureBASIC project.
- `src/ppc_math.c` retains Apple's notices for the numerical code used.
  `licenses/Apple-Libm-APSL-1.1.txt` contains the license and is included in all bundles.
- This package does not assign a new blanket license to the original game assets
  or the entire reconstruction. Tracking files in Git does not make the package
  MIT-licensed or public domain.
- Original Infini-D models are separate artist source materials, unnecessary for
  building or playing. The original PEF and private analysis materials are not
  included in the distributed repository.

## LLVM BlocksRuntime (used by Intel-Tiger)

`src/tiger/vendor/BlocksRuntime` contains runtime.c, data.c, Block.h and
Block_private.h from LLVM compiler-rt llvmorg-3.8.0, with trailing whitespace
removed; config.h is a local configuration.
Source: https://github.com/llvm/llvm-project/tree/llvmorg-3.8.0/compiler-rt/lib/BlocksRuntime
The Apple license is in `licenses/BlocksRuntime.txt` and the application bundles.
Apple SDK files are not included in the repository or release.
