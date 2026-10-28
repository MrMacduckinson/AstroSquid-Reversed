#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d /tmp/astrosquid-registration-fields.XXXXXX)
trap 'rm -r "$scratch"' EXIT
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra -Isrc tests/registration_field_key_test.c src/scores.c -o "$scratch/host"
gzip -cd tests/registration_field_native.csv.gz > "$scratch/native.csv"
"$scratch/host" > "$scratch/host.csv"
cmp "$scratch/native.csv" "$scratch/host.csv"
echo 'PASS81120 original/host two-field editing states, focus switching, signed cursors and continued overflow alerts'
