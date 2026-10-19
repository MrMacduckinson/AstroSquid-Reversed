# AstroSquid reconstruction

Work in progress: recover the behavior of AstroSquid 1.1 and build a native
Intel macOS port. This is not yet a playable port or the original source code.

The original executable is PowerPC CFM/PEF, compiled with FutureBASIC 3.
The `FCOD` resource contains the actual program. The tiny data fork is a loader.

## Inputs

Original downloads are preserved unchanged in Downloads. Working extraction
is kept outside Git. `tools/macresources.py` exports a resource inventory and
the main PEF container for analysis with REA and Ghidra.

The executable data and resource forks in `astrosquid.sit` and `astrosquid.zip`
are identical. A later archive timestamp is not evidence of newer game code.
The Ten for X build is a separate comparison and runtime reference.

## Current state

- Original reference runs and accepts registration on PowerPC Tiger.
- REA 6.7.0 installed and used to inventory the original ZIP; native PEF is not
  an admitted REA target. Actual PEF analysis uses Ghidra 12.1.4 directly.
- Found 820 original procedure-name markers; 790 match recognized function
  entries and were assigned to the analysis project.
- Recovered 74 PICT images, 54 RGBA atlases, 295 sprite definitions, 134 object
  attributes, 22 weapons, 29 AI scripts, 17 stage files and 12 background/UI scenes.
- Graph validation covers 8126 level entities and all sprite/script references.
- Native Cocoa/OpenGL renderer compiled and visually verified on x86_64 High
  Sierra 10.13.6. It displays actual extracted sprites and level placements.
- VECTORMAKE and VECTORSLOW recovered as portable C. Each passed 1000 cases
  against original unmodified code executed on the G5; captured vectors also
  pass on ARM64. Numeric tolerance is 1e-10, not a bit-identical game claim.
- Original gameplay, collisions, AI, bosses, effects and sound effects are pending.

The preview is a renderer and host-input smoke test. It is not the finished game.
It uses the recovered movement primitives; complete player behavior and camera
rules are pending. Camera scrolling remains a test control.
Generated decompiler pseudocode is not yet buildable recovered source.

## Extract and build the preview

On a Mac with Python, Pillow, `sips`, and Xcode Command Line Tools:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python tools/extract_assets.py '/path/to/original/AstroSquid' assets
.venv/bin/python tools/check_assets.py assets
cp '/path/to/original/Data/Music1.mp3' assets/
./build.sh
open 'build/AstroSquid Preview.app'
```

Preview controls: arrows/WASD move the test player; Z/X move the camera; Space
toggles automatic camera scrolling; N/P select a stage file; M toggles music;
Escape quits. These controls apply only to the preview.

`./test.sh` checks the recovered physics against the captured original results
and validates the complete extracted asset graph. `--self-test DIRECTORY` on the
preview executable tests its own key handlers, level switching, framebuffer and
muted audio decoder, writes evidence there, and exits. This avoids requiring
system-wide accessibility access for the preview's own integration tests.

## Reproduce binary analysis

`tools/prepare_analysis.py APPLICATION OUTPUT` exports the original PEF and an
explicitly named analysis copy. It extends the code mapping to retain existing
import stubs and clears the compiler's reserved compare bit at four sites.
Neither the downloaded archive nor the original executable is rewritten.
`tools/ppc_compare_probe.c` verified equivalent CR0 results for the legacy and
canonical compare encoding in 100 cases on the real G5.

Import the normalized analysis copy into Ghidra using `PowerPC:BE:32:default`.
Run `PrepareAstro.java` with the literal-pool path and function-names TSV path,
then `ExportAstro.java` with an output directory. The scripts are in `tools/`.
Default PEF architecture detection selected an unsuitable VLE language; do not
rely on it. Retain diagnostics and review pseudocode before translating it.

FutureBASIC also emits non-arithmetic PPC `stfs` conversions without `frsp`.
These truncate significant bits rather than following a normal C float cast.
The recovered damping routine preserves those conversions; this difference was
verified against original execution, not assumed from the decompiler cast.
See [IBM's stfs reference](https://www.ibm.com/docs/kk/ssw_aix_72/assembler/idalangref_stfs_instrs.html)
and the Power ISA `SINGLE` conversion implemented in
[QEMU's PowerPC helpers](https://github.com/qemu/qemu/blob/master/target/ppc/fpu_helper.c).
