#!/bin/bash
# Authorized Intel runtime only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -Wall -Wextra tests/music_volume_test.m src/audio.m -framework Foundation -framework AVFoundation -o build/music_volume_test
build/music_volume_test assets
