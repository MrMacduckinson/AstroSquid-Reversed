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

- FOLLOW=500 continues the real game loop after 1B victory and 2A creation,
  without resetting player, inventory, clocks or RNG: 1,115,774 records match
  (FOLLOW1_VERIFIED), including all 500 post-load music observations. The host
  fixture now passes pilot input once READY reaches PLAY instead of retaining
  its card-only key override. Initial HP30000/Laser4 remain controlled inputs;
  this is a bounded continuous segment, not an ordinary full campaign.


- Extending FOLLOW to natural death on 2A matches 1,182,411 records through
  GameOver entry (FOLLOW1_LONG_VERIFIED), clocks1370562/1370661/1370606.
  The initial 1B controlled setup remains HP30000/Laser4; after transition,
  health, weapon and lives follow the game without test refills. This verifies
  post-load play and death, not a full campaign win.

- With AIM/AVOID/BRAKE inputs the continuous 1B-to-2A route reaches late2A
  before natural GameOver: 2,957,894 records match (FOLLOW1_PILOT_VERIFIED),
  final clocks3168645/3168744/3168692. No post-load health refill is used;
  this remains a controlled initial1B setup, not an ordinary full campaign.

- Independent 2B victory through the end card and 3A player/world creation
  matches 2,187,877 records (BOSS2_NEXT_VERIFIED), terminal clocks
  2190443/2190032/2190425. Captured inventory, stage, RNG and 3000 stars match;
  only G/E/R/S annotation ticks are normalized. The boss-next fixture now
  derives the next level from its initial stage instead of assuming level2.
  Initial HP30000/Laser4 and held fire/Y95 remain controlled test conditions.


- The corresponding 3B victory through 4A creation matches 2,491,503 records
  (BOSS3_NEXT_VERIFIED), terminal clocks 2966341/2965901/2966293, including
  next-stage RNG569a46a1, inventory and all stars. Same controlled HP30000,
  Laser4/Y95 scope and annotation-only normalization; no continuous campaign
  or ordinary-health completion claim.

- Independent 4B victory through 5A creation matches 3,974,206 records
  (BOSS4_NEXT_VERIFIED), terminal clocks 2826813/2826414/2826806 and
  next-stage RNG19478066. Initial HP30000/Laser4/Y225 with terrain avoidance
  and braking; only diagnostic annotation ticks normalized. This includes
  the end transition, ready card and world/player creation after the boss.

- Reactor destruction on 5B through 6A creation matches 4,417,697 records
  (BOSS5_NEXT_VERIFIED), terminal clocks 3411295/3410856/3411248 and next-stage
  RNG39a9015e. Initial HP30000/Laser4/Y190 with avoidance/braking; complete
  captured state and event order match except diagnostic annotation ticks.
  This is an independent stage carryover test, not ordinary campaign proof.

- Independent 7B victory through 8A creation matches 1,895,487 records
  (BOSS7_NEXT_VERIFIED), terminal clocks 1952192/1951742/1952125 and RNG63abc2bb.
  Initial HP30000/Laser4/Y95 with aiming, avoidance and braking; only diagnostic
  annotation ticks normalized. This does not prove ordinary-health campaign play.

- 6B victory through 7A creation matches 2,073,038 records after fixing
  incoming scroll preservation (BOSS6_NEXT_VERIFIED), terminal clocks
  1862516/1861732/1862491 and RNGdf258983. Pending stage dispatch previously
  zeroed scroll before ENDOFLEVEL, unlike the moving 6B arena in the original.
  Dispatch now retains the last scroll and transition initialization inherits it.
  The actual MID/END virtual-clock regression passes after its manually
  requested transitions explicitly initialize pendingCampaign. Initial HP30000,
  Laser4/Y280 avoidance/braking remain controlled conditions.

- On 2026-10-30, independent full-stage native G5/Intel comparisons matched
  through victory on 4B (3,954,811 records), 5B (4,402,142 records), and 6B
  (2,065,930 records). The actual targets were attribute153 (Drill-Killah),
  attribute258 (station reactor), and attribute156 (laser tank); each reached
  HP <= 0 and removal -1 before the terminal campaign-load marker. These runs
  used initial HP30000, Laser4, terrain avoidance and braking, with target Y225,
  Y190 and Y280 respectively. Only G/E/R/S diagnostic annotation ticks were
  normalized; all other captured fields and record order matched. Full gzip
  captures and SHA-256 manifests are retained in the internal fidelity audit
  as BOSS4_VERIFIED, REACTOR5_VERIFIED and BOSS6_VERIFIED. This is controlled
  gameplay-state evidence, not ordinary-health or continuous-campaign proof,
  and does not establish pixel or audio-sample equality.

- The independent 7B comparison additionally matches 1,889,889 records through
  defeat of attribute155 (HP -14447, removal -1). It uses the same HP30000/Laser4
  fixture with target Y95, enemy aiming, terrain avoidance and braking. The
  original and host both retain 15474 player HP. This high-health outcome is
  not evidence of an ordinary-health winning strategy. BOSS7_VERIFIED retains
  the complete capture hashes; the same annotation-only normalization applies.

- The continuous 8B-to-9B route matches 2,726,752 records through final victory,
  including destruction of the tag -2 entrance (attribute261) and final boss
  (attribute157). Both end at HP0/removal -1. The fixture uses HP30000/Laser4,
  Y190, enemy aiming, objective priority, terrain avoidance and braking.
  Objective priority targets live tag -1/-2 entities 80–600 pixels ahead; it
  changes test inputs only. The host additionally asserts campaign completion
  while the global stage remains 8B. FINAL8_VERIFIED retains full captures and
  hashes with the same annotation-only normalization. This stops before the
  ending transition and does not establish an ordinary-health campaign win.

- Continuing that final route with BOSS_END matches 2,738,045 records through
  the transition to the pre-end-card boundary (FINAL8_END_VERIFIED). The final
  K/end clock tuple is 2132130/2131836/2132229 on both systems. This extends the
  coupled world comparison beyond boss destruction; it does not include the
  subsequent card presentation, four ending pages or return to GameOver.

- Extending the final route through the end card, four ending pages and
  GameOver entry matches 2,738,066 records (ENDING_VERIFIED). The held-key
  sequence includes five presentations and four Delay60 intervals. This found
  68 missing clock reads: original ENDDIALOGCLEAR creates 17 temporary HUD
  sprites per ending page. Production now accounts for actual ending HUD sprite
  births/clocks and its integer camera restoration; the fixture draws that HUD
  rather than adding a fixed clock correction. Final K/entry clocks match
  2132438/2131836/2132229. The separate card-delay regression passes. This is
  still a controlled high-health route and stops before the GameOver panel;
  text/glyph/pixel coverage remains as scoped in the separate card tests.

- ENDING combined with GAMEOVER_WARM extends the same original/host route
  through all ten GameOver warm frames: 2,738,085 records match, including
  delays 0,1,1,2,3,3,4,4,5,6 and their exact clock counts. ENDING_WARM_VERIFIED
  retains the captures. The real cleanup, actor and visual updates run after
  the ending; the observer stops at ShowCursor before panel construction.

- ENDING + GAMEOVER_WARM + PANEL now reaches panel-ready with 2,738,092
  matching canonical records (ENDING_PANEL_VERIFIED). Native's three linked
  UI render nodes are compared through U/F, with host P duplicates checked
  against U; game clocks and IEEE coordinates are not normalized. This found
  and fixed stale screen coordinates after HUD truncates the world camera:
  the UI now reprojects its retained world coordinates against the updated
  origin. Pause/GameOver actual projection tests pass at 1x and 2x. This route
  still uses initial HP30000/Laser4 and stops before name submission/menu return.

- The same controlled final route now continues through A/B/Left/C/Enter,
  score insertion (ACB, 59007), panel cleanup, world destruction and menu
  return: 2,741,184 canonical records match (ENDING_RETURN_VERIFIED).
  Each repeated UI snapshot is mapped independently; native R fields are
  checked against host P fields, including IEEE coordinates and deadlines.
  A redundant native arena_play end-pre-card diagnostic on menu music is
  checked against all 52 already-recorded menu objects before omission.
  The final return clock is 2133871; menu RNG, 3000 stars, 52 UI objects,
  registration carets and return protocol match. This remains an independent
  high-health final-stage test, not a continuous ordinary-health campaign.

- `tests/gameover_held_host.sh` matches171 records from three original GAMEOVER
  schedules with held mouse and queued A/B/Enter at intervals1/2/3. The original
  TRANS and DOMOUSE body execute; a validated PC-independent prologue trampoline
  supplies the controlled empty mouse-action name. Scene construction/IO,
  hover/render/music and terminal sprite change are observers. A/B advances
  are the verified font129 values. Actual field selection runs on closed
  gates and after frame-body clock storage, so A/B produces BA. Host uses the
  same shared field/action handler for AppKit and held polling. Closing-state
  coordinates and duplicate terminal-tail prevention have separate assertions.
  This does not verify factory-derived field geometry or every mixed input.

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
  reachability claim. The later linked-parent special gate below covers two
  controlled surviving-target cases during actual nested specials.
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
- `tests/picture_native/*.pict.gz` contains original offscreen, window and
  fullscreen PICT captures. The encoder checks normalize only process-local
  PixMap handle words; native DrawPicture additionally checked decoded RGB.
  `bash tests/picture_host.sh` was rerun on the Intel iMac after the pilot work:
  actual startup/debug gating, held screenshot key, quit coexistence, complete
  saved window PICT, 512-byte prefix, Finder type/creator, same-name truncation,
  read-only failure and folder failure all passed. The temporary files are removed
  by the test. Earlier fullscreen evidence covers RGBA and GL state restoration;
  this rerun does not revalidate fullscreen or every later in-game port state.
  Full campaign screenshot identity remains unproved.
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
214272 simulation ticks and ending reached in the 2026-10-29 rerun after the event/field lifecycle fixes. This controlled port route is not a canonical original-versus-port campaign comparison. `validation/runtime.json` records
the final actual-application self-test; assertions also run for the normal
lifecycle and input cases described above.

## Boundaries

This is reconstructed source and an unsigned application. It is not the original
FutureBASIC project, a PPC build, or a claim of support for every macOS version.
No unaided full playthrough or pixel-identical live campaign capture across GPUs
has been established. Native routine comparisons, controlled rendering and a
complete assisted route provide separate evidence for their respective scopes.

## Main event and registration lifecycle checks (2026-10-29)

The original Main loop trace now includes the published 16-bit frame count:
108 schedules and 11,058 records compared by `tests/main_queue_schedule_test.py`.
Actual Root tests in `tests/registration_input_host_test.m` cover eligible and
closed frame gates, 59/60-tick publication, low-word wrap, and nested menu exclusion.
These are separate from renderer FPS; the complete native trace is not yet
replayed against the complete Root run loop.

Game-window key events enter the shared queue before Cocoa menu equivalents.
Targeted tests cover repeat, wrapped views, other windows, and the modal guard.
Original startup snapshots (`tools/ppc_startup_callbacks.gdb`) found zero menu/end
callbacks and quit identity 00010001 after initialization. Menu Quit therefore
uses runtime termination without saving, while physical key-map quit remains a
separate path. `tests/menu_quit_process_test.m` verified actual Intel process exit
and fullscreen restoration, with a failing trap if saveSettings was called.

`tools/ppc_menu_setup_oracle.c` in `lifecycle` mode seeds existing field state
before actual PUTCONTROLS: focus and the second field's submitted flag survive;
text/cursors and the first submitted flag reset. The port now preserves this
asymmetry. Nine native profiles and three Root focus cases passed. Unused Pascal
buffer bytes and the complete shared GameOver-field lifecycle remain unaudited.
The complete application self-test passed again after this change (f7f8e1c),
with normal process exit and native display restoration. This is not a new
whole-campaign equivalence result.

### Extended world and lifecycle checks (2026-10-29)

The fixed coupled-world scenario was extended to 3600 updates on the original
G5 executable and current Intel host: all 142089 canonical records matched
exactly (22729649 bytes). This scenario uses controlled inputs and clocks; it
is not a complete campaign comparison.

The final-arena harness now supports `outer64` and `outer-map256`. The latter
executes actual map spawning after each follow-up world update. It exposed a
post-death parallax mismatch: original MOVESTARS stops background motion while
the death/end flag is set. Commit 9872ad0 applies that gate, including resuming
motion during the respawn wait after the original clears its death flag. All
28856 state records then matched. Only the harness record timestamp is excluded
in this comparison: the native recorder labels the base tick, while the host
labels its latest sampled tick. Object timer bytes remain compared exactly.
The G5 map and scene inputs match download #3 by MD5.

New Game/Continue initialization order and cursor boundaries now follow the
original. Intel tests cover retained state through level load, score reset and
swap before player creation, pause show/hide order, GameOver and return-to-menu
cursor placement, balanced real AppKit hide/unhide forwarding, and controlled
Stop/Continue alert returns. These checks do not prove cursor appearance across
real application focus changes. The full application self-test passed at
production 5deed41; the later parallax fix has passed targeted GameOver,
respawn, pause and quit tests and an Intel build. Whole-game equality remains
unproven, and release archives have not been refreshed as final deliverables.

The complete controlled campaign passed again at 9872ad0: all 17 stages,
214271 ticks, ending reached, exit 0 and native display restoration. The pilot
replenishes shield and uses weapon 53 without stage teleportation. Initial RNG
is not fixed, so score/tick differences from prior runs are not a deterministic
comparison. This establishes current route completion, not original campaign
equivalence. See `validation/campaign.json`.

Continuous carryover with close-enemy avoidance: the original on G5 and Intel
host matched all 3,124,822 records through 10,000 post-load observations after
1B→2A. Only G/E/R/S annotation ticks were normalized; game clocks, RNG,
serialized entity/render fields and events were compared exactly. Both ended
with `W follow-complete`, player alive in 2A (HP30, lives2, x10019.065101883212),
RNG db0df262. The optional `ASTRO_WORLD_BOSS_AVOID_ENEMIES` pilot flag includes
live kind5 enemies in the existing obstacle checks; this changes test inputs,
not production collision rules. Initial 1B uses controlled HP30000/Laser4;
after loading 2A the original health/weapon resets apply, without test refills.
This does not establish ordinary full-campaign equivalence or the subsequent
2A→2B transition. Full paired traces and hashes are retained internally in
`FOLLOW1_AVOID_ENEMIES_VERIFIED.json`.

Continuous 1B→2A→2B through natural GameOver now matches the original G5 in
all 4,438,577 records, including 16,221 post-load observations and both READY
music-service snapshots. Terminal clocks are 4625066/4625165/4625122, RNG
4775ea5c, stage2B/lives0. Only diagnostic G/E/R/S annotation ticks are normalized;
serialized game state, event order and clocks are exact. This extends the prior
10,000-observation route using the same initial controlled HP30000/Laser4 and
actual health/weapon resets after loading 2A, without test refills thereafter.

The comparison found a real held-fire bug: MID scripted movement suppressed
manual movement but allowed ordinary shots. The original clears ordinary fire
at 0x4eb30 and 0x4ecbc; the port now suppresses it during MID transitions while
preserving END and special-weapon behavior. The original mismatch began after
3,371,675 matching records with an extra Plasma projectile. With the fix, all
MID state and clocks match, followed by READY and subsequent gameplay. The
existing synchronous MID/END virtual-clock/card regression also passes on Intel.
The paired fixtures now drive subsequent A→B READY through production methods
and observe its music-service calls; unsupported later flow phases still assert.
Full paired traces/hashes are retained in internal FOLLOW1_READY_VERIFIED.json.
This is bounded route equivalence, not proof of the full ordinary campaign.

The continuous scenery-fallback route matches all 6,706,802 original G5 records,
including exactly 20,000 observations after 1B→2A, actual READY into 2B, and the
alive endpoint x8573/HP60/lives0. Terminal RNG is 106b8fa8 and clocks are
6879048/6878675/6879143. Only G/E/R/S diagnostic annotation ticks are normalized.
`ASTRO_WORLD_BOSS_AVOID_FALLBACK` retries the input pilot's corridor selection
against scenery alone when enemies leave no conservative safe candidate. It
changes test inputs, not collision rules or health. The initial 1B remains a
controlled HP30000/Laser4 setup; no test health refills occur after stage load.
This verifies the bounded route, not a 2B victory or full ordinary campaign.
Complete paired traces and hashes: internal FOLLOW1_FALLBACK_VERIFIED.json.

## Authorized correction: death during a midlevel transition (2026-10-30)

The G5 original crashes on a NULL player rectangle read at original code offset 0x4ea80 when the player dies during scripted midlevel movement. The port previously remained in the nested transition loop. The user explicitly approved safe respawn with remaining lives, otherwise Game Over. This is an intentional difference from the original crash.

The transition now returns to the existing death dispatcher and clears scripted controls when death is pending. Its pending destination survives respawn. On the Intel iMac, `mid_virtual_clock_host_test.m` passed both injected-death cases: one remaining life is consumed, the player respawns at 100 HP, and the transition reaches the next half READY; zero lives dispatches Game Over. Existing synchronous MID/END clock and ending checks also passed. This test intercepts Game Over dispatch; it does not verify that panel visually or prove a full campaign playthrough.

## Continuous route through late level 2 (2026-10-30)

A scenery-only 100-pixel lookahead fallback lets the input pilot pass the corridor where both 180-pixel searches found no safe choice. Original G5 and production-host Intel traces match all 9,675,872 records across 29,000 observations after the controlled initial boss victory, through level 2 and damage to its boss. Only G/E/R/S annotation ticks are normalized. The native FOLLOW watchdog is 20 minutes because the previous 10-minute run was terminated by SIGALRM; its retained partial trace matched until truncation. Full traces and hashes: internal FOLLOW1_NEAR29_VERIFIED.json.

This does not prove the ordinary initial level, victory over the second boss, the next level transition, or the complete campaign. Subsequent transition observer changes remain pending separately.

## Continuous victory and transition to level 3 (2026-10-30)

All 9,877,555 records match the G5 original through the second boss victory, END card, actual level 3 load, and early level 3 gameplay. FOLLOW is 30,000; the comparator also counts the END summary K row, yielding 30,001 post-load K rows. Only G/E/R/S annotation ticks are normalized. Full traces and hashes are in internal FOLLOW1_NEXT3_VERIFIED.json.

The subsequent END observer preserves old entity identifiers during card polling and resets them when stage loading begins. Native observers track the next stage and resume music snapshots across later transitions. An initial test-only premature ID reset caused five differing rows; moving that reset to loading resolves the entire comparison without changing production logic or reference records. This still starts from a controlled first-boss fixture and does not prove an ordinary full campaign.

## Continuous early level 3 death route (2026-10-30)

The extended FOLLOW36000 run matches all 10,031,483 G5 original records through early level 3 death, respawn and natural Game Over (30,524 post-load observations). Only G/E/R/S annotation ticks are normalized. Full traces and SHA256 are recorded in internal FOLLOW1_LEVEL3_VERIFIED.json. This extends the controlled first-boss route; it does not prove completion of level 3 or an ordinary campaign start. Optional predictive pilot changes remain unverified separately.

## Continuous predictive-input route into level 3 (2026-10-30)

The complete original G5 and Intel traces match all 10,221,976 records, including 31,179 post-load observations, special ammunition consumption, damage, respawn and natural Game Over in early level 3. Only G/E/R/S diagnostic annotation ticks are normalized. The input pilot predicts enemy/projectile bounds over 16 velocity steps from level 3 and uses the remaining special ammunition at x500; production rules, health and inventory are unchanged. The initial first-boss setup still uses HP30000/weapon43; this does not prove an ordinary campaign start or victory in level 3.

The full native run exited0 with a 30-minute watchdog; its previous 20-minute timeout is retained as incomplete evidence, not a pass. Full comparison and SHA256: internal FOLLOW1_BULLET3_VERIFIED.json. Later near-lookahead, cross-level and beam-route input candidates remain unverified separately.

## Continuous level 3 laser corridor route (2026-11-01)

Complete original G5 and Intel traces match 11,130,022 records, including 34,651 post-load observations. This route survives the first vertical laser corridor, then dies under angled turret beams, respawns and reaches natural Game Over in level 3A. Only G/E/R/S diagnostic annotation ticks are normalized. Full CRC/hash evidence is internal FOLLOW1_BEAMROUTE3_VERIFIED.json; native actual exit was0. The verified test pilot uses shorter hostile lookahead and a bounded level3 crossing/preposition schedule. Production rules are unchanged.

The route still starts at the controlled first boss with HP30000/weapon43; it does not prove ordinary New Game startup or completion of level3. The later turret-route candidate and normal1A bootstrap extension are separate unverified work.

## Actual normal New Game through first gameplay frame (2026-11-01)

`tests/normal_start_host.sh` passes on the authorized Intel iMac against a twice-repeated original G5 STARTNEWGAME trace. All 6,025 compared records match: natural HP100/defaultweapon10/special1/lives1/score0, object state, RNG, game clocks, READY60-tick delay, music switch, and all 3,000 stars at both READY and the first gameplay service boundary. The host enters the broader menu-action boundary; its exactly one upstream Click is explicitly validated and excluded. Only G/E/R/S diagnostic annotation ticks are normalized; all payloads and ND/NK clocks compare exactly. Comparator rejects tested entity/star mutations.

Removed the redundant playMusic1 call from New Game/Continue: original STARTNEWGAME inherits the existing menu track. The actual audio implementation already treats a same-track call as a no-op, so this is not evidence of an audible restart bug. Bootstrap and READY lifecycle regressions pass, including no music-start call during bootstrap. The wrapper uses existing Intel system Python2.7; its comparator also passes on Python3.

This bounded gate uses controlled initial seed/prestate, not physical menu-click timing or an entire ordinary campaign. Longer normal-start play, later levels and final deliverables remain incomplete. The turret-route pilot candidate is separate unverified work.

## 256 consecutive frames after ordinary startup (2026-11-01)

`bash tests/normal_start_host.sh 256` passes on the Intel reference Mac against a repeated original G5 trace: 775,010 records, including 257 complete states of 3,000 stars, all world snapshots and 256 game-clock records. It starts through actual STARTNEWGAME/READY with natural100HP, defaultweapon, one life and one special. Inputs remain released; this proves bounded early1A, not combat-directed ordinary play or level completion. The original one-frame gate still passes unchanged.

The comparator supports plain and gzip traces on Python2.7/3; actual Intel Python2.7 full256 comparison and the complete runner pass. Only the previously documented upstream Click and diagnostic annotation boundary handling apply; payloads are exact. Native capture is tests/normal_start_256_native.tsv.gz.

## Ordinary startup with firing and movement (2026-11-01)

`bash tests/normal_start_host.sh combat` passes on Intel system Python2 against a repeated original G5 trace. The full818,888 records match across256 service boundaries, retaining all subsequent sound events and all star/world payloads. The profile holds ordinary fire and briefly moves upward; it starts with natural100HP/defaultweapon/lives. Positive evidence:255 distinct projectile entities,255 Pellet sounds,1 Bang1 sound, and playerY190→42.979004799180224. HP remains100 throughout: no damage or respawn claim.

Only the established initial Click boundary and diagnostic snapshot ticks are normalized. The test phase bookkeeping now follows native service boundaries for later sound annotations; no payload is filtered. Default native/host first-frame regression passes. Production is unchanged. Service boundaries may include nested lifecycle loops in future longer captures, so they must not automatically be counted as outer gameplay frames.

## Level 3 turret crossing route (2026-11-01)

The complete paired route matches11,100,760 G5/Intel records and34,550 post-load observations through the upper turret encounter, lower-beam damage, death, respawn and natural GameOver. Native actualexit0 and full CRC/hash comparison are recorded internally in FOLLOW1_TURRETROUTE3_VERIFIED.json. Only G/E/R/S diagnostic ticks normalize. The testpilot holds target100 overx4900..5900 and movesright overx5350..5800 in level3; production is unchanged.

This remains a controlled first-boss start, not ordinary campaign or level3 completion. A later lower-target pilot revision and longer ordinary lifecycle tests remain separate pending work.

## Natural ordinary damage, respawn and Game Over entry (2026-11-01)

`bash tests/normal_start_host.sh death` passes on IntelPython2 against a repeated original G5 capture. Starting normally with released inputs causes actual collisions with the unchanged Data1A scenery, without injected damage or inventory. All1,495,130 records match, including495 complete world/star states,1,485,000 star records,494 NK observations and20 sound events. HP first falls to90 at service429 and0 at476; replacement player44 hasHP100/lives0 at479 and becomes active at482. SecondHP0 occurs at492, followed by GameOverentry494. Nested lifecycle observations remain included and are not claimed as outer frames.

The paired fixtures stop at actual GameOver entry before its UI, with explicit terminal reason. The streaming comparator checks every record, ordered full star states, clock-count budget and exact terminal, retaining the documented upstream Click/diagnostic-tick handling only. Mutated star data, HP and terminal reasons were rejected. Native repeat, default6025 and priorcombat818888 regressions pass. A separate normalfire1024 capture also matched3,316,799 records but had no player damage.

This proves the bounded natural lifecycle, not GameOver UI, a complete first level or the full ordinary campaign. Production is unchanged.

## Menu coverage reconciliation (2026-11-01)

The current Intel tree passes `menu_setup_host.sh`, `menu_handle_host.sh` and
`menu_moving_host.sh` against their unchanged native references: nine complete
menu reload profiles, six root-handler profiles and18 moving-pointer routes
(33675 records,507 frames and6084000 IEEE star words). This supersedes the older
blanket statements above that factory deadlines, normal-menu handling and all
moving-pointer integration were unproved. It does not extend these gates to
arbitrary mixed input, the complete Main/Root event loop, or Game Over UI.
Only the coverage documentation changed; production and reference data did not.

## Actual Root replay of Main scheduling, including idle events (2026-11-01)

`bash tests/main_queue_host.sh` compares the real Root `pollMainMenu`/`pollMenu` and field consumers to actual PPC Main traces: 108 generated-event profiles (11,058 records) and 432 finite-FIFO/idle profiles (41,572 records). Every clock, frame, event, terminal field/counter and idle deadline record compares exactly. The idle matrix covers expired/future deadlines and both signed32 extremes; the native capture was repeated identically. Existing generated and historical zero-initialized mixed traces were preserved. The new idle reference initializes the original runtime's 60-tick timer.

This exposed a missing production branch: an empty periodic OS event still executes original `FBNULLEVENTS`, sampling its timer and a second reset clock when the signed deadline has expired. Root now preserves that behavior and initializes its timer before game asset setup. Actual original v3 G5 startup snapshots confirm interval60/callback0 and the same initial deadline before game initialization, after assets, and at the first Main key-map call. Static anchors are `INITRUNTIME`0x1001b06c, `FBHANDLEEVENTS`0x10024064 and `FBNULLEVENTS`0x10023424.

Full Intel registration-input, bootstrap, and normal first-gameplay (6,025 records) regressions pass. Frame rendering, audio and OS event/time sources are controlled observers in this Main gate; it does not prove physical event delivery, every window/dialog callback, complete UI rendering or the whole campaign. Evidence and original startup transcript: internal `fidelity-audit/main-root-20261101/`.

## Linked targets during nested specials (2026-11-01)

`active_special_world_host.sh` now passes18 original/Intel scenarios, adding
controlled linked-target cases for plasma40 and storm51. Their513/1687 complete
canonical records and127003/127050 clock reads match; both native captures
repeat exactly. Target2 retains parent1 through64 snapshots, inherits its
velocity during nested calculations, and moves from(350,190) to
(412.71603086767584,164.3434419177689). Storm damage reduces itsHP30000 to29654.
The original cleanup/CALC/special/LM and outer return remain active.

The host fixture now explicitly seeds the same world bounds as the native
fixture, correcting an initial-only worldRight0 versus640 mismatch caused by
reliance on an old initialization side effect. Production is unchanged.
The established two native HUD observer records are outside this presentation
boundary; every other canonical record and every clock value is compared.
This proves controlled surviving-target parent inheritance during specials,
not campaign creation of links, a parent on the firing actor, or deleted-parent
behavior. Full fidelity remains incomplete outside the verified scopes.

### GameOver real overlay and pointer composition (2026-11-01)

`bash tests/gameover_held_host.sh` retains the three legacy held-input goldens and
also compares all 2,570 rows from six native GameOver composites. Each uses the
actual Data B1 factory and 60-tick ready state, real overlay/field/caret, hover,
DOMOUSE, sprite changes and animation. Intervals 1/2/3 cover both continued held
input and release/repress followed by moving onto and away from OK. A/B/Enter
passes through the actual event queue. Every clock boundary, field/latch/end
state, Click pan, complete node geometry and two terminal draws is compared.
Two G5 captures are byte-identical and the Intel trace matches without filtering.
World/HUD drawing, sound playback and score persistence remain observers; this
is not a whole-world, physical input or pixel identity claim.

This exposed a renderer ordering difference: original DRAWMYEDITFIELD toggles
caret visibility before its second TickCount, then assigns reset+20. The renderer
now preserves that intermediate state as well as its final state. The portable
caret helper checks final values but cannot establish callback ordering. Existing
field draw, registration draw (810 profiles), GameOver draw and 4,225 caret
vectors pass. The legacy host fixture now sends separate A/B events, matching
the unchanged native sequence instead of a synthetic two-character key event.

### Retained world, HUD and real GameOver overlay coupling (2026-11-01)

`bash tests/gameover_world_overlay_host.sh` compares two continuous 8B death,
respawn, last-death and GameOver routes, including ten warm world updates,
60-frame panel transition, real score input, two terminal draws, score insertion
and panel cleanup. Both retain actual world and HUD logic while running the real
overlay, field/caret and hover together. One pointer stays in the field; the other
moves over OK during A/B/left/C/Enter input. All 31,168 canonical records per route
match on G5/Intel, and both native captures repeat byte-identically.

The comparison retains all world records, seven overlay field/clock checkpoints,
all UI node geometry/type/deadline/counter records at each overlay and lifecycle
boundary, and all ten score-table entries. The existing shared-list mapping
accounts for native UI nodes sharing the world allocator; only diagnostic
G/E/R/S tick annotations are normalized. Physical input, OS window dispatch,
actual score-file persistence, audio output and pixel identity remain outside
this gate. No production change was needed. The optional overlay flag and
capture binary name preserve existing arena and normal-pilot defaults.

### Ordinary 1A through the first loaded 1B state (2026-11-01)

The complete original G5/Intel route matches **34,712,025 records**, with zero
differences through EOF: 10,751 complete world/star states, 32,253,000 star
records, 10,749 music-service observations, 8,481 sound events, six music events
and two READY boundaries. It runs actual STARTNEWGAME, ordinary 1A with genuine
pickups and use of the starting special, MIDLEVEL, second READY, LOADLEVEL and
the first post-load 1B state (`NT stage1B`). Input, initial seed/prestate and OS
observers remain controlled; no health or equipment is injected. This proves the
1A route and entry into 1B, not the remainder of 1B or the full campaign.

Two native-observer setup gaps were corrected: the menu music token/play1 event,
and per-map renderer identity numbering at LOAD after asserting that the old
entity/render lists are empty. Entity identities remain continuous. No production
code or comparison payload filtering changed; the established upstream Click and
diagnostic tick handling remains. The unchanged 6,025-record native startup
regression also passes. Full paired evidence is retained internally under
`fidelity-audit/normal-keepbolt-20261101/`.

### Ordinary play through natural Game Over in 1B (2026-11-01)

The same normal-inventory route was continued on original G5 and Intel through
1B to natural Game Over. The completed gzip traces match all **48,915,780
records** through EOF with zero differences: 15,089 complete world states,
45,267,000 star records, 15,087 music-service checkpoints and 12,742 sounds.
This includes actual damage, pickups, deaths and respawns after the second
READY. The host fixture had previously suppressed held fire during READY→PLAY;
it now reads the scripted game keys at that transition, matching the original's
two immediate Pellet shots. Production gameplay code did not change. Only the
established upstream Click and G/E/R/S diagnostic tick annotations are
normalized. Full paired evidence is retained under
`fidelity-audit/normal-post1b-20261101/`. This is one ordinary input route
ending in 1B, not a full-campaign victory or proof for every input sequence.

### Sound channel allocation (2026-11-01)

An isolated G5 probe called the original `GETAFREECHANNEL` with all 64 busy/free
combinations of its six channels. All 190 ordered records show a scan from
channel 1 upward, returning the first free index or zero when all six are busy;
a second native run was byte-identical. The Intel adapter removes completed
voices, permits six concurrent cues and drops a seventh. This verifies its
capacity rule, not exact Sound Manager channel identity or pause/completion
scheduling. Probe source, native trace and validation are retained internally
under `fidelity-audit/sound-slot-20261101/`.

The original Pause entry calls `SOUNDPLAY` once with the Pascal cue `Menu` in
each of 16 existing native schedules. An extended G5 probe preserved all 709
prior pause-trace rows and added the same four cue bytes in every case; its
repeat was byte-identical. The production Pause entry requests `Menu` before
showing its panel. This checks cue identity and call count, not audio device
timing or lifetime of voices while paused. Evidence is retained under
`fidelity-audit/pause-cue-20261101/`.

### Ordinary first-stage pickups, damage and Game Over (2026-11-01)

A normal New Game input route with the original inventory and no injected stats was
run to its natural Game Over on both G5 and Intel. Complete captures compare through
EOF: 28,176,361 records, zero differences (8,455 world states, 25,365,000 star
records, 8,454 music-service checkpoints and 7,470 sound records). The trace covers
the actual shield, weapon upgrades, spent special, later Bolt-to-Pellet pickup,
damage, death and respawn. It stops in 1A before a stage transition; this is
evidence for that route only. Full captures and streaming comparison result are
retained under internal `fidelity-audit/normal-pickups-20261101/`.

### Second ordinary 1A to Game Over in 1B route (2026-11-01)

The G5 original and Intel port both ran New Game with normal 100 HP, inventory,
spawns, pickups, damage, death and respawn to natural Game Over in 1B. This
alternate input route suppresses seeking pickups at 1B x=1100..1800 and targets
y=275 at 1B x=4050..4650; it changes no game rule or starting resource.
Complete traces match all 51,779,097 records through EOF after normalizing
only diagnostic G/E/R/S clock annotations. The Intel input fixture now emits
no vertical direction while the player is absent during respawn; otherwise its
pilot moved the newly created player one frame earlier than the G5 input path.
The original and final host archives passed gzip CRC checks. The full traces,
source copies and comparator result are retained in the internal
`fidelity-audit/normal1b-gap2-pair-20261101/` evidence directory and on the
authorized test machines. This verifies this ordinary route through Game Over,
not a complete ordinary-health campaign victory.

### Ordinary startup at 30 and 20 FPS (2026-11-01)

The original G5 and Intel port were each run from New Game through READY and
256 game music-service boundaries with frame interval 2 (30 FPS) and 3 (20 FPS).
For each interval, complete captures match 775,010 records through EOF with
zero differences, including 257 world snapshots, 771,000 star records, actors,
render nodes and clocks. Only the usual G/E/R/S diagnostic tick annotations
are normalized. The two native captures themselves differ from the first game
render record, so both frame settings were exercised. The optional
`ASTRO_WORLD_FRAME_INTERVAL` harness input allows either setting without
changing the normal default. Full captures, exact comparator results and
probe source are retained under internal `fidelity-audit/normal-fps-20261101/`.
This verifies the first 256 no-input service boundaries after ordinary startup;
combat, later stages and preference-file loading at those FPS values remain
outside this check.

### Ordinary startup combat at 30 and 20 FPS (2026-11-01)

The same 256-service New Game pairs were repeated with ordinary fire and the
initial upward movement input. At 30 FPS, all 818,888 records match; at 20 FPS,
all 818,886 records match. Both comparisons reach EOF with zero differences and
both pairs passed gzip CRC. They include 256 sound events and the actual
projectile, player-motion, render, world and star records. The different record
counts show that frame settings affect the recorded world. Full captures and
comparison results are in internal `fidelity-audit/normal-fps-20261101/`.
This verifies these early combat routes, not later combat or a complete campaign.

### Full ordinary 30 FPS route to Game Over in 1B (2026-11-01)

The original G5 and Intel port ran the same ordinary New Game route at frame
interval 2 (30 FPS), with normal health, inventory, combat, pickups, deaths and
respawns. Both ended naturally at Game Over in 1B with the same final clock
tuple 3796354/3796453/3796406. Complete captures compare through EOF:
48,923,105 records, zero differences after normalizing only diagnostic G/E/R/S
tick annotations. Both gzip archives passed CRC; the complete original archive
also matches the G5 source MD5 after an interrupted transfer was resumed.
The comparison result and original archive are retained under internal
`fidelity-audit/normal-fps-20261101/`. This verifies this complete route to
Game Over at 30 FPS, not an ordinary-health campaign victory or every input.
