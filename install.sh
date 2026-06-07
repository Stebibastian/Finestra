#!/bin/bash
# Ein Befehl: Signatur einrichten (lautlos) → bauen → nach /Applications → starten.
set -euo pipefail
cd "$(dirname "$0")"

./make-cert.sh || echo "  (certificate setup skipped - using existing or ad-hoc)"
./make-app.sh

DEST="/Applications/Finestra.app"

# Laufende Instanz beenden, sonst kann 'open' mit Fehler -600 scheitern.
pkill -x Finestra 2>/dev/null || true
sleep 1

echo "→ Installing to $DEST …"
rm -rf "$DEST"
cp -R "Finestra.app" "$DEST"

# Launch Services neu registrieren, damit Finder/Programme sofort die App zeigen.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST" 2>/dev/null || true

echo "→ Launching …"
open "$DEST" 2>/dev/null || { sleep 2; open "$DEST"; }
echo "✓ Installed. The window icon appears in the menu bar."
echo "  First time: grant Accessibility - the app then relaunches itself."
