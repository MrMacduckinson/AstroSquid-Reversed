#!/bin/bash
# Run only on the authorized Intel reference Mac, never the primary Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
clang -fobjc-arc -O2 -ffp-contract=off -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/beam_world_host.m \
  src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c \
  src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c \
  src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c \
  src/debris.c src/scene.c src/audio.m src/ui_model.c src/ui_renderer.m \
  src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/beam_world_host
scratch=$(mktemp -d /tmp/astrosquid-beam-world.XXXXXX)
trap 'rm -r "$scratch"' EXIT
for weapon in 40 50; do
  for cleanup in 0 1; do
    build/beam_world_host assets "$weapon" "$cleanup" "$scratch/clocks.tsv" > "$scratch/world.tsv"
    cmp "tests/beam_world_native/world-$weapon-$cleanup.tsv" "$scratch/world.tsv"
    cmp "tests/beam_world_native/clocks-$weapon-$cleanup.tsv" "$scratch/clocks.tsv"
  done
done
echo 'PASS four coupled beam world traces: 121 state records and 23 clock observations identical to G5'
