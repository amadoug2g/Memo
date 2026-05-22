#!/usr/bin/env bash
# Packages the SPM release build into a self-contained .app bundle
# and ad-hoc signs it for local use.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO/Memo.app"
MACOS="$APP/Contents/MacOS"
RESOURCES="$APP/Contents/Resources"

echo "→ Packaging Memo.app"

mkdir -p "$MACOS" "$RESOURCES"

cp "$REPO/.build/release/MemoMain" "$MACOS/Memo"
chmod +x "$MACOS/Memo"

cp -r "$REPO/.build/release/Memo_Memo.bundle" "$RESOURCES/"

BUNDLE_DIR="$RESOURCES/Memo_Memo.bundle"
echo "  → Memo_Memo.bundle contents:"
find "$BUNDLE_DIR" -maxdepth 3 | sed 's/^/      /'

BUNDLE_PLIST=$(find "$BUNDLE_DIR" -name "Info.plist" 2>/dev/null | head -1)

if [ -z "$BUNDLE_PLIST" ]; then
  echo "  → No Info.plist found, creating one at bundle root"
  BUNDLE_PLIST="$BUNDLE_DIR/Info.plist"
  cat > "$BUNDLE_PLIST" <<'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.amadoug2g.memo.resources</string>
    <key>CFBundleName</key>
    <string>Memo</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
</dict>
</plist>
PLIST_EOF
else
  echo "  → Found existing Info.plist at $BUNDLE_PLIST"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.amadoug2g.memo.resources" "$BUNDLE_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.amadoug2g.memo.resources" "$BUNDLE_PLIST"
fi

echo "  → Final Memo_Memo.bundle Info.plist:"
/usr/libexec/PlistBuddy -c "Print" "$BUNDLE_PLIST" | sed 's/^/      /'

# Always generate icon so the iconset directory exists for actool
echo "  → Generating app icon"
"$REPO/scripts/generate-icon.sh"

# Compile asset catalog (required for App Store — produces Assets.car)
echo "  → Compiling asset catalog"
ICONSET_DIR="$REPO/.build/AppIcon.iconset"
XCASSETS_DIR="$REPO/.build/AppIcon.xcassets"
APPICONSET_DIR="$XCASSETS_DIR/AppIcon.appiconset"
mkdir -p "$APPICONSET_DIR"

cp "$ICONSET_DIR"/*.png "$APPICONSET_DIR/"

cat > "$XCASSETS_DIR/Contents.json" <<'XCASSETS_EOF'
{"info": {"author": "xcode", "version": 1}}
XCASSETS_EOF

cat > "$APPICONSET_DIR/Contents.json" <<'CONTENTS_EOF'
{
  "images": [
    {"size": "16x16",   "scale": "1x", "idiom": "mac", "filename": "icon_16x16.png"},
    {"size": "16x16",   "scale": "2x", "idiom": "mac", "filename": "icon_16x16@2x.png"},
    {"size": "32x32",   "scale": "1x", "idiom": "mac", "filename": "icon_32x32.png"},
    {"size": "32x32",   "scale": "2x", "idiom": "mac", "filename": "icon_32x32@2x.png"},
    {"size": "128x128", "scale": "1x", "idiom": "mac", "filename": "icon_128x128.png"},
    {"size": "128x128", "scale": "2x", "idiom": "mac", "filename": "icon_128x128@2x.png"},
    {"size": "256x256", "scale": "1x", "idiom": "mac", "filename": "icon_256x256.png"},
    {"size": "256x256", "scale": "2x", "idiom": "mac", "filename": "icon_256x256@2x.png"},
    {"size": "512x512", "scale": "1x", "idiom": "mac", "filename": "icon_512x512.png"},
    {"size": "512x512", "scale": "2x", "idiom": "mac", "filename": "icon_512x512@2x.png"}
  ],
  "info": {"author": "xcode", "version": 1}
}
CONTENTS_EOF

xcrun actool \
  --output-format human-readable-text \
  --notices \
  --warnings \
  --output-partial-info-plist "$REPO/.build/assetcatalog.plist" \
  --app-icon AppIcon \
  --compress-pngs \
  --enable-on-demand-resources NO \
  --target-device mac \
  --minimum-deployment-target 13.0 \
  --platform macosx \
  --product-type com.apple.product-type.application \
  --compile "$RESOURCES" \
  "$XCASSETS_DIR"

echo "  → Asset catalog compiled → Assets.car"

if [ -z "${CI:-}" ]; then
  codesign --force --deep --sign - "$APP" 2>/dev/null
else
  echo "  → Skipping ad-hoc signing in CI (Developer ID signing follows)"
fi

echo "Memo.app is ready"
