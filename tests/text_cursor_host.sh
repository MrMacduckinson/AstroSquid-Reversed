#!/bin/bash
# Actual runtime only on authorized Intel.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/text_cursor_host_test.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/preferences.c src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/text_cursor_host_test
scratch=$(mktemp /tmp/astrosquid-text-cursor.XXXXXX)
trap 'rm "$scratch"' EXIT
build/text_cursor_host_test assets > "$scratch"
cmp tests/text_cursor_native.csv "$scratch"
echo 'PASS390 original integer widths,2385 cursor positions and252 mouse routes'
