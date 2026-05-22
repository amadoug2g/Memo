#!/usr/bin/env bash
# Creates a signed Mac App Store installer package (.pkg) from Memo.app.
# Must be run after package-app.sh and after the app is signed with
# an Apple Distribution certificate.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?Usage: package-pkg.sh <version> <signing-identity>}"
SIGNING_IDENTITY="${2:?Usage: package-pkg.sh <version> <signing-identity>}"
PKG="$REPO/Memo-v${VERSION}.pkg"

echo "→ Creating installer package $PKG"

productbuild \
  --component "$REPO/Memo.app" /Applications \
  --sign "$SIGNING_IDENTITY" \
  "$PKG"

echo "→ Verifying package signature"
pkgutil --check-signature "$PKG"

echo "Memo-v${VERSION}.pkg is ready"
