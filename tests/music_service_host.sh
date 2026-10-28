#!/bin/bash
# Authorized Intel runtime only.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
clang -fobjc-arc -O2 -Wall -Wextra tests/music_service_test.m src/audio.m -framework Foundation -framework AVFoundation -o build/music_service_test
build/music_service_test
clang -fobjc-arc -O2 -Wall -Wextra tests/music_identity_test.m src/audio.m -framework Foundation -framework AVFoundation -o build/music_identity_test
build/music_identity_test
