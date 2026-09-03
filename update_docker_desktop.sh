#!/bin/bash

# Striktes Fehlermanagement aktivieren
set -euo pipefail

# 1. Prüfen, ob die benötigten Werkzeuge vorhanden sind
command -v curl >/dev/null 2>&1 || { echo "❌ Fehler: curl ist nicht installiert." >&2; exit 1; }
command -v dnf >/dev/null 2>&1 || { echo "❌ Fehler: dnf ist nicht installiert. Dieses Skript erfordert Fedora/RHEL." >&2; exit 1; }
command -v rpm >/dev/null 2>&1 || { echo "❌ Fehler: rpm ist nicht installiert." >&2; exit 1; }

echo "🔍 Suche nach der aktuellsten Docker Desktop Version..."

# 2. Architektur dynamisch ermitteln (Docker nutzt im Link amd64/arm64 und im Dateinamen x86_64/aarch64)
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    URL_ARCH="amd64"
    FILE_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    URL_ARCH="arm64"
    FILE_ARCH="aarch64"
else
    echo "❌ Fehler: Architektur $ARCH wird von diesem Skript nicht unterstützt." >&2
    exit 1
fi

NOTES_URL="https://docs.docker.com/desktop/release-notes/"

# 3. Webseite mit Timeout-Schutz abrufen, um unendliches Hängen zu vermeiden
if ! PAGE_CONTENT=$(curl --connect-timeout 10 -fsSL "$NOTES_URL"); then
    echo "❌ Fehler: Konnte die Docker Release Notes nicht abrufen (Timeout oder Netzwerkfehler)." >&2
    exit 1
fi

# 4. Den neuesten RPM-Downloadlink dynamisch auslesen
RPM_URL=$(echo "$PAGE_CONTENT" | grep -Eo "https://desktop\.docker\.com/linux/main/${URL_ARCH}/[0-9]+/docker-desktop-${FILE_ARCH}\.rpm" | head -n 1)

if [ -z "$RPM_URL" ]; then
    echo "❌ Fehler: Konnte den Fedora Download-Link für $ARCH in den Release Notes nicht finden." >&2
    exit 1
fi

# 5. Versionsnummer aus dem HTML-Text extrahieren
VERSION=$(echo "$PAGE_CONTENT" | grep -Eo '>[0-9]+\.[0-9]+\.[0-9]+<' | head -n 1 | tr -d '><')

if [ -z "$VERSION" ]; then
    echo "❌ Fehler: Konnte die Versionsnummer nicht aus der Webseite extrahieren." >&2
    exit 1
fi

# 6. Validierung der extrahierten Versionsnummer (Regex-Schutz)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Fehler: Die abgerufene Version '$VERSION' hat ein unerwartetes Format." >&2
    exit 1
fi

# 7. Lokale Version ermitteln und normalisieren
LOCAL_VERSION=""
LOCAL_VERSION_NORMALIZED=""
if rpm -q docker-desktop >/dev/null 2>&1; then
    LOCAL_VERSION=$(rpm -q --queryformat '%{VERSION}' docker-desktop)
    LOCAL_VERSION_NORMALIZED=$(echo "$LOCAL_VERSION" | tr '~' '-')
fi

# 8. Versionsabgleich
if [ "$LOCAL_VERSION_NORMALIZED" == "$VERSION" ]; then
    echo "✅ Docker Desktop ist bereits auf dem neuesten Stand ($LOCAL_VERSION)."
    exit 0
fi

echo "🔄 Neue Version verfügbar: $VERSION (lokal: ${LOCAL_VERSION:-nicht installiert})"

# 9. Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_RPM="$DEST_DIR/docker-desktop-${VERSION}-${FILE_ARCH}.rpm"

# 10. Download mit Fortschrittsanzeige, Fehlerprüfung und Timeout-Logik
echo "⬇️ Lade Paket herunter in: $TARGET_RPM"
if ! curl --connect-timeout 10 --max-time 120 -fL -# --retry 3 -o "$TARGET_RPM" "$RPM_URL"; then
    echo "❌ Fehler: Download fehlgeschlagen (Timeout oder Netzwerkfehler)." >&2
    rm -f "$TARGET_RPM"
    exit 1
fi

# Absicherung: Prüfen, ob die heruntergeladene Datei ein gültiges und unbeschädigtes RPM-Paket ist
echo "🛡️ Prüfe Datei-Integrität (RPM-Struktur)..."
if ! rpm -qip "$TARGET_RPM" >/dev/null 2>&1; then
    echo "❌ Fehler: Die heruntergeladene Datei ist beschädigt oder kein gültiges RPM-Paket. Abbruch." >&2
    rm -f "$TARGET_RPM" 
    exit 1
fi

# 11. Installation / Upgrade
echo "⚙️ Installiere Update (fordert evtl. sudo an)..."
sudo dnf install -y "$TARGET_RPM"

# 12. Aufräumen alter Versionen
echo "🧹 Entferne alte Docker-Desktop-Installationsdateien..."
find "$DEST_DIR" -maxdepth 1 -name "docker-desktop-*.rpm" ! -name "$(basename "$TARGET_RPM")" -delete

echo "------------------------------------------------"
echo "✅ Update auf Docker Desktop $VERSION erfolgreich abgeschlossen!"
echo "------------------------------------------------"