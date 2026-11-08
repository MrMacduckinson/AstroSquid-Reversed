#!/bin/bash
# Run with an Apple i386-capable linker and an authentic MacOSX10.4u SDK.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${TIGER_SDK:?Set TIGER_SDK to MacOSX10.4u.sdk}"
app=build/tiger-intel/AstroSquid.app
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/assets" build/tiger-intel/objects
flags=(-arch i386 -mmacosx-version-min=10.4 -isysroot "$TIGER_SDK" -O2 -ffp-contract=off -Isrc -Isrc/tiger -fblocks -Wno-deprecated-declarations)
objects=()
for file in src/*.c src/tiger/vendor/BlocksRuntime/runtime.c src/tiger/vendor/BlocksRuntime/data.c; do
  object="build/tiger-intel/objects/$(basename "$file").o"
  clang "${flags[@]}" -std=c99 -c "$file" -o "$object"
  objects+=("$object")
done
for file in src/tiger/*.m; do
  object="build/tiger-intel/objects/$(basename "$file").o"
  clang "${flags[@]}" -fobjc-runtime=macosx-fragile-10.4 -Xclang -fobjc-subscripting-legacy-runtime -c "$file" -o "$object"
  objects+=("$object")
done
clang -arch i386 -mmacosx-version-min=10.4 -isysroot "$TIGER_SDK" "${objects[@]}" -framework Cocoa -framework Carbon -framework OpenGL -framework OpenAL -framework AudioToolbox -framework QTKit -o "$app/Contents/MacOS/AstroSquid"
cp -R assets/atlases assets/sounds assets/ui "$app/Contents/Resources/assets/"
cp assets/Music*.mp3 assets/preferences-defaults.bin "$app/Contents/Resources/assets/"
cp assets/AstroSquid.icns "$app/Contents/Resources/"
python tools/tiger_assets.py assets "$app/Contents/Resources/assets"
mkdir -p "$app/Contents/Resources/licenses"
cp licenses/* "$app/Contents/Resources/licenses/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AstroSquid</string>
<key>CFBundleIdentifier</key><string>local.astrosquid.reconstruction-preview</string>
<key>CFBundleName</key><string>AstroSquid</string>
<key>CFBundleIconFile</key><string>AstroSquid.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>0.0.2</string>
<key>CFBundleShortVersionString</key><string>0.0.2</string>
<key>LSMinimumSystemVersion</key><string>10.4</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
printf 'Built %s\n' "$app"
