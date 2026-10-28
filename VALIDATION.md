# Validation scope

Target: AstroSquid 1.1 reconstructed native Intel application, macOS 10.13.6.
Original execution references: PowerPC G5, Mac OS X 10.4.11, original 1.1 CFM/PEF.
No game, GUI, OpenGL or audio test is launched on the primary development Mac.

## Bitwise fidelity work in progress

Full defined-gameplay equivalence remains unproved. On2026-10-28 the user
explicitly excluded reproducing allocator-dependent use-after-free. When nested
cleanup deletes a cached next actor, production traversal skips that retired
identity and follows its retained next link. It still visits actors merely
marked for removal until cleanup actually removes them. The original unsafe
reference remains documented in `tests/known_gaps/README.md`; its post-free
allocator outcome is an intentional difference, not a passing equality claim.

Current bounded evidence:

Native comparisons below describe individual verification milestones. Later
clock, actor and lifecycle changes are not automatically covered by older world
captures; those captures do not establish equivalence of the current full game.

- Shared production world methods match an original G5 capture for180 controlled
  ticks:26808 canonical records, with exact nonpointer fields, list order, RNG,
  effects, sound names/pan and animation. The committed30tick fixture has6588
  records. See `tools/WORLD_ORACLE.md`; this excludes map scheduling, respawn,
  transitions, normal frame ordering and actual GPU rasterization.
- A controlled parent-linked variant matches6576 records across30ticks, including
  chain order and propagation of a parent death; normalparent-free180ticks remain
  identical. This is an explicit initial-condition probe, not a normal-campaign
  reachability claim. Parent links during specials remain unverified.
- All29 original AI scripts match104400 controlled original/portable ticks,
  including natural/scaled visual dimensions (separate G5 oracle invocation).
- `tests/script_clock_native.csv` captures10 whole-original DOSCRIPTEDSPRITE
  cases with33 independent clock reads. Replay checks actual call-site roles,
  state before every read, final state/velocity bits and one fire callback that
  consumes a clock before animation resumes. Script-resource delivery and the
  fire callback are controlled boundaries; this does not execute real weapon
  allocation or prove all AI/world interactions. The10 source-derived tests
  remain separate from this native capture.
- `tests/debris_clock_vectors.csv` contains12 fresh original G5 debris cases,
  replayed by the default test suite. They check32 conditional clock reads,
  native call-site addresses, timer/removal values before each read and final
  IEEE velocity bits for kind4 and the CALC kind20 branch. The private oracle
  bypasses MOVESTARS and CHECKSPRITECOLLISION; this is not a full coupled world
  or renderer proof. The5 separate source-derived clock cases remain labelled.
- `tests/bullet_clock_native.csv` contains8 whole-original DOBULLETSPRITE cases,
  including7 native clock reads and inactive states with no reads. The Intel
  production-host test replays native call-site roles, pre-read update values
  and final timers. The oracle checks that other entity bytes remain unchanged;
  common CALC movement checks are separate and do not turn this into a coupled
  original-world trace.
- Keyboard polling now uses one native Carbon `GetKeys` snapshot at the ordinary
  loop tail, WAIT/blink, card and special input boundaries. The Intel provider
  call was checked without logging key values. `tests/keymap_host_test.m` checks
  all128 positions, replacement of stale state and call ordering with injected
  snapshots; it is not an original G5 physical-key capture. Execution of the
  original quit/screenshot actions is not covered by those host checks.
- `tests/keymap_native.csv` records137 private-original G5 GETKEYMAP cases with
  scripted maps and a screenshot observer. The host matches control bits and
  key counts for136 API-conforming maps, including every single key. A separate
  padding-write diagnostic exercises bit128; original local clearing left that
  byte zero before every captured call. Native results identify Escape as the
  pause key, Command-Q as the stop flag and keypad multiply as the debug-enabled
  screenshot key. This does not prove physical-device input, pause-loop timing
  or implementation of the stop/screenshot actions in the port.
- `tests/pause_native.csv` records16 original G5 PAUSE/GETKEYMAP cases and708
  boundary/state observations. Two captures were byte-identical. It establishes
  held-key exit at eligible frame polls, interval1/2/3 gates, fresh post-swap CPU
  clock stores, HUD dirty decrements, CmdQ state, clock wrap and cleanup order.
  UI/audio/render/mouse are controlled observers. The actual Intel host replays
  the230 clock/frame/input/mouse-boundary projections (100 clock reads), including
  CPU stores and paused/key-count state. Pause now runs synchronously from the
  ordinary/WAIT/blink/READY-return input checkpoints, with a timer reentry guard.
  Separate actual-host checks verify WAIT and blink continue after pause without
  an extra world/factory step; special raw input does not invoke misc keys.
  The full app selftest exercises the production pause loop and panel rendering.
  Native HUD/resource/cursor/quit side effects, held mouse input and real queued
  mouse delivery are not established by this projected replay.
- `tests/caret_vectors.csv` contains4225 original DRAWMYEDITFIELD captures of
  deadline, visibility and conditional TickCount reads. GL/font drawing is
  replaced by no-ops in the private native oracle; original caret logic runs.
  Signed deadline comparison, strict inequality and a single reschedule after a
  long gap are preserved. `tests/ui_render_host.m` checks the real Intel renderer
  independently of panel frames; name input does not reset the caret clock.
- GameOver control-flow checks execute actual host world methods with controlled
  OS clock/Delay:10cleanup/calc/animate/render iterations,29delay ticks,60panel
  redraws, then name entry. This does not prove a complete native GameOver world
  or rendered-state trace.
- `astro_frame_interval` matches the original startup conversion for all65536
  signed16 FPS values on both the development CPU and Intel iMac. The G5 oracle
  executes the original Float2Int/store instruction slice in private memory
  (`tools/ppc_fps_oracle.c`); no preferences are changed. The standard physics
  test retains24 boundary cases, including FPS0 producing interval-1.
- `tests/ui_interval_test.m` matches39 original G5 camera states at intervals2/3
  bitwise, including the initial camera residual. Menu orb animation receives
  the configured interval, while synchronous Pause/GameOver panels retain30/60
  frames. Actual Intel GL rendering also passes at both intervals. This is
  renderer support; host FPS preferences and all gameplay consumers are not yet
  connected. The shared world/special render deadline is checked below.
- `tests/special_fps_vectors.csv` retains40 original timed-special render phases
  and1232 captured CPU updates. Shared render deadlines, signed intervals,
  world-before-special RNG, first-flash IEEE coordinates and terminal outer
  render eligibility match. This replays captured CPU ticks; it does not replace
  the original busy-loop TickCount read schedule with a fixed31-update claim.
- A current audit reproduced the old `special_phase_host_test.m` assertion
  `beams==30` failure both before and after the pause change. Its synthetic
  clock schedule needs comparison with a native capture; the cause is still
  unresolved and this test is not counted as passing. The16 native coupled special and48 coupled
  beam trace gates passed with the pause change.
- `tests/special_phase_host_test.m` historically checked the actual host at intervals2/3/0/-1:
  gun coordinates cached before nested CALC, parent inheritance before damage,
  world render before special visuals, inner animation before restoring kind1,
  suppressed outer rendering while blocked, and terminal shared-deadline reuse.
  A pending respawn timer does not suppress the original unconditional kind1
  restoration. The synchronous path checks both30-update and zero-update
  completion, including a positive-interval outer render after return. Distinct
  fresh outer render-compare/store/animation clocks are also checked.
- `tests/player_tail_host_test.m` matches48 native G5 postfire states for every
  shield/glow presence combination, signed frames and timer wrapping. The host
  runs this continuation after synchronous special return, before the remaining
  outer actors. A closed player update gate suppresses both firing and this
  continuation; primary fire precedes fresh action/update clock stores.

Original configured FPS intervals, parent-linked cases, production scheduling,
full startup/menu state, extended campaigns and final packaging remain open.
The production timed-special path now uses `astro_special_run_nested`, matching
the original separate clock reads and synchronous call stack. This driver matches12 original polling
schedules and all62066 clock reads, with distinct compare/store times, a
clock-consuming CALC hook, ordered effects/RNG and terminal deadlines. Its
728-line fixture losslessly expands repeated clock records; every expanded read
is checked. Shared player action stores are checked before every clock/hook.
Actor internals and entity-kind writes are outside this driver test. Host tests
check their integration separately; this is not a full native coupled special
world trace. Original per-actor clock reads, list lifetimes across nested cleanup,
and unusual clock-jump/input reentry cases still need broader verification.

## Checks performed

- `./test.sh --native-only` on Intel: portable behavior fixtures from original
  execution and interpreter checks, weapons, targeting, damage, pickups,
  player/scenery, visuals, special attacks, nested scheduling, campaign, HUD,
  score editing and transitions.
- `./test.sh` portable/resource checks: all 8126 map entries and cross-links,
  all 54 atlas dimensions, sound PCM hashes and all 74 original QuickDraw rasters.
  Python checks require Pillow; Intel's native-only run explicitly omits them.
- Actual application `--self-test DIRECTORY` on Intel: menus, stage cards,
  settings and score entry handlers, movement, all four special families, beams,
  projectile hits, effects, boss defeat/score, stage selection, GL rendering and
  music advancement. Additional assertions cover normal death/respawn, retained
  base weapon, upgrade reset, relative blink and invulnerability, scenery shield
  effects, modifier-key pause/resume and release order, and elapsed pause time.
  The combat fixture grants a shield; this is not an unaided playthrough.
- Actual write/reload in two separate Intel processes with an isolated temporary
  bundle identifier: reassigned key, filtering, both volumes, unlocked stage and
  score survive restart. Probe defaults are removed, player defaults untouched.
- Original G5 hit-effect oracle: 1980 mixed projectile/scenery lifecycle ticks,
  matching sound cue/pan, new effect layers 7/8, existing effect reset and resize,
  follow position, animation deadlines and removal. See `validation/hit-visual.json`.
- Complete Intel controlled campaign: real AI, collisions, map spawning and
  transitions through 1A–8B and 9B, then all four ending pages. Pilot replenishes
  shield, uses weapon 53 and steers using normal directional inputs; no stage
  teleport. This proves the complete route works, not ordinary-player difficulty.

## Actual production renderer versus original PPC

`tests/production_framebuffer_reference_metrics.json` records 12 complete
640×380 playfields. The G5 executes the unmodified original renderer and sprite
drawer. The Intel test directly includes the application's source and calls its
actual `AstroView.drawRect`, texture loader, stars, object ordering and effects;
it does not duplicate those production drawing functions. Scene state is
controlled, backing resolution is pinned to 640×480, and dithering is disabled on
both GPUs. Readback is the entire playfield after the complete production draw.
Original HUD border sprite 404 is drawn before the original world, with a bullet
crossing the shared edge. Both representative images are under `validation/`.

Every frame has at least 99.515625% of pixels within 2/255 RGB; mean per-channel
error is at most 0.250128/255. Sparse point/nearest-filter edges can differ by a
pixel across GPUs. A separate shared-edge regression gate requires mean error
below 1/255: ten frames match exactly; two differ by at most 1/255. A negative
control deliberately redrawing the HUD after the world fails this focused gate.
This caught and verified the corrected gameplay HUD/world ordering. Pause keeps
its original world-then-HUD overlay order.

This is a complete controlled playfield comparison, not a pixel-identity claim
for live campaign captures or the entire window's HUD text and menus. Original
HUD commands and all 74 rasters have separate native checks. The earlier
standalone duplicate-math experiment remains in
`tests/framebuffer_reference_metrics.json`, clearly labelled as indirect evidence.

Build the production render test on the Intel target (OpenGL/audio initialization
is involved; do not run on the primary Mac):

```sh
clang -fobjc-arc -O2 -Wno-deprecated-declarations tests/production_framebuffer.m \
  src/*.c src/audio.m src/ui_renderer.m src/hud_renderer.m \
  -framework Cocoa -framework OpenGL -framework AVFoundation \
  -o build/production_framebuffer
build/production_framebuffer assets /tmp/astrosquid-frames --hud-edge
```

Generate original inputs with `tools/prepare_framebuffer_inputs.py` and run
`tools/ppc_framebuffer_oracle.c` on the G5 with its `--hud-edge` flag. The native
oracle requires the original application/analysis and generated `imports.h` from
`tools/prepare_script_oracle.py`. Compare corresponding raw frames with
`tools/compare_framebuffers.py FRAME_DIRECTORY OUTPUT_JSON --hud-edge`.

## Reproduce runtime checks on the target Mac

```sh
./test.sh --native-only
./build.sh
'build/AstroSquid.app/Contents/MacOS/AstroSquid' --self-test /tmp/astrosquid-selftest
'build/AstroSquid.app/Contents/MacOS/AstroSquid' --campaign-test /tmp/astrosquid-campaign
```

Both application checks write JSON evidence and exit with a failing status if a
required assertion fails. Full campaign takes several minutes on the reference
iMac. Do not run two interactive application checks simultaneously.

The final Intel campaign result is `validation/campaign.json`: 17 stages,
214398 simulation ticks and ending reached, including the final HUD/world ordering fix. `validation/runtime.json` records
the final actual-application self-test; assertions also run for the normal
lifecycle and input cases described above.

## Boundaries

This is reconstructed source and an unsigned application. It is not the original
FutureBASIC project, a PPC build, or a claim of support for every macOS version.
No unaided full playthrough or pixel-identical live campaign capture across GPUs
has been established. Native routine comparisons, controlled rendering and a
complete assisted route provide separate evidence for their respective scopes.
