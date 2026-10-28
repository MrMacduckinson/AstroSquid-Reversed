#!/bin/bash
# Authorized Intel reference Mac only; no game launch or OpenGL context.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 tests/menu_edges_host_test.m src/ui_renderer.m src/ui_model.c \
  src/scores.c src/weapons.c src/ppc_math.c -framework Cocoa -framework OpenGL -o build/menu_edges_host_test
scratch=$(mktemp -d /tmp/astrosquid-menu-edges.XXXXXX)
trap 'rm -r "$scratch"' EXIT
gzip -cd tests/menu_edges_native.csv.gz > "$scratch/native.csv"
build/menu_edges_host_test assets "$scratch/native.csv" > "$scratch/host.csv"
cmp "$scratch/native.csv" "$scratch/host.csv"
echo 'PASS342576 original/host menu edge hits and28548 full IEEE animated node states'
