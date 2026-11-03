# Original analysis and asset regeneration

## Regenerate assets from the original

Assets are generated from the original application, including its resource fork
and adjacent Data folder. On macOS with Xcode Command Line Tools, Python, Pillow,
ImageMagick (`magick`) and the built-in `sips`:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python tools/prepare_assets.py '/path/to/original/AstroSquid' assets
./build.sh
# Run build/AstroSquid.app on the target test Mac.
```

Development weapon and stage shortcuts are enabled only in the explicit
self-test. They are disabled during ordinary play.

`PYTHON=.venv/bin/python ./test.sh` replays original captures and checks resources,
audio PCM integrity and all74 QuickDraw image references. The native executable's
`--self-test DIRECTORY` exercises actual key handlers, movement, all4 special
families, hits, effects, boss defeat/score, level selection, rendering and muted
music playback; it writes evidence and exits. It does not prove a full campaign.

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

`--campaign-test DIRECTORY` runs the complete campaign through real world updates
and screens, with a controlled pilot that replenishes its shield, uses weapon53
and steers toward bosses. It writes progress/results without modifying player
preferences. This diagnoses campaign connectivity; it does not prove an unaided
playthrough or original-game frame identity. Test rendering submits every frame
to OpenGL without waiting for screen presentation, allowing accelerated checks.

