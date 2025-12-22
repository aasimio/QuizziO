# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuizziO is building a Flutter application for OMR (Optical Mark Recognition) quiz scanning and grading. The root app has the main OMR pipeline + quiz feature implemented, and PDF export fully wired into GradedPapersPage. A validated spike lives in `omr_spike/` with the full pipeline UI/tests/assets used for the results below.

## Repository Layout

```
.
├── lib/                     # Main app code
│   ├── core/                # Camera service, constants, stubs for utils/errors/extensions
│   ├── features/
│   │   ├── omr/             # Implemented services + camera_test_page; marker model
│   │   ├── quiz/            # Quiz CRUD: BLoC, pages, widgets
│   │   └── export/          # PDF export (fully implemented)
│   ├── injection.dart(.config.dart)  # get_it + injectable setup
│   ├── main.dart            # Entry point (Hive init, CameraTestPage)
│   └── app.dart             # Placeholder
├── assets/templates/        # OMR template JSON + ArUco marker assets
├── assets/sheets/           # Printable answer sheets (PNG/PDF)
├── omr_spike/               # Standalone spike with full OMR pipeline, assets, tests, SPIKE_RESULTS.md
├── Tasks/                   # PRD + planning docs
└── test/                    # Root smoke test
```

## Development Commands

### Running the Application
```bash
flutter run
```

### Hot Reload
Press `r` in the terminal while the app is running to hot reload changes.

### Hot Restart
Press `R` in the terminal to hot restart the application.

### Building
```bash
# Build for specific platforms
flutter build apk          # Android APK
flutter build ios          # iOS
flutter build web          # Web
flutter build macos        # macOS
flutter build windows      # Windows
flutter build linux        # Linux
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Run static analysis
flutter analyze

# Format code
flutter format lib/

# Check formatting without modifying
flutter format --set-exit-if-changed lib/

# Run build_runner (after annotation changes)
dart run build_runner build --delete-conflicting-outputs
```

### Dependency Management
```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Architecture

The project follows **Clean Architecture** with a **feature-based folder structure**:

```
lib/
├── core/                    # Constants + camera service (utils/errors/extensions are stubs)
├── features/                # Feature modules
│   ├── omr/                 # OMR services, ScannerBloc, camera_test_page, detection_result model
│   ├── quiz/                # Quiz CRUD: BLoC, pages (list, menu), widgets (card, dialog)
│   └── export/              # PDF export (fully implemented)
├── injection.dart(.config.dart)  # DI setup
└── main.dart                # Entry point (uses CameraTestPage)
```

Clean Architecture is the target. Domain/data/presentation layers are implemented for both quiz and OMR features.

### Clean Architecture Rules

**CRITICAL**: Follow these dependency rules strictly:
- **Dependency Flow**: data → domain → presentation (NEVER reverse imports)
- **Repositories**: Interface in `domain/`, implementation in `data/`
- **Dependency Injection**: Inject via abstract types, never concrete classes
- **Imports**: presentation layer can import domain, domain CANNOT import presentation

### Feature Structure

Target structure (not yet implemented in current code):

```
features/<feature_name>/
├── data/
│   ├── datasources/       # Remote/local data sources
│   ├── models/            # Data models (extend entities)
│   └── repositories/      # Repository implementations
├── domain/
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository contracts
│   └── usecases/          # Business logic use cases
├── presentation/
│   ├── bloc/              # BLoC state management
│   ├── pages/             # Full-screen pages
│   └── widgets/           # Reusable UI components
└── services/              # Feature-specific services (if needed)
```

### Current Features

1. **OMR Feature** (`lib/features/omr/`)
   - Domain: `ScanResult`, `AnswerStatus`, `OmrTemplate` entities, `ScanRepository` interface
   - Data: `ScanResultModel` (Hive), `ScanRepositoryImpl`
   - Services: Full OMR pipeline (preprocess → detect → transform → read → threshold via `OmrPipeline`)
   - Presentation: `ScannerBloc` (8-state machine for camera → capture → process → result flow)
   - Scanner flow: frame processing throttled ~10 FPS and only during Previewing/Aligning; 500ms stable markers auto-capture
   - Error mapping: name-region marker failures → `ScannerErrorType.markerDetection`, persistence failures → `ScannerErrorType.persistence`
   - Pages: `ScanPapersPage`, `ScanResultDetailPage`, `CameraTestPage`
   - Widgets: `AlignmentOverlay`, `ScanBottomBar`, `ProcessingOverlay`, `ScanResultPopup`
   - **ArUco markers** used for corner detection (DICT_4X4_50, IDs 0-3)
   - Markers are inset from sheet edges; perspective warp uses marker corners + edge padding
   - DI via get_it/injectable (`configureDependencies`)

2. **Spike** (`omr_spike/`)
   - Standalone Flutter project with full pipeline UI, assets (`assets/gallery/*`), and tests
   - Detailed results in `omr_spike/SPIKE_RESULTS.md`
   - Note: Spike uses old template matching; main app now uses ArUco

3. **Quiz Feature** (`lib/features/quiz`)
   - Domain: `Quiz` entity, `QuizRepository` interface
   - Data: `QuizModel` (Hive), `QuizRepositoryImpl`
   - Presentation: `QuizBloc` (CRUD), `AnswerKeyCubit` (answer key editing with 500ms debounced auto-save)
   - Pages: `QuizzesPage`, `QuizMenuPage`, `EditAnswerKeyPage`
   - Widgets: `QuizCard`, `QuizDialog`, `AnswerKeyRow`

4. **Export Feature** (`lib/features/export`)
   - `services/pdf_export_service.dart` implemented (generate/save/share/exportAndShare)
   - Export wired into `GradedPapersPage` AppBar via `_handleExport()` with loading dialog and error handling

### Key Architectural Patterns

- **BLoC Pattern**: State management using the BLoC pattern (`QuizBloc` implemented)
- **Dependency Flow**: presentation → domain → data (dependencies point inward)
- **Repository Pattern**: Abstract repositories in domain layer, implemented in data layer
- **Use Cases**: Each business action is a separate use case class in `domain/usecases/`

## Technical Implementation Guidelines

### BLoC/Cubit

`QuizBloc` is implemented; follow these rules for all BLoC/Cubit classes.

**State Management Rules**:
- All states MUST extend `Equatable` with ALL fields in `props`
- Always check `if (isClosed) return;` before `emit()` after any `await`
- Use `Cubit` for CRUD operations, `Bloc` for multi-step flows (e.g., OMR scanning)
- States are immutable — always use `copyWith()` for updates
- Never mutate state fields directly

**Example Pattern**:
```dart
class MyState extends Equatable {
  final String data;
  final bool isLoading;

  const MyState({required this.data, required this.isLoading});

  @override
  List<Object?> get props => [data, isLoading];

  MyState copyWith({String? data, bool? isLoading}) {
    return MyState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// In Cubit/Bloc
Future<void> fetchData() async {
  final result = await repository.getData();
  if (isClosed) return;  // Check before emit
  emit(state.copyWith(data: result));
}
```

### GetIt + Injectable

**Dependency Injection Rules**:
- Register: `getIt.registerLazySingleton<Interface>(() => Implementation())`
- Run `dart run build_runner build --delete-conflicting-outputs` after ANY annotation change
- Never call `getIt<T>()` inside widget `build()` methods
- Use constructor injection in widgets
- Register repositories as interfaces, not concrete classes

**Example Pattern**:
```dart
// In service locator setup
getIt.registerLazySingleton<QuizRepository>(
  () => QuizRepositoryImpl(dataSource: getIt()),
);

// In widget - inject via constructor
class QuizPage extends StatelessWidget {
  final QuizRepository repository;

  const QuizPage({required this.repository});
}
```

### Hive

**Local Storage Rules**:
- Register adapters BEFORE opening boxes
- Always use typed boxes: `Hive.box<Quiz>(name: 'quizzes')`
- Each `@HiveType(typeId: X)` must have unique X across all models
- Call `Hive.close()` on app lifecycle pause
- Never use dynamic boxes

Current state: `main.dart` registers `QuizModelAdapter` and `ScanResultModelAdapter`, then opens typed boxes.

**Example Pattern**:
```dart
// Register adapter before opening
Hive.registerAdapter(QuizAdapter());
await Hive.openBox<Quiz>(name: 'quizzes');

// Use typed box
final box = Hive.box<Quiz>(name: 'quizzes');
final quiz = box.get(key);
```

### Camera

**Camera Usage Rules**:
- Always `dispose()` CameraController in widget lifecycle
- Check permissions before initializing camera
- Use `ResolutionPreset.high` (not `max`) for OMR scanning
- Lock orientation: `controller.lockCaptureOrientation(DeviceOrientation.portraitUp)`
- Handle camera errors gracefully

**Example Pattern**:
```dart
class CameraState extends State<CameraWidget> {
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      camera,
      ResolutionPreset.high,  // Not max!
    );
    await _controller.initialize();
    await _controller.lockCaptureOrientation(
      DeviceOrientation.portraitUp,
    );
  }

  @override
  void dispose() {
    _controller.dispose();  // Always dispose
    super.dispose();
  }
}
```

### OpenCV Dart

**Image Processing Rules**:
- Use async variants: `cvtColorAsync`, `imreadAsync` (sync variants block UI)
- Always `dispose()` Mat objects after use to prevent memory leaks
- Validate 4 corner markers detected before grading — abort if not found
- Use `adaptiveThreshold` for inconsistent lighting conditions
- Handle exceptions when image processing fails
- **Testing note:** `opencv_dart` native libs are not available in standard `flutter test` runs; performance benchmarks or pipeline validation must run on device/emulator.

**ArUco Marker Detection** (preferred for corner detection):
- Use `DICT_4X4_50` dictionary with marker IDs 0-3 for corners
- ArUco detection is binary (found/not found) - no false positives
- No confidence threshold needed - markers either match or don't
- Works on grayscale images after preprocessing

**Example Pattern**:
```dart
// ArUco marker detection
final dictionary = cv.ArucoDictionary.predefined(cv.PredefinedDictionaryType.DICT_4X4_50);
final params = cv.ArucoDetectorParameters.empty();
final detector = cv.ArucoDetector.create(dictionary, params);

final (corners, ids, rejected) = detector.detectMarkers(grayscaleImage);
// corners: List of 4 corner points for each detected marker
// ids: List of marker IDs found (should be 0, 1, 2, 3 for valid sheet)

// Validate all 4 markers found
if (ids.length != 4) {
  throw OMRException('Could not detect all 4 corner markers');
}

// Always dispose
detector.dispose();
dictionary.dispose();
params.dispose();
```

**Legacy Template Matching** (deprecated - causes false positives):
```dart
// Don't use - solid black squares match any dark region
final result = cv.matchTemplate(image, template, cv.TM_CCOEFF_NORMED);
```

### PDF Export

**PDF Generation Rules**:
- Generate PDFs off main thread using `compute()` function
- Use `path_provider` for file paths, never hardcode paths
- Verify file exists after write before sharing
- Handle PDF generation errors gracefully

`lib/features/export/services/pdf_export_service.dart` is implemented; use it as the reference for PDF generation/saving/sharing.

**Example Pattern**:
```dart
// Generate off main thread
final pdfBytes = await compute(generatePdfBytes, quizResults);

// Use path_provider
final directory = await getApplicationDocumentsDirectory();
final filePath = '${directory.path}/results_${DateTime.now().millisecondsSinceEpoch}.pdf';

// Write and verify
final file = File(filePath);
await file.writeAsBytes(pdfBytes);

if (!await file.exists()) {
  throw Exception('PDF file was not created');
}
```

### General Rules

**Code Quality Standards**:
- **Null safety**: Use `?.` and `??`, never `!` without validation
- **Error handling**: Log errors at catch point, not just rethrow
- **Validation**: Validate all external data (JSON templates, scan results)
- **Async**: Use `async/await`, never `.then()` chaining
- **Immutability**: Prefer `final` over `var`, use `const` constructors
- **Comments**: Only add comments where logic isn't self-evident
- **Formatting**: Run `flutter format lib/` before committing

**Example Patterns**:
```dart
// Good null safety
final score = result?.score ?? 0;

// Bad - avoid force unwrap
final score = result!.score;  // ❌

// Good async
final data = await repository.fetchData();

// Bad - avoid .then()
repository.fetchData().then((data) => ...);  // ❌

// Good immutability
final quiz = Quiz(name: 'Test');
const spacing = EdgeInsets.all(8.0);
```

### Quick Reference

| ❌ Avoid | ✅ Use |
|----------|--------|
| `Hive.box()` | `Hive.box<T>(name: 'x')` |
| `emit()` after await | `if (isClosed) return;` first |
| `cv.cvtColor()` | `cv.cvtColorAsync()` |
| `result!.score` | `result?.score ?? 0` |
| `getIt<T>()` in build | Constructor injection |
| `.then()` chains | `async/await` |
| Concrete class injection | Abstract interface injection |
| Hardcoded paths | `path_provider` package |
| `ResolutionPreset.max` | `ResolutionPreset.high` |
| Forgetting `dispose()` | Always dispose controllers/Mats |
| Template matching for markers | ArUco marker detection |
| Solid black square markers | ArUco markers (DICT_4X4_50) |

## Asset Management

Quiz templates are stored in `assets/templates/`:
- `template_10q.json` - 10 question template
- `template_20q.json` - 20 question template
- `template_50q.json` - 50 question template
- `aruco_0.png` - ArUco marker ID 0 (Top-Left corner)
- `aruco_1.png` - ArUco marker ID 1 (Top-Right corner)
- `aruco_2.png` - ArUco marker ID 2 (Bottom-Right corner)
- `aruco_3.png` - ArUco marker ID 3 (Bottom-Left corner)
- `aruco_test_sheet.png` - Test sheet with all 4 ArUco markers for testing
- `marker.png` - (Legacy) Old solid black marker, no longer used
- `assets/sheets/answer_sheet_10q.{png,pdf}` - Printable 10Q sheet
- `assets/sheets/answer_sheet_20q.{png,pdf}` - Printable 20Q sheet
- `assets/sheets/answer_sheet_50q.{png,pdf}` - Printable 50Q sheet (uses horizontal layout: 2 columns × 25 rows)

When adding new assets, update `pubspec.yaml` under the `flutter.assets` section.
Printable answer sheets are generated via `scripts/generate_answer_sheet.dart`.

Spike-only assets for validation live under `omr_spike/assets/` (marker/test sheets/gallery variations).

## Code Standards

The project uses `flutter_lints` package for linting. Analysis options are configured in `analysis_options.yaml`.

Follow the technical implementation standards in the sections above, including:
- Null safety patterns (use `?.` and `??`, avoid `!`)
- Async/await usage (never `.then()`)
- Immutability (`final` over `var`, `const` constructors)
- Error handling and validation

## Environment Requirements

- Dart SDK: `>=3.0.0 <4.0.0`
- Flutter SDK: `>=3.10.0`
- Android minSdkVersion 24 (set in `android/app/build.gradle.kts`) due to `opencv_dart`

## Dependencies

Root `pubspec.yaml` dependencies (main app):
- UI: `cupertino_icons`, `flutter_svg`, `google_fonts`
- State: `flutter_bloc`, `equatable`
- DI: `get_it`, `injectable`
- Storage: `hive`, `hive_flutter`
- Camera/permissions: `camera`, `permission_handler`
- OMR: `opencv_dart` ^1.4.3, `image`
- Export: `pdf`, `printing`, `share_plus`, `path_provider`
- Utils: `uuid`, `intl`, `collection`
- Dev: `flutter_test`, `bloc_test`, `mocktail`, `flutter_lints`, `build_runner`, `injectable_generator`, `hive_generator`

The `omr_spike/` subproject has its own `pubspec.yaml` (opencv_dart, image, path_provider, image_picker).

When adding new dependencies, run `flutter pub get` to install them.
