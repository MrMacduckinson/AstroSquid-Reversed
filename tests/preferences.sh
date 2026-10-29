#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d /tmp/astrosquid-preferences.XXXXXX)
trap 'rm -r "$scratch"' EXIT
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra -Isrc tests/preferences_test.c src/preferences.c -o "$scratch/host"
gzip -cd tests/preferences_native.bin.gz > "$scratch/native.bin"
"$scratch/host" assets/preferences-defaults.bin > "$scratch/host.bin"
cmp "$scratch/native.bin" "$scratch/host.bin"
echo 'PASS132701 complete542-byte original/host preference transactions'
