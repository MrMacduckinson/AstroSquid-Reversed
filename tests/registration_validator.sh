#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d /tmp/astrosquid-registration-validator.XXXXXX)
trap 'rm -r "$scratch"' EXIT
"${CC:-cc}" -std=c99 -O2 -Wall -Wextra -Isrc tests/registration_validator_test.c src/ui_model.c -o "$scratch/host"
gzip -cd tests/registration_validator_native.csv.gz > "$scratch/native.csv"
"$scratch/host" > "$scratch/host.csv"
cmp "$scratch/native.csv" "$scratch/host.csv"
echo 'PASS12288 original/host raw-byte registration validations and computed operands'
