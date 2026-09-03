#!/bin/bash

# Striktes Fehlermanagement aktivieren
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Prüfen, ob die benötigten Werkzeuge vorhanden sind
require_cmd curl "curl ist nicht installiert."
require_cmd dnf "dnf ist nicht installiert."
require_cmd rpm "rpm ist nicht installiert."
require_cmd python3 "python3 ist nicht installiert."

echo "🔍 Suche nach der neuesten OpenLogi-Version mit verfügbarem RPM-Paket..."

# Architektur dynamisch ermitteln
DL_ARCH=$(detect_arch "amd64" "arm64") || exit 1

# API-Abfrage mit sicherem Error-Handling
if ! READ_DATA=$(python3 -c '
import urllib.request, json, sys
try:
    req = urllib.request.urlopen("https://api.github.com/repos/AprilNEA/OpenLogi/releases", timeout=15)
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
except Exception as e:
    print(f"{type(e).__name__}: {e}", file=sys.stderr)
    exit(1)
' "$DL_ARCH"); then
    echo "❌ Fehler: Konnte in den GitHub-Releases kein passendes RPM-Paket finden (siehe Ursache oben, oder API-Limit erreicht)." >&2
    exit 1
fi

LATEST_VERSION=$(echo "$READ_DATA" | cut -d'|' -f1)
LATEST_URL=$(echo "$READ_DATA" | cut -d'|' -f2)

# Validierung der extrahierten Versionsnummer (Regex-Schutz)
validate_version "$LATEST_VERSION" || exit 1

LOCAL_VERSION=""
LOCAL_VERSION_NORMALIZED=""
if rpm -q openlogi >/dev/null 2>&1; then
    LOCAL_VERSION=$(rpm -q --queryformat '%{VERSION}\n' openlogi)
    LOCAL_VERSION_NORMALIZED=$(normalize_version "$LOCAL_VERSION")
fi

echo "📦 Installierte Version: ${LOCAL_VERSION:-none}"
echo "🌐 Neueste verfügbare Version mit RPM: ${LATEST_VERSION}"

# Versionsvergleich (inkl. Downgrade-Schutz)
if ! version_needs_update "$LOCAL_VERSION_NORMALIZED" "$LATEST_VERSION"; then
    echo "✅ Du hast bereits die aktuellste Version mit RPM-Paket installiert. Es ist kein Update nötig."
    exit 0
fi

echo "🔄 Ein Update auf Version $LATEST_VERSION ist verfügbar! Starte Download..."

# Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$SCRIPT_DIR"
TARGET_RPM="$DEST_DIR/openlogi-${LATEST_VERSION}-linux-${DL_ARCH}.rpm"

echo "⬇️ Lade RPM-Paket herunter in: $TARGET_RPM"
trap_download_cleanup "$TARGET_RPM"
download_rpm "$LATEST_URL" "$TARGET_RPM" || exit 1
clear_download_trap

verify_rpm "$TARGET_RPM" || exit 1

echo "⚙️ Installiere Update (fordert evtl. sudo an)..."
sudo dnf install -y "$TARGET_RPM"

# Alte Versionen bereinigen
echo "🧹 Entferne alte OpenLogi-Installationsdateien..."
cleanup_old_rpms "$DEST_DIR" "openlogi-*.rpm" "$(basename "$TARGET_RPM")"

echo "------------------------------------------------"
echo "✅ Update auf OpenLogi $LATEST_VERSION erfolgreich abgeschlossen!"
echo "------------------------------------------------"
