#!/bin/bash

# Striktes Fehlermanagement aktivieren
set -euo pipefail

# 1. Prüfen, ob die benötigten Werkzeuge vorhanden sind
command -v curl >/dev/null 2>&1 || { echo "❌ Fehler: curl ist nicht installiert." >&2; exit 1; }
command -v dnf >/dev/null 2>&1 || { echo "❌ Fehler: dnf ist nicht installiert. Dieses Skript erfordert Fedora/RHEL." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Fehler: python3 ist nicht installiert." >&2; exit 1; }

echo "🔍 Ermittle aktuellste Versionsnummer für Fastfetch..."

# Zuverlässige JSON-Abfrage über Python (verhindert Fehler wie das Auslesen von Emojis/Reactions)
VERSION=$(python3 -c '
import urllib.request, json
try:
    req = urllib.request.urlopen("https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest")
    data = json.loads(req.read().decode())
    # Entfernt ein eventuelles "v" vor der Version, falls die Entwickler das Tag-Format ändern
    print(data["tag_name"].lstrip("v"))
except Exception:
    exit(1)
')

if [ -z "$VERSION" ]; then
    echo "❌ Fehler: Konnte die Versionsnummer von GitHub nicht extrahieren." >&2
    exit 1
fi

# Lokale Version abrufen und normalisieren
LOCAL_VERSION=""
LOCAL_VERSION_NORMALIZED=""
if command -v fastfetch >/dev/null 2>&1; then
    LOCAL_VERSION=$(fastfetch --version | awk '{print $2}')
    LOCAL_VERSION_NORMALIZED=$(echo "$LOCAL_VERSION" | tr '~' '-')
fi

# Versionsvergleich
if [ "$LOCAL_VERSION_NORMALIZED" == "$VERSION" ]; then
    echo "✅ Fastfetch ist bereits auf dem neuesten Stand ($LOCAL_VERSION)."
    exit 0
fi

echo "🔄 Neue Version verfügbar: $VERSION (lokal: ${LOCAL_VERSION:-nicht installiert})"

# 2. Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_RPM="$DEST_DIR/fastfetch-${VERSION}-linux-amd64.rpm"

# 3. Download
URL="https://github.com/fastfetch-cli/fastfetch/releases/download/${VERSION}/fastfetch-linux-amd64.rpm"
echo "⬇️ Lade Paket herunter in: $TARGET_RPM"
curl -fL -# --retry 3 -o "$TARGET_RPM" "$URL"

# Absicherung: Prüfen, ob die heruntergeladene Datei ein gültiges RPM-Paket ist
echo "🛡️ Prüfe Datei-Integrität (RPM-Struktur)..."
if ! rpm -qip "$TARGET_RPM" >/dev/null 2>&1; then
    echo "❌ Fehler: Die heruntergeladene Datei ist beschädigt oder kein gültiges RPM-Paket. Abbruch." >&2
    rm -f "$TARGET_RPM"
    exit 1
fi

# 4. Installation
echo "⚙️ Installiere Update (fordert evtl. sudo an)..."
sudo dnf install -y "$TARGET_RPM"

# 5. Aufräumen alter Versionen
echo "🧹 Entferne alte Fastfetch-Installationsdateien..."
find "$DEST_DIR" -maxdepth 1 -name "fastfetch-*.rpm" ! -name "$(basename "$TARGET_RPM")" -delete

echo "------------------------------------------------"
echo "✅ Update auf Version $VERSION erfolgreich abgeschlossen!"
echo "------------------------------------------------"
