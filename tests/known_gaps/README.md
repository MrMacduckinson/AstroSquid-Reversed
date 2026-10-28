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
