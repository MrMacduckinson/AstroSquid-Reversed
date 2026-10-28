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
