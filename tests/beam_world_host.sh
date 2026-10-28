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
cases=0
for fixture in tests/beam_world_native/world-*.tsv; do
  name=${fixture##*/}; name=${name#world-}; name=${name%.tsv}
  IFS=- read -r weapon cleanup scenario <<< "$name"
  set -- "$weapon" "$cleanup" "$scratch/clocks.tsv"
  case "$scenario" in
    "") ;;
    chain|kill) set -- "$@" "$scenario" ;;
    *) echo "Unknown scenario: $scenario" >&2; exit 2 ;;
  esac
  build/beam_world_host assets "$@" > "$scratch/world.tsv"
  cmp "$fixture" "$scratch/world.tsv"
  cmp "tests/beam_world_native/clocks-$name.tsv" "$scratch/clocks.tsv"
  cases=$((cases+1))
done
echo "PASS $cases coupled beam world and clock traces identical to G5"
