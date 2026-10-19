#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/physics_test.c src/physics.c -lm -o build/physics_test
build/physics_test tests/physics_vectors.csv tests/heading_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/script_test.c src/script.c src/physics.c -lm -o build/script_test
build/script_test
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/weapons_test.c src/weapons.c -o build/weapons_test
build/weapons_test tests/weapon_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/combat_test.c src/combat.c -lm -o build/combat_test
build/combat_test tests/combat_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/beams_test.c src/beams.c src/weapons.c -lm -o build/beams_test
build/beams_test tests/beam_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/pickup_test.c src/combat.c -lm -o build/pickup_test
build/pickup_test tests/pickup_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/scenery_test.c src/combat.c -lm -o build/scenery_test
build/scenery_test tests/scenery_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/player_test.c src/player.c src/physics.c -lm -o build/player_test
build/player_test tests/player_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/campaign_test.c src/campaign.c -o build/campaign_test
build/campaign_test
if [ -f assets/game.json ]; then
  if [ -n "${PYTHON:-}" ]; then
    "$PYTHON" tools/check_assets.py assets
  elif [ -x .venv/bin/python ]; then
    .venv/bin/python tools/check_assets.py assets
  else
    python3 tools/check_assets.py assets
  fi
fi
