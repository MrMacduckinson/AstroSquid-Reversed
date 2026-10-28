#!/bin/bash
# Runtime only on authorized Intel, never on the primary Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/card_text_host_test.m src/ui_renderer.m src/ui_model.c src/physics.c src/weapons.c src/ppc_math.c src/scores.c \
  -framework Cocoa -framework OpenGL -o build/card_text_host_test
scratch=$(mktemp /tmp/astrosquid-card-text.XXXXXX)
trap 'rm "$scratch"' EXIT
build/card_text_host_test assets > "$scratch"
cmp tests/card_text_native.csv "$scratch"
echo 'PASS52 original card/credits text commands: MacRoman bytes, order and exact IEEE coordinates/sizes/colors'
