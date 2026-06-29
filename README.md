# **Fastfetch Fedora Updater**

Dieses Repository stellt ein automatisiertes Bash-Skript zur Verfügung, um das Systeminformationstool [Fastfetch](https://github.com/fastfetch-cli/fastfetch) auf Fedora Linux stets auf dem neuesten Stand zu halten. Da die offiziellen Paketquellen von Distributionen gelegentlich verzögert aktualisiert werden, bezieht dieses Skript das jeweils aktuellste .rpm-Release (für die x86\_64-Architektur) direkt über die GitHub-API.

## **Funktionen**

* **Versionsabgleich:** Prüft die lokal installierte Version gegen das neueste GitHub-Release, um unnötige Downloads zu vermeiden.  
* **Sicherheitsstandards:** Nutzt mktemp für temporäre Dateien und trap für garantiertes Aufräumen, selbst bei Verbindungsabbrüchen oder manuellen Abbrüchen (Ctrl+C).  
* **Strikte Fehlerbehandlung:** Implementiert set \-euo pipefail sowie Retry-Logiken für Netzwerkverbindungen (curl).  
* **User-Space First:** Das Skript erfordert bei der Ausführung zunächst keine Root-Rechte. Privilegien werden via sudo erst im allerletzten Schritt für den dnf install-Befehl angefordert.

## **Systemvoraussetzungen**

* **Betriebssystem:** Fedora Linux (oder kompatible RHEL-Derivate)  
* **Architektur:** x86\_64 (amd64)  
* **Abhängigkeiten:** bash, curl, dnf, awk

## **Installation und Nutzung**

1. Das Repository klonen oder das Skript direkt herunterladen:  
   git clone \[https://github.com/Obi-Wahn/fastfetch-fedora-updater.git\](https://github.com/Obi-Wahn/fastfetch-fedora-updater.git)  
   cd fastfetch-fedora-updater

2. Das Skript ausführbar machen:  
   chmod \+x update-fastfetch.sh

3. Das Skript starten:  
   ./update-fastfetch.sh

   *Hinweis: Wenn ein Update verfügbar ist, wird für den Installationsprozess das sudo-Passwort abgefragt.*

## **Hinweis zur Entwicklung (KI-Transparenz)**

Der Quellcode dieses Skripts sowie Teile dieser Dokumentation wurden in Zusammenarbeit mit generativen KI-Modellen (Large Language Models) iterativ entwickelt, auf Robustheit geprüft und optimiert.

## **Lizenz**

Dieses Projekt ist Open Source. Es kann frei verwendet, modifiziert und weitergegeben werden.
