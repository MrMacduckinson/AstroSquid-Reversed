#!/bin/bash
# Runtime only on the authorized Intel iMac.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/picture_host_test.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon -o build/picture_host_test
scratch=$(mktemp -d /tmp/astrosquid-picture-host.XXXXXX)
trap 'rm -r "$scratch"' EXIT
build/picture_host_test assets "$scratch"
python_bin=$(command -v python3 || command -v python)
"$python_bin" - "$scratch/Screenshots/Screen 123.pict" <<'PYTEST'
import gzip,sys
with open(sys.argv[1],'rb') as source: actual=bytearray(source.read())
with gzip.open('tests/picture_native/window-white.pict.gz','rb') as source: native=bytearray(source.read())
native[98:106]=b'\0'*8
assert actual[:512]==bytearray(512) and actual[512:]==native
print('PASS actual host saved file matches complete native window PICT plus512zero prefix')
PYTEST
