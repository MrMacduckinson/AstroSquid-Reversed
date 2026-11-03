#!/bin/bash
# Actual mixed PCM capture upstream of a muted sink, no audible output or microphone.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -Wno-deprecated-declarations tests/audio_waveform_host_test.m src/audio.m -framework Foundation -framework AVFoundation -o build/audio_waveform_host_test
build/audio_waveform_host_test assets
