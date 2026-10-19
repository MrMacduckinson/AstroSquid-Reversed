#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="build/AstroSquid.app"
output="${1:-$HOME/Downloads/AstroSquid-Release}"
# Package the Intel build, even when this script is run on another architecture.
lipo "$app/Contents/MacOS/AstroSquid" -verify_arch x86_64
mkdir -p "$output"
staging=$(mktemp -d "${TMPDIR:-/tmp}/astrosquid-source.XXXXXX")
trap 'mv "$staging" "$HOME/.Trash/$(basename "$staging")"' EXIT
source_dir="$staging/AstroSquid-Source"
mkdir "$source_dir"
rsync -a --exclude __pycache__ --exclude .DS_Store src tests tools assets validation "$source_dir/"
cp README.md VALIDATION.md build.sh test.sh requirements.txt "$source_dir/"
if git rev-parse HEAD > "$source_dir/SOURCE_COMMIT.txt" 2>/dev/null; then :; else
  printf 'Source snapshot\n' > "$source_dir/SOURCE_COMMIT.txt"
fi
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app" "$output/AstroSquid-Intel.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$source_dir" "$output/AstroSquid-Source.zip"
printf 'Packaged Intel application and buildable source with runtime assets in %s\n' "$output"
