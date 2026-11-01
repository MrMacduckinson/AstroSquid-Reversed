#!/bin/bash
# Actual runtime only on authorized Intel.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/main_queue_host_test.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/preferences.c src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/main_queue_host_test
scratch=$(mktemp -d /tmp/astrosquid-main-queue.XXXXXX)
trap 'rm -r "$scratch"' EXIT
for mode in generated idle; do
    if [ "$mode" = idle ]; then
        build/main_queue_host_test assets idle > "$scratch/host.csv"
        gzip -cd tests/main_queue_idle_native.csv.gz > "$scratch/native.csv"
    else
        build/main_queue_host_test assets > "$scratch/host.csv"
        gzip -cd tests/main_queue_native.csv.gz > "$scratch/native.csv"
    fi
    cmp "$scratch/native.csv" "$scratch/host.csv"
done
echo 'PASS540 original/Root Main schedules: all clock, frame, event and terminal field/counter records exact'
