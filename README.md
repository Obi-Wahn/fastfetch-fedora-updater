# Fedora App Updater

Eine Sammlung von Bash-Skripten, die Anwendungen unter Fedora Linux aktuell halten, deren Updates nicht (zeitnah) über die offiziellen Paketquellen (`dnf`) verfügbar sind. Jedes Skript prüft die neueste verfügbare Version (meist über die GitHub-API oder die offizielle Release-Seite), vergleicht sie mit der lokal installierten Version und installiert bei Bedarf automatisch das passende `.rpm`-Paket.

## Enthaltene Updater

| Skript | Aktualisiert |
| --- | --- |
| `update_fastfetch.sh` | [Fastfetch](https://github.com/fastfetch-cli/fastfetch) über die GitHub-Releases |
| `update_docker_desktop.sh` | [Docker Desktop](https://www.docker.com/products/docker-desktop/) über die offiziellen Release Notes |
| `update_linwood-apps.sh` | [Linwood Butterfly](https://github.com/LinwoodDev/butterfly) & [Linwood Flow](https://github.com/LinwoodDev/Flow) über die GitHub-Releases |
| `update_moonfin.sh` | [Moonfin](https://github.com/Moonfin-Client/Moonfin-Core) über die GitHub-Releases |
| `update_OpenLogi.sh` | [OpenLogi](https://github.com/AprilNEA/OpenLogi) über die GitHub-Releases |

Alle Skripte liegen direkt im Wurzelverzeichnis. Für Moonfin liegt zusätzlich eine Einrichtungsanleitung bei: [`Anleitung_ Moonfin auf Fedora 44 einrichten.docx`](./Anleitung_%20Moonfin%20auf%20Fedora%2044%20einrichten.docx).

## Gemeinsame Funktionsweise

Alle Skripte folgen demselben Muster:

* **Architekturerkennung:** Ermittelt per `uname -m` automatisch, ob x86_64 oder aarch64 vorliegt, und wählt das passende `.rpm`-Paket.
* **Versionsabgleich:** Vergleicht die installierte Version (per `rpm -q` bzw. dem jeweiligen `--version`-Aufruf) mit der neuesten verfügbaren Version. Ist bereits alles aktuell, bricht das Skript ohne Download ab.
* **Robuste API-/Web-Abfrage:** Nutzt Python (`urllib`/`json`) für zuverlässiges JSON-Parsing der GitHub-API bzw. `curl` mit Timeouts (`--connect-timeout`, `--max-time`) und Retry-Logik (`--retry`) für Downloads und Webseiten-Abfragen.
* **Validierung:** Prüft die extrahierte Versionsnummer per Regex, bevor sie in Dateinamen oder URLs verwendet wird.
* **Integritätsprüfung:** Verifiziert jedes heruntergeladene Paket vor der Installation mit `rpm -qip` auf eine gültige RPM-Struktur.
* **User-Space First:** Download und Prüfung laufen ohne Root-Rechte; `sudo` wird nur für den finalen `dnf install`-Schritt angefordert.
* **Striktes Fehlermanagement:** Jedes Skript nutzt `set -euo pipefail` und bricht bei Fehlern sauber mit einer verständlichen Meldung ab.
* **Dateiverwaltung:** RPM-Pakete werden in das jeweilige Skriptverzeichnis heruntergeladen; nach einem erfolgreichen Update werden ältere Pakete desselben Programms automatisch entfernt.

## `update_all.sh` – alle Updates auf einmal

`update_all.sh` führt alle `update_*.sh`-Skripte im selben Verzeichnis nacheinander aus:

```bash
chmod +x update_all.sh
./update_all.sh
```

Dabei wird einmalig `sudo`-Zugriff angefordert und im Hintergrund wachgehalten, sodass die einzelnen Skripte nicht mehrfach nach dem Passwort fragen. Vor jeder Ausführung prüft `update_all.sh`, ob das jeweilige Skript dem aktuellen Nutzer gehört und ausführbar ist; andernfalls wird es übersprungen. Am Ende gibt es eine Zusammenfassung fehlgeschlagener Updates aus und beendet sich mit einem entsprechenden Exit-Code.

## Einzelne Skripte ausführen

Jedes Skript lässt sich auch unabhängig von `update_all.sh` starten:

```bash
chmod +x update_fastfetch.sh
./update_fastfetch.sh
```

## Systemvoraussetzungen

* **Betriebssystem:** Fedora Linux (oder kompatible RHEL-Derivate)
* **Architektur:** x86_64 oder aarch64
* **Abhängigkeiten:** `bash`, `curl`, `dnf`, `rpm`, `python3` (je nach Skript zusätzlich `awk`, `grep`, `sed`)

## Hinweis zur Entwicklung (KI-Transparenz)

Der Quellcode dieser Skripte sowie Teile dieser Dokumentation wurden in Zusammenarbeit mit generativen KI-Modellen (Large Language Models) iterativ entwickelt, auf Robustheit geprüft und optimiert.

## Lizenz

Dieses Projekt ist Open Source und steht unter der [MIT-Lizenz](./LICENSE). Es kann frei verwendet, modifiziert und weitergegeben werden.
