#!/usr/bin/env bash
# Ad-hoc sign an app bundle inside-out: loose Mach-O files, then nested
# bundles deepest-first, then the app itself.
set -euo pipefail
APP="$1"
find "$APP" -type f -perm -u+x -print0 | while IFS= read -r -d '' f; do
  if file -b "$f" | grep -q "Mach-O"; then
    codesign --force --sign - --timestamp=none "$f" >/dev/null 2>&1 || { echo "failed: $f" >&2; exit 1; }
  fi
done
find "$APP/Contents" -depth -type d \( -name "*.app" -o -name "*.framework" -o -name "*.plugin" -o -name "*.appex" -o -name "*.xpc" -o -name "*.systemextension" -o -name "*.bundle" \) -print0 |
  while IFS= read -r -d '' b; do
    [ -f "$b/Contents/Info.plist" ] || [ -f "$b/Info.plist" ] || [ -d "$b/Versions" ] || continue
    codesign --force --sign - --timestamp=none "$b" >/dev/null 2>&1 || echo "note: skipped $b" >&2
  done
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"
echo "signed and verified: $APP"
