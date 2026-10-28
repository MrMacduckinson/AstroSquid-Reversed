#!/bin/bash
# Authorized Intel runtime only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations -mmacosx-version-min=10.13 tests/picture_filter_host_test.m src/ui_renderer.m src/ui_model.c src/scores.c src/weapons.c src/physics.c src/ppc_math.c -framework Cocoa -framework OpenGL -o build/picture_filter_host_test
build/picture_filter_host_test assets
