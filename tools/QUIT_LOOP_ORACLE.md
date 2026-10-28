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

## Host implementation and replay

Raw polling now latches Command-Q even when a controlled test input bypasses the
physical keyboard. Neither raw input nor nested WAIT/blink/special/card loops
terminate the application. Ordinary-tail completion destroys world/map/effects,
clears retained next/parent links, reloads the correct menu, presents it, flushes
queued events and stops/restarts menu music. Only after returning to the caller
can the main scheduler save preferences/scores, stop audio and terminate.

Normal PauseQuit and completed GameOver/score input use the same terminal tail.
A game-end request may end the blink loop early (original58c==1); application
quit58e alone may not. A pending death also suppresses the reverse pause panel,
as the original condition requires58c==0. Non-editing GameOver keyboard input is
accepted at an eligible raw-poll frame; keyDown/modifier events alone do not exit.
AppKit Quit and window-close callbacks request the latch and cancel immediate
termination; a completed shutdown permits the final AppKit termination call.
Existing fatal Stop/debug diagnostic paths retain immediate termination.

Compile tests/quit_lifecycle_host_test.m with build.sh dependencies in place of
src/preview.m, and run on the Intel reference Mac from the repository root:

```
build/quit_lifecycle_host_test assets
```

The5 host-compatible cases0/1/4/5/6 match71 projected native event labels, clock
query totals, final latch/menu selection and empty logical world/map state.
The projection includes clock/keys, entity deletion, controls/menu presentation,
flush, stop/play and return. Native LM-image/map disposal details are not separate
host events. Cases2/3/7 remain boundary diagnostics rather than STARTNEWGAME input
states. Source-backed tests check WAIT strict60/61 and blink180 versus game end,
card delay and score/stage deferral, repeat-safe shutdown and actual delegate
callback policy. special_phase_host_test adds a Command-Q injection inside the
actual nested special: all31 updates still match the original phase1 timing,
then the ordinary tail cleans the world. This is a host input perturbation,
not an additional native nested-quit recording.

An isolated normal app bundle on the Intel Mac received a real Quit AppleEvent.
The first AppKit reply was deferred/cancelled; the process subsequently saved
its six control keys and ten score rows and exited0. The private bundle and its
preference domain were deleted; user game settings were not used or overwritten.
The normal build/selftest and keyboard/pause/respawn/menu/GameOver/phase/card
regressions also passed.

## Limits

Native UI/audio/cursor/GL remain observers, including PUTCONTROLS side effects
as described above. The captured tail has closed CPU/spawn gates. The outer main
loop10066ce4 and CLOSEDOWN10066c74 were inspected as source, not run natively
here. Exact LMEXIT/GL resource shutdown, main-loop FB-event timing, score text
input scheduling, native window-close/AppleEvent reply delivery, real nested
quit input and full
renderer/audio equivalence are not established by these checks. Screenshot
behavior and the broader whole-game fidelity objective remain open.
