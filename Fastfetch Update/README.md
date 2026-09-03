# **Fastfetch Fedora Updater**

Dieses Repository stellt ein automatisiertes Bash-Skript zur Verfügung, um das Systeminformationstool [Fastfetch](https://github.com/fastfetch-cli/fastfetch) auf Fedora Linux stets auf dem neuesten Stand zu halten. Da die offiziellen Paketquellen von Distributionen gelegentlich verzögert aktualisiert werden, bezieht dieses Skript das jeweils aktuellste .rpm-Release (für die x86_64-Architektur) direkt über die GitHub-API.

## **Funktionen**

* **Intelligenter Versionsabgleich:** Prüft die lokal installierte Version gegen das neueste GitHub-Release, um unnötige Downloads zu vermeiden. Beinhaltet eine Normalisierung von Tilden (`~` zu `-`), um Vorabversionen aus den Paketquellen sauber mit den GitHub-Tags abzugleichen.
* **Robuste API-Abfrage:** Nutzt ein Python-basiertes JSON-Parsing für die Kommunikation mit der GitHub-API. Dies verhindert zuverlässig Auslesefehler, die bei reinem Text-Parsing (z. B. durch Emojis in Release-Notes) entstehen können.
* **Dynamische Dateiverwaltung & Auto-Cleanup:** Das Skript speichert das heruntergeladene RPM-Paket dauerhaft in exakt dem Verzeichnis, in dem das Skript selbst ausgeführt wird. Veraltete Fastfetch-Installationsdateien im selben Ordner werden nach einem erfolgreichen Update automatisch bereinigt.
* **Sicherheitsstandards & Integritätsprüfung:** Bevor Systemrechte angefordert werden, wird die Struktur des Downloads via `rpm -qip` auf Beschädigungen geprüft. Zudem implementiert das Skript ein striktes Fehlermanagement (`set -euo pipefail`) sowie Retry-Logiken für Netzwerkverbindungen (`curl`).
* **User-Space First:** Das Skript erfordert bei der Ausführung zunächst keine Root-Rechte. Privilegien werden via `sudo` erst im allerletzten Schritt für den Installations-Befehl angefordert.

## **Systemvoraussetzungen**

* **Betriebssystem:** Fedora Linux (oder kompatible RHEL-Derivate)
* **Architektur:** x86_64 (amd64)
* **Abhängigkeiten:** `bash`, `curl`, `dnf`, `rpm`, `awk`, `python3`

## **Installation und Nutzung**

1. Das Repository klonen oder das Skript direkt herunterladen:
   ```bash
   git clone https://github.com/Obi-Wahn/fastfetch-fedora-updater.git
   cd fastfetch-fedora-updater
   ```

2. Das Skript ausführbar machen:
   ```bash
   chmod +x update_fastfetch.sh
   ```

3. Das Skript starten:
   ```bash
   ./update_fastfetch.sh
   ```

   *Hinweis: Wenn ein Update verfügbar ist, wird für den Installationsprozess das sudo-Passwort abgefragt.*

## **Hinweis zur Entwicklung (KI-Transparenz)**

Der Quellcode dieses Skripts sowie Teile dieser Dokumentation wurden in Zusammenarbeit mit generativen KI-Modellen (Large Language Models) iterativ entwickelt, auf Robustheit geprüft und optimiert.

## **Lizenz**

Dieses Projekt ist Open Source und steht unter der [MIT-Lizenz](https://opensource.org/license/mit). Es kann frei verwendet, modifiziert und weitergegeben werden.
