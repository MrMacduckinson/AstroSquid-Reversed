# Historical allocator-dependent reference

On2026-10-28 the user selected “Определённая логика без этой ошибки” after the
original's freed cached-tail behavior was demonstrated. Reproducing that
use-after-free and a particular system allocator layout is excluded from the
fidelity target. The `freed_tail_51_*` files remain unchanged historical evidence;
they are not an expected production output after the invalid original access.

Production now keeps traversal-link ownership and skips actors already removed
from the world. It follows retained links to the remaining actors. Marking an
actor for removal without cleanup still permits its normal update. Seven
production-host lifetime mutation scenarios check these boundaries, including
removal of the cached next actor, several cached actors, self-removal and head
insertion. `tests/world_lifetime_host_test.m` is the defined-behavior regression.

The timed tail-death probe still matches all5200 native state/event records
before the invalid original return. Its later native heap-dependent positions,
visit counter and clock count are intentionally not required to match. No
reference bytes were edited to make the unsafe original match the safe port.
Other original-fidelity gaps and complete-game verification remain open.

## Verified mouse primitives and bounded menu integration

`../mouse_release_host.sh` now checks the actual root rapid-release boundary:
press outside, drag onto OK, release/repress before an eligible released-button
poll stays blocked; a closed gate cannot rearm; an eligible released poll
rearms and the next click exits. Field selection still precedes click blocking.
The previous failing test and original counterexample remain in persistent
fidelity notes. This behavior is required, not an allocator-related exclusion.

The native reference has two17-step streams plus closing polls (focused/unfocused),52 records,
from actual MOUSEOVERMENU, DOMOUSE, LMPOINTSPRITE and LMCHANGESPRITEID using the
original sprt table. H polls hover/Button, D dispatches a held mouse, U changes
raw button state without a hover poll. T rows contain TickCount values; S rows
contain exact IEEE Click positions. Other rows contain case,step,operation,
button sprite,animation deadline,latch,active,end,cursor,focus and four IEEE
button rectangle coordinates. Latch is an original signed16 field at+5aa.

Hover clears old902 to900, selects the highest-kind hit, and changes eligible
900 to902 with a new TickCount+1 deadline. Only a hover poll observing Button
false resets the latch. DOMOUSE updates field selection even while latched;
click sound/action are gated, and every DOMOUSE call sets the latch. Raw release
alone leaves it set. The original50-record baseline was repeatable; its rows remain unchanged,
with two additional closing-state polls in the current52-record reference.

The current host passes `../mouse_latch_host.sh` for all52 primitive records,
including per-sprite hover deadlines and original geometry operations. Actual
GL rendering uses the sampled sprite state without another clock read. `../gameover_held_host.sh` additionally matches171 records from three whole
GAMEOVER control-flow schedules with real DOMOUSE body and A/B/Enter while held,
including closed gates and post-frame dispatch.

Later gates cover additional integration and passed again on the Intel Mac on
2026-11-01. `../menu_setup_host.sh` compares nine actual menu reload profiles,
including all52 scene nodes, factory deadlines, RNG and all3000 stars.
`../menu_handle_host.sh` compares six actual root-handler profiles with signed
deadlines, clock wrap, keys and FPS diagnostics; its rendering is an observer.
`../menu_moving_host.sh` compares18 moving-pointer routes across507 frames,
including33675 records and every captured star word. These bounded schedules
do not prove arbitrary combinations of physical input or complete Game Over UI.

The108 original Main-loop schedules currently have a Python-model comparator
and selected root-input checks. Replaying the complete schedules through the
actual root loop remains required, as does ordinary campaign integration with
the UI. These are verification gaps, not authorized fidelity exclusions.

## Key capture regression

The former held-key/first-event mismatch is covered by `../wait_key_host.sh`
(134 complete original traces) and `../key_binding_host.sh` (18 named DOMOUSE
transactions across all six bindings). Original key-wait reference bytes remain
unchanged. The old discrepancy characterization is retained in Git history and
persistent fidelity notes, rather than remaining an expected failing behavior.
Movement/render/animation callbacks are observers in these traces; they do not
prove every numeric waiting-frame state or physical OS event delivery.

## Authorized correction for death during a scripted transition

On 2026-10-30 the user also approved safe death handling instead of the original
NULL-player crash during a midlevel transition. This is a separate exception
from the allocator-dependent cached-tail issue above. The original G5 fault
was mapped to a player rectangle read at code offset 0x4ea80.

The port returns to its existing death dispatcher: remaining lives allow
respawn and continuation; zero lives dispatches Game Over.
`../mid_virtual_clock_host_test.m` checks both branches and successful
continuation to the next half after respawn in controlled geometry. A longer
route separately exercised repeated deaths and reached Game Over without
stalling; it did not complete the transition or campaign. Exact equality after
the original crash is not claimed.
