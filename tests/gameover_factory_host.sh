#!/bin/bash
# Run only on the authorized Intel reference Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/gameover_factory_host_test.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/gameover_factory_host_test
scratch=$(mktemp /tmp/astrosquid-gameover-factory.XXXXXX)
trap 'rm "$scratch"' EXIT
build/gameover_factory_host_test assets > "$scratch"
cmp tests/gameover_factory_native.csv "$scratch"
echo 'PASS80 original/host actual DataB1 field records: constructor clocks, geometry, wraparound and 62 mouse edges'
