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

- `tests/mouse_latch_host.sh` matches52 original MOUSEOVERMENU/DOMOUSE primitive
  records, including10 exact clock reads, hover902 deadlines, latch/input state
  and IEEE rectangle coordinates. The original50 records remain unchanged;
  two added closing polls verify the a68=0 coordinate conversion and no extra
  hover clock. Root eligible-frame polling now samples window mouse position;
  UI stores sprite902 and uint32 tick+1, retaining original222px resize/center
  math. Actual GL drawing uses that state without clock reads and event-only
  movement does not prematurely change it. This is not proof of whole-frame
  held-button dispatch, initial factory deadlines or normal-menu LMHANDLE.

- `tests/mouse_release_host.sh` checks the fixed root rapid-release boundary:
  outside-click latch survives raw release/repress and a closed frame gate;
  only an eligible released-button poll rearms it. Latched field selection
  remains active. The52-record gate above additionally covers hover
  deadlines/geometry and controlled held input; complete frame integration
  remains unproved. See the known-gaps README for the remaining scope.

- `tests/gameover_scene_mouse_host.sh` matches46 records from27 routes through
  all three DataB1 scene nodes: OK, fade and offscreen player. Original
  GAMEOVERTRANS settles the panel in60 steps before real DOMOUSE/LMPOINTSPRITE;
  rendering, scene construction and OS bookkeeping are controlled. Background
  and empty-name field clicks also play Click using fade position0, while the
  field cursor updates first. Hit testing includes kinds1..10 and converts
  overlay Y before integer rectangle truncation; this preserves the negative
  fade origin at its lower edge. Hover, held-button latch and whole-loop Button
  scheduling remain outside this gate. The original SetSVolume sound exception
  is a separate remaining audit.

- `tests/gameover_mouse_host.sh` matches20 records for14 actual original
  DOMOUSE/LMPOINTSPRITE routes and host mouseDown/UI hit tests in an explicitly
  isolated single-button scene: button edges,
  center, outside and focus/no focus. Native mouse bookkeeping is shimmed;
  hit testing, name dispatch and state changes execute unchanged. GameOverOK
  sets the end flag before the terminal tail, whereas the keyboard sets it
  after its redraws. Click pan matches exact IEEE381/640, using the selected
  sprite's left edge. The shared menu handler now uses that original formula
  through UI bounds; missing programmatic targets retain centered playback.
  Held-mouse/whole-loop polling, hover and other menu camera positions are not
  independently captured by this fixture.

- `tests/gameover_input_host.sh` matches294 records from six original GAMEOVER
  schedules: focused/unfocused input at frame intervals1/2/3, including closed
  gates. Native HANDLEFIELDEVENTS/HANDLEFIELDKEYS execute unchanged with scripted
  GetNextEvent; host uses actual keyDown, pollMenu, editor and drawRect with
  rendering/audio observers. Exact clocks, bytes, cursor, submitted/active flag,
  button state and render/animate/swap/music/terminal ordering match. Classic
  bytes queue in keyDown, one is consumed per eligible frame; the final input
  frame hides the title before the terminal tail presses OK. Queue and AppKit
  events flush at entry. Additional checks cover255-byte overflow alerts waiting
  for the gate and resolving one byte at a time. Mouse input and full scene
  composite drawing remain outside this fixture.

- `tests/gameover_exit_host.sh` matches23 terminal events from actual original
  GAMEOVER control flow, with and without a qualifying score. World, IO, input,
  scene loading and score implementation are semantic observers on the native
  side. Actual host finishGameOver/drawRect sets button901, hides the title,
  draws world/panel/HUD twice with one intervening swap, requests game end,
  inserts/saves the score, and removes button/fade records. Caller presentation
  deferral is restored. Input timing is covered separately by the294-record gate above;
  this terminal gate retains its narrower scope.

- `tests/panel_projection_host.sh` checks actual drawRect for all30 Pause and
  60 GameOver transition frames plus two steady frames, at1x and2x backing size
  (188 frames). Native `ppc_panel_projection_oracle.c` executes original HUD ->
  RENDERGAMEWINDOW -> DRAWGAMEOVEROVERLAY: the panel inherits viewport0/30/640/380
  and projection0/640/379/0, retaining the same17 logical commands. Production
  now keeps that projection, subtracting70 from UI coordinates with a scoped
  modelview translation restored before HUD. Actual GL viewport/translation
  are exact; projection matrix tolerance1e-8 accounts for driverfloat storage.
  The original whole transition input loop and complete scene composite remain
  outside these checks.

- `tests/gameover_draw_host.sh` matches30 original whole
  DRAWGAMEOVEROVERLAY text/field commands across eight active/closing, focused/unfocused and
  caret-visible/hidden profiles. Original PEF execution retains sprite lookup,
  resource strings and field code. Exact MacRoman bytes, command order and IEEE
  coordinates/sizes/RGBA match: title, OK, field, then Highscore. The title is
  gray while editing a record and absent in closing frames; the closing button is901. Logical menu Y is normalized by70; inherited
  viewport/projection, scene sprite drawing and transition frames remain
  outside this fixture.

- `tests/field_draw_host.sh` matches316 original field records:90 focused
  text/cursor/visibility profiles and the absent-field case. Text bytes,
  logical rectangles, coordinates, sizes, fill mode and RGBA match exactly.
  Native menu-world Y is translated by70, the original DOMOUSE overlay offset;
  parent viewport/projection and glyph rasterization are outside this fixture.
  Original DRAWMYEDITFIELD keeps name origin225 fixed, moves the caret with the
  full integer prefix width and adds no scrolling/scissor. The port now follows
  that behavior and original vertical coordinates. Actual Intel GL checks
  confirm long names extend beyond the box and inherited scissor state is
  respected without being changed. Caret clock tests remain separate.

- `tests/text_cursor_host.sh` compares3027 original/host records:390 integer
  GETSTRINGWIDTH measurements,2385 SETCURSORPOS positions and252 DOMOUSE/root
  mouseDown routes. Cases include empty/space/MacRoman strings, long names,
  five sizes and field edges. Font advances still accumulate as doubles;
  metrics return the original truncated integer. Selection uses strict prefix
  widths from field origin223, including original cursor-1 at the left edge.
  Whole native DOMOUSE confirms hit bounds223<=x<423 and255<=y<277 after its
  70-pixel overlay translation. Other sprite hits and raw mouse acquisition
  are observers, as is the host Cocoa-to-menu transform. Widget glyph geometry,
  long-name scrolling/clipping and cross-GPU pixels remain outside this proof.

- `tests/card_text_host.sh` matches52 original GETREADY/ENDDIALOG/credits text
  commands: all16 ready briefings and all4 ending pages under two key-poll
  schedules, plus4 startup credits lines. MacRoman bytes, order and IEEE coordinates, sizes and RGBA
  values match exactly. The original LMTEXTWIDTH and font resource remain
  active in the G5 oracle; glyph drawing is observed. The startup capture
  retains the original INITSAGAIA frame, skips initialization services with
  one checked branch and stops at the credits swap. This fixes fractional
  centering (native integer width before division) and restores the ending
  prompt before each page body. The native card run also asserts Delay60 per
  page, key/music poll counts and accepted-key STOP/PLAY or GAMEOVER entry;
  existing port delay/music probes pass separately. End-of-level cards and
  unregistered reminder branches are outside this native fixture.

- `tests/outer_loop_host.sh` compares the actual original GAMELOOP entry and
  first ordinary iteration with production beginGameLoop/pollGame/renderTick:
  30 schedules,460 semantic events,228 clock reads. It covers closed/open CPU,
  frame and21-tick map gates, fresh stores, signed wrap and clocks consumed
  inside world/factory callbacks. Those callbacks, graphics, audio and input
  are observers; terminal, transition and respawn branches are excluded. The
  production HUD dispatcher now matches original counter states0/1/2 and each
  decrement. Actual GPU HUD commands are observed at this boundary.
- `tests/hud_countdown_host.sh` also checks actual drawRect ordering/countdown
  for normal, WAIT/blink, special, paused and GameOver contexts; unconditional
  cards/panel transitions do not consume the countdown, and departure trail
  frames do not draw HUD. Source-backed collision/start/transition/special
  probes check invalidation, including zero-score kills and removed pickups.
  The live renderer preserves existing buffers rather than clearing the full
  screen. On the authorized Retina Intel Mac, the actual drawRect paints a
  controlled HUD exactly twice, retained across8 alternating FBO frames and8
  actual window swaps. This proves retention/cadence, not cross-GPU pixel
  identity for every original sprite.

- The first active frame after tag-2 final-arena loading matches94 original
  cleanup/CALC records, including camera1,211 independent clock reads, RNG,
  all active actors and image links. `tests/loaded_world_composite_host.sh`
  checks this together with the96060-byte star/parallax phase. Only the
  observation tick column is normalized (native100, host310); actor timers
  and every gameplay payload remain exact. Rendering is suppressed at this
  boundary; this does not establish whole-campaign equality.

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
  screenshot action is not covered by those host checks; quit is checked below.
- `tests/picture_native/*.pict.gz` contains10 original GETPICT_ offscreen captures.
  The pure-C encoder matches every byte except the two process-local PixMap
  handle words, and G5 native DrawPicture decodes all generated RGB pixels exactly.
  Primary ASan/UBSan, default pure-C suite and actual Intel replay pass. This is
  a PICT payload codec proof; screenshot startup/capture/save is not integrated,
  and the actual window/OpenGL capture and file metadata/prefix remain open.
- `tests/keymap_native.csv` records137 private-original G5 GETKEYMAP cases with
  scripted maps and a screenshot observer. The host matches control bits and
  key counts for136 API-conforming maps, including every single key. A separate
  padding-write diagnostic exercises bit128; original local clearing left that
  byte zero before every captured call. Native results identify Escape as the
  pause key, Command-Q as the stop flag and keypad multiply as the debug-enabled
  screenshot key. This does not prove physical-device input, pause-loop timing
  or implementation of the screenshot action. The host now checks the actual
  quit latch against these native outputs.
- `tests/quit_loop_native.csv` records8 original GAMELOOP terminal-tail cases,
  188 event/state observations with closed CPU/spawn gates. It verifies latched
  input, exact positive1 exit checks, actual image/entity/map cleanup and menu/
  event/music/cursor callback order. UI/audio/GL are observers; original outer
  CLOSEDOWN and advancing/nested world exits are outside this native capture.
  The host now matches71 high-level event labels from5 STARTNEWGAME-compatible
  paths, plus their clock totals and terminal world/map/menu/quit states. Signed
  quit=-1 and pre-entry game-end1 remain native diagnostics, not host start states.
  Actual host checks cover deferred WAIT/blink/card/score/stage completion,
  normal game exit, retained actor link cleanup, and AppKit quit/window-close
  routing. A further special-phase test injects Command-Q inside the real nested
  special and preserves all31 updates before ordinary-tail cleanup. A private
  real app bundle also received Quit through AppKit, persisted6 keys/10 scores,
  and exited0; its temporary bundle/preferences were removed.
  These are bounded lifecycle checks, not full native CLOSEDOWN/GL/audio/event
  parity. Text-field event/frame scheduling and native window-close delivery
  remain outside the capture.
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
- `tests/special_phase_native.csv` now resolves the old hardcoded `beams==30`
  failure with7 actual G5 timed-plasma captures. Under the host probe's clock
  schedule, interval3 produces31 updates/action193, not30/action192. All7 cases
  match186082 advancing clock queries, final CPU/render/action times, frame and
  swap counts on Intel. CALC/LM clocks are held fixed inside those boundaries;
  GPU/audio are observers. This is not an unrestricted real-time world proof.
- `tests/special_phase_host_test.m` checks the actual host at intervals2/3/0/-1:
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
