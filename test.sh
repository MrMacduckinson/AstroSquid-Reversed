#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/physics_test.c src/physics.c -lm -o build/physics_test
build/physics_test tests/physics_vectors.csv
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra tests/script_test.c src/script.c src/physics.c -lm -o build/script_test
build/script_test
if [ -f assets/game.json ]; then
  if [ -n "${PYTHON:-}" ]; then
    "$PYTHON" tools/check_assets.py assets
  elif [ -x .venv/bin/python ]; then
    .venv/bin/python tools/check_assets.py assets
  else
    python3 tools/check_assets.py assets
  fi
fi
