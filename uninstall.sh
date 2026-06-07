#!/bin/bash
# Entfernt Finestra vollstaendig: beendet die App, loescht das Bundle,
# Login-Item, Einstellungen und den lokalen Signier-Schluesselbund.
set -euo pipefail

echo "→ Beende Finestra …"
pkill -x Finestra 2>/dev/null || true
sleep 1

echo "→ Loesche App-Bundle(s) …"
rm -rf "/Applications/Finestra.app"
rm -rf "$HOME/Applications/Finestra.app"

echo "→ Entferne Login-Item (falls vorhanden) …"
# SMAppService raeumt beim naechsten Login selbst auf; hier nur Best effort.

echo "→ Loesche Einstellungen …"
defaults delete com.realview.finestra 2>/dev/null || true

echo "→ Loesche lokalen Signier-Schluesselbund …"
SIGN_KC="$HOME/Library/Keychains/finestra-signing.keychain-db"
if [ -f "$SIGN_KC" ]; then
    current=()
    while IFS= read -r line; do
        line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/"//g')"
        [ -n "$line" ] && [ "$line" != "$SIGN_KC" ] && current+=("$line")
    done < <(security list-keychains -d user)
    [ ${#current[@]} -gt 0 ] && security list-keychains -d user -s "${current[@]}" || true
    security delete-keychain "$SIGN_KC" 2>/dev/null || true
fi

echo "✓ Finestra entfernt. Den Eintrag unter Systemeinstellungen → Datenschutz →"
echo "  Bedienungshilfen kannst Du bei Bedarf manuell loeschen."
