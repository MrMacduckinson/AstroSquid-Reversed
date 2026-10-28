# Original GAMELOOP terminal tail

Run tools/ppc_quit_loop_oracle.c only on the reference G5. It invokes original
GAMELOOP10051a68 in a private copy, using real original GETKEYMAP, misc handling,
entity/LM destruction and map-list destruction. A constant TickCount100 leaves
the CPU/world and map-spawn gates closed; this probe exercises the terminal
poll/tail and does not claim an ordinary advancing-world GAMELOOP capture.

```
gcc -std=gnu99 -O2 -mno-fused-madd -I analysis/script-oracle \
 tools/ppc_quit_loop_oracle.c -framework Carbon -lm -o quit_oracle
./quit_oracle original.pef original.literals.bin original_resource_app \
 analysis/script-oracle 0
```

Dependencies: ppc_active_special_world_oracle.c, ppc_bridge.h and imports.h.
Use unchanged original PEF/literals (MD5 b93ca67a59bbc3cbcad434402bfa7bca and
da53d77004bb595663b57f260f7776c7). Supply the6884-byte extracted STR#25000 payload
as original.pef.strings; it is compared with the original resource-fork app
opened read-only. PEF/literal/table/resource sizes, case0..7, read/poll guards,
final list/active state and menu route are checked. A15-second alarm bounds the
probe. No original on-disk code, live game, cursor, audio or window is changed.

The initial world has one actual NEWSPRITE1/1 with its real LM image and one
zeroed50-byte map node. Disposal observers mark private allocations retired but
retain their storage. Original unlink/kill logic still executes. The three
observed disposals are image, entity and map, in that order. Original player,
entity and map heads are NULL at return, and game-active590 is cleared before
controls/menu callbacks.

## Cases

0: Command55+Q12 on first poll, quit initially0.
1: quit already1, no key; the do-until body still executes once.
2: quit initially-1, empty first map, Command-Q second; only positive1 exits.
3: game-end58c already1, quit0, no key; game loop exits without requesting app quit.
4: game-end58c=-1 (death), empty first map, Command-Q second, CPU gate closed.
5: Command-Q with highscore-modea06=1; route goes to Highscores Menu.
6: Tab48+B11 first (does not quit), then Command-Q.
7: both quit/game-end already1, no key; body still executes once.

Case2 is a signed-flag boundary diagnostic; no normal gameplay path setting quit
to-1 is established. All other routes go to Play Menu. The original loop order
is three entry clocks, then comparison clock/music/spawn clock/raw input per
pass. At termination: real list destruction, controls, menu positioning, stars,
menu/sprites drawing, swap, event flush, music stop/play, cursor and return.
Cases2/4/6 poll twice; others once. This gives188 event/state records in
 tests/quit_loop_native.csv; two complete native runs were byte-identical.

Controls/menu/drawing/music/cursor/GL are semantic observers. PUTCONTROLSINWINDOW
is not executed, including its own game-end58c=1 write; the recorded end column
after that callback intentionally retains the loop-exit value. Actual UI
allocation, menu animation, RNG, music, cursor and GPU effects are not covered.
The flush import is observed, so it does not flush the user's real event queue.

## Port gap and remaining scope

Current host raw-key polling does not latch Command-Q. AppKit's application menu
terminates directly, bypassing the original tail. Native GETKEYMAP137 fixtures
previously verified the latch but only interpreted it in host tests. These new
traces are reference evidence; no production quit action is implemented by this
oracle-only change.

Source GAMELOOP checks quit58e==1 after GETKEYMAP/HANDLEMISCKEYS. The native main
loop10066ce4 subsequently sees the same latch and calls CLOSEDOWN10066c74, which
saves preferences and exits services/world before FBEND. That outer shutdown was
not executed by this probe. Original WAITLOOP, timed special and respawn blink
have no early quit58e test: they return to the ordinary tail. Preserve that
continuation rather than adding immediate termination inside a raw input poll.
Real nested quit input, full shutdown, screenshot actions and whole-game fidelity
remain open.
