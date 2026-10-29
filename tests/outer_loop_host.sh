#!/bin/bash
# Run only on the authorized Intel reference Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/outer_loop_host.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/preferences.c src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/outer_loop_host
scratch=$(mktemp /tmp/astrosquid-outer-loop.XXXXXX)
trap 'rm "$scratch"' EXIT
for initial in 0 1 2; do
  build/outer_loop_host assets "$initial" > "$scratch"
  if [ "$initial" = 0 ]; then fixture=tests/outer_loop_native.csv; else fixture="tests/outer_loop_hud${initial}_native.csv"; fi
  cmp "$fixture" "$scratch"
done
build/outer_loop_host assets 2 repeat > "$scratch"
cmp tests/outer_loop_repeat_native.csv "$scratch"
build/outer_loop_host assets 2 end > "$scratch"
cmp tests/outer_loop_hud2_native.csv "$scratch"
echo 'PASS10 end-on-entry plus 30 single-iteration and 10x64 repeated original/host outer-loop schedules'
