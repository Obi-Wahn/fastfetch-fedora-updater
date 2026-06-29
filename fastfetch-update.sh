#!/bin/bash

# Striktes Fehlermanagement aktivieren
set -euo pipefail

# 1. Prüfen, ob die benötigten Werkzeuge vorhanden sind
command -v curl >/dev/null 2>&1 || { echo "Fehler: curl ist nicht installiert." >&2; exit 1; }
command -v dnf >/dev/null 2>&1 || { echo "Fehler: dnf ist nicht installiert. Dieses Skript erfordert Fedora/RHEL." >&2; exit 1; }

echo "Ermittle aktuellste Versionsnummer..."
# Dank pipefail bricht das Skript ab, falls curl fehlschlägt
VERSION=$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo "Fehler: Konnte die Versionsnummer von GitHub nicht extrahieren." >&2
    exit 1
fi

# Lokale Version abrufen (fängt ab, falls fastfetch nicht installiert ist)
LOCAL_VERSION=""
if command -v fastfetch >/dev/null 2>&1; then
    LOCAL_VERSION=$(fastfetch --version | awk '{print $2}')
fi

# Versionsvergleich
if [ "$LOCAL_VERSION" == "$VERSION" ]; then
    echo "Fastfetch ist bereits auf dem neuesten Stand ($LOCAL_VERSION)."
    exit 0
fi

echo "Neue Version verfügbar: $VERSION (lokal: ${LOCAL_VERSION:-nicht installiert})"

# 2. Sichere temporäre Datei erstellen
TMP_RPM=$(mktemp --suffix=.rpm)

# Trap sorgt dafür, dass die temporäre Datei IMMER gelöscht wird
trap 'rm -f "$TMP_RPM"' EXIT

# 3. Download
URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${VERSION}/fastfetch-linux-amd64.rpm"
echo "Lade Paket herunter..."
curl -fsSL --retry 3 -o "$TMP_RPM" "$URL"

# 4. Installation (fordert sudo erst hier an, wenn nötig)
echo "Installiere Update (fordert evtl. sudo an)..."
sudo dnf install -y "$TMP_RPM"

echo "------------------------------------------------"
echo "Update auf Version $VERSION erfolgreich abgeschlossen!"
echo "------------------------------------------------"
