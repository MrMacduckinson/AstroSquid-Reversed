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

## Verified mouse primitives; remaining frame integration

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
GL rendering uses the sampled sprite state without another clock read. This
still does not prove repeated held DOMOUSE dispatch from the complete frame
loop, field dragging between frames, initial scene factory deadlines or the
normal-menu LMHANDLE lifecycle. These remain required work, not exclusions.
