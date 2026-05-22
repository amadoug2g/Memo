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

ICNS="$RESOURCES/AppIcon.icns"
if [ ! -f "$ICNS" ]; then
  echo "  → Generating placeholder icon…"
  "$REPO/scripts/generate-icon.sh"
fi

if [ -z "${CI:-}" ]; then
  codesign --force --deep --sign - "$APP" 2>/dev/null
else
  echo "  → Skipping ad-hoc signing in CI (Developer ID signing follows)"
fi

echo "Memo.app is ready"
