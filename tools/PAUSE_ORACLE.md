# Original pause loop oracle

Run tools/ppc_pause_oracle.c only on the reference PowerPC G5. It executes
original PAUSE1004d818 and GETKEYMAP1004cb28 in a private loaded PEF copy.
The included keymap oracle main is renamed and never executed.

```
gcc -std=gnu99 -O2 -mno-fused-madd -I analysis/script-oracle \
 tools/ppc_pause_oracle.c -framework Carbon -o pause_oracle
./pause_oracle original.pef original.literals.bin strings25000.bin > pause.csv
```

Use the unchanged download-3 PEF (MD5 b93ca67a59bbc3cbcad434402bfa7bca), its
11812-byte literal pool and the6884-byte STR#25000 payload selected with
tools/macresources.py. Its SHA-256 is
`e08c3f406f8543edd4d909eb7d83a006b298663fb57e627f9eed32598807504a`.
Build dependencies are ppc_keymap_oracle.c, ppc_bridge.h and
analysis/script-oracle/imports.h. Input sizes are checked; a15-second alarm
bounds unexpected native loops.

TickCount and GetKeys supply finite scripted input. GetResource supplies the
unchanged constant table. UI, sound, cursor, mouse, scene loading and rendering
boundaries are semantic observers; no actual game window, sound, cursor change
or screenshot is requested. SYSTEM/FOLDER return0 in this private copy; four
mock sprites supply writable geometry. Original files/live game are unchanged.
Import callbacks preserve their incoming r2 but must NOT overwrite the caller
linkage slot: the original CFM glue already saved the original TOC before
loading the import descriptor's r2. This differs from replacing raw import glue
itself, where the replacement must populate that linkage slot.

## Captured contract

The16 cases cover intervals1/2/3, immediate held Escape, one/two released polls
before a held key, Command-Q (any-key count2 and stop latch), HUD dirty count2,
game-over suppression of the reverse transition and32-bit clock wrap.
Cases8–15 repeat0–7 with the clock starting at UINT32_MAX-3.

Within an eligible frame the original order is mouse hover, world render,
pause overlay, optional HUD draw/decrement, music, animation, swap, fresh clock
store, GETKEYMAP and any-key exit. Mouse polling follows even the final key
poll. No key polling or frame callbacks occur below the frame interval.
Cleanup performs8 total sprite lookups,4 kills and cursor restoration.
A held Escape ends pause at the first eligible frame; no new key event is needed.

Two consecutive native runs were byte-identical. tests/pause_native.csv records
708 callback/state observations, SHA-256 `a1138c9846e4023d88571a72c3d9e3e1d2462158c350561a1ca23f2b5b7e3699`.
The oracle asserts frame/poll/lookup/transition counts and final key/quit states.
The capture was additionally checked for complete callback order, fresh CPU
stores, interval gates, HUD decrements and wrap behavior.

## Production host replay

Compile tests/pause_native_host_test.m with the source files/frameworks from
build.sh, replacing src/preview.m with this test. Execute only on the Intel
reference Mac:

```
build/pause_native_host_test assets tests/pause_native.csv
```

The actual production pause loop matches the230 clock/frame/input/mouse-boundary
projections from these16 native cases, including100 clock reads and CPU/paused
states. Rendering and event dispatch are observers in this host replay. It also
checks timer reentry is suppressed, world simulation/spawn/render clocks remain
untouched under those observers, the WAIT timeout/constructor and blink timeout
continue in the same call after pause, the ordinary tail invokes pause, and a
special raw-key poll does not invoke HANDLEMISCKEYS. UI entry/exit transitions
still execute; their draw calls are observed. The full Intel app selftest also
executes the production pause loop with its real renderer/event pump and held
controlled input, in addition to the existing direct mouse Resume handler check.

These are bounded checks. Original HUD/resource/cursor/quit/screenshot side
effects, actual queued mouse delivery, held mouse behavior and full renderer/
music equivalence remain unproved. Standalone queued-click experiments could
not activate their background test window and are not counted as proof.
Full-game equivalence remains open.
