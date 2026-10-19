# Coupled native world trace

`ppc_world_oracle.c` runs a private loaded copy of original download-3 FCOD on the
reference PowerPC G5. Original disk binaries and the live app are untouched. It
uses the existing PPC/CFM bridge and import table. Compile on G5 with GCC:

```
gcc -std=gnu99 -O2 -mno-fused-madd -I analysis/script-oracle \
 tools/ppc_world_oracle.c src/script.c src/physics.c src/ppc_math.c \
 -framework Carbon -o world_oracle
world_oracle ORIGINAL.pef ORIGINAL.literals.bin ORIGINAL_APP TABLES_DIR 180 > trace.tsv
```

The included `ppc_script_oracle.c` renamed legacy main requires these C objects
at link time; the world oracle itself **does not invoke portable game code**.
TABLES_DIR contains the original Attr.bin (441×30), sprt.bin (1001×14), Wpns.bin.
Original resources are opened read-only for actual STR# scripts/string lookup.

## Boundaries

Unchanged original routines execute: NEWSPRITE/NEWBULLETSPRITE/LMNEWSPRITE,
CALCSPRITES including MOVESTARS, CHECKSPRITECOLLISION and collision resolution,
DOSCRIPTEDSPRITE, DOPLAYERSPRITE and real FIREWEAPON, debris updates,
CLEANUPMARKEDSPRITES and actual ADDSPRITEDEATHEFFECTS/DELETESPRITE/LMKILLSPRITE,
then LMHANDLESPRITES and frame changes. There is no replacement AI, collision,
weapon, effect, factory, RNG or list logic. No OpenGL renderer is invoked.

Only OS/environment boundaries are controlled:

- TickCount always returns current integer tick, including repeated reads.
- NewPtrClear zeroes real requested bytes and assigns monotonic creation IDs.
  Entity size106 and LM size308 have separate ID sequences. DisposePtr marks
  allocations dead and retains storage until process exit to prevent address reuse.
- Original SOUNDPLAYPAN entry 0x1003ce84 is redirected in the private memory copy
  to record requested Pascal cue bytes and raw pan double. It does not run audio.
- All other imports use the G5's real dlsym implementations. Unavailable imports
  fail immediately with index/name rather than silently substituting behavior.

## Exact scenario

Zero all globals and allocate FutureBASIC evaluation heap1MiB. Configure literal
pool, pi, integer-conversion constants, original tables, and zero3001×4 double
star buffer. Global viewport=(0,0,640,380), scroll=(1,0), interval1, seed0x12345678,
weapon10, upgrade0, specials2; all unspecified globals remain zero.

At TickCount0, call original NEWSPRITE in this creation order:

1. kind1/subtype1 at(100,180): designate g_player; set frame12, tilt3, HP200.
2. kind7/subtype3 at(300,180): HP1 (explicit controlled initial condition).
3. kind20/subtype4 at(200,250): HP1.
4. kind7/subtype3 at(450,100): retain original attributes/script/HP.
5. kind40/subtype1 at(160,180): original pickup.
6. Call original NEWBULLETSPRITE type1 at(300,180), heading0, source=player.
7. Call original NEWBULLETSPRITE type1 at(200,250), heading0, source=player.

NEWSPRITE prepends entity nodes and LMNEWSPRITE appends render nodes; retain this
order, factory timing and every original RNG draw. HP1 and initial projectiles
make actual collision/death effects reachable immediately; the surviving enemy
executes its genuine shipped script.

Capture `initial`, then for tick1..180 inclusive set keys=(tick/30)%16 using integer
division; bit0 up,1 down,2 left,3 right. Set fire to true iff tick%7==0; special
fire remains false. Original key globals use -1 for pressed,0 otherwise.
Per tick execute and snapshot these complete phases in order:

1. `calc`: original CALCSPRITES0x10054c64.
2. `cleanup`: original CLEANUPMARKEDSPRITES0x100539b8.
3. `animate`: original LMHANDLESPRITES0x1003b55c.

No pause, spawning scheduler, level script loader, presentation, UI, respawn or
transition routine is invoked. This is a controlled coupled-world fixture, not a
claim of an entire normal campaign trace. Stars start zero rather than INITSTARS;
this is intentional to make the exact initial state cheap to reproduce.

## Canonical TSV schema

Every raw byte field is hexadecimal **big endian**, preserving original signed
widths and IEEE double bit patterns. IDs never contain native memory addresses.
Rows retain original entity-list and render-list iteration order.

- `G tick phase rngHex playerEntityID viewportHex scrollHex inventoryHex scoreHex`
  viewport: globals0xa1e..0xa3d (four doubles left/right/top/bottom).
  scroll:0xa58..0xa67 (two doubles x/y).
  inventory:0xa8a..0xa93 (three int16 weapon/upgrade/specials, int32 entity count).
  scoreHex:0xa7e..0xa89 (score int32, stage int16, remaining global int16/int32;
  reproduce these exact bytes, do not treat unknown fields as asserted semantics).
- `E tick phase entityID renderID parentEntityID previousEntityID nextEntityID payload`
  payload concatenates original entity bytes [0,62),[66,92),[96,98):90 bytes.
  Restore pointer holes separately: render at62, parent at92, previous98,next102.
  This preserves every nonpointer byte of the106-byte original entity, including
  counters, signed16 bounds, previous bounds, cached x/y and velocities.
- `R tick phase renderID previousRenderID nextRenderID payload userdataHex`
  payload=[0,40): x/y/width/height doubles, int16 layer, uint32 animation deadline,
  int16 sprite ID. userdataHex=[296,300) is original signed32 custom data.
  LM previous is304,next300. Pascal name occupies40..295; it is intentionally
  omitted from numeric state (sound names have their own observable row).
- `S tick phase cueNameHex panDoubleHex`: emitted during that phase in real order.

Snapshots include both list links explicitly; no sums/digests replace state.
Host comparison should stop at first differing row/field and report original raw
bits versus portable raw bits. Unmodelled entity fields are explicit coverage gaps,
not permission to ignore mismatches.

## Captured evidence

`tests/world_trace_native.txt` is the first30 ticks of the independently repeated
180-tick original run:6588 records, approximately1MiB. Full180 ticks remain in
internal context `world-coupled/original-180.tsv` with26808 records. Both native
processes generated byte-identical180-tick traces (cmp);49 entity allocations,
73 LM allocations,8 distinct RNG states. Semantic cues were12 Pellet,1 Shield,
1 Bang3 and1 Bang2: collision/death sounds and genuine effects were reached.

```
python3 tools/world_trace.py tests/world_trace_native.txt
python3 tools/world_trace.py tests/world_trace_native.txt HOST_TRACE.tsv
```

The validator checks field widths and bidirectional entity/LM list consistency
for each phase. The comparator reports first differing record, field and raw byte
offset; a self-comparison verifies plumbing only, not host fidelity.
