#!/bin/bash
# Baut das Release-Binary und verpackt es in ein signiertes .app-Bundle,
# damit die Bedienungshilfen-Freigabe dauerhaft erhalten bleibt.
set -euo pipefail
cd "$(dirname "$0")"

APP="Finestra.app"

echo "→ Kompiliere (release) …"
swift build -c release

echo "→ Baue $APP …"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/Finestra" "$APP/Contents/MacOS/Finestra"
cp "AppSupport/Info.plist" "$APP/Contents/Info.plist"

# Icon bei Bedarf erzeugen und einbetten
if [ ! -f "AppSupport/AppIcon.icns" ]; then
    ./make-icon.sh
fi
cp "AppSupport/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Lautloses Signieren ueber den lokalen Signier-Schluesselbund (siehe make-cert.sh);
# haelt die Bedienungshilfen-Freigabe ueber Rebuilds stabil. Sonst ad-hoc.
# In iCloud haengt der Dateiprovider Attribute an, an denen codesign scheitert
# („resource fork … not allowed"). Darum in einem Temp-Ordner saeubern, signieren
# und das signierte Bundle zuruecklegen.
CERT_NAME="Finestra Local Signing"
SIGN_KC="$HOME/Library/Keychains/finestra-signing.keychain-db"
[ -f "$SIGN_KC" ] && security unlock-keychain -p "finestra-local" "$SIGN_KC" 2>/dev/null || true

SIGN_DIR="$(mktemp -d)"
SIGN_APP="$SIGN_DIR/$APP"
cp -R "$APP" "$SIGN_APP"
xattr -cr "$SIGN_APP" 2>/dev/null || true
if security find-identity -p codesigning 2>/dev/null | grep -qF "$CERT_NAME"; then
    echo "→ Signiere lautlos mit lokalem Zertifikat …"
    codesign --force --sign "$CERT_NAME" --identifier com.realview.finestra "$SIGN_APP"
else
    echo "→ Signiere ad-hoc (fuer stabile Rechte einmal ./make-cert.sh ausfuehren) …"
    codesign --force --sign - --identifier com.realview.finestra "$SIGN_APP"
fi
rm -rf "$APP"
mv "$SIGN_APP" "$APP"
rm -rf "$SIGN_DIR"

echo "✓ Fertig: $(pwd)/$APP"
echo "  Starten mit:  open \"$APP\""
