#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="build/AstroSquid.app"
case "$(uname -m)" in
  arm64) minimum_macos=11.0 ;;
  x86_64) minimum_macos=10.13 ;;
  *) printf 'Unsupported build architecture\n' >&2; exit 1 ;;
esac
audio_source=src/audio.m
extra_flags=()
extra_frameworks=()
if [ "${1:-}" = --legacy-intel ]; then
  minimum_macos=10.7
  app="build/legacy-intel/AstroSquid.app"
  audio_source=src/audio_legacy.m
  extra_flags=(-arch x86_64 -Wunguarded-availability)
  if [ -n "${SDKROOT:-}" ]; then extra_flags+=(-isysroot "$SDKROOT"); fi
  extra_frameworks=(-framework OpenAL -framework AudioToolbox)
elif [ $# -ne 0 ]; then
  printf 'Usage: ./build.sh [--legacy-intel]\n' >&2; exit 1
fi
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/assets/atlases"
compile() {
clang ${extra_flags[@]+"${extra_flags[@]}"} -fobjc-arc -O2 -ffp-contract=off -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min="$minimum_macos" src/preview.m src/picture.c src/physics.c src/ppc_math.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/hit_visual.c src/effects.c src/special.c src/debris.c src/scene.c "$audio_source" src/preferences.c src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -framework Carbon ${extra_frameworks[@]+"${extra_frameworks[@]}"} -o "$app/Contents/MacOS/AstroSquid"
}
if [ "${1:-}" = --legacy-intel ]; then
  # Apple's libarclite backports these four collection methods to Lion.
  # Keep all other availability diagnostics fatal; do not hide newer APIs.
  compile 2> build/legacy-intel/compile.log || { cat build/legacy-intel/compile.log >&2; exit 1; }
  awk '/warning:.*only available/ && !/objectForKeyedSubscript:|setObject:forKeyedSubscript:|objectAtIndexedSubscript:|setObject:atIndexedSubscript:/ { print; bad=1 } END { exit bad }' build/legacy-intel/compile.log
else
  compile
fi
mkdir -p "$app/Contents/Resources/assets/ui"
mkdir -p "$app/Contents/Resources/licenses"
cp licenses/* "$app/Contents/Resources/licenses/"
cp assets/AstroSquid.icns "$app/Contents/Resources/"
cp assets/ui/ui.json "$app/Contents/Resources/assets/ui/"
cp assets/game.json assets/audio.json assets/preferences-defaults.bin "$app/Contents/Resources/assets/"
mkdir -p "$app/Contents/Resources/assets/sounds"
cp assets/sounds/*.wav "$app/Contents/Resources/assets/sounds/"
cp assets/Music*.mp3 "$app/Contents/Resources/assets/"
cp assets/atlases/*.png "$app/Contents/Resources/assets/atlases/"
# Keep the original bundle identifier so existing settings and scores survive.
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AstroSquid</string>
<key>CFBundleIdentifier</key><string>local.astrosquid.reconstruction-preview</string>
<key>CFBundleName</key><string>AstroSquid</string>
<key>CFBundleIconFile</key><string>AstroSquid.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.1</string>
<key>LSMinimumSystemVersion</key><string>$minimum_macos</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
printf 'Built %s\n' "$app"
