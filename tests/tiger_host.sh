#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${TIGER_SDK:?Set TIGER_SDK to the prepared 10.4 SDK}"
objects=()
for object in build/tiger-intel/objects/*.o; do
  [[ "$object" == */preview.m.o ]] || objects+=("$object")
done
for test in tiger_host tiger_audio tiger_departure_geometry tiger_retina_primitives tiger_ui; do
  clang -arch i386 -mmacosx-version-min=10.4 -isysroot "$TIGER_SDK" -O2 -ffp-contract=off -Isrc -Isrc/tiger -fblocks -fobjc-runtime=macosx-fragile-10.4 -Xclang -fobjc-subscripting-legacy-runtime -c "tests/${test}_test.m" -o "build/tiger-intel/$test.o"
  clang -arch i386 -mmacosx-version-min=10.4 -isysroot "$TIGER_SDK" "build/tiger-intel/$test.o" "${objects[@]}" -framework Cocoa -framework Carbon -framework OpenGL -framework OpenAL -framework AudioToolbox -framework QTKit -o "build/tiger-intel/$test"
  NSZombieEnabled=YES "build/tiger-intel/$test" build/tiger-intel/AstroSquid.app/Contents/Resources/assets
done
