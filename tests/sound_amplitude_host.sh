#!/bin/bash
# Run only on the authorized Intel reference Mac.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -Wall -Wextra tests/sound_amplitude_test.m src/audio.m -framework Foundation -framework AVFoundation -o build/sound_amplitude_test
build/sound_amplitude_test assets tests/sound_amplitude_native.csv
