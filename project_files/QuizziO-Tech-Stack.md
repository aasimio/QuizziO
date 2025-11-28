# QuizziO Tech Stack Analysis (Updated)

Based on my deep dive into your PRD, here's the complete tech stack breakdown with the latest package versions:

---

## Frontend Framework

| Component | Technology | Rationale |
| --- | --- | --- |
| **Framework** | Flutter 3.24+ | Cross-platform (iOS + Android) from single codebase |
| **UI System** | Material 3 (Material Design 3) | Modern, accessible, built-in theming |
| **Min Android** | API 23 (Android 6.0) | ~95% market coverage per PRD |
| **Min iOS** | iOS 12.0+ | ~95% market coverage per PRD |

```yaml
# Material 3 is enabled in theme
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.blue,
  ),
)

```

---

## State Management

| Component | Technology | Rationale |
| --- | --- | --- |
| **Primary** | `flutter_bloc` (BLoC/Cubit) | Clean separation, testable, scales well |
| **DI** | `get_it` + `injectable` | Service locator pattern for dependency injection |

The PRD specifies BLoC architecture:

- `ScannerBloc` - Camera & scanning state machine
- `QuizBloc` - Quiz CRUD operations
- `GradedPapersBloc` - Results management

---

## Local Database (Offline-First)

| Component | Technology | Rationale |
| --- | --- | --- |
| **Database** | **Hive** | Fast NoSQL, no native dependencies, Flutter-native |
| **Alternative** | Drift (SQLite) | If relational queries needed later |

**Why Hive over SQLite?**

- Pure Dart (no platform channels)
- Faster for simple key-value/document storage
- No schema migrations headaches for MVP
- Works identically on iOS/Android

```dart
// Hive Boxes (from PRD)
- QuizBox         // Quiz metadata + answer keys
- ScanResultBox   // Scanned papers + scores

```

---

## Camera & Image Capture

| Component | Technology | Rationale |
| --- | --- | --- |
| **Camera** | `camera` package | Official Flutter plugin, supports preview streaming |
| **Permissions** | `permission_handler` | Cross-platform permission requests |

```yaml
dependencies:
  camera: ^0.11.3
  permission_handler: ^12.0.1

```

---

## OMR Image Processing (Core Engine)

| Component | Technology | Rationale |
| --- | --- | --- |
| **OpenCV** | `opencv_dart` | Native OpenCV via FFI, runs at C++ speed |
| **Alternative** | `opencv_4` | Older but more stable (fallback option) |

**Key OpenCV Operations Used:**

```
┌─────────────────────────────────────────────────────────────┐
│  Operation              │ OpenCV Function                   │
├─────────────────────────────────────────────────────────────┤
│  Grayscale conversion   │ cv.cvtColorAsync()                │
│  Contrast enhancement   │ cv.createCLAHE()                  │
│  Template matching      │ cv.matchTemplateAsync()           │
│  Perspective warp       │ cv.warpPerspectiveAsync()         │
│  Bubble intensity       │ cv.meanAsync()                    │
└─────────────────────────────────────────────────────────────┘

```

**Risk noted in PRD**: `opencv_dart` API stability - will pin version and abstract interfaces.

---

## PDF Generation (Offline)

| Component | Technology | Rationale |
| --- | --- | --- |
| **PDF Creation** | `pdf` package | Pure Dart, no internet needed |
| **Sharing** | `share_plus` | Native share sheet (iOS/Android) |
| **File Access** | `path_provider` | Get documents directory |

```yaml
dependencies:
  pdf: ^3.11.3
  share_plus: ^10.1.5
  path_provider: ^2.1.5

```

---

## Architecture Pattern

The PRD specifies **Clean Architecture** with clear layer separation:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE LAYERS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              PRESENTATION LAYER                         │   │
│   │  • Flutter Widgets (Screens)                            │   │
│   │  • BLoC/Cubit (State Management)                        │   │
│   └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                DOMAIN LAYER                             │   │
│   │  • Entities (Quiz, ScanResult, etc.)                    │   │
│   │  • Repository Interfaces                                │   │
│   │  • Use Cases                                            │   │
│   └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                  DATA LAYER                             │   │
│   │  • Repository Implementations                           │   │
│   │  • Data Sources (Hive, Assets)                          │   │
│   │  • Models (JSON serialization)                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              SERVICE LAYER (OMR Engine)                 │   │
│   │  • MarkerDetector                                       │   │
│   │  • PerspectiveTransformer                               │   │
│   │  • BubbleReader                                         │   │
│   │  • ThresholdCalculator                                  │   │
│   │  • GradingService                                       │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

```

---

## Complete `pubspec.yaml` Dependencies

```yaml
name: quizzio
description: OMR Scanner for Teachers
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

  # UI
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.14

  # State Management
  flutter_bloc: ^9.1.1
  equatable: ^2.0.7

  # Dependency Injection
  get_it: ^9.0.5
  injectable: ^2.6.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Camera
  camera: ^0.11.3
  permission_handler: ^12.0.1

  # Image Processing (OMR)
  opencv_dart: ^1.4.3
  image: ^4.3.0

  # PDF & Export
  pdf: ^3.11.3
  printing: ^5.13.4
  share_plus: ^10.1.5
  path_provider: ^2.1.5

  # Utilities
  uuid: ^4.5.1
  intl: ^0.20.1
  collection: ^1.19.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Testing
  bloc_test: ^9.1.8
  mocktail: ^1.0.5

  # Code Generation
  build_runner: ^2.4.14
  hive_generator: ^2.0.1
  injectable_generator: ^2.6.2

  # Linting
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/templates/
    - assets/templates/marker.png
    - assets/templates/template_10q.json
    - assets/templates/template_20q.json
    - assets/templates/template_50q.json

```

---

## Project Structure (from PRD)

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/          # App & OMR constants
│   ├── errors/             # Failures & Exceptions
│   ├── services/           # CameraService
│   ├── utils/              # Image/Math utilities
│   └── extensions/         # Dart extensions
│
├── features/
│   ├── quiz/               # Quiz CRUD
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── omr/                # CORE OMR ENGINE
│   │   ├── data/
│   │   ├── domain/
│   │   ├── services/       # MarkerDetector, BubbleReader, etc.
│   │   └── presentation/
│   │
│   └── export/             # PDF generation
│
└── assets/
    └── templates/          # JSON + marker.png

```

---

## Tech Stack Summary

| Category | Choice | Package |
| --- | --- | --- |
| **Framework** | Flutter 3.24+ | - |
| **UI** | Material 3 | Built-in |
| **State** | BLoC/Cubit | `flutter_bloc` |
| **DI** | Service Locator | `get_it` + `injectable` |
| **Database** | Hive (NoSQL) | `hive_flutter` |
| **Camera** | Camera Plugin | `camera` |
| **OMR Engine** | OpenCV | `opencv_dart` |
| **PDF** | Pure Dart PDF | `pdf` + `printing` |
| **Architecture** | Clean Architecture | - |