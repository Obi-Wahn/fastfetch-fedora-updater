# Anleitung: Moonfin auf Fedora 44 einrichten

Diese Anleitung beschreibt die vollständige Einrichtung von Moonfin auf einem HP-Desktop unter Fedora 44. Sie beinhaltet das automatisierte Skript für den korrekten Download sowie die essenziellen Codec-Anpassungen, damit auch HEVC-Videos (H.265) mit funktionierender Hardwarebeschleunigung laufen.

## 1. Das Installations- und Update-Skript anlegen

*(Dieser Abschnitt war in der ursprünglichen Anleitung noch leer. Das Skript liegt als [`update_moonfin.sh`](./update_moonfin.sh) im Repository-Root.)*

## 2. Fedora-Codecs & Hardwarebeschleunigung freischalten

Fedora liefert aus Lizenzgründen standardmäßig keine proprietären Codecs wie HEVC (H.265) mit. Das führt in der nativen RPM-Version von Moonfin zu Dekodierungsfehlern (failed to initialize codec hevc). Zudem zwingt das Fehlen der Codecs die Video-Engine fälschlicherweise in die Suche nach Nvidia-Treibern (libcuda), was die Hardwarebeschleunigung für Intel-Grafikchips blockiert.
Um das zu beheben, müssen die vollständigen Codecs aus dem **RPM Fusion Repository** geladen werden.

### Schritt 2.1: Das beschnittene FFmpeg austauschen

Ersetze die eingeschränkte Fedora-Version durch die Vollversion. Führe dazu im Terminal aus:

```bash
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

### Schritt 2.2: Die proprietären Hardware-Decoder installieren

Installiere das Paket, das die fehlenden Patente für HEVC/H.264 und die korrekten VA-API-Schnittstellen für die Intel-Hardware freischaltet:

```bash
sudo dnf install libavcodec-freeworld
```

**Abschluss:** Sobald diese beiden Befehle durchgelaufen sind, ist das System vollständig vorbereitet. Moonfin nutzt nun natives *Direct Play* mit voll funktionierender Hardwarebeschleunigung über die Intel-GPU für alle modernen Videoformate.
