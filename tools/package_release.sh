#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:-$HOME/Downloads/AstroSquid-Release}"
if [ -n "$(git status --porcelain)" ]; then
  printf 'Commit the source, assets and Applications before packaging.\n' >&2
  exit 1
fi
for target in ARM Intel; do
  app="Applications/$target/AstroSquid.app"
  case "$target" in ARM) arch=arm64; minimum=11.0 ;; Intel) arch=x86_64; minimum=10.13 ;; esac
  lipo "$app/Contents/MacOS/AstroSquid" -verify_arch "$arch"
  declared=$(/usr/libexec/PlistBuddy -c 'Print LSMinimumSystemVersion' "$app/Contents/Info.plist")
  [ "$declared" = "$minimum" ] || { printf 'Wrong minimum for %s\n' "$target" >&2; exit 1; }
done
shasum -a 256 -c Applications/SHA256SUMS >/dev/null
mkdir -p "$output"
output=$(cd "$output" && pwd)
staging=$(mktemp -d "${TMPDIR:-/tmp}/astrosquid-release.XXXXXX")
trap 'rm -r -- "$staging"' EXIT
source_dir="$staging/AstroSquid-Source"
repo_dir="$staging/AstroSquid-Reconstruction"
mkdir "$source_dir" "$repo_dir"
rsync -a --exclude __pycache__ --exclude .DS_Store src tests tools assets validation licenses docs "$source_dir/"
cp README.md SOURCE_GUIDE.md VALIDATION.md STATUS.md CHANGELOG.md THIRD_PARTY.md build.sh test.sh requirements.txt "$source_dir/"
git rev-parse HEAD > "$source_dir/SOURCE_COMMIT.txt"
git archive HEAD | tar -xf - -C "$repo_dir"
git rev-parse HEAD > "$repo_dir/SOURCE_COMMIT.txt"
for target in ARM Intel; do
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "Applications/$target/AstroSquid.app" "$output/AstroSquid-$target.zip"
done
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$source_dir" "$output/AstroSquid-Source.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$repo_dir" "$output/AstroSquid-Repository.zip"
(cd "$output" && shasum -a 256 *.zip > SHA256SUMS)
printf 'Packaged ARM, Intel, source and repository snapshots in %s\n' "$output"
