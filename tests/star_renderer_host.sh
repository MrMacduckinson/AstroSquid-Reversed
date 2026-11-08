#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wno-deprecated-declarations tests/star_renderer_host_test.m src/scene.c src/weapons.c src/ppc_math.c -framework Cocoa -framework OpenGL -o build/star_renderer_host_test
build/star_renderer_host_test
