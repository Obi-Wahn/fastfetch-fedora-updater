#!/bin/bash

# Striktes Fehlermanagement aktivieren
set -euo pipefail

# Prüfen, ob die benötigten Werkzeuge vorhanden sind
command -v curl >/dev/null 2>&1 || { echo "❌ Fehler: curl ist nicht installiert." >&2; exit 1; }
command -v dnf >/dev/null 2>&1 || { echo "❌ Fehler: dnf ist nicht installiert. Dieses Skript erfordert Fedora." >&2; exit 1; }
command -v rpm >/dev/null 2>&1 || { echo "❌ Fehler: rpm ist nicht installiert." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Fehler: python3 ist nicht installiert." >&2; exit 1; }

echo "🔍 Überprüfe auf neue Moonfin-Versionen..."

# Architektur dynamisch ermitteln (mit Positiv- und Negativ-Listen)
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DL_ARCH="x86_64"
    VALID_ARCHS="x86_64 amd64 x64"
    INVALID_ARCHS="aarch64 arm64 armv"
elif [ "$ARCH" = "aarch64" ]; then
    DL_ARCH="aarch64"
    VALID_ARCHS="aarch64 arm64"
    INVALID_ARCHS="x86_64 amd64 x64"
else
    echo "❌ Fehler: Architektur $ARCH wird von diesem Skript nicht unterstützt." >&2
    exit 1
fi

# API abfragen (Mit intelligentem Ausschlussverfahren)
if ! API_RESPONSE=$(python3 -c '
import urllib.request, json, sys, re
try:
    req = urllib.request.urlopen("https://api.github.com/repos/Moonfin-Client/Moonfin-Core/releases/latest")
    data = json.loads(req.read().decode())
    version = data.get("tag_name", "").lstrip("v")

    valid_archs = sys.argv[1].split()
    invalid_archs = sys.argv[2].split()
    download_url = ""

    # 1. Priorität: Exakter Architektur-Treffer im Dateinamen
    for asset in data.get("assets", []):
        name = asset.get("name", "").lower()
        if name.endswith(".rpm") and any(a in name for a in valid_archs):
            download_url = asset["browser_download_url"]
            break

    # 2. Priorität: Fallback auf ein RPM-Paket, das KEINE falsche Architektur im Namen trägt
    if not download_url:
        for asset in data.get("assets", []):
            name = asset.get("name", "").lower()
            if name.endswith(".rpm") and not any(i in name for i in invalid_archs):
                download_url = asset["browser_download_url"]
                break

    if download_url:
        print(f"{version}|{download_url}")
        exit(0)
    exit(1)
except Exception:
    exit(1)
' "$VALID_ARCHS" "$INVALID_ARCHS"); then
    echo "❌ Fehler: Konnte kein passendes RPM-Paket für $ARCH auf GitHub finden (oder API-Limit erreicht)." >&2
    exit 1
fi

LATEST_VERSION=$(echo "$API_RESPONSE" | cut -d'|' -f1)
LATEST_URL=$(echo "$API_RESPONSE" | cut -d'|' -f2)

# Validierung der extrahierten Versionsnummer
if [[ ! "$LATEST_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([a-zA-Z0-9.-]+)?$ ]]; then
    echo "❌ Fehler: Die abgerufene Version '$LATEST_VERSION' hat ein unerwartetes Format." >&2
    exit 1
fi

# Lokale Version abrufen und normalisieren
LOCAL_VERSION=""
LOCAL_VERSION_NORMALIZED=""
if rpm -q moonfin >/dev/null 2>&1; then
    LOCAL_VERSION=$(rpm -q --queryformat '%{VERSION}\n' moonfin)
    LOCAL_VERSION_NORMALIZED=$(echo "$LOCAL_VERSION" | tr '~' '-')
fi

echo "📦 Installierte Version: ${LOCAL_VERSION:-nicht installiert}"
echo "🌐 Neueste Version:      ${LATEST_VERSION}"

# Versionsvergleich (mit normalisierter Version)
if [ "$LOCAL_VERSION_NORMALIZED" == "$LATEST_VERSION" ]; then
    echo "✅ Du hast bereits die aktuellste Version installiert. Es ist kein Update nötig."
    exit 0
fi

# Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_RPM="$DEST_DIR/moonfin-${LATEST_VERSION}-${DL_ARCH}.rpm"

echo "⬇️ Lade RPM-Paket herunter in: $TARGET_RPM"
if ! curl --connect-timeout 10 --max-time 120 --http3 -4 -fL -# --retry 3 -o "$TARGET_RPM" "$LATEST_URL"; then
    echo "❌ Fehler beim Download (Timeout oder Netzwerkfehler)." >&2
    rm -f "$TARGET_RPM"
    exit 1
fi

# Absicherung: Prüfen, ob die heruntergeladene Datei ein gültiges RPM-Paket ist
echo "🛡️ Prüfe Datei-Integrität (RPM-Struktur)..."
if ! rpm -qip "$TARGET_RPM" >/dev/null 2>&1; then
    echo "❌ Fehler: Die heruntergeladene Datei ist beschädigt oder kein gültiges RPM-Paket. Abbruch." >&2
    rm -f "$TARGET_RPM"
    exit 1
fi

echo "⚙️ Installiere Update (fordert evtl. sudo an)..."
sudo dnf install -y "$TARGET_RPM"

# Aufräumen alter Versionen
echo "🧹 Entferne alte Moonfin-Installationsdateien..."
find "$DEST_DIR" -maxdepth 1 -name "moonfin-*.rpm" ! -name "$(basename "$TARGET_RPM")" -delete

echo "------------------------------------------------"
echo "✅ Installation von Moonfin $LATEST_VERSION erfolgreich abgeschlossen!"
echo "------------------------------------------------"
