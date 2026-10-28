# PICT payload encoder and native reference

src/picture.c implements the PICT payload needed by the original screenshot
operation. It is not yet connected to the application. It emits extended PICT2,
DirectBitsRgn, zero-alpha32-bit planar ARGB and QuickDraw-compatible PackBits.
Input is top-to-bottom RGB; output excludes SAVEPICTFILE's512-byte file prefix.
Dimensions are bounded to1..640 by1..480, with stride/overflow/allocation checks.
The picture-size word retains the original16-bit truncation for large payloads.

## Independent native capture

Run tools/ppc_picture_oracle.c only on G5, compiling with the existing
ppc_keymap_oracle.c, ppc_bridge.h and imports.h dependencies:

```
gcc -std=gnu99 -O2 -I analysis/script-oracle tools/ppc_picture_oracle.c \
 -framework Carbon -o picture_oracle
./picture_oracle original.pef original.literals.bin 640 480 1 output.pict
```

The oracle executes original GETPICT_100139dc in a private loaded PEF. A private
32-bit offscreen GWorld supplies known pixels. It opens no window and captures
no user desktop. Original files/live game are untouched. Size guards verify
PEF455780/literals11812; a15-second alarm bounds unexpected behavior. Source
identity is MD5 b93ca67a59bbc3cbcad434402bfa7bca / da53d77004bb595663b57f260f7776c7.
Patterns are black0, RGB affine(x,y)1 and red2, as in the C source.

Ten captures cover1x3,2x2black/color,9x3,62x2,63x2,128x2,129x2 and640x480black/color.
They check the raw-row exception below8 bytes, one/two-byte row-count boundary,
128-byte runs/literals, odd-width/padding and large picture length. The initial
seven pictures were repeated byte-identically; three additional narrow/prefix
boundary cases were then captured. A final size-checked native build reproduced
the full-color payload after address normalization. Native captures are retained
compressed in tests/picture_native/*.pict.gz.

Two on-disk words at offsets98/102 are the actual source PixMap.pmTable/pmExt
handles: the oracle prints them and they match the recorded words. The encoder
writes zero instead of serializing process-local addresses. The [Apple PixMap
reference](https://developer.apple.com/documentation/applicationservices/pixmap)
identifies these as a color-table handle and extension pointer. The observed
G5 payload has four components even though the generic reference describes
three for ordinary RGB. Runtime evidence governs this encoder's format.

## Checks

```
cc -std=c99 -O2 tests/picture_test.c src/picture.c -o build/picture_test
python3 tests/picture_native_test.py build/picture_test
./test.sh --native-only
```

The comparison driver supports system Python2.7 as well as Python3. Every payload
byte matches all ten native pictures after zeroing only those two handle fields.
The codec passed primary pure-C ASan/UBSan checks and actual Intel compilation/
replay. No GUI/image runtime was executed on the primary Mac.

The generated payloads were independently decoded on G5 using native DrawPicture
in tools/ppc_picture_decode.c; every RGB pixel matched the known source patterns
for all ten pictures, including both640x480 captures. This verifies the zeroed
handle fields remain decodable. Alpha in the decoded destination is not asserted.

## Remaining screenshot integration

LMTAKESCREENSHOT1003e208 captures Rect0,0,640,480, then calls GETPICT_,
SAVEPICTFILE1003dfc4 and DisposeHandle. Static SAVEPICTFILE reads STR#25000:
Screenshots / PICT???? / Screen / .pict. It writes512 bytes then the picture.
Filename is Screen + STR$(TIMER) + .pict: STR1000459c prepends an ASCII space to
nonnegative numbers; TIMER10003f28 uses GetDateTime modulo86400 with signed-wrap
handling. Folder base SYSTEM(1), exact header contents/file-open collision/error
semantics and actual native save execution still need verification.

Debug flag ede is distinct from preview visualDebug (held down-arrow). LMINITMINI
10037ec4 checks BitTst48 at startup, corresponding to physical leftCommand55;
GETKEYMAP later uses keypad-multiply67 when that flag equals1. The startup path
has been inspected as code, not captured as a complete native LM initialization.

Do not wire an arbitrary PNG/save panel or a redraw of current simulation state.
The actual current QuickDraw port/OpenGL front-buffer relationship, clipping,
window scaling and presented-frame identity are not established by this offscreen
probe. File prefix, timestamp/folder/Finder type/creator, null-picture/error paths,
startup activation and actual host capture/save remain unfinished. No screenshot
feature or whole-game equivalence is claimed by this codec milestone.

## SAVEPICTFILE boundary reference

`ppc_picture_save_oracle.c` executes original SAVEPICTFILE1003dfc4 privately
on G5, using the same PEF/literals plus original STR#25000 (6884 bytes).
All filesystem calls are observers: no screenshot directory/file is created.
The native timer, numeric formatting, concatenation and metadata setup remain
original code. Seven UInt32 Mac-time boundary cases repeat identically; a null
picture produces only the original error message. Fixture: tests/picture_save_native.csv.

Names are `Screen <unsigned seconds modulo 86400>.pict`. Writes are exactly
512 zero bytes, then the picture handle contents, followed by close. Open
metadata is type PICT and creator ????. Static FBOPENFILE1000ec84 with flags
0x302 attempts creation, opens the data fork, sets metadata, truncates to zero
and seeks to the start. FBSETFILETYPE1000e43c passes both words unchanged to
PBHSetFInfoSync. Actual filesystem errors, collision behavior and resulting
Finder metadata have not been dynamically verified.

`astro_picture_filename` and `astro_picture_file_encode` implement the verified
name and byte layout; tests/picture_file_test.c replays the native fixture.
Strict C and ASan/UBSan pass on the primary Mac; strict C passes on Intel iMac.
The payload regression still matches all ten original captures. These helpers
remain disconnected from the application: current-port/GL capture and legacy
working-directory mapping need evidence before integration.

## Owned AGL window: offscreen codec is NOT a window replacement

`ppc_picture_gl_oracle.c` runs on G5 only. Build like the capture oracle, adding
-framework AGL -framework OpenGL. Arguments are original PEF and literals.
It creates its own 640x480 Carbon document window, paints QuickDraw blue,
executes original GETPICT_, draws red through AGL using original
LMSETUPAGLDRAWABLE100363dc attributes (4,5,73,50,32,0), swaps, validates GL_FRONT
red, and calls original GETPICT_ again. Both pictures are decoded into an owned
GWorld and all307200 RGB pixels are compared. No user desktop/window is captured.

Two final native runs pass: GL_FRONT255/0/0, captured306975blue,225other,0red,
0black,0changed RGB pixels versus before GL. The225other pixels are also identical
between captures; none retains the decoder's0x55 fill. Their cause was not proved.
Window payload1228944 bytes has DirectBitsRgn,packType1,cmpCount3, unlike the
offscreen packType4/cmpCount4 fixtures. Original serialized state also includes
QuickDraw foreground color and finite clip. The existing offscreen encoder
must NOT be presented as byte-identical to this window path. A glReadPixels
replacement would capture different pixels on this tested platform.

Scope: owned Carbon document window on G5/Tiger, not the original full game
window or fullscreen DrawSprocket/AGL path, not Intel/AppKit. Original window
style/current-port initialization and fullscreen semantics remain unresolved.
The tool deliberately asserts this calibrated G5 result and disposes its own
window/context on success. It does not install hooks or modify original files.

## Original window constructor and calibrated window codec

`ppc_picture_window_oracle.c` invokes actual _FBWINDOW10026040 with
(id1, owned title,80/80/560/720 rect,style5,0,0) using a private six-argument
FB bridge. Runtime window/style/clip tables and string heap are empty owned
allocations; system version/font defaults are seeded as FBCOREINIT does.
No window constructor or _CLS callback is replaced. The original maps style5
to NewCWindow proc4, sets its port, calls _CLS1002b460 and restores clipping.
Native assertions confirm owned current port, black foreground, white background
and rectangular0/0/480/640 clip. Position is explicit rather than original
centered zero-origin input; full LMINITMINI and fullscreen are outside this probe.

Build as the AGL oracle. Arguments: original.pef original.literals.bin output.pict.
Original GETPICT_ before/after red AGL front yields307200 white pixels, zero
changed pixels,1228936-byte PICT. Two initial captures are byte-identical, and
the final color/clip-guarded build reproduces those bytes exactly. Retained
compressed reference: tests/picture_native/window-white.pict.gz.

`astro_picture_window_encode` emits this default window format: finite full
clip, black foreground, DirectBitsRgn packType1/cmpCount3 with interleaved
FF/R/G/B bytes and no row length prefix. It shares bounds, allocation and header
logic with the offscreen encoder. All11 fixtures match on primary strict C,
ASan/UBSan and Intel strict C after only pmTable/pmExt zeroing; original file
metadata/prefix regression passes on primary/Intel. Generated640x480 white
payload is independently decoded pixel-for-pixel by G5 QuickDraw. No arbitrary
colored window reference yet; no application integration or full-suite rerun.
The file helper still uses the offscreen encoder until a capture caller exists.
The app must capture default QuickDraw content rather than redraw/GL-readback;
full original startup/current-port lifecycle, save folder/error semantics and
fullscreen remain open.

## Colored window and actual filesystem reference

Window oracle accepts optional `bars`: eight80-pixel vertical RGB bitmask
bands drawn through QuickDraw, foreground restored to black. Both native
pre/post AGL pictures decode to exactly the expected colors at every pixel.
Counts:38400 each red/blue/black/white and153600 remaining colors, zero changed
RGB pixels after red AGL swap. Two raw captures are byte-identical; fixture
window-bars.pict.gz. All12 PICT fixtures match on primary strict C, ASan/UBSan,
and Intel strict C/Python2.7. G5 QuickDraw independently decodes generated bars
correctly at every RGB pixel. Existing window encoder required no changes.

`ppc_picture_file_oracle.c` executes actual SAVEPICTFILE plus SYSTEM/FOLDER/open/
write/close; only GetDateTime (123), STR#25000 resource source and debug message
sink are controlled. Runtime file table is empty; FBPBTOFBWD10000458 registers
an owned scratch FSRef's volume/nodeID and seeds SYSTEM1 runtime base. The path
is constrained to /tmp/astrosquid-window-bars-20261028/io-v4, which must not exist.
Arguments: PEF,literals,6884-byte STR#25000,that exact base path. Compile with
Carbon and script-oracle imports, as other private PPC probes. No window or
original game is patched; all real writes stay below the owned directory.

Original creates Screenshots/Screen123.pict (with a space before123), writes
512zeros then16'A' bytes; second same-time save truncates to512+4'B' bytes.
Actual FSGetCatalogInfo verifies PICT/???? metadata. Runtime error vector is
absent in this isolated setup. Making the file0444 makes the native unguarded
write dereference null fileblock+0x192. GDB observed EXC_BAD_ACCESS at private
code+0xfe08 (original0x1000fe08 in WRITEFILE), address0x192. Final probe isolates
that call in forked child, disables its core dumps, asserts SIGBUS and unchanged
file, then restores0600. Success path prints two original success messages.
This proves this private runtime's failure path; full app error-vector behavior
is not proved, and undefined null dereference must not be copied into defined
logic. No app screenshot integration, full startup base-folder mapping or
fullscreen proof is claimed.

## Startup key prefix and directory provenance

`ppc_startup_keys_oracle.c` invokes original LMINITMINI10037ec4 with controlled
GetKeys, replacing SYSTEM10024450 by a longjmp boundary that requires selector8.
It stops before any UI/audio initialization. All original key/BitTst/flag-store
instructions before that boundary execute. It tests130 snapshots (none, each
physical key0..127, leftCmd+leftOption) against debug initial0/1/2 and fullscreen
initial0/1:780 cases. Each consumes one GetKeys and one SYSTEM8 boundary;
leftCommand55 stores debug1, leftOption58 stores fullscreen0, otherwise flags
preserve their supplied initial values. The platform flag ee2 is cleared before
SYSTEM8. Native G5 optimized run PASS. This proves a prefix, not the full startup
or subsequent debug-file setup and renderer selection. Existing GETKEYMAP
reference separately proves held keypad multiply invokes capture on every poll
only when debug equals1.

Static directory provenance: _INITRUNTIME1001b06c calls GETVOL10000688 and stores
the returned virtual working-directory reference at g+23e. GETVOL calls
PBHGetVolSync then FBPBTOFBWD10000458; SYSTEM1 returns that saved reference.
_FOLDER may change the default volume, so later current working-directory reads
cannot replace this retained startup base. Do not assume POSIX cwd, bundle
Resources, executable parent or Downloads without launch-context evidence.
The original LaunchServices/CFM startup directory mapping remains unresolved.

## Version3 CFM launch directory

An owned executable copy was made on G5 from the old reference only to preserve
APPL Finder metadata; its data fork and resource fork were replaced by the
selected download3 AstroSquid.stub.pef (2510 bytes) and AstroSquid.rsrc
(7328466 bytes). MD5 of source and installed resource fork both
7a8ea3807ca1a6f52d2a5ce984ebb8de. The old reference was unchanged. No Data folder
was copied; the debugger intentionally stops before normal gameplay.

Run LaunchCFMApp under G5 native GDB using tools/ppc_launch_directory.gdb and
this owned path /tmp/astrosquid-launch-dir-20261028/AstroSquid. GDB6.3 requires
`set breakpoint pending on` before `break PBHGetVolSync`, because Carbon loads
after launch; use -batch -x commandfile, not -ex. An initial attempt without
pending breakpoints failed to stop and reached an EXC_BAD_ACCESS; it did not
prove any directory result. Corrected runs stop at the imported function and
finish only that call, reading PB volume at22 and directoryID at48.

Observed two calls: first stack is GETVOL -> FBGETVOLREF -> FBCOREINIT; second
is GETVOL -> INITRUNTIME (the saved g23e source). Both return volume-100 and
directory612671. Read-only tools/carbon_directory_probe.c independently maps
the owned executable parent to that volume/node. A separate owned `othercwd`
node612688 was the POSIX working directory for the second launch; both Carbon
reads still return executable-parent612671. Initial launch from executable
parent also returned612671. This establishes CFM-loader direct-launch behavior
on G5/Tiger, and the saved original screenshot base is the executable parent
in those tests. It does not prove Finder/LaunchServices, alternate launchers,
other OS versions or an NSApplication bundle's automatic Carbon default folder.
Do not replace the original saved startup reference with a later current folder.

GDB quits/kills the owned inferior after the second read. No completed UI/game/
audio initialization, original live process patch, or original on-disk change
is part of this successful test. Temporary copied executable/resources and
directory helper binary are removed after evidence is recorded.

## Full original menu capture after asset initialization

`ppc_full_window_capture.gdb` and debugger-only `ppc_capture_reference.c` close
the current-port lifetime gap for the original windowed menu. Prepare an owned
/tmp/astrosquid-full-port-20261028/AstroSquid with selected download3 stub/rsrc
forks as above. Copy Data from the preserved G5 reference into that owned
directory (these auxiliary Data files were not independently matched to v3;
textures/program resources use selected v3 rsrc). Build capture.dylib with
gcc -std=gnu99 -O2 -dynamiclib ppc_capture_reference.c -framework Carbon.
The hook also needs ppc_bridge.h. Run native GDB -batch -x the commandfile
against LaunchCFMApp. It modifies only the owned inferior's test input state.

The first GETKEYMAP is DOFIRSTRUNCHECK before GETPREFS/INITSAGAIA; its screen
port does NOT prove a game-window capture. Main FUN10066c40 sets fullscreen1
before that call, overriding the earlier engine thunk's fullscreen0 default.
Therefore normal game startup defaults fullscreen, an outstanding host gap.
The successful window test sets ee0=0 at INITSAGAIA entry (controlled window
case). Original LMINITMINI, all107 map loads, sound/music setup, attribute loads
and intro rendering execute. The intro waits for a key: after original keymap
returns at65f2c, set ab6=1 for one controlled any-key transition. Stop at
MainLoop returnsite66cf0, disable the intro keymap-return breakpoint, then stop
at the menu's GETKEYMAP (caller return66e7c). Explicit address boundaries avoid
GDB `finish` on untyped PEF functions, which waited indefinitely in the intro
in an earlier attempt; only native PBHGetVolSync uses finish.

Observed menu current port equals owned window1 port; bounds0/0/480/640,
foregroundblack/backgroundwhite, fullscreen0/debug0. The dylib checks current
port equals the supplied window's port and bounds640x480, refusing desktop
ports. It calls actual GETPICT_139dc with current original globals/TOC via the
FB bridge and writes only the fixed owned window.pict. Two native launches
return0 and1228936-byte payloads; each matches existing window-white.pict.gz
after only pmTable/pmExt address zeroing. Canonical SHA256:
ac9321d7766f17cee0df3813d45da9556639c9f5799e1c58c018ada89df800ea.
No duplicate fixture is retained. GDB kills owned inferior without CLOSEDOWN
or SAVEPREFS; no settings are intentionally written. No original files/live
original process are patched. Fullscreen capture, in-game later port changes,
Finder launch and full gameplay equivalence remain unproved. Primary/Intel
app runtime is unchanged; this is original G5 evidence only.

## Production windowed screenshot integration

preview.m now samples startup leftCommand55 once into a separate engineDebug
flag. Each readKeyMap poll with physical67 held invokes saveScreenshot, after
the existing quit latch. It uses the verified white window backing and window
encoder,512zero prefix, PICT/???? Finder attributes, local Macseconds modulo
86400 and direct same-name truncation. The base is frozen from app-bundle parent
at initialization, an explicit Cocoa mapping of the observed CFM executable
parent. No PNG/readback/redraw or dialog is substituted. Failures return safely
instead of reproducing the original undefined null-fileblock dereference.

GetDateTime is unavailable in the modern64-bit SDK; portable equivalent is
floor(CFAbsoluteTime + kCFAbsoluteTimeIntervalSince1904 + systemGMTOffset),
then UInt32 wrap. Native tools/carbon_clock_probe.c confirms original
GetDateTime delta equals systemoffset7200 on G5 and10800 on Intel i386, within
one second tolerance. No timezone/clock was changed.

tests/picture_host.sh runs on Intel only. Actual AstroView subclass initialization
checks rightCommand/noCommand disabled and leftCommand enabled; raw polling
checks held67 repeats,68 exclusion, disabled gate and simultaneous CmdQ. Real
save checks full native fixture+prefix, Finder metadata, repeat-name truncation,
readonly preservation and blocked-folder failure. All PASS. Existing128keymap
and quit lifecycle native/host projections PASS. Primary and Intel app build
PASS; shellsyntax/diff checks PASS. App-wide rendered selftest/full native suite
not rerun this milestone. build.sh and both coupled host build scripts link
picture.c. Fullscreen startup/capture, later in-game QuickDraw port changes and
other engineDebug effects/logging still need separate evidence/integration.

## Native fullscreen selection policy

ppc_fullscreen_policy_oracle.c executes original LMSETUPAGLFULLSCREEN36898
and LMTRYFULLSCREENHZ367a4 in a private PEF. AGL imports are observers only:
no display/context/window is actually changed. Original strings/formatting and
loop remain intact; debug message sink is replaced. Eight cases cover success
at200/199/60/56, all-fail, current-context failure, format failure and context
failure. Native G5 PASS: attempts descend200..56 inclusive (145 maximum), stop
after first success; pixel format attributes exactly4,5,73,54,50,32,0; dimensions
640x480/device0. Format is destroyed whenever chosen, even context failure.
An allocated context is returned even if fullscreen/current selection fails;
global e8a is zero unless both succeed. Callers must use e8a for fallback.
This is policy evidence, not actual display switching/restoration proof.
LMEXIT38ecc statically kills maps/list then deactivates AGL and disposes DSp
when present; cleanup execution and native fallback remain next.

## Native graphics shutdown ordering

ppc_fullscreen_exit_oracle.c executes original LMEXIT38ecc plus original
LMDEACTIVATEAGLCONTEXT36db4 and LMDISPOSEDSP36328. Map/list destruction and
graphics imports are observers, so no real graphics/display state changes.
Original resource formatting,107-loop and shutdown branches remain intact.
Eight G5 cases cross AGL context0/nonzero,DSp0/nonzero and API success/failure.
All PASS: map callbacks0..106 (including empty entries), list callback,
aglSetCurrentContext(NULL),aglSetDrawable(context,NULL),aglDestroyContext(context),
then only when DSp nonzero SetState(dsp,2),Release(dsp),Shutdown. Exact111 or114
ordered events per case. Graphics API errors are ignored and do not skip later
cleanup; original e8a/e8e globals retain their supplied values. The observer
does not prove actual resource destruction, hardware mode restoration or safe
repeated cleanup. Native fallback and real display lifecycle still need proof.

## Native startup fallback branch prefix

ppc_fullscreen_fallback_oracle.c executes LMINITMINI37ec4 through its final
context load38240, stopping before fatal handling or GL initialization. Setup
AGL/DSp/drawable/window calls are observers; no screen or window is changed.
Original input,version gate,strings,branches,rectangle setup and offset copy
remain active. Nine native G5 cases PASS: requested window, AGL success, AGL
failure->DSp success, both fail->window, classic version skips AGL, classic DSp
failure->window, failed DSp drawable, failed window drawable and leftOption.
SYSTEM8>=1000 tries AGL first; lower version starts DSp. Setup AGL return9999
is deliberately ignored while its global active context decides fallback.
DSp front port rect12/34/492/674 yields original x/y offsets34/12. On DSp
drawable failure, fullscreen remains1 and context0; no window fallback occurs,
and the following original context check selects fatal handling (not executed
by this prefix probe). Window creation uses id1/style5/rect0/0/480/640 and
WINDOW31 returns its port before drawable setup. All cases consume one GetKeys.
This establishes branch policy; actual AGL/DSp/backend availability, hardware
restoration, fatal UI and modern-host implementation remain outside proof.

## Real G5 fullscreen and restoration

`ppc_fullscreen_live_probe.c` runs only on authorized G5/Tiger, linked Carbon,
AGL, OpenGL and DrawSprocket. Original PEF/literals/STR#25000 arguments are the
same as policy probes; optional --dsp selects actual original DrawSprocket path.
A parent copies the initial CGDisplay mode dictionary; an exec child has12sec
alarm, parent15sec watchdog and recovery to the saved mode if necessary.
The parent reports native_restore separately from final_restore; recovery is
a failure of the native-restoration check. No settings or clock changes.

Direct original LMSETUPAGLFULLSCREEN fails on this G5 at pixel-format selection:
formatNULL,context0,no frequency attempts,AGL error0. Final tool exits4 to
report unavailable; original mode1440x900,bpp32,hz0 remains unchanged. This is
not a successful AGL-fullscreen rendering test and is not generalized to all
machines. Returned context and active global are both zero.

Actual original LMFULLSCREENDSP36130 succeeds, obtains front port bounds
0/0/480/640, and original LMSETUPAGLDRAWABLE363dc creates/current-selects real
AGL context. Hardware mode becomes640x480,bpp32,hz0. An owned red clear/swap
followed by GL_FRONT pixel read yields255/0/0. No desktop/QuickDraw screen
pixels are read. Original LMDEACTIVATEAGLCONTEXT36db4 then original
LMDISPOSEDSP36328 restore1440x900,bpp32,hz0 and currentAGLNULL. Two native runs,
including final copied-mode/guarded version, pass with native_restore1 and
final_restore1; watchdog/recovery unused. The real DSp fallback is therefore
necessary on this hardware. This does not establish full original startup,
fullscreen GETPICT pixels, Intel backend behavior or host fullscreen parity.
Temporary inputs/helper executable are removed after recording.

## Actual Intel Cocoa fullscreen prototype

tools/intel_fullscreen_probe.m is standalone, authorized Intel iMac only.
Compile ARC with Cocoa/OpenGL. Default invocation only lists eligible640x480
32-bit CG modes; --run invokes a monitored child that creates its own GL view.
HighSierra SDK NSView.h declares NSFullScreenModeSetting takes a CG display-mode
dictionary. Using that dictionary plus NSFullScreenModeAllScreens:NO switches
via enterFullScreenMode. A separate parent copies original mode, imposes15sec
watchdog on12sec child, and reports native_restore independently from recovery.

Actual Intel mode available640x480/32bpp/hz0. Initial prototype mode switching
and restoration succeeded but front pixel was black, so that attempt failed
rendering verification. Final prototype calls displayIfNeeded,lockFocus,context
update/makeCurrent before drawing, then unlocks focus. Two native final runs
PASS:2048x1152 ->640x480 ->2048x1152, inFullScreenMode1, red255/0/0 in owned
GL_BACK and GL_FRONT, no GL error, native_restore1/final_restore1. No recovery
or watchdog used. No user desktop pixels are read; only own cleared GL surface.
No original preferences modified. Temporary probe/log/build files are cleaned.
Evidence log internal fidelity-audit/intel-fullscreen-prototype.log.

This proves the modern backend primitive on this target, not production game
startup/fullscreen integration, frequency-selection parity on other hardware,
full-game rendering/input or screenshot semantics. Production still defaults
windowed; next wire startupOption58/defaultfull,640x480 window and safe exit
into delegate/view while preserving existing deferred quit lifecycle.

## Production fullscreen integration

preview.m now freezes fullscreenRequested from startup physical leftOption58
(absent means fullscreen), alongside Command55 debug. Delegate creates a fixed
640x480 window, then enters a640x480/32bit CG mode through the verified Cocoa
backend. Unavailable mode/failed entry leaves the window. The target Intel has
one matching hz0 mode; other-hardware frequency choice is not proved equivalent
to original AGL/DSp selection. Surface lockFocus/contextupdate/display follows
entry. Delegate retains game view explicitly because fullscreen moves it out of
the original window's contentView; Quit still uses the deferred lifecycle.

closeDown restores fullscreen before application termination. applicationWillTerminate
also restores it, and main registers atexit cleanup for existing selftest/fatal
exit paths. Fullscreen screenshots explicitly return failure until a native
fullscreen QuickDraw reference exists; windowed screenshot tests still pass.
Other original debug consumers and later in-game window-port changes remain open.

Actual tests/fullscreen_host.sh runs production AstroView on Intel in monitored
children. Default entry and actual game frame (116110 nonblack pixels), left
Option bypass/rightOption distinction, rejected backend entry, delegate Quit
after view movement, closeDown and directexit/atexit mode restoration all PASS.
Parent independently verifies originalmode retained in both child scenarios.
Keymap128, quit lifecycle/native projections and complete PICT file/gates/error
regressions PASS. Primary/Intel builds PASS, no primary runtime.

Actual newly built app also ran its complete --self-test in an owned copied
bundle with unique local.astrosquid.fullscreen-test-20261028 identifier and
independent parent mode recovery. PASS4specials,393beams,178effects,102shots,
32hits,355scriptsteps,stage switch,640x480 renderer and music. Child exited0,
native_restore1, no recovery. Internal logs fullscreen-app-result.json and
fullscreen-app-run.log. Temporary app/screenshot/testdomain/probe binaries removed
after recording; no releasedZIP regenerated. Whole-game parity remains unproved.
