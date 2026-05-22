#!/usr/bin/env bash
# Creates a signed Mac App Store installer package (.pkg) from Memo.app.
# Must be run after package-app.sh and after the app is signed with
# an Apple Distribution certificate.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?Usage: package-pkg.sh <version> <signing-identity> [keychain-path]}"
SIGNING_IDENTITY="${2:?Usage: package-pkg.sh <version> <signing-identity> [keychain-path]}"
KEYCHAIN_PATH="${3:-}"
PKG="$REPO/Memo-v${VERSION}.pkg"
UNSIGNED_PKG="$REPO/Memo-v${VERSION}-unsigned.pkg"

echo "→ Building unsigned installer package"

productbuild \
  --component "$REPO/Memo.app" /Applications \
  "$UNSIGNED_PKG"

echo "→ Signing with productsign (identity: $SIGNING_IDENTITY)"

SIGN_ARGS=(--sign "$SIGNING_IDENTITY")
if [ -n "$KEYCHAIN_PATH" ]; then
  SIGN_ARGS+=(--keychain "$KEYCHAIN_PATH")
fi

productsign "${SIGN_ARGS[@]}" "$UNSIGNED_PKG" "$PKG"
rm -f "$UNSIGNED_PKG"

echo "→ Verifying package signature"
pkgutil --check-signature "$PKG"

echo "Memo-v${VERSION}.pkg is ready"
