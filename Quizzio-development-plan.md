# 📋 QuizziO Development Tasks v2.0

> **Project:** QuizziO - OMR Scanner for Teachers
> **Approach:** Risk-First + Vertical Slices
> **Total Sub-tasks:** 69
> **Estimated Duration:** ~21-29 days

---

## 📊 Progress Overview

| Task | Description | Sub-tasks | Status |
|------|-------------|-----------|--------|
| 0.0 | Project Setup | 7 | ⬜ |
| 1.0 | Data Layer Foundation | 10 | ⬜ |
| 2.0 | Quiz Management (Screens 1, 2, 3) | 8 | ⬜ |
| 3.0 | Answer Key Management (Screen 4) | 6 | ⬜ |
| 4.0 | Camera & Scanning (Screen 5) | 14 | ⬜ |
| 5.0 | Results Management (Screen 6) | 8 | ⬜ |
| 6.0 | PDF Export & Polish | 8 | ⬜ |
| 7.0 | Testing & Validation | 8 | ⬜ |

---

## [ ] Task 0.0: Create Feature Branch & Project Setup

**Priority:** 🔴 Critical
**Estimated:** 1-2 days
**Description:** Create Flutter project with clean architecture structure, configure dependencies, set up DI container, migrate OMR services from spike. Note: Android minSdkVersion = 24 (not 23 per spike findings)

### Sub-tasks:

- [ ] **0.0.1 - Create Flutter Project**
  - Run `flutter create quizzio` with org identifier
  - Verify project builds on iOS and Android simulators
  - **Output:** Empty Flutter project

- [ ] **0.0.2 - Configure pubspec.yaml Dependencies**
  - Add all dependencies per Tech Stack:
    ```yaml
    # UI
    cupertino_icons: ^1.0.8
    flutter_svg: ^2.0.14
    
    # State Management
    flutter_bloc: ^9.1.1
    equatable: ^2.0.7
    
    # DI
    get_it: ^9.0.5
    injectable: ^2.6.0
    
    # Database
    hive: ^2.2.3
    hive_flutter: ^1.1.0
    
    # Camera
    camera: ^0.11.3
    permission_handler: ^12.0.1
    
    # OMR
    opencv_dart: ^1.4.3
    image: ^4.3.0
    
    # PDF & Export
    pdf: ^3.11.3
    printing: ^5.13.4
    share_plus: ^10.1.5
    path_provider: ^2.1.5
    
    # Utils
    uuid: ^4.5.1
    intl: ^0.20.1
    collection: ^1.19.1
    ```
  - Add dev_dependencies (build_runner, hive_generator, injectable_generator, bloc_test, mocktail)
  - **Output:** Complete pubspec.yaml

- [ ] **0.0.3 - Configure Platform Settings**
  - Android: Set `minSdkVersion 24` in build.gradle
  - Android: Add camera permission to AndroidManifest.xml
  - iOS: Add camera usage description to Info.plist
  - iOS: Set minimum deployment target to 12.0
  - **Output:** Platform configs ready

- [ ] **0.0.4 - Create Clean Architecture Folder Structure**
  ```
  lib/
  ├── main.dart
  ├── app.dart
  ├── injection.dart
  ├── core/
  │   ├── constants/
  │   ├── errors/
  │   ├── services/
  │   ├── utils/
  │   └── extensions/
  ├── features/
  │   ├── quiz/
  │   │   ├── data/
  │   │   ├── domain/
  │   │   └── presentation/
  │   ├── omr/
  │   │   ├── data/
  │   │   ├── domain/
  │   │   ├── services/
  │   │   └── presentation/
  │   └── export/
  └── assets/
      └── templates/
  ```
  - **Output:** Empty folder structure with placeholder files
  - **Note:** Use cases layer deferred for MVP - BLoCs call repositories directly

- [ ] **0.0.5 - Set Up Dependency Injection**
  - Create `injection.dart` with get_it configuration
  - Create `@InjectableInit` setup
  - Run `build_runner` to generate injection.config.dart
  - **Output:** DI container ready

- [ ] **0.0.6 - Migrate OMR Services from Spike**
  - Copy and adapt from `omr_spike/`:
    - `image_preprocessor.dart` → `lib/features/omr/services/`
    - `marker_detector.dart` → `lib/features/omr/services/`
    - `perspective_transformer.dart` → `lib/features/omr/services/`
    - `bubble_reader.dart` → `lib/features/omr/services/`
    - `threshold_calculator.dart` → `lib/features/omr/services/`
    - `answer_extractor.dart` → `lib/features/omr/services/`
    - `omr_pipeline.dart` → `lib/features/omr/services/omr_scanner_service.dart`
  - Register services with DI container
  - **Output:** OMR services integrated

- [ ] **0.0.7 - Create App Entry Point**
  - Create `main.dart` with Hive init, DI init, runApp
  - Create `app.dart` with MaterialApp, Material3 theme, routes
  - Verify app launches on both platforms
  - **Output:** App shell running

---

## [ ] Task 1.0: Data Layer Foundation (Models, Database, Assets)

**Priority:** 🔴 Critical
**Estimated:** 2-3 days
**Description:** Implement Hive database setup with QuizBox and ScanResultBox, create all data models, repository implementations, TemplateManager service, and template assets

### Sub-tasks:

- [ ] **1.0.1 - Create Domain Entities**
  - `lib/features/quiz/domain/entities/quiz.dart`
    ```dart
    class Quiz {
      final String id;
      final String name;
      final String templateId;
      final DateTime createdAt;
      final Map<String, String> answerKey; // {'q1': 'A', 'q2': 'C', ...}
    }
    ```
  - `lib/features/omr/domain/entities/omr_template.dart`
  - `lib/features/omr/domain/entities/field_block.dart`
  - `lib/features/omr/domain/entities/scan_result.dart` (per PRD Section 8.2)
  - `lib/features/omr/domain/entities/graded_result.dart`
  - Define `AnswerStatus` enum: `VALID`, `BLANK`, `MULTIPLE_MARK`
  - **Output:** 5+ entity classes

- [ ] **1.0.2 - Create Data Models with Hive Adapters**
  - `quiz_model.dart` with `@HiveType(typeId: 0)` annotations
  - `scan_result_model.dart` with `@HiveType(typeId: 1)` annotations
  - Run `build_runner` to generate adapters
  - Create `toEntity()` and `fromEntity()` mappers
  - **Output:** Hive-compatible models

- [ ] **1.0.3 - Set Up Hive Database**
  - Initialize Hive in `main.dart`
  - Register all type adapters
  - Create `QuizBox` and `ScanResultBox` box names
  - Create `hive_boxes.dart` constants
  - **Output:** Hive ready to use

- [ ] **1.0.4 - Create Repository Interfaces**
  - `lib/features/quiz/domain/repositories/quiz_repository.dart`
    ```dart
    abstract class QuizRepository {
      Future<List<Quiz>> getAllQuizzes();
      Future<Quiz?> getQuizById(String id);
      Future<void> createQuiz(Quiz quiz);
      Future<void> updateQuiz(Quiz quiz);
      Future<void> deleteQuiz(String id);
    }
    ```
  - `lib/features/omr/domain/repositories/scan_repository.dart`
  - `lib/features/omr/domain/repositories/template_repository.dart`
  - **Output:** 3 repository interfaces

- [ ] **1.0.5 - Create Repository Implementations**
  - `quiz_repository_impl.dart` using Hive
  - `scan_repository_impl.dart` using Hive
  - `template_repository_impl.dart` loading from assets
  - Register with DI container
  - **Output:** 3 repository implementations

- [ ] **1.0.6 - Create TemplateManager Service**
  - Load template JSONs from assets
  - Parse into `OmrTemplate` entities
  - Cache loaded templates
  - Provide marker image bytes
  - **Output:** TemplateManager service

- [ ] **1.0.7 - Create Template JSON Assets**
  - `assets/templates/template_10q.json` (10 questions layout)
  - `assets/templates/template_20q.json` (20 questions layout)
  - `assets/templates/template_50q.json` (50 questions layout)
  - Follow schema from PRD Section 8.1
  - **Output:** 3 template JSON files

- [ ] **1.0.8 - Add Marker Image Asset**
  - Copy `marker.png` from spike to `assets/templates/`
  - Verify dimensions: 150×150px solid black square (per PRD Appendix A)
  - Register assets in pubspec.yaml
  - **Output:** marker.png accessible

- [ ] **1.0.9 - Write Unit Tests for Data Layer**
  - Test model serialization/deserialization
  - Test repository CRUD operations (mock Hive)
  - Test TemplateManager loading
  - **Output:** Data layer tests passing

- [ ] **1.0.10 - Create Printable Answer Sheet PDFs**
  - Design answer sheets per PRD Appendix A specifications
  - Create 3 printable PDFs: `answer_sheet_10q.pdf`, `answer_sheet_20q.pdf`, `answer_sheet_50q.pdf`
  - Add to `assets/templates/`
  - **Output:** 3 printable PDF files

---

## [ ] Task 2.0: Quiz Management - Vertical Slice 1 (Screens 1, 2, 3)

**Priority:** 🔴 Critical
**Estimated:** 3-4 days
**Description:** Build complete quiz CRUD flow: Quizzes list screen, New Quiz popup, Quiz Menu screen with QuizBloc state management

### Sub-tasks:

- [ ] **2.0.1 - Create QuizBloc**
  - Define states: `QuizInitial`, `QuizLoading`, `QuizLoaded`, `QuizError`
  - Define events: `LoadQuizzes`, `CreateQuiz`, `UpdateQuiz`, `DeleteQuiz`
  - Implement event handlers using QuizRepository
  - Register with DI
  - **Output:** QuizBloc complete

- [ ] **2.0.2 - Build Screen 1: Quizzes List Page**
  - Create `quizzes_page.dart`
  - AppBar with title "Quizzes"
  - ListView.builder showing QuizCard widgets
  - FloatingActionButton for "Create New"
  - Empty state when no quizzes
  - Loading state
  - **Output:** Screen 1 UI

- [ ] **2.0.3 - Build QuizCard Widget**
  - Display quiz name and date
  - Tap navigates to Quiz Menu (Screen 3)
  - Optional: swipe to delete
  - **Output:** Reusable QuizCard widget

- [ ] **2.0.4 - Build Screen 2: New Quiz Dialog**
  - Create `new_quiz_dialog.dart`
  - Form fields: Name (text), Template (dropdown), Date (auto)
  - Template options: "10 Questions", "20 Questions", "50 Questions"
  - Cancel and "Create Quiz" buttons
  - Validation: name required, template required
  - On create: dispatch `CreateQuiz` event, close dialog
  - **Output:** Screen 2 UI

- [ ] **2.0.5 - Build Screen 3: Quiz Menu Page**
  - Create `quiz_menu_page.dart`
  - Display quiz name and date at top
  - Three main buttons: "Edit Answer Key" → Screen 4, "Scan Papers" → Screen 5, "Graded Papers" → Screen 6
  - Back button → Screen 1
  - Edit button → Screen 2 (pre-filled)
  - **Output:** Screen 3 UI

- [ ] **2.0.6 - Set Up Navigation/Routing**
  - Configure named routes or GoRouter
  - Pass quiz ID between screens
  - Handle back navigation
  - **Output:** Navigation working

- [ ] **2.0.7 - Connect UI to BLoC**
  - Wrap screens with BlocProvider
  - Use BlocBuilder for reactive UI
  - Handle loading/error states
  - **Output:** Full integration

- [ ] **2.0.8 - Write Widget Tests**
  - Test QuizCard rendering
  - Test NewQuizDialog form validation
  - Test navigation flows
  - **Output:** Widget tests passing

---

## [ ] Task 3.0: Answer Key Management - Vertical Slice 2 (Screen 4)

**Priority:** 🔴 Critical
**Estimated:** 2-3 days
**Description:** Build answer key editor screen with per-question option selection (A-E), persist to Quiz entity via repository

### Sub-tasks:

- [ ] **3.0.1 - Create AnswerKeyCubit**
  - State: `Map<String, String?>` (question → selected option)
  - Methods: `selectAnswer(questionId, option)`, `saveAnswerKey()`, `loadAnswerKey(quiz)`
  - Inject QuizRepository for persistence
  - **Output:** AnswerKeyCubit complete

- [ ] **3.0.2 - Build Screen 4: Edit Answer Key Page**
  - Create `edit_answer_key_page.dart`
  - AppBar with "Edit Answer Key" title and back button
  - Scrollable list of questions based on template
  - **Output:** Screen 4 shell

- [ ] **3.0.3 - Build AnswerKeyRow Widget**
  - Display question number (1, 2, 3...)
  - 5 option buttons (A, B, C, D, E)
  - Selected option highlighted (filled)
  - Tap to select/change
  - **Output:** AnswerKeyRow widget

- [ ] **3.0.4 - Implement Auto-Save or Save Button**
  - Option A: Auto-save on each selection change
  - Option B: Save button in AppBar
  - Update Quiz entity with new answer key
  - Show save confirmation (snackbar)
  - **Output:** Persistence working

- [ ] **3.0.5 - Handle Edge Cases**
  - Load existing answer key when editing
  - Handle incomplete answer key (warn user)
  - Validate before allowing scan (optional)
  - **Output:** Robust UX

- [ ] **3.0.6 - Write Tests**
  - Test AnswerKeyCubit state changes
  - Test answer key persistence
  - Test UI interaction
  - **Output:** Tests passing

---

## [ ] Task 4.0: Camera & Scanning - Vertical Slice 3 (Screen 5) 🔥

**Priority:** 🔴 Critical
**Estimated:** 5-6 days
**Description:** Implement CameraService, real-time marker detection on preview frames, alignment overlay UI, auto-capture logic, execute full OMR pipeline, grade against answer key, display scan result popup, save ScanResult to database

### Sub-tasks:

- [ ] **4.0.1 - Create CameraService**
  - `lib/core/services/camera_service.dart`
  - Methods: `initialize()`, `dispose()`, `previewStream`, `captureImage()`, `setFlashMode()`
  - Handle camera lifecycle
  - Register with DI
  - **Output:** CameraService complete

- [ ] **4.0.2 - Handle Camera Permissions**
  - Request camera permission on screen open
  - Handle permission denied gracefully
  - Show settings prompt if permanently denied
  - **Output:** Permission flow working

- [ ] **4.0.3 - Create ScannerBloc**
  - States: `ScannerInitial`, `ScannerInitializing`, `ScannerPreviewing`, `ScannerAligning`, `ScannerCapturing`, `ScannerProcessing`, `ScannerResult`, `ScannerError`
  - Events: `InitializeScanner`, `MarkerDetected`, `MarkersLost`, `CaptureTriggered`, `ProcessComplete`, `SaveResult`, `ResetScanner`
  - Implement state machine per PRD Appendix C
  - **Output:** ScannerBloc complete

- [ ] **4.0.4 - Build Screen 5: Scan Papers Page**
  - Create `scan_papers_page.dart`
  - Full-screen camera preview (target 30 FPS)
  - Support both portrait and landscape orientations
  - AppBar with back button and flash toggle
  - Bottom bar showing "Scanned: X" count
  - Manual capture button (always visible, fallback when auto-capture fails)
  - **Output:** Screen 5 shell

- [ ] **4.0.5 - Build AlignmentOverlay Widget**
  - 4 corner guide markers
  - States: red (not detected), green (detected)
  - Pulsing animation when searching
  - Position guides at expected marker locations
  - **Output:** AlignmentOverlay widget

- [ ] **4.0.6 - Implement Real-Time Marker Detection**
  - Process preview frames at ~10 FPS (< 100ms/frame per PRD)
  - Run lightweight marker detection (downscaled)
  - Update overlay state based on detection
  - Debounce to avoid flicker
  - **Output:** Real-time detection working

- [ ] **4.0.7 - Implement Auto-Capture Logic**
  - Require all 4 markers detected
  - Require 3 consecutive successful detections
  - Wait 500ms stable before capture
  - Trigger haptic feedback on alignment
  - Play shutter sound on capture
  - **Output:** Auto-capture working

- [ ] **4.0.8 - Execute Full OMR Pipeline on Capture**
  - Capture high-resolution image
  - Run OmrScannerService pipeline: Preprocess → Detect → Transform → Read → Threshold → Extract
  - Handle pipeline errors gracefully
  - **Output:** OMR execution integrated

- [ ] **4.0.9 - Create GradingService**
  - `lib/features/omr/services/grading_service.dart`
  - Compare extracted answers to answer key
  - Calculate: correct, incorrect, blank, multipleMarks, total, percentage
  - Return `GradedResult` with `Map<String, QuestionResult>` per question
  - **Output:** GradingService complete

- [ ] **4.0.10 - Extract Name Region Image**
  - Crop name region from aligned image per template config
  - Convert to PNG bytes
  - Store as `Uint8List` in ScanResult
  - **Output:** Name capture working

- [ ] **4.0.11 - Build ScanResultPopup Widget**
  - Modal bottom sheet or dialog
  - Show cropped name image
  - Display: "Score: 18/20 (90%)"
  - Show blank count and multiple mark count
  - "View Details" button (optional for MVP)
  - "Rescan" and "Save" buttons
  - **Output:** ScanResultPopup widget

- [ ] **4.0.12 - Save ScanResult to Database**
  - Create ScanResult with all fields per PRD Section 8.2:
    - `id` (UUID), `quizId`, `scannedAt`
    - `nameRegionImage` (Uint8List)
    - `detectedAnswers`, `answerStatuses`, `correctedAnswers` (init empty)
    - `score`, `total`, `percentage`
    - `wasEdited` (init false), `scanConfidence`, `rawBubbleValues` (optional)
  - `scanConfidence` = threshold gap confidence from ThresholdCalculator
  - Save via ScanRepository
  - Increment scanned count, return to preview
  - **Output:** Persistence complete

- [ ] **4.0.13 - Handle Error States**
  - Camera unavailable error
  - Detection failed error
  - Processing failed error
  - Show appropriate messages with retry option
  - **Output:** Error handling complete

- [ ] **4.0.14 - Write Tests**
  - Unit test GradingService
  - Test ScannerBloc state transitions
  - Test auto-capture logic
  - **Output:** Tests passing

---

## [ ] Task 5.0: Results Management & Manual Correction - Vertical Slice 4 (Screen 6)

**Priority:** 🔴 Critical
**Estimated:** 3-4 days
**Description:** Build graded papers list screen showing name images + scores, implement detail view with per-question breakdown, build manual correction UI, recalculate score on edits, preserve original vs corrected answers

### Sub-tasks:

- [ ] **5.0.1 - Create GradedPapersBloc**
  - States: `GradedPapersLoading`, `GradedPapersLoaded`, `GradedPapersEmpty`
  - Events: `LoadGradedPapers`, `DeleteScanResult`, `UpdateScanResult`
  - Load scan results by quizId
  - Sort by scannedAt descending
  - **Output:** GradedPapersBloc complete

- [ ] **5.0.2 - Build Screen 6: Graded Papers Page**
  - Create `graded_papers_page.dart`
  - AppBar with "Graded Papers" title, back button, share icon
  - ListView of graded paper cards
  - Empty state when no scans
  - **Output:** Screen 6 shell

- [ ] **5.0.3 - Build GradedPaperCard Widget**
  - Display name region image (thumbnail)
  - Show score: "18/20 (90%)"
  - Show warning icon if has multiple marks or blanks
  - Tap to view details
  - **Output:** GradedPaperCard widget

- [ ] **5.0.4 - Build ScanResultDetail Page/Sheet**
  - Show large name image
  - Display score summary
  - List all questions with: Detected answer (or BLANK/MULTI), Correct answer, ✅ or ❌ indicator
  - Highlight questions needing attention
  - **Output:** Detail view UI

- [ ] **5.0.5 - Implement Manual Correction Flow**
  - Tap question to edit detected answer
  - Show A/B/C/D/E selector (or BLANK)
  - Update `correctedAnswers` map (preserve original in `detectedAnswers`)
  - Recalculate score immediately
  - Mark `wasEdited = true`
  - **Output:** Correction flow working

- [ ] **5.0.6 - Persist Manual Corrections**
  - Save updated ScanResult via repository
  - Show save confirmation
  - Reflect changes in list view
  - **Output:** Corrections saved

- [ ] **5.0.7 - Implement Delete Functionality**
  - Swipe to delete or delete button
  - Confirmation dialog
  - Remove from database
  - Update list
  - **Output:** Delete working

- [ ] **5.0.8 - Write Tests**
  - Test GradedPapersBloc
  - Test manual correction logic
  - Test score recalculation
  - **Output:** Tests passing

---

## [ ] Task 6.0: PDF Export & Polish

**Priority:** 🟡 High
**Estimated:** 2-3 days
**Description:** Implement PdfExportService with name images and scores per PRD layout spec, share via system share sheet, comprehensive error handling, loading states, empty states, final UI polish

### Sub-tasks:

- [ ] **6.0.1 - Create PdfExportService**
  - `lib/features/export/services/pdf_export_service.dart`
  - Method: `Future<Uint8List> generateResultsPdf(Quiz quiz, List<ScanResult> results)`
  - Use `pdf` package for generation
  - **Output:** Service shell

- [ ] **6.0.2 - Implement PDF Layout Per PRD Spec**
  - Header: Quiz name, date, total students, average score
  - Table columns: #, Student Name (image), Score
  - Embed name region images (scaled to max 200px width)
  - Score format: "18/20 (90%)"
  - Footer: Page numbers only (no branding per PRD layout rules)
  - ~8-10 students per page
  - **Output:** PDF generation complete

- [ ] **6.0.3 - Implement Share Functionality**
  - Save PDF to temp directory
  - Use `share_plus` for system share sheet
  - Handle share errors
  - **Output:** Share working

- [ ] **6.0.4 - Add Export Button to Screen 6**
  - Share icon in AppBar
  - Show loading while generating
  - Trigger share on complete
  - **Output:** Export integrated

- [ ] **6.0.5 - Implement Comprehensive Error Handling**
  - Review all screens for error states
  - Add user-friendly error messages
  - Add retry mechanisms where appropriate
  - Log errors for debugging
  - **Output:** Error handling polished

- [ ] **6.0.6 - Add Loading States**
  - Skeleton loaders or spinners for: Quiz list, Answer key, Scanner initializing, PDF generating
  - **Output:** Loading UX complete

- [ ] **6.0.7 - Add Empty States**
  - "No quizzes yet" with create CTA
  - "No scanned papers" with scan CTA
  - **Output:** Empty states complete

- [ ] **6.0.8 - UI Polish Pass**
  - Consistent spacing and typography
  - Material 3 theming
  - Smooth transitions/animations
  - Haptic feedback on key actions
  - Accessibility (contrast, text scaling)
  - **Output:** Polished UI

---

## [ ] Task 7.0: Testing & Validation

**Priority:** 🟡 High
**Estimated:** 3-4 days
**Description:** Unit tests for all services, BLoC tests, widget tests, integration tests with golden images from spike, device testing on Android + iOS

### Sub-tasks:

- [ ] **7.0.1 - Unit Tests for All Services**
  - ImagePreprocessor, MarkerDetector, PerspectiveTransformer, BubbleReader tests
  - ThresholdCalculator, AnswerExtractor tests (already done in spike)
  - GradingService, PdfExportService tests
  - **Output:** Service tests passing

- [ ] **7.0.2 - BLoC/Cubit Tests**
  - QuizBloc, AnswerKeyCubit, ScannerBloc, GradedPapersBloc tests
  - Use `bloc_test` package
  - **Output:** BLoC tests passing

- [ ] **7.0.3 - Widget Tests**
  - QuizCard, NewQuizDialog, AnswerKeyRow, AlignmentOverlay, GradedPaperCard, ScanResultPopup widget tests
  - **Output:** Widget tests passing

- [ ] **7.0.4 - Integration Tests with Golden Images**
  - Copy test images from spike
  - Test full OMR pipeline with: Perfect alignment, Rotated (±10°, ±15°), Dim/bright lighting, Noisy images
  - Verify 98%+ accuracy
  - **Output:** Golden tests passing

- [ ] **7.0.5 - End-to-End Flow Tests**
  - Test: Create quiz → Set answers → Scan → View results → Export
  - Use integration_test package
  - Mock camera with test images
  - **Output:** E2E tests passing

- [ ] **7.0.6 - Device Testing Matrix**
  | Device | OS | Priority |
  |--------|-------|----------|
  | Pixel 4a | Android 13 | P0 |
  | Samsung A52 | Android 12 | P0 |
  | iPhone 12 | iOS 16 | P0 |
  | Xiaomi Redmi Note 10 | Android 11 | P1 |
  | iPhone SE | iOS 15 | P1 |
  - Test on physical devices
  - Document any device-specific issues
  - **Output:** Device compatibility verified

- [ ] **7.0.7 - Performance Validation**
  - Verify scan pipeline < 500ms
  - Verify marker detection < 100ms/frame
  - Verify app cold start < 3 seconds
  - Verify memory usage < 200MB during scanning
  - **Output:** Performance metrics met

- [ ] **7.0.8 - Bug Fixes & Final QA**
  - Address issues found in testing
  - Final regression pass
  - Prepare for release
  - **Output:** Release-ready build

---

## 📅 Recommended Execution Timeline

```
Week 1:     Task 0.0 (Setup) → Task 1.0 (Data Layer)
Week 2:     Task 2.0 (Quiz CRUD) → Task 3.0 (Answer Key)
Week 3-4:   Task 4.0 (Camera & Scanning) ← Heaviest task
Week 4-5:   Task 5.0 (Results) → Task 6.0 (Export & Polish)
Week 5-6:   Task 7.0 (Testing & Validation)
```

> **Note:** Timeline shows ~6 weeks with parallel work opportunities in weeks 3-5. Some tasks can overlap (e.g., PDF templates in 1.0.10 can be done while UI work proceeds).

---

## 📝 Notes

- **Spike Reference:** All OMR services validated in `omr_spike/` directory
- **API Level:** Android minSdkVersion must be 24 (not 23 as originally in PRD)
- **Critical Path:** Task 4.0 is the heaviest and most complex - plan buffer time
- **Dependencies:** Each vertical slice builds on previous tasks
- **Answer Statuses:** Use exact strings: `"VALID"`, `"BLANK"`, `"MULTIPLE_MARK"`
