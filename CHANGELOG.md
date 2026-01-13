# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Cloud storage integration (Google Drive, Dropbox)
- Batch OCR processing
- PDF form filling

---

## [1.0.0] - 2026-01-12

### ✨ Added

#### Core Features
- **Image to PDF Conversion**
  - Multiple image selection from gallery
  - Drag & drop page reordering
  - Customizable page sizes (A4, A3, A5, Letter, Legal)
  - Image quality settings

- **Document Scanner**
  - AI-powered edge detection with Google ML Kit
  - Automatic perspective correction
  - Multiple scan modes (Document, Book, ID Card)
  - Apple VisionKit integration (iOS)

- **PDF Security**
  - AES-256 encryption
  - Password protection for PDFs
  - Permission control (Print, Copy, Edit)
  - Biometric unlock (Fingerprint/Face ID)

- **Digital Signatures**
  - Touch-based signature capture with stylus support
  - Place signature on PDF pages
  - Save and reuse signatures
  - Customizable pen color and stroke width

- **OCR Text Extraction**
  - Google ML Kit Text Recognition
  - Multi-language support
  - Copy and export extracted text
  - Real-time text recognition

- **PDF Split/Merge**
  - Split PDFs by page ranges
  - Merge multiple PDFs
  - Extract individual pages
  - Reorder pages

- **ID Photo Generator**
  - Standard passport photo sizes (35x45mm, 2x2 inch, etc.)
  - Automatic face detection
  - AI background removal (local_rembg, ML Kit Segmentation)
  - Various background colors

- **Business Cards**
  - Professional templates
  - QR code generation
  - Embedded contact information
  - Export as PDF or image

- **Watermarks**
  - Text watermarks with font selection
  - Image watermarks
  - Adjustable position and transparency
  - Batch watermarking for multiple pages

#### User Interface
- Material Design 3 implementation
- Responsive design for all screen sizes
- Dark/Light theme support
- Smooth animations and transitions
- Shimmer loading effects
- Staggered grid layouts

#### Additional Features
- PDF history and recently used files
- Share via installed apps
- File system integration
- Settings with persistence
- Premium subscription system
- AdMob integration

### 🏗 Architecture
- Clean Architecture pattern
- Provider state management
- Service-based business logic
- SQLite database for persistence
- Responsive helper for adaptive layouts

### 🔧 Technical
- Flutter 3.5.4+ compatibility
- Dart 3.0+ null safety
- Android minSdk 21
- iOS 12+ support
- Web build available

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-12 | Initial stable release |

---

[Unreleased]: https://github.com/Nishanth619/PDF-_Gen/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Nishanth619/PDF-_Gen/releases/tag/v1.0.0
