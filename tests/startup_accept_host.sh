#!/bin/bash
# Run on the authorized Intel reference Mac only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/menu_transition_host_test.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/preferences.c src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/startup_accept_host_test
scratch=$(mktemp -d /tmp/astrosquid-navigation.XXXXXX)
trap 'rm -r "$scratch"' EXIT
gzip -cd tests/startup_accept_native.csv.gz > "$scratch/native.csv"
gzip -cd tests/startup_accept_stars.bin.gz > "$scratch/native-stars.bin"
build/startup_accept_host_test assets "$scratch/host-stars.bin" startup > "$scratch/host.csv"
cmp "$scratch/native.csv" "$scratch/host.csv"
cmp "$scratch/native-stars.bin" "$scratch/host-stars.bin"
/usr/bin/python - "$scratch/native.csv" tests/startup_anchor_native.csv <<'PYCODE'
import csv,sys
anchor=list(csv.reader(open(sys.argv[2],"rb")))
assert len(anchor)==12
assert {int(r[1]):int(r[2]) for r in anchor if r[0]=="L"}=={0:42,1:-1,2:3}
expected={int(r[1]):r[4:6] for r in anchor if r[0]=="C" and r[2]=="2"}
rows=[r for r in csv.reader(open(sys.argv[1],"rb")) if r[0]=="Z"]
assert len(rows)==9
for row in rows:assert row[5:7]==expected[int(row[1])%3+1]
PYCODE
echo 'PASS9 original/host startup acceptance transitions and held/released latch'
