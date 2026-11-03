#!/bin/bash
# Foreground, muted runtime check; use only on an authorized Intel display.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${TIGER_SDK:?Set TIGER_SDK to the prepared 10.4 SDK}"
objects=()
for object in build/tiger-intel/objects/*.o; do
  [[ "$object" == */preview.m.o ]] || objects+=("$object")
done
clang -arch i386 -mmacosx-version-min=10.4 -isysroot "$TIGER_SDK" -O2 -ffp-contract=off -Isrc -Isrc/tiger -fblocks -fobjc-runtime=macosx-fragile-10.4 -Xclang -fobjc-subscripting-legacy-runtime -c tests/tiger_fullscreen_test.m -o build/tiger-intel/fullscreen.o
clang -arch i386 -mmacosx-version-min=10.4 -isysroot "$TIGER_SDK" build/tiger-intel/fullscreen.o "${objects[@]}" -framework Cocoa -framework Carbon -framework OpenGL -framework OpenAL -framework AudioToolbox -framework QTKit -o build/tiger-intel/fullscreen_test
NSZombieEnabled=YES build/tiger-intel/fullscreen_test build/tiger-intel/AstroSquid.app/Contents/Resources/assets
