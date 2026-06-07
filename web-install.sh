#!/bin/bash
# One-line install of the latest notarized Finestra release.
# Usage (public repo only):
#   curl -fsSL https://raw.githubusercontent.com/Stebibastian/Finestra/main/web-install.sh | bash
set -euo pipefail

REPO="Stebibastian/Finestra"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Resolve the latest tag via the API and download the VERSIONED asset URL.
# (The generic releases/latest/download URL can be served stale from the CDN.)
echo "→ Resolving latest version …"
TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
       | grep -m1 '"tag_name"' | cut -d'"' -f4 || true)"
if [ -n "${TAG:-}" ]; then
    URL="https://github.com/$REPO/releases/download/$TAG/Finestra.zip"
else
    URL="https://github.com/$REPO/releases/latest/download/Finestra.zip"
fi

echo "→ Downloading ${TAG:-latest} …"
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
echo "✓ Installed ${TAG:-latest}. On first launch, grant Accessibility - the app then relaunches itself."
