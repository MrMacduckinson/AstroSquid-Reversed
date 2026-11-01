#!/bin/bash
# Authorized Intel Mac only; no game or graphics on the primary Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp /tmp/astrosquid-gameover-world-overlay.XXXXXX)
trap 'rm -f "$scratch"' EXIT
export ASTRO_WORLD_REAL_HUD=1 ASTRO_WORLD_PANEL=1 ASTRO_WORLD_PANEL_INPUT=1
export ASTRO_WORLD_PANEL_CLEANUP=1 ASTRO_WORLD_PANEL_OVERLAY=1
export ASTRO_WORLD_CAPTURE_BINARY=build/gameover_world_overlay
bash tests/final_arena_world_host.sh advancing resumewarm8B > "$scratch"
python tests/compare_gameover_world_overlay.py tests/gameover_world_overlay_1.tsv.gz "$scratch"
ASTRO_WORLD_PANEL_OVERLAY=2 "$ASTRO_WORLD_CAPTURE_BINARY" assets advancing resumewarm8B > "$scratch"
python tests/compare_gameover_world_overlay.py tests/gameover_world_overlay_2.tsv.gz "$scratch"
