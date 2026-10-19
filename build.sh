#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="build/AstroSquid Preview.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/assets/atlases"
clang -fobjc-arc -O2 -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 src/preview.m src/physics.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c src/flow.c src/transition.c src/scores.c src/visual.c src/effects.c src/special.c src/debris.c src/scene.c src/audio.m src/ui_model.c src/ui_renderer.m src/hud.c src/hud_renderer.m -framework Cocoa -framework OpenGL \
  -framework AVFoundation -o "$app/Contents/MacOS/AstroSquidPreview"
mkdir -p "$app/Contents/Resources/assets/ui"
cp assets/ui/ui.json "$app/Contents/Resources/assets/ui/"
cp assets/game.json assets/audio.json "$app/Contents/Resources/assets/"
mkdir -p "$app/Contents/Resources/assets/sounds"
cp assets/sounds/*.wav "$app/Contents/Resources/assets/sounds/"
cp assets/Music*.mp3 "$app/Contents/Resources/assets/"
cp assets/atlases/*.png "$app/Contents/Resources/assets/atlases/"
if [ -f assets/Music1.mp3 ]; then cp assets/Music1.mp3 "$app/Contents/Resources/assets/"; fi
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AstroSquidPreview</string>
<key>CFBundleIdentifier</key><string>local.astrosquid.reconstruction-preview</string>
<key>CFBundleName</key><string>AstroSquid Preview</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>0.1</string>
<key>LSMinimumSystemVersion</key><string>10.13</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
printf 'Built %s\n' "$app"
