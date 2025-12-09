# QuizziO - Development Plan v2.3 (Condensed)

## Context
> Offline-first mobile OMR scanner enabling teachers to instantly grade multiple-choice quizzes via smartphone camera with 98%+ accuracy.

**Goal:** Ship MVP with quiz creation, camera scanning, result editing, and PDF export — all offline.

**Current State:** 
- ✅ Clean architecture folders, OMR spike (98%+ validated), template JSONs, marker image
- 🔜 Next: Complete setup (dependencies, DI), then camera integration spike

**Reference:** `QuizziO-PRD.md`, `QuizziO-Tech-Stack.md`

---

## Tech Stack & Conventions

| Category | Technology | Version | Key Notes |
|----------|------------|---------|-----------|
| **Framework** | Flutter | 3.24+ | Cross-platform iOS + Android |
| **UI** | Material 3 | Built-in | `useMaterial3: true` |
| **State** | `flutter_bloc` | 9.1.1 | BLoC (complex) / Cubit (simple) |
| **DI** | `get_it` + `injectable` | 9.0.5 / 2.6.0 | Service locator |
| **Database** | `hive` + `hive_flutter` | 2.2.3 / 1.1.0 | NoSQL, pure Dart |
| **Camera** | `camera` + `permission_handler` | 0.11.3 / 12.0.1 | Official plugin + permissions |
| **OMR** | `opencv_dart` + `image` | 1.4.3 / 4.3.0 | Native OpenCV via FFI |
| **PDF** | `pdf` + `printing` + `share_plus` | 3.11.3 / 5.13.4 / 10.1.5 | Export + share |
| **Utils** | `uuid`, `intl`, `path_provider` | 4.5.1 / 0.20.1 / 2.1.5 | IDs, formatting, paths |
| **Testing** | `bloc_test`, `mocktail` | 9.1.8 / 1.0.5 | BLoC tests, mocking |
| **Code Gen** | `build_runner`, `hive_generator`, `injectable_generator` | 2.4.14 / 2.0.1 / 2.6.2 | Adapters, DI |
| **Min Android** | API 24 | Android 7.0 | ⚠️ opencv_dart requires 24 (not 23) |
| **Min iOS** | iOS 17.0+ | | ~98% coverage |

### Conventions
- **Architecture:** Clean (Presentation → Domain → Data)
- **File naming:** `snake_case.dart`
- **BLoC:** Events = past tense, States = nouns
- **Answer Status:** Enum serializes as uppercase strings: `"VALID"`, `"BLANK"`, `"MULTIPLE_MARK"`
- **Testing:** Unit tests alongside source, integration in `/test`

---

## Decisions Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Hive over SQLite | Pure Dart, no platform channels, faster key-value | PRD |
| opencv_dart for OMR | Native C++ speed, 98%+ accuracy validated | Spike |
| minSdk 24 (not 23) | opencv_dart requirement discovered in spike | Spike |
| Auto-capture | Better UX — hands-free when aligned | PRD |
| Name as image (no OCR) | Accuracy concerns, simpler MVP | PRD |
| Duplicate scans → new entry | No merge needed; manual delete | Scope |
| No negative marking | Simplifies MVP grading | Scope |
| Named routes (not GoRouter) | Simpler for MVP, no deep linking needed | v2.2 |
| Answer status as strings | DB compatibility per PRD 8.2 | PRD |
| Single quiz dialog | Code reuse for create/edit | v2.2 |

---

## Relevant Files

### Core Services (OMR)
| File | Purpose | Status |
|------|---------|--------|
| `features/omr/services/image_preprocessor.dart` | Grayscale, CLAHE, normalize | 📦 Migrate from spike |
| `features/omr/services/marker_detector.dart` | Corner template matching | 📦 Migrate |
| `features/omr/services/perspective_transformer.dart` | 4-point warp | 📦 Migrate |
| `features/omr/services/bubble_reader.dart` | ROI + mean intensity | 📦 Migrate |
| `features/omr/services/threshold_calculator.dart` | Gap-finding | 📦 Migrate |
| `features/omr/services/answer_extractor.dart` | Multi-mark/blank detection | 📦 Migrate |
| `features/omr/services/omr_scanner_service.dart` | Pipeline orchestrator | 📦 Migrate |
| `features/omr/services/grading_service.dart` | Score calculation | 🆕 Create |
| `features/omr/services/template_manager.dart` | Load JSON templates | 🆕 Create |
| `core/services/camera_service.dart` | Camera lifecycle | 🆕 Create |

### Data Layer
| File | Purpose | Status |
|------|---------|--------|
| `features/quiz/domain/entities/quiz.dart` | Quiz entity | 🆕 Create |
| `features/quiz/data/models/quiz_model.dart` | Hive model + adapter | 🆕 Create |
| `features/quiz/domain/repositories/quiz_repository.dart` | Interface | 🆕 Create |
| `features/quiz/data/repositories/quiz_repository_impl.dart` | Hive impl | 🆕 Create |
| `features/omr/domain/entities/{omr_template,field_block,scan_result,graded_result,answer_status}.dart` | OMR entities | 🆕 Create all |
| `features/omr/data/models/scan_result_model.dart` | Hive model + adapter | 🆕 Create |
| `features/omr/domain/repositories/{scan,template}_repository.dart` | Interfaces | 🆕 Create |
| `features/omr/data/repositories/{scan,template}_repository_impl.dart` | Implementations | 🆕 Create |

### Presentation Layer
| File | Purpose | Status |
|------|---------|--------|
| `features/quiz/presentation/bloc/quiz_bloc.dart` | Quiz CRUD state | 🆕 Create |
| `features/quiz/presentation/cubit/answer_key_cubit.dart` | Answer key editing | 🆕 Create |
| `features/quiz/presentation/pages/{quizzes,quiz_menu,edit_answer_key}_page.dart` | Screens 1, 3, 4 | 🆕 Create all |
| `features/quiz/presentation/widgets/{quiz_card,quiz_dialog,answer_key_row}.dart` | Quiz UI components | 🆕 Create all |
| `features/omr/presentation/bloc/{scanner,graded_papers}_bloc.dart` | Scanning + results state | 🆕 Create |
| `features/omr/presentation/pages/{scan_papers,graded_papers,scan_result_detail}_page.dart` | Screens 5, 6 + detail | 🆕 Create all |
| `features/omr/presentation/widgets/{alignment_overlay,scan_result_popup,graded_paper_card}.dart` | OMR UI components | 🆕 Create all |
| `features/export/services/pdf_export_service.dart` | PDF generation | 🆕 Create |

### Core/Shared
| File | Purpose | Status |
|------|---------|--------|
| `main.dart`, `app.dart` | Entry point + MaterialApp | 📝 Update |
| `injection.dart` | DI configuration | 🆕 Create |
| `core/constants/{hive_boxes,app_constants,omr_constants}.dart` | Constants | 🆕 Create all |

### Assets
| File | Purpose | Status |
|------|---------|--------|
| `assets/templates/marker.png` | Corner marker | ✅ Exists (verify) |
| `assets/templates/template_{10q,20q,50q}.json` | Templates | ✅ Exists (verify schema) |
| `assets/sheets/answer_sheet_{10q,20q,50q}.pdf` | Printable sheets | 🆕 Create |

### Notes
- **Tests:** `test/features/{feature}/...` mirrors source
- **Run tests:** `flutter test` (all) or `flutter test path/to_test.dart` (specific)
- **Code gen:** `dart run build_runner build`

---

## Tasks

### Phase 0: Foundation & Risk Mitigation
> Setup, migrate spike code, validate camera↔opencv bridge
**Est:** 2-3 days

- [x] **0.1 Project Dependencies**
  - [x] 0.1.1 Update `pubspec.yaml` with all dependencies from Tech Stack
  - [x] 0.1.2 `flutter pub get` and verify no conflicts
  - [x] 0.1.3 Update `AndroidManifest.xml`: `minSdkVersion 24`, camera/storage permissions
  - [x] 0.1.4 Update `Info.plist`: camera/photo permissions
  - **Done when:** `flutter doctor` passes, app builds on both platforms ✅

---

- [x] **0.2 Hive Setup**
  - [x] 0.2.1 Create `lib/core/constants/hive_boxes.dart`:
    ```dart
    class HiveBoxes {
      static const String quizzes = 'quizzes';
      static const String scanResults = 'scan_results';
    }
    ```
  - [x] 0.2.2 Initialize Hive in `main.dart`:
    ```dart
    await Hive.initFlutter();
    await Hive.openBox(HiveBoxes.quizzes);  // Untyped for now
    await Hive.openBox(HiveBoxes.scanResults);  // Will be typed in Phase 1
    ```
  - **Done when:** Hive boxes open without errors ✅

---

- [x] **0.3 Dependency Injection**
  - [x] 0.3.1 Create `lib/injection.dart` with `@InjectableInit()` annotation
  - [x] 0.3.2 Configure services, repos, BLoCs with `@injectable`, `@singleton`, `@lazySingleton`
  - [x] 0.3.3 Register in `main.dart`: `configureDependencies()` before `runApp()`
  - [x] 0.3.4 Run: `dart run build_runner build --delete-conflicting-outputs`
  - **Done when:** `injection.config.dart` generated, no DI errors ✅

---

- [x] **0.4 Asset Verification**
  - [x] 0.4.1 Verify `assets/templates/marker.png` exists and is 150x150px @ 300dpi
  - [x] 0.4.2 Verify `template_{10q,20q,50q}.json` match PRD schema (Appendix B)
  - [x] 0.4.3 Add assets to `pubspec.yaml`:
    ```yaml
    assets:
      - assets/templates/
      - assets/sheets/
    ```
  - **Done when:** `flutter build` includes assets ✅

---

- [ ] **0.5 Migrate Spike Services**
  - [ ] 0.5.1 Copy OMR services from spike to `lib/features/omr/services/`:
    - `image_preprocessor.dart`
    - `marker_detector.dart`
    - `perspective_transformer.dart`
    - `bubble_reader.dart`
    - `threshold_calculator.dart`
    - `answer_extractor.dart`
    - `omr_scanner_service.dart`
  - [ ] 0.5.2 Update imports to use project structure
  - [ ] 0.5.3 Add `@injectable` annotations to services
  - [ ] 0.5.4 Run `build_runner build`
  - **Done when:** Services compile, no import errors

---

- [ ] **0.6 Camera Integration Spike**
  - [ ] 0.6.1 Create `lib/core/services/camera_service.dart`:
    - Init camera with `availableCameras()`
    - Expose `Stream<CameraImage>` for preview
    - Provide `captureImage()` for high-res still
  - [ ] 0.6.2 Create minimal test page showing camera preview
  - [ ] 0.6.3 Test on both Android (YUV420) and iOS (BGRA8888)
  - [ ] 0.6.4 Convert `CameraImage` → `Uint8List` → feed to `MarkerDetector`
  - [ ] 0.6.5 Verify marker detection works in real-time (10 FPS)
  - **Done when:** Camera preview shows, markers detected live, prints coordinates

---

- [ ] **0.7 App Navigation Setup**
  - [ ] 0.7.1 Create route constants in `lib/core/constants/app_constants.dart`
  - [ ] 0.7.2 Configure `MaterialApp` in `app.dart` with named routes:
    - `/` → QuizzesPage
    - `/quiz-menu` → QuizMenuPage (with args)
    - `/edit-answer-key` → EditAnswerKeyPage (with args)
    - `/scan-papers` → ScanPapersPage (with args)
    - `/graded-papers` → GradedPapersPage (with args)
    - `/scan-result-detail` → ScanResultDetailPage (with args)
  - **Done when:** Navigation structure defined, routes registered

---

### Phase 1: Data Layer
> Build entities, models, repositories
**Est:** 2-3 days

- [ ] **1.1 Quiz Domain Layer**
  - [ ] 1.1.1 `domain/entities/quiz.dart`:
    ```dart
    class Quiz extends Equatable {
      final String id;
      final String name;
      final String templateId;
      final DateTime createdAt;
      final Map<String, String> answerKey; // {'q1': 'A', ...}
    }
    ```
  - [ ] 1.1.2 `domain/repositories/quiz_repository.dart` (interface):
    - `Future<List<Quiz>> getAll()`
    - `Future<Quiz?> getById(String id)`
    - `Future<void> save(Quiz quiz)`
    - `Future<void> delete(String id)`
  - **Done when:** Entities + interfaces compile

---

- [ ] **1.2 Quiz Data Layer**
  - [ ] 1.2.1 `data/models/quiz_model.dart` extends `Quiz`:
    ```dart
    @HiveType(typeId: 0)
    class QuizModel extends Quiz {
      // Hive fields with @HiveField annotations
      // toEntity() / fromEntity() methods
    }
    ```
  - [ ] 1.2.2 Run: `dart run build_runner build` → generates adapter
  - [ ] 1.2.3 Register adapter in `main.dart`: `Hive.registerAdapter(QuizModelAdapter())`
  - [ ] 1.2.4 `data/repositories/quiz_repository_impl.dart`:
    - Inject Hive box
    - Implement CRUD with box operations
  - **Done when:** Save/load works in basic test

---

- [ ] **1.3 OMR Domain Layer**
  - [ ] 1.3.1 `domain/entities/answer_status.dart`:
    ```dart
    enum AnswerType { valid, blank, multipleMark }
    
    class AnswerStatus extends Equatable {
      final String? value; // 'A', 'B', etc. or null
      final AnswerType type;
      
      String toJson() => type.name.toUpperCase(); // "VALID", "BLANK", "MULTIPLE_MARK"
    }
    ```
  - [ ] 1.3.2 Create entities: `OmrTemplate`, `FieldBlock`, `ScanResult`, `GradedResult`
  - [ ] 1.3.3 `domain/repositories/scan_repository.dart` + `template_repository.dart` (interfaces)
  - **Done when:** All entities compile with Equatable

---

- [ ] **1.4 OMR Data Layer**
  - [ ] 1.4.1 `data/models/scan_result_model.dart` extends `ScanResult`:
    ```dart
    @HiveType(typeId: 1)
    class ScanResultModel extends ScanResult {
      @HiveField(0) String id;
      @HiveField(1) String quizId;
      @HiveField(2) DateTime scannedAt;
      @HiveField(3) Uint8List nameRegionImage;
      @HiveField(4) Map<String, String?> detectedAnswers;
      @HiveField(5) Map<String, String> answerStatuses; // "VALID", "BLANK", "MULTIPLE_MARK"
      @HiveField(6) Map<String, String?> correctedAnswers;
      @HiveField(7) int score;
      @HiveField(8) int total;
      @HiveField(9) double percentage;
      @HiveField(10) bool wasEdited;
      @HiveField(11) double scanConfidence;
      @HiveField(12) String? rawBubbleValues; // JSON string for debug
    }
    ```
  - [ ] 1.4.2 Generate adapter, register in `main.dart`
  - [ ] 1.4.3 Implement `ScanRepositoryImpl` with Hive CRUD
  - [ ] 1.4.4 Implement `TemplateRepositoryImpl`:
    - Load JSONs from `assets/templates/` via `rootBundle`
    - Parse to `OmrTemplate` entities
    - Cache in memory
  - **Done when:** Template loads, scan result saves/loads

---

- [ ] **1.5 Supporting Services**
  - [ ] 1.5.1 `features/omr/services/template_manager.dart`:
    - Wrapper around `TemplateRepository`
    - `Future<OmrTemplate> getTemplate(String id)`
    - `List<String> getAvailableTemplateIds()`
  - [ ] 1.5.2 `features/omr/services/grading_service.dart`:
    - Input: `Map<String, AnswerStatus> extractedAnswers`, `Map<String, String> answerKey`
    - Output: `GradedResult` with correct/incorrect/blank/multiMark counts
    - Grading rules: correct=+1, all else=0
  - [ ] 1.5.3 Register both in DI
  - **Done when:** Services instantiate via DI, basic logic works

---

### Phase 2: Quiz Management (Screens 1-3)
> Quizzes list, create/edit, menu
**Est:** 2-3 days

- [ ] **2.1 QuizBloc**
  - [ ] 2.1.1 Events: `LoadQuizzes`, `CreateQuiz`, `UpdateQuiz`, `DeleteQuiz`
  - [ ] 2.1.2 States: `QuizInitial`, `QuizLoading`, `QuizLoaded`, `QuizError`
  - [ ] 2.1.3 Inject `QuizRepository`, implement event handlers
  - [ ] 2.1.4 Register in DI
  - **Done when:** BLoC tests pass (`bloc_test`)

---

- [ ] **2.2 Screen 1: Quizzes Page**
  - [ ] 2.2.1 Create `features/quiz/presentation/pages/quizzes_page.dart`
  - [ ] 2.2.2 Scaffold: AppBar("Quizzes"), FloatingActionButton(+), BlocBuilder(QuizBloc)
  - [ ] 2.2.3 Empty state: "No quizzes yet. Tap + to create one."
  - [ ] 2.2.4 List state: `ListView` of `QuizCard` widgets
  - [ ] 2.2.5 FAB → Show `QuizDialog` in create mode
  - [ ] 2.2.6 Card tap → Navigate to `/quiz-menu` with quiz ID
  - **Done when:** List displays, FAB opens dialog, tap navigates

---

- [ ] **2.3 QuizCard Widget**
  - [ ] 2.3.1 Create `features/quiz/presentation/widgets/quiz_card.dart`
  - [ ] 2.3.2 Display: Quiz name, date, template (e.g., "20 Questions")
  - [ ] 2.3.3 Trailing: Edit icon, Delete icon (with confirmation dialog)
  - [ ] 2.3.4 Dismissible for swipe-to-delete (optional)
  - **Done when:** Card renders correctly, delete works

---

- [ ] **2.4 QuizDialog (Screen 2)**
  - [ ] 2.4.1 Create `features/quiz/presentation/widgets/quiz_dialog.dart`
  - [ ] 2.4.2 Accept `Quiz? quiz` param (null = create mode, non-null = edit mode)
  - [ ] 2.4.3 Fields: Name (TextField), Template (DropdownButton), Date (DatePicker)
  - [ ] 2.4.4 Buttons: Cancel, Create/Save
  - [ ] 2.4.5 Validation: Name required, template required
  - [ ] 2.4.6 On save → Dispatch `CreateQuiz` or `UpdateQuiz` event
  - **Done when:** Create + edit both work, validation enforced

---

- [ ] **2.5 Screen 3: Quiz Menu Page**
  - [ ] 2.5.1 Create `features/quiz/presentation/pages/quiz_menu_page.dart`
  - [ ] 2.5.2 Load quiz by ID from route args
  - [ ] 2.5.3 AppBar: Quiz name, back button, edit icon (opens `QuizDialog` in edit mode)
  - [ ] 2.5.4 Body: 3 large buttons:
    - "Edit Answer Key" → Navigate to `/edit-answer-key`
    - "Scan Papers" → Navigate to `/scan-papers`
    - "Graded Papers" → Navigate to `/graded-papers`
  - **Done when:** Menu displays, all navigation works

---

### Phase 3: Answer Key Management (Screen 4)
> Edit answer key with live persistence
**Est:** 1-2 days

- [ ] **3.1 AnswerKeyCubit**
  - [ ] 3.1.1 State: `{ Map<String, String> answers, bool isSaving, String? error }`
  - [ ] 3.1.2 Methods:
    - `load(String quizId)` → Load from repo
    - `selectAnswer(String questionId, String option)` → Update map, debounce save
    - `save()` → Persist to repo
  - [ ] 3.1.3 Debounce: 500ms delay after last selection before auto-save
  - [ ] 3.1.4 Register in DI
  - **Done when:** Cubit tests pass, debounce works

---

- [ ] **3.2 Screen 4: Edit Answer Key Page**
  - [ ] 3.2.1 Create `features/quiz/presentation/pages/edit_answer_key_page.dart`
  - [ ] 3.2.2 Load quiz by ID, get question count from template
  - [ ] 3.2.3 AppBar: Quiz name, back button, save indicator (optional)
  - [ ] 3.2.4 Body: `ListView` of `AnswerKeyRow` widgets (one per question)
  - [ ] 3.2.5 Show SnackBar when auto-save completes
  - **Done when:** Page displays all questions, selection saves

---

- [ ] **3.3 AnswerKeyRow Widget**
  - [ ] 3.3.1 Create `features/quiz/presentation/widgets/answer_key_row.dart`
  - [ ] 3.3.2 Layout: `Row([ Text("1."), ChoiceChip("A"), ChoiceChip("B"), ... ])`
  - [ ] 3.3.3 ChoiceChips for A-E, selected state visual
  - [ ] 3.3.4 On tap → Call `cubit.selectAnswer(questionId, option)`
  - **Done when:** Selection is clear, state updates immediately

---

### Phase 4: Scanning (Screen 5)
> Camera view, alignment, auto-capture, processing
**Est:** 3-4 days (heaviest phase)

- [ ] **4.1 ScannerBloc State Machine**
  - [ ] 4.1.1 States: `Idle`, `Initializing`, `Previewing`, `Aligning`, `Capturing`, `Processing`, `Result`, `Error`
  - [ ] 4.1.2 Events: `InitCamera`, `MarkerDetected`, `MarkerLost`, `CaptureTriggered`, `ProcessingComplete`, `RescanRequested`, `ResultDismissed`, `ErrorOccurred`
  - [ ] 4.1.3 Inject: `CameraService`, `OmrScannerService`, `GradingService`, `ScanRepository`
  - [ ] 4.1.4 Logic:
    - `Previewing` → poll camera frames (10 FPS), detect markers
    - `Aligning` → markers stable for 500ms → emit `CaptureTriggered`
    - `Capturing` → capture high-res image → emit processing
    - `Processing` → run OMR pipeline → grade → save → emit `Result`
  - [ ] 4.1.5 Register in DI
  - **Done when:** State machine tests pass

---

- [ ] **4.2 Screen 5: Scan Papers Page**
  - [ ] 4.2.1 Create `features/omr/presentation/pages/scan_papers_page.dart`
  - [ ] 4.2.2 Scaffold: AppBar("Scan Papers"), back button, flash toggle
  - [ ] 4.2.3 Body: `BlocBuilder<ScannerBloc>` → render based on state
  - [ ] 4.2.4 `Previewing`: Camera preview + `AlignmentOverlay`
  - [ ] 4.2.5 `Processing`: Semi-transparent overlay + spinner + "Analyzing..."
  - [ ] 4.2.6 `Result`: Show `ScanResultPopup` dialog
  - [ ] 4.2.7 `Error`: Show error message with retry button
  - [ ] 4.2.8 Bottom bar: "Scanned: X / ∞", manual capture button
  - **Done when:** Full flow works from camera → result

---

- [ ] **4.3 AlignmentOverlay Widget**
  - [ ] 4.3.1 Create `features/omr/presentation/widgets/alignment_overlay.dart`
  - [ ] 4.3.2 CustomPaint with 4 corner squares (red when not detected, green when detected)
  - [ ] 4.3.3 Listen to `ScannerBloc` for marker confidence
  - [ ] 4.3.4 Pulsing animation when red, solid when green
  - [ ] 4.3.5 Center text: "Align sheet with corners" or "Hold steady..."
  - **Done when:** Guides are clear, state changes visible

---

- [ ] **4.4 ScanResultPopup Widget**
  - [ ] 4.4.1 Create `features/omr/presentation/widgets/scan_result_popup.dart`
  - [ ] 4.4.2 Dialog with:
    - Name region image (cropped from scan)
    - Score: "18 / 20 = 90%"
    - Blank answers: N
    - Multiple marks: N
    - Buttons: "View Details", "Rescan", "Save"
  - [ ] 4.4.3 "View Details" → Navigate to `/scan-result-detail` (Phase 5)
  - [ ] 4.4.4 "Rescan" → Dispatch `RescanRequested` event
  - [ ] 4.4.5 "Save" → Dispatch `ResultDismissed` event → back to `Previewing`
  - **Done when:** Popup displays correctly, all buttons work

---

- [ ] **4.5 Camera Frame Processing**
  - [ ] 4.5.1 In `ScannerBloc`: Stream camera frames from `CameraService`
  - [ ] 4.5.2 Throttle to 10 FPS (skip frames if processing)
  - [ ] 4.5.3 Convert `CameraImage` → `Uint8List` (handle YUV420/BGRA)
  - [ ] 4.5.4 Call `MarkerDetector.detect()`
  - [ ] 4.5.5 If detected (confidence > 0.3): Emit `MarkerDetected` event
  - [ ] 4.5.6 If stable for 500ms: Emit `CaptureTriggered`
  - **Done when:** Real-time detection works, auto-capture fires

---

- [ ] **4.6 High-Res Capture & Processing**
  - [ ] 4.6.1 On `Capturing` state → Call `CameraService.captureImage()`
  - [ ] 4.6.2 Feed to `OmrScannerService.scanAnswerSheet(image, template)`
  - [ ] 4.6.3 Get `ScanResult` with detected answers + statuses
  - [ ] 4.6.4 Call `GradingService.grade(scanResult, answerKey)`
  - [ ] 4.6.5 Get `GradedResult` with score
  - [ ] 4.6.6 Save to `ScanRepository`
  - [ ] 4.6.7 Emit `ProcessingComplete` event with result
  - **Done when:** Full pipeline executes <500ms, result saved

---

### Phase 5: Results Management (Screen 6)
> List graded papers, edit results, delete
**Est:** 2-3 days

- [ ] **5.1 GradedPapersBloc**
  - [ ] 5.1.1 Events: `LoadResults`, `UpdateResult`, `DeleteResult`
  - [ ] 5.1.2 States: `ResultsInitial`, `ResultsLoading`, `ResultsLoaded`, `ResultsError`
  - [ ] 5.1.3 Inject `ScanRepository`
  - [ ] 5.1.4 `LoadResults` → Fetch by quiz ID, sort by date
  - [ ] 5.1.5 `UpdateResult` → Update corrected answers, recalculate score, save
  - [ ] 5.1.6 `DeleteResult` → Remove from repo
  - [ ] 5.1.7 Register in DI
  - **Done when:** BLoC tests pass

---

- [ ] **5.2 Screen 6: Graded Papers Page**
  - [ ] 5.2.1 Create `features/omr/presentation/pages/graded_papers_page.dart`
  - [ ] 5.2.2 AppBar: Quiz name, back button, export icon (Phase 6)
  - [ ] 5.2.3 Load results on init: `context.read<GradedPapersBloc>().add(LoadResults(quizId))`
  - [ ] 5.2.4 Empty state: "No papers scanned yet"
  - [ ] 5.2.5 Loaded state: `ListView` of `GradedPaperCard` widgets
  - [ ] 5.2.6 Card tap → Navigate to `/scan-result-detail`
  - **Done when:** List displays, navigation works

---

- [ ] **5.3 GradedPaperCard Widget**
  - [ ] 5.3.1 Create `features/omr/presentation/widgets/graded_paper_card.dart`
  - [ ] 5.3.2 Layout: Row([ Name image (thumbnail), Score, Date, Delete icon ])
  - [ ] 5.3.3 Delete icon → Show confirmation dialog
  - [ ] 5.3.4 On confirm → Dispatch `DeleteResult` event
  - [ ] 5.3.5 Dismissible for swipe-to-delete (optional)
  - **Done when:** Card displays correctly, delete works

---

- [ ] **5.4 Screen: Scan Result Detail Page**
  - [ ] 5.4.1 Create `features/omr/presentation/pages/scan_result_detail_page.dart`
  - [ ] 5.4.2 Load result by ID from route args
  - [ ] 5.4.3 AppBar: "Scan Details", back button
  - [ ] 5.4.4 Body sections:
    - Name region image (full size)
    - Score summary
    - Question-by-question breakdown:
      - Question #, Detected answer, Correct answer, Status icon (✓/✗/⚠/∅)
      - Tap question → Edit dialog to override detected answer
  - [ ] 5.4.5 Edit dialog:
    - ChoiceChips for A-E + "Blank" + "Multiple Mark"
    - On save → Dispatch `UpdateResult` event
  - [ ] 5.4.6 Show "Edited" badge if `wasEdited == true`
  - **Done when:** Detail view displays, manual override works

---

### Phase 6: Export & Polish
> PDF generation, final UI touches
**Est:** 2-3 days

- [ ] **6.1 PdfExportService**
  - [ ] 6.1.1 Create `features/export/services/pdf_export_service.dart`
  - [ ] 6.1.2 Method: `Future<Uint8List> generateResultsPdf(Quiz quiz, List<ScanResult> results)`
  - [ ] 6.1.3 Layout (per PRD Appendix):
    - Header: Quiz name, date, student count, average
    - Table: # | Name image | Score
    - 8-10 students per page
    - Page numbers in footer
  - [ ] 6.1.4 Use `pdf` package for generation
  - [ ] 6.1.5 Return PDF bytes
  - [ ] 6.1.6 Register in DI
  - **Done when:** PDF generates with correct layout

---

- [ ] **6.2 Export Functionality**
  - [ ] 6.2.1 In `GradedPapersPage`: Add export icon to AppBar
  - [ ] 6.2.2 On tap → Show loading dialog
  - [ ] 6.2.3 Call `PdfExportService.generateResultsPdf()`
  - [ ] 6.2.4 Save to temp directory: `path_provider.getTemporaryDirectory()`
  - [ ] 6.2.5 Share via `share_plus`: `Share.shareXFiles([XFile(pdfPath)])`
  - [ ] 6.2.6 Handle errors gracefully
  - **Done when:** Share sheet opens with PDF, apps like Gmail receive it

---

- [ ] **6.3 UI Polish**
  - [ ] 6.3.1 Loading states: Show `CircularProgressIndicator` when appropriate
  - [ ] 6.3.2 Error states: User-friendly messages, retry buttons
  - [ ] 6.3.3 Empty states: Clear CTAs ("Create your first quiz", etc.)
  - [ ] 6.3.4 Confirmation dialogs: Delete quiz, delete result
  - [ ] 6.3.5 SnackBars: "Quiz created", "Answer key saved", "Result updated"
  - [ ] 6.3.6 Haptic feedback: On marker alignment, capture, errors
  - [ ] 6.3.7 Sound effects: Camera shutter sound on capture (optional)
  - **Done when:** App feels polished, feedback is clear

---

- [ ] **6.4 Performance Optimization**
  - [ ] 6.4.1 Profile scan pipeline: Ensure <500ms total
  - [ ] 6.4.2 Profile marker detection: Ensure <100ms per frame
  - [ ] 6.4.3 Use `Isolate` for heavy CV operations if needed
  - [ ] 6.4.4 Optimize image conversions (cache, reuse buffers)
  - [ ] 6.4.5 Test on low-end device, adjust if needed
  - **Done when:** Performance targets met (per PRD 6.1)

---

- [ ] **6.5 Error Handling**
  - [ ] 6.5.1 Camera errors: Permission denied, camera unavailable → Show friendly message + settings button
  - [ ] 6.5.2 Detection errors: Markers not found → "Ensure markers visible, adjust lighting"
  - [ ] 6.5.3 Processing errors: Scan failed → "Could not read answers. Try again."
  - [ ] 6.5.4 Repository errors: Save failed → "Could not save. Check storage."
  - [ ] 6.5.5 Network-agnostic error messages (offline by design)
  - **Done when:** All error paths have user-facing messages

---

### Phase 7: Testing & QA
> Unit, widget, integration, device testing
**Est:** 3-4 days

- [ ] **7.1 Service Unit Tests**
  - [ ] 7.1.1 Test all migrated OMR services (from spike)
  - [ ] 7.1.2 Test `GradingService` logic
  - [ ] 7.1.3 Test `TemplateManager` JSON loading
  - [ ] 7.1.4 Test `AnswerStatus` serialization
  - **Done when:** `flutter test test/features/*/services/` passes

---

- [ ] **7.2 BLoC/Cubit Tests**
  - [ ] 7.2.1 `QuizBloc`: All events + state transitions
  - [ ] 7.2.2 `AnswerKeyCubit`: Load, select, save, debounce
  - [ ] 7.2.3 `ScannerBloc`: Full state machine
  - [ ] 7.2.4 `GradedPapersBloc`: Load, update, delete
  - **Done when:** All BLoC tests pass with `bloc_test`

---

- [ ] **7.3 Widget Tests**
  - [ ] 7.3.1 Test key widgets: `QuizCard`, `QuizDialog`, `AnswerKeyRow`, `AlignmentOverlay`, `GradedPaperCard`, `ScanResultPopup`
  - [ ] 7.3.2 Test rendering, user interactions, state changes
  - **Done when:** Key widgets tested

---

- [ ] **7.4 Golden Image Tests (OMR)**
  - [ ] 7.4.1 Copy test images from spike: `omr_spike/assets/gallery/` → `test/fixtures/`
  - [ ] 7.4.2 Test scenarios:
    - Baseline filled sheet → 100% detection
    - Rotated sheets → perspective correction
    - Dim/bright lighting
    - Noisy/photocopied sheets
    - Multi-mark detection
    - Blank detection
  - [ ] 7.4.3 **Verify 98%+ overall accuracy** (per PRD success criteria)
  - **Done when:** Golden tests pass, accuracy documented

---

- [ ] **7.5 Integration Tests**
  - [ ] 7.5.1 Create `integration_test/app_test.dart`
  - [ ] 7.5.2 Test full user flow:
    1. Launch → Quizzes page (empty)
    2. Create quiz → appears in list
    3. Set answer key → save persists
    4. (Mock) Scan paper → result saved
    5. View graded papers → result appears
    6. Edit result → correction persists
    7. Export PDF → file generated
  - [ ] 7.5.3 Test edge cases: empty answer key, delete quiz with results
  - **Done when:** Integration tests pass

---

- [ ] **7.6 Device Testing**

  | Device | OS | Camera | Priority | Status |
  |--------|-------|--------|----------|--------|
  | Pixel 4a | Android 13 | 12MP | P0 | ⬜ |
  | Samsung A52 | Android 12 | 64MP | P0 | ⬜ |
  | iPhone 12 | iOS 17 | 12MP | P0 | ⬜ |
  | Xiaomi Redmi Note 10 | Android 11 | 48MP | P1 | ⬜ |
  | iPhone SE (2020) | iOS 17 | 12MP | P1 | ⬜ |
  | Low-end Android | Android 9+ | 8MP | P2 | ⬜ |

  - [ ] 7.6.1 Test core flows on all P0 devices
  - [ ] 7.6.2 Verify camera performance, scanning accuracy, UI rendering
  - [ ] 7.6.3 Document device-specific issues
  - **Done when:** Core flows work on P0 devices

---

- [ ] **7.7 Performance Validation**

  | Metric | Target | Status |
  |--------|--------|--------|
  | Scan pipeline | < 500ms | ⬜ |
  | Marker detection | < 100ms/frame | ⬜ |
  | App cold start | < 3s | ⬜ |
  | Memory during scan | < 200MB | ⬜ |
  | Battery (1hr scan) | < 5% | ⬜ |

  - [ ] 7.7.1 Profile critical paths with stopwatches
  - [ ] 7.7.2 Monitor memory in Flutter DevTools
  - [ ] 7.7.3 Optimize if metrics fail
  - **Done when:** All targets met

---

- [ ] **7.8 Final QA & Release Prep**
  - [ ] 7.8.1 Fix all P0 (critical) bugs
  - [ ] 7.8.2 Fix all P1 (major) bugs
  - [ ] 7.8.3 Document P2 bugs for post-launch
  - [ ] 7.8.4 Final regression: Test all screens end-to-end
  - [ ] 7.8.5 Build release: `flutter build apk --release` + `flutter build ipa --release`
  - [ ] 7.8.6 Test release builds on physical devices
  - [ ] 7.8.7 Create app icons, splash screen, version number
  - **Done when:** Release builds ready for distribution

---

## Blockers & Discoveries

| Issue | Impact | Resolution |
|-------|--------|------------|
| opencv_dart requires minSdk 24 | Can't support Android 6.0 | ✅ Accepted — covers 95%+ devices |
| PRD says minSdk 23, spike proved 24 | Documentation mismatch | ✅ Updated Dev Plan; PRD needs update |
| CameraImage format varies by platform | Need YUV420 + BGRA handling | 🔄 Handle in camera spike (0.6) |
| *Add discoveries during development* | | |

---

## Timeline Estimate

```
Week 1:   Phase 0 (Setup + Camera Spike) → Phase 1 (Data Layer)    [4-5 days]
Week 2:   Phase 2 (Quiz Management) → Phase 3 (Answer Key)         [5-6 days]
Week 3:   Phase 4 (Scanning) ← Heaviest phase                      [4-5 days]
Week 4:   Phase 4 (finish) → Phase 5 (Results)                     [4-5 days]
Week 5:   Phase 6 (Export + Polish) → Phase 7 (Testing)            [4-5 days]
```

**Total:** 19-26 days (4-5 weeks)

---

## Completion Checklist

### Pre-Release Verification
- [ ] All Phase 0-7 tasks checked off
- [ ] All tests passing: `flutter test` + integration
- [ ] No Dart analysis errors: `flutter analyze`
- [ ] Tested on all P0 devices
- [ ] Performance metrics met (PRD 6.1)
- [ ] Golden tests confirm 98%+ accuracy
- [ ] PDF export generates correct layout
- [ ] All error states have user-friendly messages

### Release Artifacts
- [ ] Release APK + IPA built and tested
- [ ] App icons, splash screen, version configured

### Documentation
- [ ] README updated
- [ ] Known issues documented
- [ ] PRD discrepancy noted (minSdk 24 vs 23)

---

*QuizziO Development Plan v2.3 (Condensed) — Streamlined for implementation*
*Reference: QuizziO-PRD.md, QuizziO-Tech-Stack.md*
