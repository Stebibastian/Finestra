#!/bin/bash
# One-line install of the latest notarized Finestra release.
# Usage (public repo only):
#   curl -fsSL https://raw.githubusercontent.com/Stebibastian/Finestra/main/web-install.sh | bash
set -euo pipefail

URL="https://github.com/Stebibastian/Finestra/releases/latest/download/Finestra.zip"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Downloading latest version …"
curl -fsSL "$URL" -o "$TMP/Finestra.zip"

echo "→ Unpacking …"
ditto -x -k "$TMP/Finestra.zip" "$TMP"

echo "→ Installing to /Applications …"
pkill -x Finestra 2>/dev/null || true
sleep 1
rm -rf "/Applications/Finestra.app"
mv "$TMP/Finestra.app" "/Applications/Finestra.app"

echo "→ Launching …"
sleep 0.5
# retry: right after a kill+replace, Launch Services can briefly miss the app
open "/Applications/Finestra.app" 2>/dev/null \
  || { sleep 2; open "/Applications/Finestra.app" 2>/dev/null; } \
  || { sleep 3; open "/Applications/Finestra.app"; }
echo "✓ Installed. On first launch, grant Accessibility - the app then relaunches itself."
