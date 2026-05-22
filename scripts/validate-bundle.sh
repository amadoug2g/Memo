#!/usr/bin/env bash
# Validates Memo.app meets App Store Connect requirements before upload.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO/Memo.app"
PLIST="$APP/Contents/Info.plist"
ERRORS=0

check_key() {
  local file="$1" key="$2" label="$3"
  if /usr/libexec/PlistBuddy -c "Print :$key" "$file" &>/dev/null; then
    echo "  ✓ $key in $label"
  else
    echo "::error::Missing required key '$key' in $label"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "→ Validating Memo.app"

for key in CFBundleIdentifier CFBundleVersion CFBundleShortVersionString \
           LSApplicationCategoryType LSMinimumSystemVersion; do
  check_key "$PLIST" "$key" "Info.plist"
done

while IFS= read -r bundle; do
  bundle_plist=$(find "$bundle" -maxdepth 2 -name "Info.plist" 2>/dev/null | head -1)
  name=$(basename "$bundle")
  if [ -z "$bundle_plist" ]; then
    echo "::error::No Info.plist found in $name"
    ERRORS=$((ERRORS + 1))
  else
    check_key "$bundle_plist" "CFBundleIdentifier" "$name"
  fi
done < <(find "$APP/Contents" -name "*.bundle" -type d)

if [ "$ERRORS" -gt 0 ]; then
  echo "→ Validation FAILED with $ERRORS error(s) — fix before uploading."
  exit 1
fi

echo "→ All checks passed."
