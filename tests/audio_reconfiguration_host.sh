#!/bin/bash
# Muted background test; simulates engine notification without changing audio devices.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -Wall -Wextra -Wno-deprecated-declarations tests/audio_reconfiguration_test.m src/audio.m -framework Foundation -framework AVFoundation -o build/audio_reconfiguration_test
build/audio_reconfiguration_test assets
