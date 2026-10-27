# Original independent AI clocks

Run tools/ppc_script_clock_oracle.c only on the reference G5. It loads a private
copy of download-3 DOSCRIPTEDSPRITE10061c40. The original routine, numeric/string
helpers, parser and animation execute unchanged. Original files and the live
game are not patched; no window, audio or preference access is requested.

```
gcc -std=gnu99 -O2 -mno-fused-madd -I analysis/script-oracle \
 tools/ppc_script_clock_oracle.c src/script.c src/physics.c src/ppc_math.c \
 -framework Carbon -lm -o script_clock_oracle
./script_clock_oracle original.pef original.literals.bin strings25000.bin > native.csv
```

The source includes tools/ppc_script_oracle.c with its old main renamed; that
main and its linked portable simulation are never called. Include the existing
src/ppc_atan_table.h when transferring build dependencies.

strings25000.bin is the6884-byte STR#25000 payload extracted using the offset and
size in analysis/download-3/resources.json. Verify its SHA-256 before use:
`e08c3f406f8543edd4d909eb7d83a006b298663fb57e627f9eed32598807504a`.
The PEF MD5 is `b93ca67a59bbc3cbcad434402bfa7bca`.

GetResource supplies this unchanged constant table and a small scripted STR#777
handle. TickCount supplies independent finite values. The private FIREWEAPON
entry records arguments and consumes one additional scripted clock; it does not
allocate or render actual projectiles. That callback's clock has site0 in the
fixture. All other clock records identify the actual original call instruction.
The import trampoline fills the caller's r2 linkage slot, as CFM code restores
it immediately after each TickCount call.

The10 cases exercise closed/open update, signed absolute action comparison,
separate stores, RETURN, absent/disabled animation, signed update wrap and the
fire-callback/animation boundary. Each read records line, timers, state, frame,
tilt, removal and raw velocity bits before the read. Tests replay the resulting
tests/script_clock_native.csv in the default suite. This finite scripted probe
does not establish full coupled AI/weapon/world or all-opcode equivalence.
