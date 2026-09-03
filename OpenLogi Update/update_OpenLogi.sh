#!/bin/bash

# Striktes Fehlermanagement aktivieren
set -euo pipefail

# Prüfen, ob die benötigten Werkzeuge vorhanden sind
command -v curl >/dev/null 2>&1 || { echo "❌ Fehler: curl ist nicht installiert." >&2; exit 1; }
command -v dnf >/dev/null 2>&1 || { echo "❌ Fehler: dnf ist nicht installiert." >&2; exit 1; }
command -v rpm >/dev/null 2>&1 || { echo "❌ Fehler: rpm ist nicht installiert." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Fehler: python3 ist nicht installiert." >&2; exit 1; }

echo "🔍 Suche nach der neuesten OpenLogi-Version mit verfügbarem RPM-Paket..."

# Architektur dynamisch ermitteln
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DL_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    DL_ARCH="arm64"
else
    echo "❌ Fehler: Architektur $ARCH wird von diesem Skript nicht unterstützt." >&2
    exit 1
fi

# API-Abfrage mit sicherem Error-Handling
if ! READ_DATA=$(python3 -c '
import urllib.request, json, sys
try:
    req = urllib.request.urlopen("https://api.github.com/repos/AprilNEA/OpenLogi/releases")
    releases = json.loads(req.read().decode())
    target_arch = sys.argv[1]
    
    for rel in releases:
        for asset in rel.get("assets", []):
            name = asset.get("name", "")
            if name.endswith(f"linux-{target_arch}.rpm"):
                tag = rel.get("tag_name", "").lstrip("v")
                url = asset["browser_download_url"]
                print(f"{tag}|{url}")
                exit(0)
    exit(1)
except Exception:
    exit(1)
' "$DL_ARCH"); then
    echo "❌ Fehler: Konnte in den GitHub-Releases kein passendes RPM-Paket finden (API-Limit oder Netzwerkfehler)." >&2
    exit 1
fi

LATEST_VERSION=$(echo "$READ_DATA" | cut -d'|' -f1)
LATEST_URL=$(echo "$READ_DATA" | cut -d'|' -f2)

# Validierung der extrahierten Versionsnummer (Regex-Schutz)
if [[ ! "$LATEST_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([a-zA-Z0-9.-]+)?$ ]]; then
    echo "❌ Fehler: Die abgerufene Version '$LATEST_VERSION' hat ein unerwartetes Format." >&2
    exit 1
fi

LOCAL_VERSION=""
LOCAL_VERSION_NORMALIZED=""
if rpm -q openlogi >/dev/null 2>&1; then
    LOCAL_VERSION=$(rpm -q --queryformat '%{VERSION}\n' openlogi)
    LOCAL_VERSION_NORMALIZED=$(echo "$LOCAL_VERSION" | tr '~' '-')
fi

echo "📦 Installierte Version: ${LOCAL_VERSION:-none}"
echo "🌐 Neueste verfügbare Version mit RPM: ${LATEST_VERSION}"

# Versionsvergleich (mit normalisierter Version)
if [ "$LOCAL_VERSION_NORMALIZED" == "$LATEST_VERSION" ]; then
    echo "✅ Du hast bereits die aktuellste Version mit RPM-Paket installiert. Es ist kein Update nötig."
    exit 0
fi

echo "🔄 Ein Update auf Version $LATEST_VERSION ist verfügbar! Starte Download..."

# Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_RPM="$DEST_DIR/openlogi-${LATEST_VERSION}-linux-${DL_ARCH}.rpm"

echo "⬇️ Lade RPM-Paket herunter in: $TARGET_RPM"
if ! curl --connect-timeout 10 --max-time 120 -fL -# --retry 3 -o "$TARGET_RPM" "$LATEST_URL"; then
    echo "❌ Fehler beim Download (Timeout oder Netzwerkfehler)." >&2
    rm -f "$TARGET_RPM"
    exit 1
fi

echo "🛡️ Prüfe Datei-Integrität (RPM-Struktur)..."
if ! rpm -qip "$TARGET_RPM" >/dev/null 2>&1; then
    echo "❌ Fehler: Die heruntergeladene Datei ist kein gültiges RPM-Paket." >&2
    rm -f "$TARGET_RPM"
    exit 1
fi

echo "⚙️ Installiere Update (fordert evtl. sudo an)..."
sudo dnf install -y "$TARGET_RPM"

# Alte Versionen bereinigen
echo "🧹 Entferne alte OpenLogi-Installationsdateien..."
find "$DEST_DIR" -maxdepth 1 -name "openlogi-*.rpm" ! -name "$(basename "$TARGET_RPM")" -delete

echo "------------------------------------------------"
echo "✅ Update auf OpenLogi $LATEST_VERSION erfolgreich abgeschlossen!"
echo "------------------------------------------------"