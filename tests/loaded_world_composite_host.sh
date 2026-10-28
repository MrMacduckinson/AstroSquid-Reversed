#!/bin/bash
# Actual runtime only on the authorized Intel reference Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d /tmp/astrosquid-loaded-world.XXXXXX)
trap 'rm -r "$scratch"' EXIT
bash tests/final_arena_world_host.sh advancing "$scratch/phase.bin" > "$scratch/host.tsv"
cmp tests/loaded_world_composite_native.tsv "$scratch/host.tsv"
phase_python=$(command -v python3 || command -v python)
"$phase_python" tests/loaded_world_phase_test.py "$scratch/phase.bin"
echo 'PASS94 complete original/host final-arena records with advancing clocks, global bounds, births, graph links and sound'
bash tests/final_arena_world_host.sh advancing outer > "$scratch/outer.tsv"
"$phase_python" tests/outer_body_test.py "$scratch/outer.tsv"
