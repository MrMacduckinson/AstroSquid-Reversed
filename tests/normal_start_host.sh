#!/bin/bash
# Authorized Intel runtime only.
set -euo pipefail
cd "$(dirname "$0")/.."
frames=${1:-1}
case "$frames" in
  1) fixture=tests/normal_start_native.tsv.gz ;;
  256) fixture=tests/normal_start_256_native.tsv.gz ;;
  *) echo "usage: $0 [1|256]" >&2; exit 2 ;;
esac
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/final_arena_world_host.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/preferences.c src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/normal_start_host_test
scratch=$(mktemp -d /tmp/astrosquid-normal-start.XXXXXX)
trap 'rm -r "$scratch"' EXIT
gzip -cd "$fixture" > "$scratch/native.tsv"
ASTRO_WORLD_NORMAL_FOLLOW="$frames" ASTRO_WORLD_REAL_HUD=1 ASTRO_WORLD_READY=1 build/normal_start_host_test assets advancing normal1A > "$scratch/host.tsv"
/usr/bin/python tests/compare_normal_start.py "$scratch/native.tsv" "$scratch/host.tsv" "$frames"
