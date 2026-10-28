#!/bin/bash
# Run on the authorized Intel reference Mac only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/ui_sprite_change_host_test.m src/ui_renderer.m src/ui_model.c src/scores.c src/weapons.c src/ppc_math.c \
  -framework Cocoa -framework OpenGL -o build/ui_sprite_change_host_test
scratch=$(mktemp /tmp/astrosquid-pressed.XXXXXX)
trap 'rm "$scratch"' EXIT
build/ui_sprite_change_host_test assets > "$scratch"
cmp tests/ui_sprite_change_native.csv "$scratch"
echo 'PASS20 original/host sprite changes: pressed901, clocks,80 IEEE bounds and wrap'
