# Changelog

Alle bemerkenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt der [Semantischen Versionierung](https://semver.org/lang/de/).

## [Unreleased]

### Geplant
- Cloud-Speicher-Integration (Google Drive, Dropbox)
- Batch-OCR-Verarbeitung
- PDF-Formular-Ausfüllung

---

## [1.0.0] - 2026-01-12

### ✨ Hinzugefügt

#### Kernfunktionen
- **Image to PDF Konvertierung**
  - Mehrfachbildauswahl aus Galerie
  - Seitenreihenfolge per Drag & Drop ändern
  - Anpassbare Seitengrößen (A4, A3, A5, Letter, Legal)
  - Bildqualitätseinstellungen

- **Dokumentenscanner**
  - KI-gestützte Kantenerkennung mit Google ML Kit
  - Automatische Perspektivkorrektur
  - Mehrere Scan-Modi (Dokument, Buch, ID-Karte)
  - Apple VisionKit Integration (iOS)

- **PDF-Sicherheit**
  - AES-256 Verschlüsselung
  - Passwortschutz für PDFs
  - Berechtigungssteuerung (Drucken, Kopieren, Bearbeiten)
  - Biometrische Entsperrung (Fingerabdruck/Face ID)

- **Digitale Signaturen**
  - Touch-basierte Signaturerfassung mit Stiftunterstützung
  - Signatur auf PDF-Seiten platzieren
  - Signatur speichern und wiederverwenden
  - Anpassbare Stiftfarbe und -stärke

- **OCR-Textextraktion**
  - Google ML Kit Text Recognition
  - Unterstützung für mehrere Sprachen
  - Kopieren und Exportieren von extrahiertem Text
  - Echtzeit-Texterkennung

- **PDF Split/Merge**
  - PDFs nach Seitenbereichen aufteilen
  - Mehrere PDFs zusammenführen
  - Einzelne Seiten extrahieren
  - Seitenreihenfolge ändern

- **ID-Foto-Generator**
  - Standard-Passbildgrößen (35x45mm, 2x2 inch, etc.)
  - Automatische Gesichtserkennung
  - KI-Hintergrundentfernung (local_rembg, ML Kit Segmentation)
  - Verschiedene Hintergrundfarben

- **Visitenkarten**
  - Professionelle Vorlagen
  - QR-Code-Generierung
  - Kontaktinformationen einbetten
  - Export als PDF oder Bild

- **Wasserzeichen**
  - Textwasserzeichen mit Schriftartauswahl
  - Bildwasserzeichen
  - Position und Transparenz anpassen
  - Batch-Wasserzeichen für mehrere Seiten

#### Benutzeroberfläche
- Material Design 3 Implementierung
- Responsive Design für alle Bildschirmgrößen
- Dark/Light Theme Unterstützung
- Smooth Animations und Übergänge
- Shimmer-Ladeeffekte
- Staggered Grid Layouts

#### Zusätzliche Funktionen
- PDF-Verlauf und zuletzt verwendete Dateien
- Teilen über installierte Apps
- Dateisystemintegration
- Einstellungen mit Persistenz
- Premium-Abonnement-System
- AdMob-Integration

### 🏗 Architektur
- Clean Architecture Pattern
- Provider State Management
- Service-basierte Geschäftslogik
- SQLite Datenbank für Persistenz
- Responsive Helper für adaptive Layouts

### 🔧 Technisch
- Flutter 3.5.4+ Kompatibilität
- Dart 3.0+ Null Safety
- Android minSdk 21
- iOS 12+ Unterstützung
- Web-Build verfügbar

---

## Versionshistorie

| Version | Datum | Änderungen |
|---------|-------|------------|
| 1.0.0 | 2026-01-12 | Erste stabile Veröffentlichung |

---

[Unreleased]: https://github.com/Nishanth619/PDF-_Gen/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Nishanth619/PDF-_Gen/releases/tag/v1.0.0
