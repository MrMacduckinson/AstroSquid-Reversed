#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:-$HOME/Downloads/AstroSquid-Release}"
if [ -n "$(git status --porcelain)" ]; then
  printf 'Commit the source, assets and Applications before packaging.\n' >&2
  exit 1
fi
for target in arm64-SDK27.0-min11.0 x86_64-SDK10.13-min10.13 x86_64-SDK10.13-min10.7 i386-SDK10.4u-min10.4; do
  app="Applications/$target/AstroSquid.app"
  case "$target" in arm64-*) arch=arm64; minimum=11.0 ;; x86_64-*-min10.13) arch=x86_64; minimum=10.13 ;; x86_64-*-min10.7) arch=x86_64; minimum=10.7 ;; i386-*) arch=i386; minimum=10.4 ;; esac
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
for target in arm64-SDK27.0-min11.0 x86_64-SDK10.13-min10.13 x86_64-SDK10.13-min10.7 i386-SDK10.4u-min10.4; do
  /usr/bin/ditto -c -k --norsrc --noextattr --noqtn --keepParent "Applications/$target/AstroSquid.app" "$output/AstroSquid-$target.zip"
done
/usr/bin/ditto -c -k --norsrc --noextattr --noqtn --keepParent "$source_dir" "$output/AstroSquid-Source.zip"
/usr/bin/ditto -c -k --norsrc --noextattr --noqtn --keepParent "$repo_dir" "$output/AstroSquid-Repository.zip"
(cd "$output" && shasum -a 256 *.zip > SHA256SUMS)
printf 'Packaged ARM, Intel, Intel-Legacy, Intel-Tiger, source and repository snapshots in %s\n' "$output"
