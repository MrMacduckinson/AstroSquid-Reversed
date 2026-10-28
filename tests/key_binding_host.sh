#!/bin/bash
# Run on the authorized Intel reference Mac only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/wait_key_host_test.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/key_binding_host_test
scratch=$(mktemp -d /tmp/astrosquid-wait-key.XXXXXX)
trap 'rm -r "$scratch"' EXIT
gzip -cd tests/key_binding_native.csv.gz > "$scratch/native.csv"
build/key_binding_host_test assets dispatch > "$scratch/host.csv"
cmp "$scratch/native.csv" "$scratch/host.csv"
echo 'PASS18 complete original/host key binding transactions'
