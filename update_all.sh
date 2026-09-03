#!/bin/bash

# Striktes Fehlermanagement
set -euo pipefail
# Verhindert fehlerhafte Schleifen, wenn keine Skripte existieren
shopt -s nullglob

echo "🚀 Starte das globale Update-Programm..."

# Einmal vorab sudo-Rechte anfordern
sudo -v

# Sudo-Keepalive im Hintergrund mit sauberem Cleanup (Punkt 1)
SUDO_PID=""
trap '[ -n "$SUDO_PID" ] && kill "$SUDO_PID" 2>/dev/null || true' EXIT
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!

# Verzeichnis dynamisch auf den Speicherort dieses Skripts setzen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Array für fehlgeschlagene Skripte (Punkt 2)
FAILED=()

# Alle "update_*.sh"-Skripte eine Ebene tiefer suchen, z.B. "Fastfetch Update/update_fastfetch.sh"
# (mindepth/maxdepth 2 schließt dieses Master-Skript im Wurzelverzeichnis automatisch aus)
while IFS= read -r -d '' script; do

    CLEAN_NAME=$(basename "$(dirname "$script")")

    echo "========================================"
    echo "🔄 Führe aus: $CLEAN_NAME"

    # Sicherheitsprüfung: Gehört das Skript dem aktuellen Nutzer? (Punkt 3)
    if [ ! -O "$script" ]; then
        echo "⚠️ Übersprungen: Skript gehört nicht dir (Sicherheitsrisiko)."
        continue
    fi

    # Ausführbarkeitsprüfung (Punkt 4)
    if [ ! -x "$script" ]; then
        echo "⚠️ Übersprungen: Skript ist nicht ausführbar (chmod +x fehlt)."
        continue
    fi

    # Das Skript ausführen und bei Fehler erfassen (Punkt 2)
    if ! "$script"; then
        echo "⚠️ Fehler bei $CLEAN_NAME aufgetreten."
        FAILED+=("$CLEAN_NAME")
    fi
done < <(find "$SCRIPT_DIR" -mindepth 2 -maxdepth 2 -type f -name "update_*.sh" -print0 | sort -z)

echo "========================================"

# Fehler-Zusammenfassung und Exit-Code (Punkt 2)
if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "❌ Abschluss mit Fehlern! Folgende Updates sind fehlgeschlagen:"
    for failed_script in "${FAILED[@]}"; do
        echo "   - $failed_script"
    done
    exit 1
else
    echo "🎉 Alle Update-Vorgänge wurden erfolgreich abgeschlossen!"
fi
