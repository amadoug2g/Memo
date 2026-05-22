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

BUNDLE_PLIST="$RESOURCES/Memo_Memo.bundle/Contents/Info.plist"
if [ -f "$BUNDLE_PLIST" ]; then
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.amadoug2g.memo.resources" "$BUNDLE_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.amadoug2g.memo.resources" "$BUNDLE_PLIST"
fi

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
