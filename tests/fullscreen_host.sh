#!/bin/bash
# Authorized foreground runtime check; verifies the display mode never changes.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
audio=src/audio.m
extra=()
if [ "${1:-}" = --legacy-intel ]; then audio=src/audio_legacy.m; extra=(-framework OpenAL -framework AudioToolbox); fi
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/fullscreen_host_test.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c "$audio" src/preferences.c src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon ${extra[@]+"${extra[@]}"} -o build/fullscreen_host_test
build/fullscreen_host_test assets
