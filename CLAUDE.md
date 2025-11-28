# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuizziO is a Flutter application for OMR (Optical Mark Recognition) quiz scanning and grading. The app allows users to create quizzes, scan answer sheets using a camera, grade papers automatically, and export results to PDF.

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
├── core/                    # Shared utilities and services
│   ├── constants/          # App-wide constants (app, OMR)
│   ├── errors/             # Error handling (exceptions, failures)
│   ├── extensions/         # Dart extensions (list extensions)
│   ├── services/           # Core services (camera)
│   └── utils/              # Utility functions (image, math)
├── features/               # Feature modules
│   ├── quiz/              # Quiz management feature
│   ├── omr/               # OMR scanning and processing
│   └── export/            # PDF export functionality
├── app.dart               # App widget configuration
└── main.dart              # Application entry point
```

### Clean Architecture Rules

**CRITICAL**: Follow these dependency rules strictly:
- **Dependency Flow**: data → domain → presentation (NEVER reverse imports)
- **Repositories**: Interface in `domain/`, implementation in `data/`
- **Dependency Injection**: Inject via abstract types, never concrete classes
- **Imports**: presentation layer can import domain, domain CANNOT import presentation

### Feature Structure

Each feature follows Clean Architecture layers:

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

1. **Quiz Management** (`features/quiz/`)
   - Create and manage quizzes
   - Define answer keys
   - Quiz templates (10, 20, 50 questions)

2. **OMR Scanning** (`features/omr/`)
   - Camera-based paper scanning
   - Optical mark recognition
   - Paper grading and results

3. **Export** (`features/export/`)
   - PDF generation for results
   - Export functionality for graded papers

### Key Architectural Patterns

- **BLoC Pattern**: State management using the BLoC pattern (see `presentation/bloc/` in features)
- **Dependency Flow**: presentation → domain → data (dependencies point inward)
- **Repository Pattern**: Abstract repositories in domain layer, implemented in data layer
- **Use Cases**: Each business action is a separate use case class in `domain/usecases/`

## Technical Implementation Guidelines

### BLoC/Cubit

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

**Example Pattern**:
```dart
// Use async variants
final mat = await cv.imreadAsync(imagePath);
try {
  final gray = await cv.cvtColorAsync(mat, cv.COLOR_BGR2GRAY);
  try {
    // Process image...
  } finally {
    gray.dispose();  // Always dispose
  }
} finally {
  mat.dispose();  // Always dispose
}

// Validate markers
if (corners.length != 4) {
  throw OMRException('Could not detect 4 corner markers');
}
```

### PDF Export

**PDF Generation Rules**:
- Generate PDFs off main thread using `compute()` function
- Use `path_provider` for file paths, never hardcode paths
- Verify file exists after write before sharing
- Handle PDF generation errors gracefully

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

## Asset Management

Quiz templates are stored in `assets/templates/`:
- `template_10q.json` - 10 question template
- `template_20q.json` - 20 question template
- `template_50q.json` - 50 question template
- `marker.png` - Marker image for OMR alignment

When adding new assets, update `pubspec.yaml` under the `flutter.assets` section.

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

## Dependencies

All required dependencies are installed:
- `cupertino_icons` - iOS style icons
- `flutter_bloc` + `equatable` - State management
- `get_it` + `injectable` - Dependency injection
- `hive` + `hive_flutter` - Local storage
- `camera` - Camera access for OMR
- `opencv_dart` ^1.4.3 - Image processing for OMR
- `pdf` + `printing` - PDF generation
- `path_provider` - File system paths
- `permission_handler` - Camera/storage permissions
- `flutter_lints` - Recommended lints (dev dependency)
- `build_runner`, `injectable_generator`, `hive_generator` - Code generation (dev dependencies)

When adding new dependencies, run `flutter pub get` to install them.

# Progress

## Session: 2025-11-28

**Task 0.0 Completed: POC Flutter Project Created**
- Created `omr_spike/` POC project with opencv_dart v1.4.3, image, path_provider, image_picker
- Configured Android minSdkVersion to 24 (⚠️ opencv_dart requires API 24+, conflicts with PRD's API 23 target)
- Verified iOS build (pods installed, Xcode build successful)
- Created folder structure: `lib/{models,services,utils}/`, `assets/`, `test/`
- Created `lib/utils/cv_utils.dart` helper for Mat disposal

**Task 1.0 Completed: Test Assets & Template Configuration**
- Created `lib/models/template_config.dart` with template dimensions (800x1100), bubble positions (5 questions x 5 options)
- Generated `assets/marker.png` (50x50 solid black square)
- Generated `assets/test_sheet_blank.png` (800x1100 with corner markers, name field, and 5 questions)
- Generated `assets/test_sheet_filled.png` with answers: Q1=B, Q2=A, Q3=D, Q4=C, Q5=E
- Recorded test answers in `kTestSheetAnswers` constant for verification
- Added assets to `pubspec.yaml`
- Created asset loading test UI in `main.dart`

**Task 2.0 Completed: Image Preprocessor**
- Implemented `lib/services/image_preprocessor.dart`: uint8ListToMat(), matToUint8List(), preprocess()
- Preprocessing pipeline: grayscale → CLAHE → normalization with proper Mat disposal
- Added test UI button in `main.dart`, verified macOS build succeeds
- Note: opencv_dart tests require platform runtime (cannot use `flutter test`)

**Next: Task 3.0** - Implement Marker Detection
