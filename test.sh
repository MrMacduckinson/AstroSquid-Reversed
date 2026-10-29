#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/picture_test.c src/picture.c -o build/picture_test
picture_python=$(command -v python3 || command -v python)
"$picture_python" tests/picture_native_test.py build/picture_test
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/picture_file_test.c src/picture.c -o build/picture_file_test
build/picture_file_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/ppc_math_test.c src/physics.c src/ppc_math.c -lm -o build/ppc_math_test
build/ppc_math_test tests/physics_hex_vectors.csv tests/asin_hex_vectors.csv tests/atan_hex_vectors.csv
for check in scene star; do
  "${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra "tests/${check}_bits_test.c" src/scene.c src/weapons.c src/ppc_math.c -lm -o "build/${check}_bits_test"
done
build/scene_bits_test tests/scene_hex_vectors.csv
build/star_bits_test tests/star_hex_vectors.txt
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/physics_test.c src/physics.c src/ppc_math.c -lm -o build/physics_test
build/physics_test tests/physics_vectors.csv tests/heading_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/script_test.c src/script.c src/physics.c src/ppc_math.c -lm -o build/script_test
build/script_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/script_clock_test.c src/script.c src/physics.c src/ppc_math.c -lm -o build/script_clock_test
build/script_clock_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/script_clock_native_test.c src/script.c src/physics.c src/ppc_math.c -lm -o build/script_clock_native_test
build/script_clock_native_test tests/script_clock_native.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/weapons_test.c src/weapons.c -o build/weapons_test
build/weapons_test tests/weapon_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/combat_test.c src/combat.c -lm -o build/combat_test
build/combat_test tests/combat_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/beams_test.c src/beams.c src/weapons.c src/ppc_math.c -lm -o build/beams_test
build/beams_test tests/beam_vectors.csv
build/beams_test tests/stale_beam_vectors.csv
build/beams_test tests/edge_beam_vectors.csv
build/beams_test tests/beam_interval_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/pickup_test.c src/combat.c -lm -o build/pickup_test
build/pickup_test tests/pickup_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/scenery_test.c src/combat.c -lm -o build/scenery_test
build/scenery_test tests/scenery_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/player_test.c src/player.c src/physics.c src/ppc_math.c -lm -o build/player_test
build/player_test tests/player_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/player_clock_test.c src/player.c src/physics.c src/ppc_math.c -lm -o build/player_clock_test
build/player_clock_test tests/player_clock_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/campaign_test.c src/campaign.c -o build/campaign_test
build/campaign_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/effects_test.c src/effects.c src/weapons.c src/physics.c src/ppc_math.c -lm -o build/effects_test
build/effects_test tests/effects_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/visual_test.c src/visual.c -lm -o build/visual_test
build/visual_test tests/visual_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/visual_clock_test.c src/visual.c -o build/visual_clock_test
build/visual_clock_test tests/visual_clock_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/special_test.c src/special.c src/beams.c src/weapons.c src/physics.c src/ppc_math.c -lm -o build/special_test
build/special_test tests/special_vectors.csv
build/special_test tests/stale_special_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/ui_test.c src/ui_model.c -lm -o build/ui_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/ui_motion_test.c src/ui_model.c -lm -o build/ui_motion_test
build/ui_motion_test tests/ui_motion_vectors.csv tests/ui_panel_vectors.csv
build/ui_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/ui_motion_test.c src/ui_model.c -lm -o build/ui_motion_test
build/ui_motion_test tests/ui_motion_vectors.csv tests/ui_panel_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/debris_test.c src/debris.c src/physics.c src/ppc_math.c -lm -o build/debris_test
build/debris_test tests/debris_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/debris_clock_test.c src/debris.c src/physics.c src/ppc_math.c -lm -o build/debris_clock_test
build/debris_clock_test --synthetic
build/debris_clock_test tests/debris_clock_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/scene_test.c src/scene.c src/weapons.c src/ppc_math.c -lm -o build/scene_test
build/scene_test tests/scene_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/hud_test.c src/hud.c -lm -o build/hud_test
build/hud_test tests/hud_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/flow_test.c src/flow.c -o build/flow_test
build/flow_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/scores_test.c src/scores.c -o build/scores_test
build/scores_test
bash tests/registration_field_key.sh
bash tests/registration_validator.sh
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/caret_test.c src/scores.c -o build/caret_test
build/caret_test tests/caret_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/transition_test.c src/transition.c -lm -o build/transition_test
build/transition_test
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/nested_special_test.c src/special.c src/beams.c src/weapons.c src/physics.c src/ppc_math.c -lm -o build/nested_special_test
build/nested_special_test tests/nested_special_trace.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/special_fps_test.c src/special.c src/beams.c src/weapons.c src/physics.c src/ppc_math.c -lm -o build/special_fps_test
build/special_fps_test tests/special_fps_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/special_clock_test.c src/special.c src/beams.c src/weapons.c src/physics.c src/ppc_math.c -lm -o build/special_clock_test
build/special_clock_test tests/special_clock_vectors.csv
"${CC:-cc}" -std=c99 -O2 -ffp-contract=off -Wall -Wextra tests/hit_visual_test.c src/hit_visual.c src/visual.c -o build/hit_visual_test
build/hit_visual_test
if [ "${1:-}" != "--native-only" ] && [ -f assets/game.json ]; then
  if [ -z "${PYTHON:-}" ]; then
    if [ -x .venv/bin/python ]; then PYTHON=.venv/bin/python; else PYTHON=python3; fi
  fi
  "$PYTHON" tools/check_assets.py assets
  "$PYTHON" tests/audio_test.py
  "$PYTHON" tests/ui_assets_test.py
fi
