# Original keymap oracle

Run only on the reference PowerPC G5, using the original download-3 PEF:

```
gcc -std=gnu99 -O2 -I tools -I analysis/script-oracle \
 tools/ppc_keymap_oracle.c -framework Carbon -o keymap_oracle
./keymap_oracle analysis/download-3/AstroSquid.pef \
 analysis/download-3/AstroSquid.literals.bin > native.csv
```

PEF MD5: `b93ca67a59bbc3cbcad434402bfa7bca`.
The oracle executes original GETKEYMAP `1004cb28` in a private allocated copy.
GetKeys supplies scripted bytes; BitTst is the G5's real Carbon implementation.
The private LMTAKESCREENSHOT entry is replaced with a counter. No physical keys,
screenshots, live-game memory, original files or preferences are changed.

Cases0–127 press each virtual key separately. The remaining cases cover no/all
keys, Command-Q, Tab+B, a previously set stop flag, enabled/disabled screenshot
requests and padding. Normal GetKeys writes16bytes. Case135 deliberately writes
32bytes and sets bit128, outside the API's keymap; it is a boundary diagnostic,
not a physical key or a normal host replay. Case136 verifies clearing after that
write. The byte beyond the16-byte map was zero before every captured call.

The original BitTst numbering reverses bits within each byte relative to virtual
key codes: `bit_index = key_code ^ 7`. Thus hardcoded bit50 is Escape53, bits48
and11 are Command55 and Q12, and bit68 is keypad-multiply67. Stop is latched;
screenshot requests require the original enable flag to equal1.

`tests/keymap_native.csv` contains137 native outputs.
`tests/keymap_native_host_test.m` compares the host's control states and counts
against the136 normal maps and checks the pause binding. Compile with the same
sources/frameworks as build.sh, substituting that test for src/preview.m; run
with `assets tests/keymap_native.csv` on the reference Intel Mac.

These fixtures do not prove OS keyboard-device behavior, the full pause loop,
or execution of the port's stop/screenshot actions. The native screenshot sink
checks requests only, without rendering or writing an image.
