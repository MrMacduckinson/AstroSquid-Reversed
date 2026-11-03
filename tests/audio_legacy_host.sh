#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -arch x86_64 -mmacosx-version-min=10.7 -fobjc-arc -O2 -Wno-deprecated-declarations -Wunguarded-availability tests/audio_legacy_host_test.m src/audio_legacy.m -framework Foundation -framework AVFoundation -framework OpenAL -framework AudioToolbox -o build/audio_legacy_host_test
build/audio_legacy_host_test assets
