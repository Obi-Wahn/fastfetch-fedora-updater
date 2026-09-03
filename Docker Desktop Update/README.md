# **Docker Desktop Fedora Updater**

Dieses Repository stellt ein automatisiertes Bash-Skript zur Verfügung, um [Docker Desktop](https://www.docker.com/products/docker-desktop/) unter Fedora Linux aktuell zu halten. Da Docker Desktop für Linux als natives RPM-Paket bereitgestellt wird, automatisiert dieses Skript den Abgleich der Version, den Download der aktuellen Datei sowie die Installation.

## **Funktionen**

* **Automatisierter Versionsabgleich:** Vergleicht die lokal installierte Version mit der neuesten, auf den offiziellen Docker-Release-Notes verfügbaren Version.  
* **Intelligentes Dateimanagement:** Lädt das aktuelle Paket direkt in ein definiertes Verzeichnis herunter und bereinigt automatisch veraltete Installationsdateien, um Speicherplatz zu sparen.  
* **Sicherheitsprüfungen:** Integriert eine Integritätsprüfung des heruntergeladenen RPM-Pakets (rpm \-qip), bevor die Installation gestartet wird.  
* **Strikte Fehlerbehandlung:** Verwendet set \-euo pipefail für robuste Skriptausführung und Retry-Logiken für Downloads.

## **Systemvoraussetzungen**

* **Betriebssystem:** Fedora Linux  
* **Architektur:** x86\_64  
* **Abhängigkeiten:** bash, curl, dnf, rpm

## **Installation und Nutzung**

1. Das Skript in das gewünschte Verzeichnis kopieren oder das Repository klonen.  
2. Das Skript ausführbar machen:  
   chmod \+x update-docker-desktop.sh

3. Das Skript ausführen:  
   ./update-docker-desktop.sh

   *Hinweis: Das Skript erfordert bei einem anstehenden Update Administratorrechte (sudo) für die Installation via dnf.*

## **Konfiguration**

Das Zielverzeichnis für die RPM-Dateien ist im Skript unter der Variable DEST\_DIR definiert. Standardmäßig ist dies:

/home/tobias/Downloads/RPM-Pakete

Du kannst diesen Pfad bei Bedarf im Skript einfach an deine Ordnerstruktur anpassen.

## **Hinweis zur Entwicklung (KI-Transparenz)**

Der Quellcode dieses Skripts sowie Teile dieser Dokumentation wurden in Zusammenarbeit mit generativen KI-Modellen (Large Language Models) iterativ entwickelt, auf Robustheit geprüft und optimiert.

## **Lizenz**

Dieses Projekt ist Open Source und steht unter der [MIT-Lizenz](https://opensource.org/license/mit). Es kann frei verwendet, modifiziert und weitergegeben werden.
