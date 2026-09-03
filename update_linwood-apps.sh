#!/bin/bash

# Striktes Fehlermanagement
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Prüfen, ob die benötigten Werkzeuge vorhanden sind
require_cmd curl "curl ist nicht installiert."
require_cmd dnf "dnf ist nicht installiert."
require_cmd rpm "rpm ist nicht installiert."
require_cmd python3 "python3 ist nicht installiert."

# Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$SCRIPT_DIR"

echo "🔍 Überprüfe Updates für Linwood Butterfly und Linwood Flow..."

# Architektur dynamisch ermitteln
DL_ARCH=$(detect_arch "x86_64" "aarch64") || exit 1

# Apps definieren: "Repository-Name|Installierter-Paketname"
APPS=(
    "butterfly|linwood-butterfly"
    "Flow|linwood-flow"
)

for APP in "${APPS[@]}"; do
    echo "------------------------------------------------"
    IFS='|' read -r REPO PKG_NAME <<< "$APP"

    echo "🌐 Frage GitHub-API für $PKG_NAME ab..."

    # Fehleranfällige Zuweisung ersetzt durch saubere Fehlerabfangung für API-Abbrüche
    if ! API_RESPONSE=$(find_latest_github_rpm_release "LinwoodDev/$REPO" "linux-${DL_ARCH}.rpm"); then
        echo "❌ Fehler: Konnte Release-Infos für $PKG_NAME nicht abrufen (siehe Ursache oben, oder API-Limit erreicht)." >&2
        continue
    fi

    NEW_VERSION=$(echo "$API_RESPONSE" | cut -d'|' -f1)
    URL=$(echo "$API_RESPONSE" | cut -d'|' -f2)

    # Validierung der extrahierten Versionsnummer (inklusive Beta-Suffixe)
    validate_version "$NEW_VERSION" || continue

    # Lokale Version abrufen und normalisieren
    LOCAL_VERSION=""
    LOCAL_VERSION_NORMALIZED=""

    if rpm -q "$PKG_NAME" >/dev/null 2>&1; then
        LOCAL_VERSION=$(rpm -q --queryformat '%{VERSION}' "$PKG_NAME")
        LOCAL_VERSION_NORMALIZED=$(normalize_version "$LOCAL_VERSION")
    fi

    echo "📦 Installierte Version ($PKG_NAME): ${LOCAL_VERSION:-nicht installiert}"
    echo "🆕 Neueste verfügbare Version:       ${NEW_VERSION}"

    # Abgleich mit der normalisierten Version (inkl. Downgrade-Schutz)
    if ! version_needs_update "$LOCAL_VERSION_NORMALIZED" "$NEW_VERSION"; then
        echo "✅ $PKG_NAME ist bereits aktuell. Es ist kein Update nötig."
        continue
    fi

    echo "🔄 Update verfügbar! Starte Download..."
    TARGET_RPM="$DEST_DIR/${PKG_NAME}-${NEW_VERSION}-linux-${DL_ARCH}.rpm"

    echo "⬇️ Lade Paket von $URL herunter..."
    trap_download_cleanup "$TARGET_RPM"
    if ! download_rpm "$URL" "$TARGET_RPM"; then
        clear_download_trap
        continue
    fi
    clear_download_trap

    if ! verify_rpm "$TARGET_RPM"; then
        continue
    fi

    echo "⚙️ Installiere Update für $PKG_NAME (fordert evtl. sudo an)..."
    sudo dnf install -y "$TARGET_RPM"

    echo "🧹 Entferne alte Installationsdateien für $PKG_NAME..."
    cleanup_old_rpms "$DEST_DIR" "${PKG_NAME}-*.rpm" "$(basename "$TARGET_RPM")"

    echo "✅ Installation von $PKG_NAME ($NEW_VERSION) erfolgreich abgeschlossen!"
done

echo "------------------------------------------------"
echo "🎉 Alle Vorgänge abgeschlossen."
