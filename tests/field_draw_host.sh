#!/bin/bash
# Runtime only on authorized Intel, never on the primary Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/field_draw_host_test.m src/ui_renderer.m src/ui_model.c src/physics.c src/weapons.c src/ppc_math.c src/scores.c \
  -framework Cocoa -framework OpenGL -o build/field_draw_host_test
scratch=$(mktemp /tmp/astrosquid-field-draw.XXXXXX)
trap 'rm "$scratch"' EXIT
build/field_draw_host_test assets > "$scratch"
cmp tests/field_draw_native.csv "$scratch"
echo 'PASS original field boxes/text/caret commands, fixed origin and scissor behavior'
