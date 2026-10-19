#!/usr/bin/env bash
# Build a self-signed cmux Plus disk image from a cmux checkout and point the
# cask at it. Usage: scripts/build-cmux-plus.sh <cmux-checkout> <version>
# Then: gh release create plus-v<version> <dmg> --repo tommyz4/cmux --target <sha>
# and commit Casks/cmux-plus.rb.
set -euo pipefail
CHECKOUT="$(cd "$1" && pwd)"; VERSION="$2"
TAP="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${CMUX_PLUS_WORK:-$HOME/Library/Caches/cmux-plus-build}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
# Homebrew's rustup keeps cargo/rustc proxies outside ~/.cargo/bin.
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
mkdir -p "$WORK"

# Tag "plus" gives bundle id com.cmuxterm.app.debug.plus: its own socket
# (/tmp/cmux-debug-plus.sock) and no Sparkle updates. --build-only leaves
# running apps alone; Xcode's product stays in DerivedData.
(cd "$CHECKOUT" && ./scripts/reload.sh --tag plus --release --prod-auth --build-only \
  --no-global-cli-links --name "cmux Plus") > "$WORK/build.log" 2>&1 \
  || { tail -30 "$WORK/build.log"; exit 1; }
SRC="$HOME/Library/Developer/Xcode/DerivedData/cmux-plus/Build/Products/Release/cmux.app"
APP="$WORK/stage/cmux Plus.app"
rm -rf "$WORK/stage" && mkdir -p "$WORK/stage" && ditto "$SRC" "$APP"

PLIST="$APP/Contents/Info.plist"; PB=/usr/libexec/PlistBuddy
$PB -c "Set :CFBundleName cmux Plus" "$PLIST"
$PB -c "Set :CFBundleDisplayName cmux Plus" "$PLIST" 2>/dev/null || $PB -c "Add :CFBundleDisplayName string cmux Plus" "$PLIST"
for i in 0 1 2 3 4 5; do
  s="$($PB -c "Print :CFBundleURLTypes:$i:CFBundleURLSchemes:0" "$PLIST" 2>/dev/null || true)"
  [ "$s" = cmux ] && $PB -c "Set :CFBundleURLTypes:$i:CFBundleURLSchemes:0 cmux-dev-plus" "$PLIST"
done
$PB -c "Delete :LSEnvironment" "$PLIST" 2>/dev/null || true
$PB -c "Add :LSEnvironment dict" "$PLIST"
$PB -c "Add :LSEnvironment:CMUX_TAG string plus" "$PLIST"
$PB -c "Add :LSEnvironment:CMUX_AUTH_CALLBACK_SCHEME string cmux-dev-plus" "$PLIST"

"$CHECKOUT/scripts/strip-release-bundle.sh" "$APP" >/dev/null 2>&1
"$TAP/scripts/adhoc-sign.sh" "$APP"
"$APP/Contents/Resources/bin/cmux" --version

DMG="$WORK/cmux-plus-macos.dmg"; rm -rf "$WORK/dmgroot" "$DMG"
mkdir "$WORK/dmgroot" && ditto "$APP" "$WORK/dmgroot/cmux Plus.app" && ln -s /Applications "$WORK/dmgroot/Applications"
for attempt in 1 2 3; do
  hdiutil create -volname "cmux Plus" -srcfolder "$WORK/dmgroot" -ov -format UDZO "$DMG" >/dev/null 2>&1 && break
  sleep 3
done
SHA="$(shasum -a 256 "$DMG" | cut -d' ' -f1)"
sed -i '' -e "s/^  version \".*\"/  version \"$VERSION\"/" -e "s/^  sha256 \".*\"/  sha256 \"$SHA\"/" "$TAP/Casks/cmux-plus.rb"
echo "dmg: $DMG"; echo "sha256: $SHA"; echo "commit: $(git -C "$CHECKOUT" rev-parse HEAD)"
