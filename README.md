# PDFGen - Document Conversion & PDF Toolkit

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.5.4-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green)
![License](https://img.shields.io/badge/License-Proprietary-red)
![Version](https://img.shields.io/badge/Version-1.0.0-orange)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

**A professional, feature-rich Flutter application for comprehensive PDF creation and document management**

[Features](#-features) • [Architecture](#-architecture) • [Installation](#-installation) • [Project Structure](#-project-structure) • [Technologies](#-technology-stack)

</div>

---

## 📋 Overview

PDFGen is a state-of-the-art mobile application for professional PDF creation and document processing. The application offers a comprehensive suite of tools for image conversion, document scanning with AI-powered edge detection, OCR text extraction, PDF security, and more.

### Key Highlights

- 🔄 **Image Conversion**: Convert multiple images into a single PDF document
- 📷 **Document Scanning**: AI-powered edge detection with Google ML Kit
- 🔒 **PDF Security**: Password protection and encryption for PDFs
- ✍️ **Digital Signatures**: Touch-based signature capture and PDF embedding
- 🔍 **OCR Extraction**: Optical character recognition for scanned documents
- 🪪 **ID Photo Generator**: Professional passport photos with background removal
- 💼 **Business Cards**: Creation and export of business cards
- 💦 **Watermarks**: Text and image watermarks for documents

---

## 🏗 Architecture

The application follows a clean, modular architecture with clear separation of concerns:

```mermaid
graph TB
    subgraph Presentation Layer
        UI[Screens / Views]
        WG[Widgets]
    end
    
    subgraph Business Logic
        PR[Providers]
        SV[Services]
    end
    
    subgraph Data Layer
        MD[Models]
        DB[Database]
        UT[Utils]
    end
    
    UI --> PR
    UI --> WG
    PR --> SV
    SV --> MD
    SV --> DB
    SV --> UT
    
    style UI fill:#4CAF50
    style PR fill:#2196F3
    style SV fill:#FF9800
    style MD fill:#9C27B0
```

### Architecture Principles

| Principle | Description |
|-----------|-------------|
| **Separation of Concerns** | Clear separation between UI, business logic, and data layer |
| **Single Responsibility** | Each component has exactly one responsibility |
| **Dependency Injection** | Provider pattern for loose coupling |
| **Clean Code** | Readable, maintainable codebase following industry standards |

---

## ✨ Features

### Core Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Image to PDF** | Convert multiple images to PDF | ✅ Implemented |
| **Document Scanner** | AI-powered edge detection | ✅ Implemented |
| **PDF Security** | Password protection & encryption | ✅ Implemented |
| **Digital Signatures** | Touch-based signature capture | ✅ Implemented |
| **OCR Text Extraction** | Google ML Kit integration | ✅ Implemented |
| **PDF Split/Merge** | Split and merge documents | ✅ Implemented |
| **ID Photo Generator** | Passport photos with AI background removal | ✅ Implemented |
| **Business Cards** | Business card generator | ✅ Implemented |
| **Watermarks** | Text and image watermarks | ✅ Implemented |

### Advanced Features

- **Biometric Authentication**: Fingerprint/Face ID for protected PDFs
- **Batch Processing**: Process multiple documents simultaneously
- **Cloud Export**: Share via all installed apps
- **Dark Mode**: Full Dark/Light theme support
- **Localization**: Localized user interface

---

## 🛠 Technology Stack

### Framework & Language

| Technology | Version | Usage |
|------------|---------|-------|
| Flutter | 3.5.4+ | Cross-Platform UI Framework |
| Dart | 3.0+ | Programming Language |

### Core Dependencies

```yaml
# PDF Processing
pdf: ^3.11.1                          # PDF generation
printing: ^5.13.4                      # Print functionality
syncfusion_flutter_pdf: ^24.2.9       # Advanced PDF operations
pdfx: ^2.6.0                          # PDF rendering & thumbnails

# Image Processing
image: ^4.2.0                         # Image manipulation
image_cropper: ^11.0.0                # Image cropping
image_picker: ^1.1.2                  # Image selection

# Google ML Kit (AI Features)
google_mlkit_text_recognition: ^0.13.0    # OCR
google_mlkit_document_scanner: ^0.3.0     # Document scanning
google_mlkit_face_detection: ^0.11.0      # Face detection
google_mlkit_selfie_segmentation: ^0.7.0  # Background removal

# Authentication & Security
local_auth: ^2.1.8                    # Biometrics

# State Management
provider: ^6.1.2                      # State management

# Database & Storage
sqflite: ^2.4.1                       # SQLite database
shared_preferences: ^2.3.3            # Key-value storage
path_provider: ^2.1.4                 # File system paths
```

### Full Dependency List

<details>
<summary>Show all dependencies</summary>

```yaml
dependencies:
  flutter: sdk
  google_mlkit_text_recognition: ^0.13.0
  image_cropper: ^11.0.0
  google_mobile_ads: ^5.0.0
  in_app_purchase: ^3.1.11
  provider: ^6.1.2
  pdf: ^3.11.1
  printing: ^5.13.4
  image: ^4.2.0
  path_provider: ^2.1.4
  file_picker: ^8.1.6
  camera: ^0.11.0+2
  permission_handler: ^11.3.1
  sqflite: ^2.4.1
  path: ^1.9.0
  intl: ^0.19.0
  share_plus: ^10.1.2
  fluttertoast: ^8.2.8
  image_picker: ^1.1.2
  uuid: ^4.5.1
  shared_preferences: ^2.3.3
  open_filex: ^4.5.0
  url_launcher: ^6.3.1
  toastification: ^2.0.0
  syncfusion_flutter_pdf: ^24.2.9
  flutter_launcher_icons: ^0.13.1
  pdfx: ^2.6.0
  cunning_document_scanner: ^1.2.3
  google_mlkit_document_scanner: ^0.3.0
  google_mlkit_face_detection: ^0.11.0
  google_mlkit_selfie_segmentation: ^0.7.0
  local_rembg: ^1.0.1
  flutter_contacts: ^1.1.7+1
  local_auth: ^2.1.8
  google_fonts: ^6.1.0
  shimmer: ^3.0.0
  flutter_staggered_grid_view: ^0.7.0
  lottie: ^3.1.0
```

</details>

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── constants/                   # App-wide constants
│   └── app_theme.dart          # Theme definitions
├── database/                    # Database layer
│   └── database_helper.dart    # SQLite operations
├── models/                      # Data models
│   ├── id_photo_template.dart  # ID photo templates
│   ├── pdf_file_model.dart     # PDF file model
│   ├── page_range.dart         # Page range model
│   └── recent_activity_model.dart
├── providers/                   # State management
│   └── pdf_provider.dart       # PDF state management
├── screens/                     # UI screens (23 screens)
│   ├── home_screen.dart        # Main screen
│   ├── dashboard_screen.dart   # Dashboard
│   ├── converter_screen.dart   # Image conversion
│   ├── scanner_screen.dart     # Document scanner
│   ├── ocr_screen.dart         # OCR extraction
│   ├── pdf_security_screen.dart # Security settings
│   ├── digital_signature_screen.dart # Signatures
│   ├── id_photo_screen.dart    # ID photos
│   ├── watermark_screen.dart   # Watermarks
│   └── ...                     # Additional screens
├── services/                    # Business logic (14 services)
│   ├── pdf_service.dart        # PDF operations
│   ├── pdf_security_service.dart # Encryption
│   ├── ocr_service.dart        # OCR processing
│   ├── id_photo_service.dart   # ID photo generation
│   ├── watermark_service.dart  # Watermarks
│   ├── biometric_service.dart  # Biometrics
│   └── ...                     # Additional services
├── utils/                       # Utility functions
│   └── responsive_helper.dart  # Responsive design
├── widgets/                     # Reusable widgets
│   └── pdf_page_preview.dart   # PDF preview
└── theme/                       # Theme configuration
```

---

## 🚀 Installation

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter SDK | ≥ 3.5.4 |
| Dart SDK | ≥ 3.0 |
| Android Studio / VS Code | Latest |
| Android SDK | minSdk 21 (Android 5.0) |
| Xcode (for iOS) | ≥ 14.0 |

### Step-by-Step Guide

1. **Clone the repository**
   ```bash
   git clone https://github.com/Nishanth619/PDF-_Gen.git
   cd PDF-_Gen
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # Development mode
   flutter run
   
   # Release build (Android)
   flutter build apk --release
   
   # Release build (iOS)
   flutter build ios --release
   ```

### Troubleshooting

<details>
<summary>Common issues and solutions</summary>

**Issue**: Gradle sync error
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Issue**: iOS pod installation failed
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

**Issue**: ML Kit not found
- Ensure Google Play Services are installed on the device
- Check internet connection for initial download

</details>

---

## 🧪 Quality Assurance

### Test Coverage

```bash
# Run unit tests
flutter test

# With coverage report
flutter test --coverage
```

### Code Analysis

```bash
# Static analysis
flutter analyze

# Check formatting
dart format --set-exit-if-changed .
```

### Available Tests

- `test/responsive_helper_test.dart` - Responsive design tests
- `test/widget_test.dart` - Widget tests

---

## 🤝 Contributing

Contributions are welcome! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) for details on the development process and our coding standards.

### Quick Start for Developers

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/NewFeature`)
3. Commit your changes (`git commit -m 'feat: Add new feature'`)
4. Push to the branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

---

## 📄 License

This project is a proprietary software. All rights reserved. See [LICENSE](LICENSE) for details.

---

## 👨‍💻 Author

**Nishanth**

- GitHub: [@Nishanth619](https://github.com/Nishanth619)

---

## 📊 Project Statistics

| Metric | Value |
|--------|------|
| Screens | 23 |
| Services | 14 |
| Models | 6 |
| Widgets | 12 |
| Tests | 2 |
| Total Lines of Code | 400,000+ |

---

<div align="center">

**Built with ❤️ and precision engineering**

</div>
