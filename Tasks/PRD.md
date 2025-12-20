# 📋 QuizziO OMR Scanner Module — Product Requirements Document (PRD)

---

## 1. 🎯 Executive Summary

### 1.1 Purpose

This PRD defines the implementation plan for **QuizziO's OMR (Optical Mark Recognition) Scanner Module** — the core feature that enables teachers to instantly grade multiple-choice answer sheets using their smartphone camera.

### 1.2 Background

QuizziO is a mobile app targeting teachers and professors who need a fast, offline-capable way to grade standardized tests. The OMR scanner eliminates manual grading by:

- Detecting pre-printed answer sheets via corner markers
- Reading filled bubbles (A-E) for each question
- Comparing against an answer key to produce instant scores

### 1.3 Solution Overview

We will build a **native Flutter OMR scanning engine** using `opencv_dart` for image processing. The implementation is inspired by the open-source OMRChecker project but simplified for our standardized template system.

```
┌─────────────────────────────────────────────────────────┐
│                   HIGH-LEVEL FLOW                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   📷 Camera    →    🔍 Detect    →    📐 Align         │
│      Feed           Markers           Sheet             │
│                                                         │
│        ↓                                                │
│                                                         │
│   ⚫ Read      →    📊 Calculate  →    ✅ Extract      │
│     Bubbles         Threshold          Answers          │
│                                                         │
│        ↓                                                │
│                                                         │
│   📝 Grade     →    💾 Save       →    📤 Export       │
│     Against         Result             PDF              │
│     Key                                                 │
│                                                         │
└─────────────────────────────────────────────────────────┘

```

---

## 2. 🚨 Problem Statement

### 2.1 Current Pain Points

| Pain Point | Impact | Frequency |
| --- | --- | --- |
| Manual grading is time-consuming | 2-3 hours for 30 students × 50 questions | Every test |
| Human error in counting | ~5% error rate in manual grading | Common |
| No instant feedback | Students wait days for results | Every test |
| Expensive Scantron machines | $500-2000+ hardware cost | One-time but prohibitive |
| Existing apps require internet | Can't use in exam halls with no WiFi | Frequent |

### 2.2 Target User

**Primary Persona: Mrs. Priya, High School Teacher**

- Teaches 4 classes of 35 students each
- Gives weekly MCQ quizzes (20 questions)
- Has a smartphone but limited tech expertise
- School has unreliable WiFi
- Needs results same day to adjust teaching

### 2.3 Success Criteria

| Metric | Target |
| --- | --- |
| Scan accuracy | ≥ 98% correct bubble detection |
| Scan speed | < 3 seconds per sheet |
| Offline capability | 100% functional without internet |
| User satisfaction | Can complete first scan within 2 minutes |

---

## 3. 📐 Scope

### 3.1 In Scope (MVP)

| Feature | Priority | Description |
| --- | --- | --- |
| **Template System** | P0 | Support 3 pre-defined templates (10, 20, 50 questions) |
| **Marker Detection** | P0 | Detect 4 corner markers for alignment |
| **Perspective Correction** | P0 | Handle tilted/skewed scans |
| **Bubble Reading** | P0 | Read A-E bubbles for each question |
| **Adaptive Threshold** | P0 | Handle varying lighting conditions |
| **Auto-Capture** | P0 | Trigger scan when markers aligned |
| **Name Region Capture** | P0 | Crop student name area as image |
| **Multi-mark Detection** | P0 | Flag questions with multiple marks |
| **Blank Detection** | P0 | Flag unanswered questions |
| **Manual Override** | P1 | Teacher can correct scan errors |
| **Real-time Preview** | P1 | Show alignment guides on camera |

### 3.2 Out of Scope (MVP)

| Feature | Reason | Future Phase |
| --- | --- | --- |
| Custom template creation | Complexity, low MVP value | v2.0 |
| OCR for student names | Accuracy concerns, adds complexity | v2.0 |
| Handwritten answer recognition | Different technology required | v3.0 |
| Cloud sync | MVP is offline-first | v2.0 |
| Batch scanning (multiple sheets at once) | Camera limitation | v2.0 |
| Negative marking | Grading rule complexity | v1.5 |

### 3.3 Assumptions

1. Answer sheets are printed on white/off-white paper
2. Bubbles are filled with dark pen/pencil (not highlighter)
3. Corner markers are clearly visible (not torn/covered)
4. Camera has at least 8MP resolution
5. Sheet is placed on contrasting background
6. Template coordinates are fixed-pixel at 300 DPI reference; ArUco markers use fixed size + inset padding for reliable detection

### 3.4 Constraints

| Constraint | Impact | Mitigation |
| --- | --- | --- |
| `opencv_dart` API stability | May need updates | Pin version, abstract interfaces |
| Mobile processing power | Affects scan speed | Optimize algorithms, test on low-end devices |
| Camera quality variance | Affects detection | Adaptive thresholds, user guidance |
| Print DPI variance | May cause marker/bubble alignment issues | Standardize on 300 DPI templates and fixed marker size/padding; DPI-agnostic coordinates deferred to v2.0 |

---

## 4. 👤 User Stories

### 4.1 Epic: Answer Sheet Scanning

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER STORY MAP                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  EPIC: As a teacher, I want to scan answer sheets so I can grade quickly   │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │   PREPARE       │  │     SCAN        │  │    REVIEW       │            │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤            │
│  │ US-1: Set       │  │ US-4: Align     │  │ US-7: View      │            │
│  │ answer key      │  │ sheet           │  │ scan result     │            │
│  │                 │  │                 │  │                 │            │
│  │ US-2: Select    │  │ US-5: Auto      │  │ US-8: Correct   │            │
│  │ template        │  │ capture         │  │ errors          │            │
│  │                 │  │                 │  │                 │            │
│  │ US-3: Print     │  │ US-6: See       │  │ US-9: Save      │            │
│  │ sheets          │  │ progress        │  │ result          │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

### 4.2 Detailed User Stories

### US-4: Align Sheet for Scanning (Core)

```
AS A        teacher
I WANT TO   see alignment guides on camera preview
SO THAT     I know when the sheet is positioned correctly

ACCEPTANCE CRITERIA:
─────────────────────
✓ Camera preview shows 4 corner guide markers
✓ Guides change color when real markers are detected
✓ Works in portrait and landscape orientation
✓ Provides haptic feedback when aligned

TECHNICAL NOTES:
────────────────
- Run marker detection at ~10 FPS on preview frames (minimum 5 FPS on low-end devices)
- Show green overlay when marker confidence > 0.3
- Debounce detection to avoid flicker

```

### US-5: Auto-Capture When Aligned (Core)

```
AS A        teacher
I WANT TO   have the scan trigger automatically
SO THAT     I don't have to tap a button while holding the sheet

ACCEPTANCE CRITERIA:
─────────────────────
✓ Scan triggers when all 4 markers detected for 500ms
✓ Audible "shutter" sound on capture
✓ Brief flash animation confirms capture
✓ Processing indicator shows while analyzing

TECHNICAL NOTES:
────────────────
• Require 3 consecutive successful detections
• Capture highest resolution frame (not preview frame)
• Run full pipeline on captured frame

```

### US-7: View Scan Result (Core)

```
AS A        teacher
I WANT TO   see the detected answers and score immediately
SO THAT     I can verify the scan was accurate

ACCEPTANCE CRITERIA:
─────────────────────
✓ Shows score as fraction and percentage (e.g., 18/20 = 90%)
✓ Shows count of blank answers
✓ Shows count of multiple-mark questions
✓ Displays cropped name region image
✓ Can tap to see per-question breakdown

TECHNICAL NOTES:
────────────────
• Result screen appears within 500ms of capture
• Store raw bubble values for debugging
• Allow dismissing to scan next sheet

```

### US-8: Correct Scan Errors (Core)

```
AS A        teacher
I WANT TO   manually fix incorrectly detected answers
SO THAT     the final grade is accurate

ACCEPTANCE CRITERIA:
─────────────────────
✓ Can tap any question to change detected answer
✓ Can mark as blank or multiple-mark manually
✓ Score updates in real-time when edited
✓ Original scan data preserved for audit

TECHNICAL NOTES:
────────────────
• Store both original_answer and corrected_answer
• Track which questions were manually edited
• Allow undo of corrections
• MVP storage: corrected_answer uses "A"-"E" or null (blank); use sentinel "MULTIPLE_MARK" for multi-mark
• Regrading uses the latest quiz answer key from local storage

```

---

## 5. 📋 Functional Requirements

### 5.1 Template Management

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-TM-01 | System shall support 3 template types: 10, 20, 50 questions | P0 | Bundled as JSON + ArUco marker config |
| FR-TM-02 | Templates shall define bubble positions as pixel coordinates | P0 | Based on 300dpi reference |
| FR-TM-03 | Templates shall define name region bounds | P0 | Top of sheet |
| FR-TM-04 | System shall load templates from app assets | P0 | No network required |
| FR-TM-05 | Each template shall include corner marker configuration | P0 | ArUco dictionary, IDs, size/padding |

### 5.2 Image Capture

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-IC-01 | System shall access device camera | P0 | Front or back |
| FR-IC-02 | System shall display real-time camera preview | P0 | 30 FPS minimum |
| FR-IC-03 | System shall overlay alignment guides on preview | P0 | 4 corner indicators |
| FR-IC-04 | System shall capture high-resolution still image | P0 | Native camera resolution |
| FR-IC-05 | System shall support both portrait and landscape | P1 | Detect orientation |

### 5.3 Marker Detection

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-MD-01 | System shall detect 4 corner ArUco markers (DICT_4X4_50, IDs 0-3) | P0 | ArUco detection (replaces template matching) |
| FR-MD-02 | ArUco marker IDs: TL=0, TR=1, BR=2, BL=3 | P0 | Fixed IDs per corner |
| FR-MD-03 | Detection is binary (found/not found) - no confidence threshold needed | P0 | ArUco encoding prevents false positives |
| FR-MD-04 | Detection shall complete within 60ms per frame | P0 | Performance budget |
| FR-MD-05 | System shall report which markers were detected for UI feedback | P1 | 0-4 markers found |

**Note:** ArUco markers replaced solid black square markers in v0.6.5 due to false positive issues with template matching on live camera feeds. ArUco markers have built-in encoding that prevents detection of random objects.

### 5.4 Image Processing

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-IP-01 | System shall convert captured image to grayscale | P0 | Prerequisite |
| FR-IP-02 | System shall apply CLAHE for contrast enhancement | P0 | Handles lighting |
| FR-IP-03 | System shall normalize pixel values to 0-255 | P0 | Consistent range |
| FR-IP-04 | System shall apply perspective transform to align sheet | P0 | 4-point warp |
| FR-IP-05 | Output image shall match template dimensions | P0 | Pixel-accurate |

### 5.5 Bubble Reading

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-BR-01 | System shall calculate mean intensity for each bubble ROI | P0 | cv.mean() |
| FR-BR-02 | System shall use adaptive threshold (gap-finding algorithm) | P0 | Global threshold derived from all bubble intensities per scan; optionally refined per field block if accuracy issues arise (similar to OMRChecker's global/local approach) |
| FR-BR-03 | Bubble below threshold shall be marked as "filled" | P0 | Dark = filled |
| FR-BR-04 | System shall detect exactly 5 options (A-E) per question | P0 | Fixed layout |
| FR-BR-05 | System shall handle all questions defined in template | P0 | 10, 20, or 50 |

### 5.6 Answer Extraction

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-AE-01 | Question with 0 filled bubbles → BLANK | P0 | null answer |
| FR-AE-02 | Question with 1 filled bubble → that option (A/B/C/D/E) | P0 | Valid answer |
| FR-AE-03 | Question with 2+ filled bubbles → MULTIPLE_MARK | P0 | Invalid, scores 0 |
| FR-AE-04 | System shall extract name region as PNG image | P0 | Crop from aligned image |
| FR-AE-05 | System shall report scan confidence score | P1 | Based on threshold gap |

### 5.7 Grading

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-GR-01 | Correct answer = +1 point | P0 | Simple scoring |
| FR-GR-02 | Incorrect answer = 0 points | P0 | No negative marking |
| FR-GR-03 | Blank answer = 0 points | P0 | Treated as wrong |
| FR-GR-04 | Multiple mark = 0 points | P0 | Treated as wrong |
| FR-GR-05 | System shall calculate percentage score | P0 | (correct / total) × 100 |

### 5.8 Result Management

| ID | Requirement | Priority | Notes |
| --- | --- | --- | --- |
| FR-RM-01 | System shall allow manual correction of any answer | P0 | Override detected |
| FR-RM-02 | System shall preserve original detected answers | P0 | Audit trail |
| FR-RM-03 | System shall save scan result to local database | P0 | SQLite/Hive |
| FR-RM-04 | Duplicate scans shall create new entries (no merge) | P0 | Per scope doc |
| FR-RM-05 | System shall store name region image as blob | P0 | For PDF export |

### **5.9 PDF Export**

| **ID** | **Requirement** | **Priority** | **Notes** |
| --- | --- | --- | --- |
| FR-EX-01 | System shall generate PDF from graded results | P0 | Single PDF per quiz |
| FR-EX-02 | PDF shall include quiz name and date | P0 | Header section |
| FR-EX-03 | PDF shall list each student with name image and score | P0 | One row per student |
| FR-EX-04 | Student name shall display as cropped image (not OCR text) | P0 | Preserves handwriting |
| FR-EX-05 | Score shall display as fraction and percentage | P0 | e.g., "18/20 (90%)" |
| FR-EX-06 | PDF shall be generated entirely offline | P0 | No network dependency |
| FR-EX-07 | System shall support sharing PDF via system share sheet | P1 | iOS/Android native share |
| FR-EX-08 | PDF page size shall be A4 or Letter (configurable) | P2 | Default: A4 |

### PDF Layout Specification:

```jsx
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PDF EXPORT LAYOUT                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │   Quiz: Chapter 5 - Cell Biology                                   │   │
│  │   Date: November 15, 2024                                          │   │
│  │   Total Students: 32    |    Average: 78.5%                        │   │
│  │                                                                     │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │   #    Student Name                              Score              │   │
│  │   ─────────────────────────────────────────────────────────────    │   │
│  │                                                                     │   │
│  │   1    ┌─────────────────────────┐              18/20 (90%)        │   │
│  │        │ [Handwritten Name Img]  │                                 │   │
│  │        └─────────────────────────┘                                 │   │
│  │                                                                     │   │
│  │   2    ┌─────────────────────────┐              15/20 (75%)        │   │
│  │        │ [Handwritten Name Img]  │                                 │   │
│  │        └─────────────────────────┘                                 │   │
│  │                                                                     │   │
│  │   3    ┌─────────────────────────┐              20/20 (100%)       │   │
│  │        │ [Handwritten Name Img]  │                                 │   │
│  │        └─────────────────────────┘                                 │   │
│  │                                                                     │   │
│  │   ...                                                               │   │
│  │                                                                     │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │   Page 1 of 4                          Generated by QuizziO        │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  LAYOUT RULES:                                                              │
│  • ~8-10 students per page (depending on name image height)                │
│  • Name images scaled to max 200px width, maintaining aspect ratio         │
│  • Scores right-aligned                                                    │
│  • No branding/watermarks (per scope requirement)                          │
│  • Footer with page numbers only                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 6. 🔧 Non-Functional Requirements

### 6.1 Performance

| ID | Requirement | Target | Measurement |
| --- | --- | --- | --- |
| NFR-P-01 | Full scan pipeline completion | < 500ms | From capture to result display |
| NFR-P-02 | Preview marker detection | < 100ms/frame | Allows 10 FPS detection |
| NFR-P-03 | App cold start time | < 3 seconds | To camera ready |
| NFR-P-04 | Memory usage during scan | < 200MB | Peak allocation |
| NFR-P-05 | Battery consumption | < 5%/hour active scanning | Continuous use |

### 6.2 Reliability

| ID | Requirement | Target | Notes |
| --- | --- | --- | --- |
| NFR-R-01 | Scan accuracy | ≥ 98% | Correct bubble detection |
| NFR-R-02 | False positive rate | < 1% | Incorrect "filled" detection |
| NFR-R-03 | False negative rate | < 1% | Missed "filled" detection |
| NFR-R-04 | Crash rate | < 0.1% | Per scanning session |
| NFR-R-05 | Data loss prevention | 0% | Scans must be saved |

### 6.3 Usability

| ID | Requirement | Target | Notes |
| --- | --- | --- | --- |
| NFR-U-01 | Time to first successful scan | < 2 minutes | New user |
| NFR-U-02 | Alignment guidance clarity | 90% success rate | First attempt |
| NFR-U-03 | Error message helpfulness | Actionable text | Not technical jargon |
| NFR-U-04 | Accessibility | WCAG 2.1 AA | Color contrast, text size |

### 6.4 Compatibility

| ID | Requirement | Target | Notes |
| --- | --- | --- | --- |
| NFR-C-01 | Android version | 6.0+ (API 23) | ~95% market coverage |
| NFR-C-02 | iOS version | 17.0+ | ~98% market coverage |
| NFR-C-03 | Device camera | 8MP+ | Minimum resolution |
| NFR-C-04 | Screen size | 4.7" - 12.9" | Phone and tablet |

### 6.5 Offline Capability

| ID | Requirement | Target | Notes |
| --- | --- | --- | --- |
| NFR-O-01 | Core scanning | 100% offline | No network calls |
| NFR-O-02 | Template loading | 100% offline | Bundled assets |
| NFR-O-03 | Result storage | 100% offline | Local database |
| NFR-O-04 | PDF export | 100% offline | Local generation |

---

## 7. 🏗️ Technical Architecture

### 7.1 Module Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MODULE DEPENDENCY GRAPH                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                           ┌─────────────────┐                               │
│                           │   UI Screens    │                               │
│                           │  (Presentation) │                               │
│                           └────────┬────────┘                               │
│                                    │                                        │
│                    ┌───────────────┼───────────────┐                       │
│                    │               │               │                       │
│                    ▼               ▼               ▼                       │
│           ┌──────────────┐ ┌──────────────┐ ┌──────────────┐              │
│           │   Scanner    │ │   Template   │ │   Grading    │              │
│           │   BLoC/      │ │   Cubit      │ │   Cubit      │              │
│           │   Controller │ │              │ │              │              │
│           └──────┬───────┘ └──────┬───────┘ └──────┬───────┘              │
│                  │                │                │                       │
│                  │         ┌──────┴───────┐        │                       │
│                  │         │              │        │                       │
│                  ▼         ▼              ▼        ▼                       │
│           ┌─────────────────────────────────────────────┐                  │
│           │              SERVICE LAYER                   │                  │
│           │  ┌───────────┐ ┌───────────┐ ┌───────────┐  │                  │
│           │  │OmrScanner │ │ Template  │ │ Grading   │  │                  │
│           │  │ Service   │ │ Manager   │ │ Service   │  │                  │
│           │  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘  │                  │
│           └────────┼─────────────┼─────────────┼────────┘                  │
│                    │             │             │                            │
│                    ▼             │             │                            │
│           ┌─────────────────┐    │             │                            │
│           │ IMAGE PROCESSING│    │             │                            │
│           │     LAYER       │    │             │                            │
│           │ ┌─────────────┐ │    │             │                            │
│           │ │  Marker     │ │    │             │                            │
│           │ │  Detector   │ │    │             │                            │
│           │ ├─────────────┤ │    │             │                            │
│           │ │ Perspective │ │    │             │                            │
│           │ │ Transformer │ │    │             │                            │
│           │ ├─────────────┤ │    │             │                            │
│           │ │  Bubble     │ │    │             │                            │
│           │ │  Reader     │ │    │             │                            │
│           │ ├─────────────┤ │    │             │                            │
│           │ │ Threshold   │ │    │             │                            │
│           │ │ Calculator  │ │    │             │                            │
│           │ └─────────────┘ │    │             │                            │
│           └────────┬────────┘    │             │                            │
│                    │             │             │                            │
│                    ▼             ▼             ▼                            │
│           ┌─────────────────────────────────────────────┐                  │
│           │                DATA LAYER                    │                  │
│           │  ┌───────────┐ ┌───────────┐ ┌───────────┐  │                  │
│           │  │ Template  │ │   Scan    │ │   Quiz    │  │                  │
│           │  │   Repo    │ │   Repo    │ │   Repo    │  │                  │
│           │  └───────────┘ └───────────┘ └───────────┘  │                  │
│           └─────────────────────────────────────────────┘                  │
│                              │                                              │
│                              ▼                                              │
│           ┌─────────────────────────────────────────────┐                  │
│           │              EXTERNAL DEPS                   │                  │
│           │  ┌───────────┐ ┌───────────┐ ┌───────────┐  │                  │
│           │  │opencv_dart│ │  camera   │ │   Hive/   │  │                  │
│           │  │           │ │           │ │  SQLite   │  │                  │
│           │  └───────────┘ └───────────┘ └───────────┘  │                  │
│           └─────────────────────────────────────────────┘                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

### 7.2 File Structure

```jsx
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── omr_constants.dart          # Thresholds, sizes
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── services/                        # 🆕 ADDED
│   │   └── camera_service.dart          # 🆕 Camera abstraction
│   ├── utils/
│   │   ├── image_utils.dart
│   │   └── math_utils.dart
│   └── extensions/
│       └── list_extensions.dart
│
├── features/
│   ├── quiz/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── quiz_model.dart
│   │   │   │   └── answer_key_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── quiz_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── quiz_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── quiz.dart
│   │   │   │   └── answer_key.dart
│   │   │   ├── repositories/
│   │   │   │   └── quiz_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_quiz.dart
│   │   │       └── get_quizzes.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── quiz_bloc.dart
│   │       ├── pages/
│   │       │   ├── quizzes_page.dart           # Screen 1
│   │       │   ├── quiz_menu_page.dart         # Screen 3
│   │       │   └── edit_answer_key_page.dart   # Screen 4
│   │       └── widgets/
│   │           ├── quiz_card.dart
│   │           └── new_quiz_dialog.dart        # Screen 2
│   │
│   ├── omr/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── omr_template_model.dart
│   │   │   │   ├── field_block_model.dart
│   │   │   │   ├── scan_result_model.dart
│   │   │   │   └── graded_result_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── template_asset_datasource.dart
│   │   │   │   └── scan_local_datasource.dart
│   │   │   └── repositories/
│   │   │       ├── template_repository_impl.dart
│   │   │       └── scan_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── omr_template.dart
│   │   │   │   ├── field_block.dart
│   │   │   │   ├── bubble.dart
│   │   │   │   ├── scan_result.dart
│   │   │   │   └── graded_result.dart
│   │   │   ├── repositories/
│   │   │   │   ├── template_repository.dart
│   │   │   │   └── scan_repository.dart
│   │   │   └── usecases/
│   │   │       ├── scan_answer_sheet.dart
│   │   │       └── grade_scan_result.dart
│   │   ├── services/                           # 🔥 CORE OMR ENGINE
│   │   │   ├── omr_scanner_service.dart        # Orchestrator
│   │   │   ├── marker_detector.dart            # Corner detection
│   │   │   ├── perspective_transformer.dart    # Warp correction
│   │   │   ├── image_preprocessor.dart         # CLAHE, normalize
│   │   │   ├── bubble_reader.dart              # ROI extraction
│   │   │   ├── threshold_calculator.dart       # Adaptive threshold
│   │   │   ├── answer_extractor.dart           # Logic extraction
│   │   │   └── grading_service.dart            # Score calculation
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── scanner_bloc.dart
│   │       │   └── graded_papers_bloc.dart
│   │       ├── pages/
│   │       │   ├── scan_papers_page.dart       # Screen 5
│   │       │   └── graded_papers_page.dart     # Screen 6
│   │       └── widgets/
│   │           ├── camera_preview.dart
│   │           ├── alignment_overlay.dart
│   │           ├── scan_result_popup.dart
│   │           └── graded_paper_card.dart
│   │
│   └── export/
│       ├── data/
│       │   └── repositories/
│       │       └── export_repository_impl.dart  # 🆕 ADDED
│       ├── domain/
│       │   └── usecases/
│       │       └── export_results_pdf.dart      # 🆕 ADDED
│       ├── services/
│       │   └── pdf_export_service.dart
│       └── presentation/
│           └── widgets/
│               └── export_button.dart
│
└── assets/
└── templates/
├── aruco_0.png                         # ArUco marker ID 0 (Top-Left)
├── aruco_1.png                         # ArUco marker ID 1 (Top-Right)
├── aruco_2.png                         # ArUco marker ID 2 (Bottom-Right)
├── aruco_3.png                         # ArUco marker ID 3 (Bottom-Left)
├── aruco_test_sheet.png                # Test sheet with all 4 ArUco markers
├── template_10q.json
├── template_20q.json
└── template_50q.json
```

### 7.3 Key Class Interfaces

---

```jsx
┌─────────────────────────────────────────────────────────────────────────────┐
│                         KEY CLASS INTERFACES                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                       CameraService                                │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // Lifecycle                                                     │     │
│  │  + Future<void> initialize()                                      │     │
│  │  + Future<void> dispose()                                         │     │
│  │                                                                   │     │
│  │  // Preview                                                       │     │
│  │  + Stream<CameraImage> get previewStream                         │     │
│  │  + CameraController get controller                                │     │
│  │                                                                   │     │
│  │  // Capture                                                       │     │
│  │  + Future<Uint8List> captureImage()                              │     │
│  │  + Future<void> setFlashMode(FlashMode mode)                     │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                    OmrScannerService                               │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // Dependencies (injected)                                       │     │
│  │  - MarkerDetector markerDetector                                  │     │
│  │  - PerspectiveTransformer perspectiveTransformer                  │     │
│  │  - ImagePreprocessor imagePreprocessor                            │     │
│  │  - BubbleReader bubbleReader                                      │     │
│  │  - ThresholdCalculator thresholdCalculator                        │     │
│  │  - AnswerExtractor answerExtractor                                │     │
│  │                                                                   │     │
│  │  // Methods                                                       │     │
│  │  + Future<MarkerDetectionResult?> detectMarkers(Uint8List image) │     │
│  │  + Future<ScanResult?> scanAnswerSheet(                          │     │
│  │      Uint8List image,                                            │     │
│  │      OmrTemplate template                                         │     │
│  │    )                                                              │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                      MarkerDetector                                │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // ArUco Configuration                                           │     │
│  │  - dictionary: DICT_4X4_50                                        │     │
│  │  - markerIds: TL=0, TR=1, BR=2, BL=3                             │     │
│  │                                                                   │     │
│  │  // Methods                                                       │  🔄 │
│  │  + Future<void> initialize()  // Setup ArUco detector            │     │
│  │  + Future<MarkerDetectionResult> detect(cv.Mat grayscaleImage)   │     │
│  │  + List<Point>? getCornerPointsForTransform(cv.Mat image)        │     │
│  │  + void dispose()                                                 │     │
│  │                                                                   │     │
│  │  // Returns                                                       │     │
│  │  MarkerDetectionResult {                                          │     │
│  │    List<Point> markerCenters;  // 4 points (TL, TR, BR, BL)      │     │
│  │    double avgConfidence;       // Proportion of markers found    │     │
│  │    List<double> perMarkerConfidence; // 1.0 if found, 0.0 if not │     │
│  │    bool allMarkersFound;       // true if all 4 ArUco IDs found  │     │
│  │  }                                                                │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                  ImagePreprocessor                                 │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │  🆕 │
│  │  // Methods (accept/return Uint8List; use opencv_dart internally) │     │
│  │  + Future<Uint8List> preprocess(Uint8List rawImageBytes)         │     │
│  │                                                                   │     │
│  │  // Operations performed:                                         │     │
│  │  // 1. Convert to grayscale                                       │     │
│  │  // 2. Apply CLAHE for contrast enhancement                       │     │
│  │  // 3. Normalize pixel values to 0-255                            │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                 PerspectiveTransformer                             │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │  🆕 │
│  │  // Methods                                                       │     │
│  │  + Future<Uint8List> transform(                                  │     │
│  │      Uint8List imageBytes,                                       │     │
│  │      List<Point> sourcePoints,    // 4 marker corners            │     │
│  │      Size outputSize              // Template dimensions          │     │
│  │    )                                                              │     │
│  │                                                                   │     │
│  │  // Internally:                                                   │     │
│  │  // 1. Orders points (TL, TR, BR, BL)                             │     │
│  │  // 2. Calculates perspective transform matrix                    │     │
│  │  // 3. Warps image to canonical view                              │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                   ThresholdCalculator                              │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // Configuration                                                 │     │
│  │  - int minJump = 20           // Minimum gap to consider         │     │
│  │  - int looseness = 4          // Smoothing window                │     │
│  │  - double defaultThreshold = 128                                  │     │
│  │                                                                   │     │
│  │  // Methods (pure Dart - no OpenCV needed)                       │     │
│  │  + ThresholdResult calculate(List<double> bubbleValues)          │     │
│  │                                                                   │     │
│  │  // Returns                                                       │     │
│  │  ThresholdResult {                                                │     │
│  │    double threshold;          // Separation value                │     │
│  │    double confidence;         // Based on gap size               │     │
│  │    double maxGap;             // Largest gap found               │     │
│  │  }                                                                │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                       BubbleReader                                 │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // Methods (accept Uint8List; use opencv_dart internally)       │  🔄 │
│  │  + Future<BubbleReadResult> readAllBubbles(                      │     │
│  │      Uint8List alignedImageBytes,                                │  🔄 │
│  │      OmrTemplate template                                         │     │
│  │    )                                                              │     │
│  │                                                                   │     │
│  │  // Returns                                                       │     │
│  │  BubbleReadResult {                                               │     │
│  │    Map<String, List<double>> bubbleValues;                       │     │
│  │    // e.g., {'q1': [45.2, 180.5, 190.3, 185.2, 188.0]}          │     │
│  │    // Index 0=A, 1=B, 2=C, 3=D, 4=E                              │     │
│  │    List<double> allValues;  // Flattened for threshold calc      │     │
│  │  }                                                                │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                     AnswerExtractor                                │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // Methods (pure Dart - no OpenCV needed)                       │     │
│  │  + AnswerExtractionResult extract(                               │     │
│  │      BubbleReadResult bubbleResult,                               │     │
│  │      double threshold                                             │     │
│  │    )                                                              │     │
│  │                                                                   │     │
│  │  // Returns                                                       │     │
│  │  AnswerExtractionResult {                                         │     │
│  │    Map<String, AnswerStatus> answers;                            │     │
│  │    // AnswerStatus = { value: String?, status: AnswerType }      │     │
│  │    // AnswerType enum: VALID, BLANK, MULTIPLE_MARK               │     │
│  │    //                                                            │     │
│  │    // Examples:                                                  │     │
│  │    // 'q1': { value: 'B', status: VALID }                       │     │
│  │    // 'q2': { value: null, status: BLANK }                      │     │
│  │    // 'q5': { value: null, status: MULTIPLE_MARK }              │     │
│  │  }                                                                │     │
│  │                                                                   │     │
│  │  // Convenience getters                                          │     │
│  │  + List<String> get multipleMarks   // ['q5', 'q12']            │     │
│  │  + List<String> get blankAnswers    // ['q2', 'q8']             │     │
│  │  + Map<String, String> get validAnswers // {'q1': 'B', ...}     │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                      GradingService                                │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // Methods (pure Dart - no OpenCV needed)                       │     │
│  │  + GradedResult grade(                                            │     │
│  │      AnswerExtractionResult extractedAnswers,                    │     │
│  │      Map<String, String> answerKey                                │     │
│  │    )                                                              │     │
│  │                                                                   │     │
│  │  // Returns                                                       │     │
│  │  GradedResult {                                                   │     │
│  │    int correct;                                                   │     │
│  │    int incorrect;                                                 │     │
│  │    int blank;                                                     │     │
│  │    int multipleMarks;                                             │     │
│  │    int total;                                                     │     │
│  │    double percentage;                                             │     │
│  │    Map<String, QuestionResult> questionResults;                  │     │
│  │  }                                                                │     │
│  │                                                                   │     │
│  │  // QuestionResult                                                │     │
│  │  QuestionResult {                                                 │     │
│  │    String? detected;        // What was detected (A/B/C/D/E/null)│     │
│  │    String correct;          // Correct answer from key           │     │
│  │    ResultType result;       // CORRECT, INCORRECT, BLANK, MULTI  │     │
│  │  }                                                                │     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────┐     │
│  │                     PdfExportService                               │     │
│  ├───────────────────────────────────────────────────────────────────┤     │
│  │                                                                   │     │
│  │  // Methods (pure Dart - uses pdf package)                       │     │
│  │  + Future<Uint8List> generateResultsPdf(                         │     │
│  │      Quiz quiz,                                                   │     │
│  │      List<ScanResult> results                                     │     │
│  │    )                                                              │     │
│  │                                                                   │     │
│  │  + Future<File> saveAndShare(Uint8List pdfBytes, String filename)│     │
│  │                                                                   │     │
│  └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  IMPLEMENTATION NOTE:                                                       │
│  ────────────────────                                                       │
│  Services that require image processing (MarkerDetector, ImagePreprocessor, │
│  PerspectiveTransformer, BubbleReader) use opencv_dart internally.          │
│  However, their PUBLIC interfaces accept/return Uint8List to avoid          │
│  coupling callers to OpenCV types. This allows:                             │
│                                                                             │
│  • Easy testing with mock implementations                                   │
│  • Potential future swap of CV library without API changes                  │
│  • Clean separation between domain logic and image processing               │
│                                                                             │
│  Services that are pure business logic (ThresholdCalculator,                │
│  AnswerExtractor, GradingService, PdfExportService) have no OpenCV          │
│  dependency and work entirely in Dart.                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 8. 📊 Data Models

### 8.1 Template JSON Schema

```json
{
  "$schema": "OmrTemplate",
  "id": "std_20q",
  "name": "20 Questions",
  "version": "1.0",
  "questionCount": 20,

  "pageDimensions": {
    "width": 2550,
    "height": 3300,
    "dpi": 300
  },

  "bubbleDimensions": {
    "width": 40,
    "height": 40
  },

  "markerConfig": {
    "type": "aruco",
    "dictionary": "DICT_4X4_50",
    "markerIds": {
      "topLeft": 0,
      "topRight": 1,
      "bottomRight": 2,
      "bottomLeft": 3
    },
    "sizePx": 180,
    "paddingPx": 90
  },

  "nameRegion": {
    "x": 100,
    "y": 150,
    "width": 800,
    "height": 200
  },

  "fieldBlocks": [
    {
      "name": "questions_1_10",
      "origin": { "x": 200, "y": 500 },
      "options": ["A", "B", "C", "D", "E"],
      "bubblesGap": 60,
      "labelsGap": 80,
      "questionLabels": ["q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10"],
      "direction": "vertical"
    },
    {
      "name": "questions_11_20",
      "origin": { "x": 700, "y": 500 },
      "options": ["A", "B", "C", "D", "E"],
      "bubblesGap": 60,
      "labelsGap": 80,
      "questionLabels": ["q11", "q12", "q13", "q14", "q15", "q16", "q17", "q18", "q19", "q20"],
      "direction": "vertical"
    }
  ]
}

```

### 8.2 Database Schema (Hive)

```jsx
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATABASE SCHEMA (Hive)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────┐       │
│  │                         QuizBox                                  │       │
│  ├─────────────────────────────────────────────────────────────────┤       │
│  │  id: String (UUID)                      [Primary Key]           │       │
│  │  name: String                           "Chapter 5 Quiz"        │       │
│  │  templateId: String                     "std_20q"               │       │
│  │  createdAt: DateTime                                            │       │
│  │  answerKey: Map<String, String>         {'q1': 'A', 'q2': 'C'}  │       │
│  └─────────────────────────────────────────────────────────────────┘       │
│                              │                                              │
│                              │ 1:N                                          │
│                              ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────┐       │
│  │                      ScanResultBox                               │       │
│  ├─────────────────────────────────────────────────────────────────┤       │
│  │  id: String (UUID)                      [Primary Key]           │       │
│  │  quizId: String                         [Foreign Key, Indexed]  │  🔄   │
│  │  scannedAt: DateTime                    [Indexed for sorting]   │  🔄   │
│  │  nameRegionImage: Uint8List             PNG blob                │       │
│  │                                                                 │       │
│  │  // Answer data (🔄 CLARIFIED STRUCTURE)                        │       │
│  │  detectedAnswers: Map<String, String?>  {'q1': 'A', 'q2': null} │       │
│  │  answerStatuses: Map<String, String>    {'q1': 'VALID',         │  🆕   │
│  │                                          'q2': 'BLANK',          │       │
│  │                                          'q5': 'MULTIPLE_MARK'}  │       │
│  │  correctedAnswers: Map<String, String?> After manual edit       │       │
│  │                                           (null=BLANK,           │       │
│  │                                            "MULTIPLE_MARK"=multi)│       │
│  │                                                                 │       │
│  │  // Scores                                                      │       │
│  │  score: int                             18                      │       │
│  │  total: int                             20                      │       │
│  │  percentage: double                     90.0                    │       │
│  │                                                                 │       │
│  │  // Metadata                                                    │       │
│  │  wasEdited: bool                        true/false              │       │
│  │  scanConfidence: double                 0.85                    │       │
│  │  rawBubbleValues: String?               JSON (debug, nullable)  │       │
│  └─────────────────────────────────────────────────────────────────┘       │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────     │
│                                                                             │
│  INDEXES:                                                                   │
│  • ScanResultBox.quizId      → Fast lookup of scans per quiz               │
│  • ScanResultBox.scannedAt   → Chronological ordering                       │
│                                                                             │
│  ANSWER STATUS VALUES:                                                      │
│  • "VALID"         → Single bubble marked, answer in detectedAnswers       │
│  • "BLANK"         → No bubbles marked, detectedAnswers value = null       │
│  • "MULTIPLE_MARK" → 2+ bubbles marked, detectedAnswers value = null       │
│  • correctedAnswers may store "MULTIPLE_MARK" as a manual override         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. 🎨 UI/UX Specifications

### 9.1 Scan Screen (Screen 5) Wireframe

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SCAN SCREEN WIREFRAME                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  ← Quiz Menu                                    🔦 (flash toggle)   │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │    ┌─────────────────────────────────────────────────────────┐     │   │
│  │    │                                                         │     │   │
│  │    │  ┌───┐                                         ┌───┐    │     │   │
│  │    │  │ ◻ │  ←── Corner guide (red=not found)      │ ◻ │    │     │   │
│  │    │  └───┘      (green=detected)                   └───┘    │     │   │
│  │    │                                                         │     │   │
│  │    │                                                         │     │   │
│  │    │                  CAMERA PREVIEW                         │     │   │
│  │    │                                                         │     │   │
│  │    │           "Align sheet with corners"                    │     │   │
│  │    │                                                         │     │   │
│  │    │                                                         │     │   │
│  │    │  ┌───┐                                         ┌───┐    │     │   │
│  │    │  │ ◻ │                                         │ ◻ │    │     │   │
│  │    │  └───┘                                         └───┘    │     │   │
│  │    │                                                         │     │   │
│  │    └─────────────────────────────────────────────────────────┘     │   │
│  │                                                                     │   │
│  │    ┌─────────────────────────────────────────────────────────┐     │   │
│  │    │                                                         │     │   │
│  │    │  Scanned: 5 / ∞           [  Manual Capture  ]         │     │   │
│  │    │                                                         │     │   │
│  │    └─────────────────────────────────────────────────────────┘     │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  STATE: Searching for markers                                               │
│  ─────────────────────────────                                              │
│  • Corner guides: Red outline (pulsing)                                     │
│  • Instruction text: "Align sheet with corners"                             │
│  • Status bar: Shows count of scanned sheets                                │
│                                                                             │
│  STATE: Markers detected (aligned)                                          │
│  ──────────────────────────────────                                         │
│  • Corner guides: Green solid                                               │
│  • Instruction text: "Hold steady..."                                       │
│  • 500ms countdown, then auto-capture                                       │
│                                                                             │
│  STATE: Processing                                                          │
│  ─────────────────                                                          │
│  • Overlay: Semi-transparent with spinner                                   │
│  • Text: "Analyzing..."                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

### 9.2 Scan Result Popup

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SCAN RESULT POPUP                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    ┌───────────────────────────────────────────────────────────────┐       │
│    │                                                               │       │
│    │     ✅ Scan Complete                                          │       │
│    │                                                               │       │
│    │    ┌─────────────────────────────────────────────────────┐   │       │
│    │    │  ┌──────────────────────────────────────────────┐  │   │       │
│    │    │  │                                              │  │   │       │
│    │    │  │     [ Cropped Name Region Image ]            │  │   │       │
│    │    │  │                                              │  │   │       │
│    │    │  └──────────────────────────────────────────────┘  │   │       │
│    │    └─────────────────────────────────────────────────────┘   │       │
│    │                                                               │       │
│    │           ┌─────────────────────────────────┐                │       │
│    │           │         18 / 20                 │                │       │
│    │           │          90%                    │                │       │
│    │           └─────────────────────────────────┘                │       │
│    │                                                               │       │
│    │    ┌─────────────────┐    ┌─────────────────┐                │       │
│    │    │  Blank: 1       │    │  Multi-mark: 1  │                │       │
│    │    └─────────────────┘    └─────────────────┘                │       │
│    │                                                               │       │
│    │    ┌─────────────────────────────────────────────────────┐   │       │
│    │    │              [ View Details ]                       │   │       │
│    │    └─────────────────────────────────────────────────────┘   │       │
│    │                                                               │       │
│    │    ┌───────────────────┐    ┌───────────────────┐            │       │
│    │    │      Rescan       │    │       Save        │            │       │
│    │    └───────────────────┘    └───────────────────┘            │       │
│    │                                                               │       │
│    └───────────────────────────────────────────────────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

### 9.3 Alignment Guide States

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ALIGNMENT GUIDE VISUAL STATES                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STATE 1: Not Detected              STATE 2: Detected                       │
│  ─────────────────────              ──────────────────                      │
│                                                                             │
│    ┌───────────┐                      ┌───────────┐                        │
│    │           │                      │           │                        │
│    │  ┌─────┐  │    Red outline       │  ┌─────┐  │    Green solid         │
│    │  │  ⬜ │  │    Pulsing           │  │  🟩 │  │    Static              │
│    │  │     │  │    animation         │  │     │  │                        │
│    │  └─────┘  │                      │  └─────┘  │                        │
│    │           │                      │           │                        │
│    └───────────┘                      └───────────┘                        │
│                                                                             │
│  STATE 3: All Aligned (Ready)       STATE 4: Capturing                     │
│  ────────────────────────────       ──────────────────                     │
│                                                                             │
│    ┌───────────────────────┐          ┌───────────────────────┐            │
│    │ 🟩              🟩    │          │ 🟩 ═══════════ 🟩    │            │
│    │                       │          │ ║             ║      │            │
│    │    "Hold steady"      │          │ ║  FLASH ⚡   ║      │            │
│    │                       │          │ ║             ║      │            │
│    │ 🟩              🟩    │          │ 🟩 ═══════════ 🟩    │            │
│    └───────────────────────┘          └───────────────────────┘            │
│                                                                             │
│    All 4 green                        Brief white flash                    │
│    500ms countdown                    Camera shutter sound                 │
│    Haptic feedback                    Transition to processing             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

---

## 10. 🔄 Implementation Phases

### Phase Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       IMPLEMENTATION PHASES                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PHASE 1                PHASE 2                PHASE 3                      │
│  Foundation             Core Scanner           Integration                  │
│  (Week 1)               (Week 2-3)             (Week 4)                     │
│                                                                             │
│  ┌──────────────┐      ┌──────────────┐       ┌──────────────┐             │
│  │ • Project    │      │ • Marker     │       │ • Camera UI  │             │
│  │   setup      │      │   detection  │       │ • Alignment  │             │
│  │              │      │              │       │   overlay    │             │
│  │ • opencv_dart│ ───▶ │ • Perspective│  ───▶ │              │             │
│  │   integration│      │   transform  │       │ • Auto-      │             │
│  │              │      │              │       │   capture    │             │
│  │ • Template   │      │ • Bubble     │       │              │             │
│  │   system     │      │   reading    │       │ • Result     │             │
│  │              │      │              │       │   popup      │             │
│  │ • Data models│      │ • Threshold  │       │              │             │
│  │              │      │   algorithm  │       │ • Grading    │             │
│  └──────────────┘      │              │       │   flow       │             │
│                        │ • Answer     │       │              │             │
│                        │   extraction │       │ • Manual     │             │
│                        └──────────────┘       │   correction │             │
│                                               └──────────────┘             │
│                                                                             │
│  PHASE 4                                                                    │
│  Polish & Test                                                              │
│  (Week 5)                                                                   │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐      │
│  │ • Edge case handling    • Performance optimization                │      │
│  │ • Error states          • Unit tests                              │      │
│  │ • User feedback         • Integration tests                       │      │
│  │ • PDF export            • Golden tests with sample images         │      │
│  └──────────────────────────────────────────────────────────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

### Phase 1: Foundation (Week 1)

| Task | Description | Deliverable | Est. Hours |
| --- | --- | --- | --- |
| **1.1** | Create Flutter project with clean architecture | Project skeleton | 2 |
| **1.2** | Add dependencies (opencv_dart, camera, hive) | pubspec.yaml | 1 |
| **1.3** | Verify opencv_dart builds on Android/iOS | Successful build | 4 |
| **1.4** | Define data models (entities, models) | 8 model classes | 3 |
| **1.5** | Create template JSON files (10q, 20q, 50q) | 3 JSON + marker.png | 3 |
| **1.6** | Implement TemplateManager (load from assets) | TemplateManager class | 2 |
| **1.7** | Set up Hive database + Quiz repository | Database layer | 3 |
|  |  | **Total:** | **18 hrs** |

### Phase 2: Core Scanner (Week 2-3)

| Task | Description | Deliverable | Est. Hours |
| --- | --- | --- | --- |
| **2.1** | Implement ImagePreprocessor (grayscale, CLAHE, normalize) | ImagePreprocessor class | 3 |
| **2.2** | Implement MarkerDetector (template matching, quadrants) | MarkerDetector class | 6 |
| **2.3** | Implement PerspectiveTransformer (point ordering, warp) | PerspectiveTransformer | 4 |
| **2.4** | Implement BubbleReader (ROI extraction, mean calc) | BubbleReader class | 5 |
| **2.5** | Implement ThresholdCalculator (gap-finding algorithm) | ThresholdCalculator | 3 |
| **2.6** | Implement AnswerExtractor (multi-mark, blank detection) | AnswerExtractor class | 2 |
| **2.7** | Implement GradingService (score calculation) | GradingService class | 2 |
| **2.8** | Create OmrScannerService (orchestrator) | OmrScannerService | 3 |
| **2.9** | Unit tests for each component | Test files | 6 |
| **2.10** | Integration test with sample images | End-to-end test | 4 |
|  |  | **Total:** | **38 hrs** |

### Phase 3: Integration (Week 4)

| Task | Description | Deliverable | Est. Hours |
| --- | --- | --- | --- |
| **3.1** | Implement camera service (preview, capture) | CameraService | 4 |
| **3.2** | Build ScanPapersPage UI | Screen 5 UI | 4 |
| **3.3** | Implement AlignmentOverlay widget | Corner guides widget | 3 |
| **3.4** | Implement ScannerBloc (state management) | BLoC + states | 4 |
| **3.5** | Connect camera preview → marker detection | Real-time detection | 4 |
| **3.6** | Implement auto-capture logic | Capture trigger | 2 |
| **3.7** | Build ScanResultPopup | Popup widget | 3 |
| **3.8** | Implement manual correction flow | Edit answer screen | 4 |
| **3.9** | Connect to quiz flow (save results) | Repository integration | 3 |
| **3.10** | Build GradedPapersPage | Screen 6 UI | 3 |
|  |  | **Total:** | **34 hrs** |

### Phase 4: Polish & Test (Week 5)

| Task | Description | Deliverable | Est. Hours |
| --- | --- | --- | --- |
| **4.1** | Handle error states (no camera, detection fail) | Error UI | 3 |
| **4.2** | Implement torch/flash toggle | Flash button | 1 |
| **4.3** | Optimize performance (isolates if needed) | Perf improvements | 4 |
| **4.4** | Create test answer sheets (print, fill, scan) | Golden test images | 3 |
| **4.5** | Golden tests (compare against known results) | Golden test suite | 4 |
| **4.6** | Edge case testing (poor lighting, tilted) | Edge case coverage | 4 |
| **4.7** | PDF export implementation | PDF service | 4 |
| **4.8** | Bug fixes and polish | Stable build | 6 |
|  |  | **Total:** | **29 hrs** |

### 📊 Total Estimate

| Phase | Hours | Calendar Days |
| --- | --- | --- |
| Phase 1: Foundation | 18 | 3-4 days |
| Phase 2: Core Scanner | 38 | 6-7 days |
| Phase 3: Integration | 34 | 5-6 days |
| Phase 4: Polish | 29 | 5-6 days |
| **TOTAL** | **119 hrs** | **~5 weeks** |

---

## 11. 🧪 Testing Strategy

### 11.1 Test Categories

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TESTING PYRAMID                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                              ╱╲                                             │
│                             ╱  ╲                                            │
│                            ╱    ╲                                           │
│                           ╱  E2E ╲     • Full app flow                      │
│                          ╱   (5)  ╲    • Real camera (manual)               │
│                         ╱──────────╲                                        │
│                        ╱            ╲                                       │
│                       ╱  Integration ╲  • Scanner pipeline                  │
│                      ╱     (10)       ╲ • Camera + detection                │
│                     ╱──────────────────╲                                    │
│                    ╱                    ╲                                   │
│                   ╱     Unit Tests       ╲  • Each service                  │
│                  ╱         (40+)          ╲ • Pure functions                │
│                 ╱────────────────────────────╲ • Edge cases                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

### 11.2 Unit Test Coverage

| Component | Test Cases | Priority |
| --- | --- | --- |
| **ThresholdCalculator** | Empty list, single value, no gap, clear gap, edge values | P0 |
| **AnswerExtractor** | Single mark, no marks, multi marks, all options | P0 |
| **GradingService** | All correct, all wrong, mixed, blank handling | P0 |
| **MarkerDetector** | Valid markers, missing markers, low confidence | P0 |
| **BubbleReader** | Valid positions, boundary check | P1 |
| **PerspectiveTransformer** | Point ordering, various orientations | P1 |
| **TemplateManager** | Load all templates, invalid JSON | P1 |

### 11.3 Golden Test Images

| Image | Scenario | Expected Result |
| --- | --- | --- |
| `perfect_20q.jpg` | Ideal lighting, perfectly aligned | 100% accuracy |
| `tilted_15deg.jpg` | Sheet rotated 15 degrees | Perspective corrected |
| `low_light.jpg` | Dim room lighting | CLAHE compensates |
| `partial_fill.jpg` | Lightly filled bubbles | Correct threshold |
| `multi_mark.jpg` | Several multi-marked questions | Multi-marks detected |
| `all_blank.jpg` | No bubbles filled | All detected as blank |
| `xerox_copy.jpg` | Photocopied sheet (gray bg) | Adaptive threshold works |

### 11.4 Test Device Matrix

| Device | OS Version | Camera | Priority |
| --- | --- | --- | --- |
| Pixel 4a | Android 13 | 12MP | P0 |
| Samsung A52 | Android 12 | 64MP | P0 |
| iPhone 12 | iOS 17 | 12MP | P0 |
| Xiaomi Redmi Note 10 | Android 11 | 48MP | P1 |
| iPhone SE (2020) | iOS 17 | 12MP | P1 |
| Low-end Android | Android 9 | 8MP | P2 |

---

## 12. ⚠️ Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| **opencv_dart API instability** | Medium | High | Pin version, abstract interfaces, have fallback plan |
| **Low-end device performance** | Medium | Medium | Profile early, use isolates, reduce resolution |
| **Varying paper quality** | Medium | Medium | Test with different papers, adjust threshold params |
| **Camera permission denial** | Low | High | Clear permission rationale, graceful degradation |
| **Detection fails in bright sunlight** | Medium | Medium | Add warning in UI, suggest shade |
| **Template misalignment at print** | Low | High | Add calibration step if needed, generous margins |

---

## 13. 📈 Success Metrics

### 13.1 Technical Metrics

| Metric | Target | Measurement Method |
| --- | --- | --- |
| Bubble detection accuracy | ≥ 98% | Golden test comparison |
| Marker detection rate | ≥ 95% | Production telemetry |
| False positive (incorrect filled) | < 1% | Golden tests |
| False negative (missed filled) | < 1% | Golden tests |
| Scan pipeline duration | < 500ms | Performance profiling |
| App crash rate | < 0.1% | Crash reporting |

### 13.2 User Metrics (Post-Launch)

| Metric | Target | Measurement |
| --- | --- | --- |
| First scan success rate | > 80% | Analytics |
| Manual corrections per scan | < 2 questions | Database query |
| Feature adoption (scans/user/week) | > 5 | Analytics |
| Task completion time | < 3 min for 30 sheets | User research |

---

## 14. 📎 Appendices

### Appendix A: Answer Sheet Design Requirements

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ANSWER SHEET DESIGN SPECIFICATIONS                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PAGE SIZE: US Letter (8.5" × 11") or A4                                   │
│  ORIENTATION: Portrait                                                      │
│  DPI: 300 (for template coordinates)                                        │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  ■                                                             ■    │   │
│  │  ↑                                                             ↑    │   │
│  │  Corner marker                                    Corner marker     │   │
│  │  (solid black square, ~0.5" × 0.5")                                │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │  Name: _________________________________                    │   │   │
│  │  │                                                             │   │   │
│  │  │  (Handwriting area, ~2.5" × 0.75")                         │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │       A    B    C    D    E                                        │   │
│  │  1.   ○    ○    ○    ○    ○     ← Bubble grid                      │   │
│  │  2.   ○    ○    ○    ○    ○        (bubbles ~0.15" diameter)       │   │
│  │  3.   ○    ○    ○    ○    ○        (gap between: ~0.2")           │   │
│  │  ...                                                               │   │
│  │  20.  ○    ○    ○    ○    ○                                        │   │
│  │                                                                     │   │
│  │                                                                     │   │
│  │  ■                                                             ■    │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  MARKER SPECIFICATIONS:                                                     │
│  • Solid black (#000000) squares                                           │
│  • Size: 0.5" × 0.5" (150px × 150px at 300dpi)                            │
│  • Position: 0.25" from page edges                                         │
│  • Must be fully visible (no crop)                                         │
│                                                                             │
│  BUBBLE SPECIFICATIONS:                                                     │
│  • Empty circles with thin black outline                                   │
│  • Fill area: solid when marked by student                                 │
│  • Diameter: 0.15" (~45px at 300dpi)                                       │
│  • Horizontal gap (A→B→C→D→E): 0.2"                                        │
│  • Vertical gap (Q1→Q2→Q3): 0.25"                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

```

### Appendix B: OpenCV Operations Reference

The following OpenCV functions are used within our image processing services. All operations are executed via **`opencv_dart`**, which provides Dart bindings to native C++ OpenCV libraries through FFI. This means actual image processing runs at native speed, not in Dart.

| OpenCV Function | Service | Usage |
| --- | --- | --- |
| `cv.cvtColorAsync()` | ImagePreprocessor | Convert captured image to grayscale |
| `cv.createCLAHE()` | ImagePreprocessor | Contrast Limited Adaptive Histogram Equalization |
| `cv.normalizeAsync()` | ImagePreprocessor | Normalize pixel values to 0-255 range |
| `cv.matchTemplateAsync()` | MarkerDetector | Find corner markers via template matching |
| `cv.minMaxLocAsync()` | MarkerDetector | Locate best match position and confidence |
| `cv.getPerspectiveTransform()` | PerspectiveTransformer | Calculate 4-point transform matrix |
| `cv.warpPerspectiveAsync()` | PerspectiveTransformer | Apply perspective correction to align sheet |
| `cv.meanAsync()` | BubbleReader | Calculate mean pixel intensity of bubble ROI |
| `cv.rectangleAsync()` | Debug only | Draw visualization overlays (development) |

**Architecture Note:**

```jsx
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   Dart Service Layer          opencv_dart Package         Native Layer     │
│   (Your Code)                 (FFI Bindings)              (C++ OpenCV)     │
│                                                                             │
│   ┌──────────────┐           ┌──────────────┐           ┌──────────────┐   │
│   │ MarkerDetector│           │              │           │              │   │
│   │ BubbleReader  │  ──────▶  │  dart:ffi    │  ──────▶  │  libopencv   │   │
│   │ etc.          │   Dart    │  bindings    │  Native   │  (C++)       │   │
│   └──────────────┘   calls    └──────────────┘  calls    └──────────────┘   │
│                                                                             │
│   Uint8List in/out           cv.Mat internally          Actual processing  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Appendix C: State Machine for Scanner

```jsx
┌─────────────────────────────────────────────────────────────────────────────┐
│                       SCANNER STATE MACHINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                        ┌─────────────┐                                      │
│                        │             │                                      │
│            ┌──────────▶│    IDLE     │◀──────────────────┐                 │
│            │           │             │                   │                 │
│            │           └──────┬──────┘                   │                 │
│            │                  │                          │                 │
│            │           Start Camera                      │                 │
│            │                  │                          │                 │
│            │                  ▼                          │                 │
│            │           ┌─────────────┐                   │                 │
│            │           │             │     Camera        │                 │
│            │           │ INITIALIZING│────Error─────────▶│                 │
│            │           │             │                   │                 │
│            │           └──────┬──────┘                   │                 │
│            │                  │                          │                 │
│            │           Camera Ready                      │                 │
│            │                  │                          │                 │
│            │                  ▼                          │                 │
│            │           ┌─────────────┐                   │                 │
│            │           │             │                   │                 │
│            │           │  PREVIEWING │                   │                 │
│            │           │  (scanning) │                   │                 │
│            │           └──────┬──────┘                   │                 │
│            │                  │                          │                 │
│            │           Markers Detected                  │                 │
│            │           (confidence > 0.3)                │                 │
│            │                  │                          │                 │
│            │                  ▼                          │                 │
│            │           ┌─────────────┐                   │                 │
│            │           │             │                   │                 │
│       Back Button      │  ALIGNING   │──Markers──────────│                 │
│            │           │  (500ms)    │   Lost      ┌─────┴─────┐          │
│            │           └──────┬──────┘             │           │          │
│            │                  │                    │  ERROR    │  🆕 NEW   │
│            │           Stable for 500ms            │           │          │
│            │                  │                    │ • message │          │
│            │                  ▼                    │ • retry   │          │
│            │           ┌─────────────┐             │ • dismiss │          │
│            │           │             │             │           │          │
│            │           │  CAPTURING  │             └─────┬─────┘          │
│            │           │             │                   │                 │
│            │           └──────┬──────┘                   │                 │
│            │                  │                          │                 │
│            │           Image Captured                    │                 │
│            │                  │                          │                 │
│            │                  ▼                          │                 │
│            │           ┌─────────────┐                   │                 │
│            │           │             │     Processing    │                 │
│            │           │ PROCESSING  │────Error─────────▶│                 │
│            │           │             │                   │                 │
│            │           └──────┬──────┘                   │                 │
│            │                  │                          │                 │
│            │           Scan Complete                     │                 │
│            │                  │                          │                 │
│            │                  ▼                          │                 │
│            │           ┌─────────────┐                   │                 │
│            │           │             │                   │                 │
│            └───────────│   RESULT    │───────────────────┘                 │
│              Dismiss   │             │   Rescan                            │
│                        └─────────────┘                                      │
│                                                                             │
│  ─────────────────────────────────────────────────────────────────────     │
│                                                                             │
│  ERROR STATE DETAILS:                                                       │
│  ────────────────────                                                       │
│                                                                             │
│  Error Type            │ Message                      │ Actions            │
│  ──────────────────────┼──────────────────────────────┼──────────────────  │
│  CAMERA_UNAVAILABLE    │ "Camera not available"       │ [Settings] [Close] │
│  CAMERA_PERMISSION     │ "Camera permission needed"   │ [Grant] [Close]    │
│  DETECTION_FAILED      │ "Could not detect sheet.     │ [Retry] [Close]    │
│                        │  Ensure markers visible."    │                    │
│  PROCESSING_FAILED     │ "Could not read answers.     │ [Retry] [Close]    │
│                        │  Try scanning again."        │                    │
│  UNKNOWN_ERROR         │ "Something went wrong"       │ [Retry] [Close]    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```
