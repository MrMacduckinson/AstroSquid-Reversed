#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="build/AstroSquid Preview.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/assets/atlases"
clang -fobjc-arc -O2 -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations \
  -mmacosx-version-min=10.13 src/preview.m src/physics.c src/script.c src/weapons.c src/combat.c src/beams.c src/player.c src/campaign.c -framework Cocoa -framework OpenGL \
  -framework AVFoundation -o "$app/Contents/MacOS/AstroSquidPreview"
cp assets/game.json "$app/Contents/Resources/assets/"
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
