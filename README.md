# Fastfetch Fedora Updater

Dieses Repository stellt ein automatisiertes Bash-Skript zur Verfügung, um das Systeminformationstool [Fastfetch](https://github.com/fastfetch-cli/fastfetch) auf Fedora Linux stets auf dem neuesten Stand zu halten. Da die offiziellen Paketquellen von Distributionen gelegentlich verzögert aktualisiert werden, bezieht dieses Skript das jeweils aktuellste `.rpm`-Release (für die `x86_64`-Architektur) direkt über die GitHub-API.

## Funktionen

- **Versionsabgleich:** Prüft die lokal installierte Version gegen das neueste GitHub-Release, um unnötige Downloads zu vermeiden.
- **Sicherheitsstandards:** Nutzt `mktemp` für temporäre Dateien und `trap` für garantiertes Aufräumen, selbst bei Verbindungsabbrüchen oder manuellen Abbrüchen (Ctrl+C).
- **Strikte Fehlerbehandlung:** Implementiert `set -euo pipefail` sowie Retry-Logiken für Netzwerkverbindungen (`curl`).
- **User-Space First:** Das Skript erfordert bei der Ausführung zunächst keine Root-Rechte. Privilegien werden via `sudo` erst im allerletzten Schritt für den `dnf install`-Befehl angefordert.

## Systemvoraussetzungen

- **Betriebssystem:** Fedora Linux (oder kompatible RHEL-Derivate)
- **Architektur:** `x86_64` (amd64)
- **Abhängigkeiten:** `bash`, `curl`, `dnf`, `awk`

## Installation und Nutzung

1. Das Repository klonen oder das Skript direkt herunterladen:
   ```bash
   git clone [https://github.com/Obi-Wahn/fastfetch-fedora-updater.git](https://github.com/Obi-Wahn/fastfetch-fedora-updater.git)
   cd fastfetch-fedora-updater
