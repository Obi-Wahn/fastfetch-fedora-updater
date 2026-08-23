#!/bin/bash

# Striktes Fehlermanagement aktivieren
set -euo pipefail

# 1. Prüfen, ob die benötigten Werkzeuge vorhanden sind
command -v curl >/dev/null 2>&1 || { echo "Fehler: curl ist nicht installiert." >&2; exit 1; }
command -v dnf >/dev/null 2>&1 || { echo "Fehler: dnf ist nicht installiert. Dieses Skript erfordert Fedora/RHEL." >&2; exit 1; }

echo "Ermittle aktuellste Versionsnummer..."
VERSION=$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo "Fehler: Konnte die Versionsnummer von GitHub nicht extrahieren." >&2
    exit 1
fi

# Lokale Version abrufen
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

# 2. Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_RPM="$DEST_DIR/fastfetch-${VERSION}-linux-amd64.rpm"

# 3. Download
URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${VERSION}/fastfetch-linux-amd64.rpm"
echo "Lade Paket herunter in: $TARGET_RPM"
curl -fsSL --retry 3 -o "$TARGET_RPM" "$URL"

# Absicherung: Prüfen, ob die heruntergeladene Datei ein gültiges RPM-Paket ist
echo "Prüfe Datei-Integrität..."
if ! rpm -qip "$TARGET_RPM" >/dev/null 2>&1; then
    echo "Fehler: Die heruntergeladene Datei ist beschädigt oder kein gültiges RPM-Paket. Abbruch." >&2
    rm -f "$TARGET_RPM"
    exit 1
fi

# 4. Installation
echo "Installiere Update (fordert evtl. sudo an)..."
sudo dnf install -y "$TARGET_RPM"

# 5. Aufräumen alter Versionen
echo "Entferne alte Fastfetch-Installationsdateien..."
find "$DEST_DIR" -maxdepth 1 -name "fastfetch-*.rpm" ! -name "$(basename "$TARGET_RPM")" -delete

echo "------------------------------------------------"
echo "Update auf Version $VERSION erfolgreich abgeschlossen!"
echo "------------------------------------------------"
