#!/bin/bash
# Run only on the authorized Intel reference Mac, never the primary Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
clang -fobjc-arc -O2 -ffp-contract=off -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/active_special_world_host.m \
  src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c \
  src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c \
  src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c \
  src/debris.c src/scene.c src/audio.m src/preferences.c src/ui_model.c src/ui_renderer.m \
  src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/active_special_world_host
scratch=$(mktemp -d /tmp/astrosquid-active-world.XXXXXX)
trap 'rm -r "$scratch"' EXIT
for variant in base tail storm; do
  set -- assets "$scratch/clocks.csv"
  suffix=""
  if [ "$variant" != base ]; then set -- "$@" "$variant"; suffix="_$variant"; fi
  build/active_special_world_host "$@" > "$scratch/host.tsv"
  awk '$1 != "V"' "tests/active_special_world${suffix}_native.tsv" > "$scratch/native.tsv"
  cmp "$scratch/native.tsv" "$scratch/host.tsv"
  gzip -cd "tests/active_special_world${suffix}_clocks.csv.gz" | awk -F, '{print $1 "," $3}' > "$scratch/native-clocks.csv"
  cmp "$scratch/native-clocks.csv" "$scratch/clocks.csv"
done
for weapon in 40 41 42 43 51 52 53; do
  build/active_special_world_host assets "$scratch/clocks.csv" storm "$weapon" > "$scratch/host.tsv"
  awk '$1 != "V"' "tests/active_special_levels/$weapon.tsv" > "$scratch/native.tsv"
  cmp "$scratch/native.tsv" "$scratch/host.tsv"
  if [ "$weapon" -lt 50 ]; then clocks=plasma-clocks; else clocks="$weapon-clocks"; fi
  gzip -cd "tests/active_special_levels/$clocks.csv.gz" | awk -F, '{print $1 "," $3}' > "$scratch/native-clocks.csv"
  cmp "$scratch/native-clocks.csv" "$scratch/clocks.csv"
done
for weapon in 51 52 53; do
  for mode in pair kill; do
    name="$weapon-$mode"
    build/active_special_world_host assets "$scratch/clocks.csv" storm "$weapon" "$mode" > "$scratch/host.tsv"
    awk '$1 != "V"' "tests/active_special_pairs/$name.tsv" > "$scratch/native.tsv"
    cmp "$scratch/native.tsv" "$scratch/host.tsv"
    gzip -cd "tests/active_special_pairs/$name-clocks.csv.gz" | awk -F, '{print $1 "," $3}' > "$scratch/native-clocks.csv"
    cmp "$scratch/native-clocks.csv" "$scratch/clocks.csv"
  done
done
for weapon in 40 51; do
  build/active_special_world_host assets "$scratch/clocks.csv" storm "$weapon" parents > "$scratch/host.tsv"
  gzip -cd "tests/active_special_parents/$weapon.tsv.gz" | awk '$1 != "V"' > "$scratch/native.tsv"
  cmp "$scratch/native.tsv" "$scratch/host.tsv"
  gzip -cd "tests/active_special_parents/$weapon-clocks.csv.gz" | awk -F, '{print $1 "," $3}' > "$scratch/native-clocks.csv"
  cmp "$scratch/native-clocks.csv" "$scratch/clocks.csv"
done
echo 'PASS original nested special worlds: base, tail, eight weapon levels, two-target chains, destruction and linked parents'
