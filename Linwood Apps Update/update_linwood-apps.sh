#!/bin/bash

# Striktes Fehlermanagement
set -euo pipefail

# Prüfen, ob die benötigten Werkzeuge vorhanden sind
command -v curl >/dev/null 2>&1 || { echo "❌ Fehler: curl ist nicht installiert." >&2; exit 1; }
command -v dnf >/dev/null 2>&1 || { echo "❌ Fehler: dnf ist nicht installiert." >&2; exit 1; }
command -v rpm >/dev/null 2>&1 || { echo "❌ Fehler: rpm ist nicht installiert." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Fehler: python3 ist nicht installiert." >&2; exit 1; }

# Zielverzeichnis dynamisch auf den Speicherort dieses Skripts setzen
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Überprüfe Updates für Linwood Butterfly und Linwood Flow..."

# Architektur dynamisch ermitteln
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DL_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    DL_ARCH="aarch64"
else
    echo "❌ Fehler: Architektur $ARCH wird von diesem Skript nicht unterstützt." >&2
    exit 1
fi

# Funktion: Holt die neueste Version und Download-URL via Python
get_latest_release_info() {
    local REPO=$1
    local REPO_ARCH=$2
    python3 -c '
import urllib.request, json, sys, re
try:
    req = urllib.request.urlopen(f"https://api.github.com/repos/LinwoodDev/{sys.argv[1]}/releases")
    releases = json.loads(req.read().decode())

    for release in releases:
        version = release.get("tag_name", "").lstrip("v")

        # Prüfen auf normale Versionen ODER Beta-Versionen
        if re.match(r"^\d+\.\d+\.\d+", version):
            download_url = ""
            asset_suffix = f"linux-{sys.argv[2]}.rpm"
            for asset in release.get("assets", []):
                if asset["name"].endswith(asset_suffix):
                    download_url = asset["browser_download_url"]
                    break

            if download_url:
                print(f"{version}|{download_url}")
                exit(0)

    exit(1)
except Exception:
    exit(1)
' "$REPO" "$REPO_ARCH"
}

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
    if ! API_RESPONSE=$(get_latest_release_info "$REPO" "$DL_ARCH"); then
        echo "❌ Fehler: Konnte Release-Infos für $PKG_NAME nicht abrufen (API-Limit oder Netzwerkfehler)." >&2
        continue
    fi

    NEW_VERSION=$(echo "$API_RESPONSE" | cut -d'|' -f1)
    URL=$(echo "$API_RESPONSE" | cut -d'|' -f2)

    # Validierung der extrahierten Versionsnummer (inklusive Beta-Suffixe)
    if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([a-zA-Z0-9.-]+)?$ ]]; then
        echo "❌ Fehler: Die abgerufene Version '$NEW_VERSION' hat ein unerwartetes Format." >&2
        continue
    fi

    # Lokale Version abrufen und normalisieren
    LOCAL_VERSION=""
    LOCAL_VERSION_NORMALIZED=""

    if rpm -q "$PKG_NAME" >/dev/null 2>&1; then
        LOCAL_VERSION=$(rpm -q --queryformat '%{VERSION}' "$PKG_NAME")
        # Wandelt eine Tilde (~) in ein Minus (-) um, damit der Text-Vergleich mit GitHub klappt
        LOCAL_VERSION_NORMALIZED=$(echo "$LOCAL_VERSION" | tr '~' '-')
    fi

    echo "📦 Installierte Version ($PKG_NAME): ${LOCAL_VERSION:-nicht installiert}"
    echo "🆕 Neueste verfügbare Version:       ${NEW_VERSION}"

    # Abgleich mit der normalisierten Version
    if [ "$LOCAL_VERSION_NORMALIZED" == "$NEW_VERSION" ]; then
        echo "✅ $PKG_NAME ist bereits auf dem neuesten Stand. Es ist kein Update nötig."
        continue
    fi

    echo "🔄 Update verfügbar! Starte Download..."
    TARGET_RPM="$DEST_DIR/${PKG_NAME}-${NEW_VERSION}-linux-${DL_ARCH}.rpm"

    echo "⬇️ Lade Paket von $URL herunter..."
    # Timeout und Retry-Sicherung hinzugefügt
    if ! curl --connect-timeout 10 --max-time 120 -fL -# --retry 3 -o "$TARGET_RPM" "$URL"; then
         echo "❌ Fehler beim Download (Timeout oder Netzwerkfehler)." >&2
         rm -f "$TARGET_RPM"
         continue
    fi

    echo "🛡️ Prüfe Datei-Integrität (RPM-Struktur)..."
    if ! rpm -qip "$TARGET_RPM" >/dev/null 2>&1; then
        echo "❌ Fehler: Die heruntergeladene Datei ist beschädigt." >&2
        rm -f "$TARGET_RPM"
        continue
    fi

    echo "⚙️ Installiere Update für $PKG_NAME (fordert evtl. sudo an)..."
    sudo dnf install -y "$TARGET_RPM"

    echo "🧹 Entferne alte Installationsdateien für $PKG_NAME..."
    find "$DEST_DIR" -maxdepth 1 -name "${PKG_NAME}-*.rpm" ! -name "$(basename "$TARGET_RPM")" -delete

    echo "✅ Installation von $PKG_NAME ($NEW_VERSION) erfolgreich abgeschlossen!"
done

echo "------------------------------------------------"
echo "🎉 Alle Vorgänge abgeschlossen."