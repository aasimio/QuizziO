# 🔍 Task List Review & Analysis

## 📝 Revised Detailed Task List

---

## Relevant Files

- `omr_spike/lib/main.dart` - Entry point with simple UI to load image and display results
- `omr_spike/lib/models/detection_result.dart` - Data classes for detection results
- `omr_spike/lib/models/template_config.dart` - Hardcoded template configuration for testing
- `omr_spike/lib/services/image_preprocessor.dart` - Grayscale, CLAHE, normalization (NEW)
- `omr_spike/lib/services/marker_detector.dart` - Corner marker detection using template matching
- `omr_spike/lib/services/perspective_transformer.dart` - 4-point perspective warp
- `omr_spike/lib/services/bubble_reader.dart` - Extract mean intensity from bubble ROIs
- `omr_spike/lib/services/threshold_calculator.dart` - Determine filled vs unfilled threshold
- `omr_spike/lib/omr_pipeline.dart` - Orchestrates all services end-to-end
- `omr_spike/lib/utils/cv_utils.dart` - Helper for cv.Mat memory management (NEW)
- `omr_spike/assets/marker.png` - Corner marker template image (solid black square)
- `omr_spike/assets/test_sheet_blank.png` - Sample blank answer sheet for testing
- `omr_spike/assets/test_sheet_filled.png` - Sample filled answer sheet for testing
- `omr_spike/test/marker_detector_test.dart` - Unit tests for marker detection
- `omr_spike/test/threshold_calculator_test.dart` - Unit tests for threshold logic
- `omr_spike/test/omr_pipeline_test.dart` - Integration test for full pipeline

### Notes

- This is a **throwaway proof-of-concept project** — clean code structure is secondary to validating the tech works
- We'll use static test images first (no camera) to isolate OMR logic from camera complexity
- The goal is a **Go/No-Go decision** on `opencv_dart` within 1-2 days
- If this succeeds, we'll port the validated services into the real QuizziO project
- Use `flutter test` to run tests
- Test on **both Android and iOS** physical devices if possible (emulators may have different OpenCV behavior)
- ⚠️ **CRITICAL:** Always dispose `cv.Mat` objects after use to prevent memory leaks

---

## Instructions for Completing Tasks

**IMPORTANT:** As you complete each task, you must check it off in this markdown file by changing `- [ ]` to `- [x]`. This helps track progress and ensures you don't skip any steps.

Example:

- `1.1 Read file` → `1.1 Read file` (after completing)

Update the file after completing each sub-task, not just after completing an entire parent task.

---

## Tasks

- [x]  **0.0 Create POC Flutter Project**
    - [x]  0.1 Create new Flutter project: `flutter create omr_spike`
    - [x]  0.2 Navigate into project: `cd omr_spike`
    - [x]  0.3 Add dependencies to `pubspec.yaml`:

        ```yaml
        dependencies:
          flutter:
            sdk: flutter
          opencv_dart: ^1.4.3
          image: ^4.3.0
          path_provider: ^2.1.5
          image_picker: ^1.1.2  # For testing with gallery photos

        ```

    - [x]  0.4 Run `flutter pub get`
    - [x]  0.5 Check opencv_dart minimum SDK requirements in their documentation
    - [x]  0.6 Configure Android `minSdkVersion` in `android/app/build.gradle`:
        - Set to 24 (or higher if opencv_dart requires)
        - Note: This may conflict with PRD's API 23 target — document this finding
    - [x]  0.7 Build and run on Android emulator/device — verify no opencv_dart build errors
    - [x]  0.8 Build and run on iOS simulator/device — verify no opencv_dart build errors
    - [x]  0.9 Create folder structure:

        ```
        lib/
        ├── main.dart
        ├── models/
        ├── services/
        ├── utils/
        assets/
        test/

        ```

    - [x]  0.10 Create `lib/utils/cv_utils.dart` with helper for safe Mat disposal:

        ```dart
        /// Always use this to safely dispose cv.Mat objects
        void disposeMats(List<cv.Mat> mats) {
          for (final mat in mats) {
            mat.dispose();
          }
        }

        ```
        
- [x]  **1.0 Prepare Test Assets & Template Configuration**
    - [x]  1.1 Define test template dimensions (reference size after perspective warp):
        
        ```dart
        // lib/models/template_config.dart
        const kTemplateWidth = 800;  // pixels
        const kTemplateHeight = 1100; // pixels (approx A4 ratio)
        const kMarkerSize = 50;       // pixels (corner marker size)
        
        ```
        
    - [x]  1.2 Create `marker.png`:
        - Solid black square (#000000)
        - Size: 50x50 pixels (matches kMarkerSize)
        - Save to `assets/marker.png`
    - [x]  1.3 Define bubble positions for 5-question test template in `lib/models/template_config.dart`:
        
        ```dart
        // Bubble positions relative to warped template (800x1100)
        // Each question has 5 bubbles: A, B, C, D, E
        const kBubbleWidth = 30;
        const kBubbleHeight = 30;
        const kBubblePositions = {
          'q1': [Rect(100, 300, 30, 30), Rect(150, 300, 30, 30), ...], // A,B,C,D,E
          'q2': [Rect(100, 350, 30, 30), ...],
          'q3': [...],
          'q4': [...],
          'q5': [...],
        };
        
        ```
        
    - [x]  1.4 Create test answer sheet design (using Figma, Canva, or any design tool):
        - Canvas size: 800x1100 pixels
        - 4 corner markers (50x50 black squares) positioned 20px from edges
        - "Name: ___________" region at top (y: 100-200)
        - 5 questions with bubbles A, B, C, D, E matching positions defined in 1.3
        - Bubble style: Empty circles with thin black outline
    - [x]  1.5 Export as `test_sheet_blank.png` and save to `assets/`
    - [x]  1.6 Create `test_sheet_filled.png` — **Two options:**
        - **Option A (Preferred):** Print blank sheet, fill bubbles with dark pen, photograph with phone, crop to just the sheet
        - **Option B (Digital fallback):** Use image editor to digitally fill some bubbles with dark gray/black
    - [x]  1.7 Record the "correct answers" for your filled test sheet:
        
        ```dart
        // What you filled in (for verification)
        const kTestSheetAnswers = {'q1': 'B', 'q2': 'A', 'q3': 'D', 'q4': 'C', 'q5': 'E'};
        
        ```
        
    - [x]  1.8 Add assets to `pubspec.yaml`:
        
        ```yaml
        flutter:
          uses-material-design: true
          assets:
            - assets/marker.png
            - assets/test_sheet_blank.png
            - assets/test_sheet_filled.png
        
        ```
        
    - [x]  1.9 Create simple test in `main.dart` to verify assets load correctly:
        
        ```dart
        final byteData = await rootBundle.load('assets/marker.png');
        print('Marker loaded: ${byteData.lengthInBytes} bytes');
        
        ```
        
- [x]  **2.0 Implement Image Preprocessor** *(NEW — from PRD requirements)*
    - [x]  2.1 Create `lib/services/image_preprocessor.dart` with class skeleton:
        
        ```dart
        class ImagePreprocessor {
          /// Converts image to grayscale, applies CLAHE, normalizes values
          Future<cv.Mat> preprocess(cv.Mat inputMat);
        
          /// Converts Uint8List to cv.Mat
          cv.Mat uint8ListToMat(Uint8List bytes);
        
          /// Converts cv.Mat back to Uint8List
          Uint8List matToUint8List(cv.Mat mat);
        }
        
        ```
        
    - [x]  2.2 Implement `uint8ListToMat()`:
        - Use `cv.imdecode()` to convert bytes to Mat
    - [x]  2.3 Implement `matToUint8List()`:
        - Use `cv.imencode()` to convert Mat to bytes
    - [x]  2.4 Implement `preprocess()`:
        - Convert to grayscale: `cv.cvtColorAsync(mat, cv.COLOR_BGR2GRAY)`
        - Apply CLAHE: `cv.createCLAHE()` then `clahe.applyAsync()`
        - Normalize: `cv.normalizeAsync(mat, 0, 255, cv.NORM_MINMAX)`
    - [x]  2.5 Add proper disposal of intermediate Mat objects
    - [x]  2.6 Test preprocessing on test image — verify output is grayscale and contrast-enhanced
- [x]  **3.0 Implement Marker Detection**
    - [x]  3.1 Create `lib/models/detection_result.dart` with data classes:
        
        ```dart
        import 'package:opencv_dart/opencv_dart.dart' as cv;
        
        class Point {
          final double x;
          final double y;
          const Point(this.x, this.y);
        }
        
        class MarkerDetectionResult {
          final List<Point> markerCenters; // 4 points: TL, TR, BR, BL
          final double avgConfidence;
          final List<double> perMarkerConfidence;
          final bool allMarkersFound;
        
          bool get isValid => allMarkersFound && avgConfidence >= 0.3;
        }
        
        ```

    - [x]  3.2 Create `lib/services/marker_detector.dart` with class skeleton:
        
        ```dart
        class MarkerDetector {
          cv.Mat? _markerTemplate;
          final double minConfidence;
          final List<double> scales;
        
          MarkerDetector({
            this.minConfidence = 0.3,
            this.scales = const [0.85, 1.0, 1.15],
          });
        
          Future<void> loadMarkerTemplate(Uint8List bytes);
          Future<MarkerDetectionResult> detect(cv.Mat grayscaleImage);
          void dispose(); // Clean up _markerTemplate
        }
        
        ```

    - [x]  3.3 Implement `loadMarkerTemplate()`:
        - Decode bytes to cv.Mat
        - Convert to grayscale if needed
        - Store in `_markerTemplate`
    - [x]  3.4 Implement `_getQuadrantRegion()` helper:
        
        ```dart
        /// Returns ROI rect for each corner quadrant
        cv.Rect _getQuadrantRegion(cv.Mat image, String corner) {
          final w = image.width ~/ 2;
          final h = image.height ~/ 2;
          switch (corner) {
            case 'TL': return cv.Rect(0, 0, w, h);
            case 'TR': return cv.Rect(w, 0, w, h);
            case 'BR': return cv.Rect(w, h, w, h);
            case 'BL': return cv.Rect(0, h, w, h);
          }
        }
        
        ```

    - [x]  3.5 Implement `_searchInQuadrant()`:
        - Extract ROI from image using quadrant rect
        - For each scale in `scales`:
            - Resize marker template
            - Run `cv.matchTemplateAsync()` with `cv.TM_CCOEFF_NORMED`
            - Run `cv.minMaxLocAsync()` to get best match location and confidence
        - Keep best result across all scales
        - **Translate local coordinates to full image coordinates** (add quadrant offset)
        - Return center point and confidence
    - [x]  3.6 Implement `detect()`:
        - Search for marker in each quadrant (TL, TR, BR, BL)
        - Collect all 4 results
        - Calculate average confidence
        - Return `MarkerDetectionResult`
    - [x]  3.7 Implement `dispose()` to clean up `_markerTemplate`
    - [x]  3.8 Create `test/marker_detector_test.dart`:
        - Test with blank sheet — should find all 4 markers with confidence > 0.3
        - Test with filled sheet — should still find markers
        - Test with missing marker (crop image) — should report failure
    - [x]  3.9 Run tests: `flutter test test/marker_detector_test.dart`
- [ ]  **4.0 Implement Perspective Transform**
    - [ ]  4.1 Create `lib/services/perspective_transformer.dart` with class skeleton:
        
        ```dart
        class PerspectiveTransformer {
          /// Transforms image using 4 source points to a rectangular output
          Future<cv.Mat> transform(
            cv.Mat inputMat,
            List<Point> sourcePoints, // 4 marker centers
            int outputWidth,
            int outputHeight,
          );
        }
        
        ```
        
    - [ ]  4.2 Implement `_orderPoints()`:
        
        ```dart
        /// Orders 4 points as: Top-Left, Top-Right, Bottom-Right, Bottom-Left
        List<Point> _orderPoints(List<Point> points) {
          // Sort by sum (x+y): smallest = TL, largest = BR
          // Sort by diff (x-y): smallest = BL, largest = TR
          // Return [TL, TR, BR, BL]
        }
        
        ```
        
    - [ ]  4.3 Implement `transform()`:
        - Order source points using `_orderPoints()`
        - Define destination points (corners of output rectangle):
            
            ```dart
            final dst = [
              Point(0, 0),                          // TL
              Point(outputWidth - 1, 0),            // TR
              Point(outputWidth - 1, outputHeight - 1), // BR
              Point(0, outputHeight - 1),           // BL
            ];
            
            ```
            
        - Convert points to cv.Mat format for OpenCV
        - Get transform matrix: `cv.getPerspectiveTransform(srcMat, dstMat)`
        - Apply warp: `cv.warpPerspectiveAsync(input, matrix, Size(outputWidth, outputHeight))`
        - Dispose intermediate Mats
        - Return warped image
    - [ ]  4.4 Manual integration test:
        - Load test image → preprocess → detect markers → transform
        - Save warped output to device using path_provider
        - Visually verify the output is correctly aligned (rectangular, markers at corners)
- [ ]  **5.0 Implement Bubble Reading**
    - [ ]  5.1 Create `lib/services/bubble_reader.dart` with class skeleton:
        
        ```dart
        class BubbleReadResult {
          final Map<String, List<double>> bubbleValues; // {'q1': [45.2, 180.5, ...]}
          final List<double> allValues; // Flattened for threshold calculation
        }
        
        class BubbleReader {
          Future<BubbleReadResult> readAllBubbles(
            cv.Mat alignedImage,
            Map<String, List<Rect>> bubblePositions,
          );
        }
        
        ```
        
    - [ ]  5.2 Implement `_readSingleBubble()`:
        
        ```dart
        Future<double> _readSingleBubble(cv.Mat image, Rect position) async {
          // Extract ROI
          final roi = image.region(cv.Rect(
            position.left.toInt(),
            position.top.toInt(),
            position.width.toInt(),
            position.height.toInt(),
          ));
        
          // Calculate mean intensity
          final mean = await cv.meanAsync(roi);
          roi.dispose(); // Important!
        
          return mean.val1; // Grayscale mean value (0-255)
        }
        
        ```
        
    - [ ]  5.3 Implement `readAllBubbles()`:
        - Iterate through all questions and their bubble positions
        - Read each bubble's mean intensity
        - Collect into `bubbleValues` map
        - Flatten all values into `allValues` list
        - Return `BubbleReadResult`
    - [ ]  5.4 Test bubble reading on aligned test image — verify values are captured
- [ ]  **6.0 Implement Threshold Calculator & Answer Extractor**
    - [ ]  6.1 Create `lib/services/threshold_calculator.dart`:
        
        ```dart
        class ThresholdResult {
          final double threshold;
          final double confidence; // Based on gap size
          final double maxGap;
        }
        
        class ThresholdCalculator {
          final int minJump;
          final int looseness;
        
          ThresholdCalculator({this.minJump = 20, this.looseness = 4});
        
          ThresholdResult calculate(List<double> allBubbleValues);
        }
        
        ```
        
    - [ ]  6.2 Implement `calculate()` using gap-finding algorithm:
        
        ```dart
        ThresholdResult calculate(List<double> values) {
          if (values.isEmpty) return ThresholdResult(threshold: 128, ...);
        
          // Sort values ascending
          final sorted = [...values]..sort();
        
          // Apply smoothing (moving average with looseness window)
          final smoothed = _smooth(sorted, looseness);
        
          // Find largest gap
          double maxGap = 0;
          int maxGapIndex = 0;
          for (int i = 0; i < smoothed.length - 1; i++) {
            final gap = smoothed[i + 1] - smoothed[i];
            if (gap > maxGap && gap >= minJump) {
              maxGap = gap;
              maxGapIndex = i;
            }
          }
        
          // Threshold is midpoint of largest gap
          final threshold = (smoothed[maxGapIndex] + smoothed[maxGapIndex + 1]) / 2;
          final confidence = maxGap / 255; // Normalize to 0-1
        
          return ThresholdResult(threshold: threshold, confidence: confidence, maxGap: maxGap);
        }
        
        ```
        
    - [ ]  6.3 Implement answer extraction logic:
        
        ```dart
        enum AnswerStatus { valid, blank, multipleMark }
        
        class ExtractedAnswer {
          final String? value; // 'A', 'B', 'C', 'D', 'E', or null
          final AnswerStatus status;
        }
        
        Map<String, ExtractedAnswer> extractAnswers(
          Map<String, List<double>> bubbleValues,
          double threshold,
        ) {
          final results = <String, ExtractedAnswer>{};
          final options = ['A', 'B', 'C', 'D', 'E'];
        
          for (final entry in bubbleValues.entries) {
            final question = entry.key;
            final values = entry.value;
        
            // Find filled bubbles (dark = low value = below threshold)
            final filledIndices = <int>[];
            for (int i = 0; i < values.length; i++) {
              if (values[i] < threshold) {
                filledIndices.add(i);
              }
            }
        
            if (filledIndices.isEmpty) {
              results[question] = ExtractedAnswer(value: null, status: AnswerStatus.blank);
            } else if (filledIndices.length == 1) {
              results[question] = ExtractedAnswer(
                value: options[filledIndices.first],
                status: AnswerStatus.valid,
              );
            } else {
              results[question] = ExtractedAnswer(value: null, status: AnswerStatus.multipleMark);
            }
          }
        
          return results;
        }
        
        ```
        
    - [ ]  6.4 Create `test/threshold_calculator_test.dart`:
        - Test with clear bimodal distribution (e.g., [40, 45, 50, 180, 185, 190]) → should find threshold ~115
        - Test with all high values (no marks) → should handle gracefully
        - Test with all low values (all filled) → should handle gracefully
        - Test edge case: single value
    - [ ]  6.5 Run tests: `flutter test test/threshold_calculator_test.dart`
- [ ]  **7.0 Build OMR Pipeline & Test UI**
    - [ ]  7.1 Create `lib/omr_pipeline.dart` that orchestrates all services:
        
        ```dart
        class OmrResult {
          final bool success;
          final String? errorMessage;
          final MarkerDetectionResult? markerResult;
          final Map<String, ExtractedAnswer>? answers;
          final ThresholdResult? thresholdResult;
          final int processingTimeMs;
        }
        
        class OmrPipeline {
          final ImagePreprocessor _preprocessor;
          final MarkerDetector _markerDetector;
          final PerspectiveTransformer _transformer;
          final BubbleReader _bubbleReader;
          final ThresholdCalculator _thresholdCalculator;
        
          Future<OmrResult> process(Uint8List imageBytes) async {
            final stopwatch = Stopwatch()..start();
        
            try {
              // 1. Preprocess
              final mat = _preprocessor.uint8ListToMat(imageBytes);
              final processed = await _preprocessor.preprocess(mat);
              mat.dispose();
        
              // 2. Detect markers
              final markers = await _markerDetector.detect(processed);
              if (!markers.isValid) {
                processed.dispose();
                return OmrResult(success: false, errorMessage: 'Markers not detected');
              }
        
              // 3. Transform perspective
              final aligned = await _transformer.transform(
                processed,
                markers.markerCenters,
                kTemplateWidth,
                kTemplateHeight,
              );
              processed.dispose();
        
              // 4. Read bubbles
              final bubbleResult = await _bubbleReader.readAllBubbles(aligned, kBubblePositions);
              aligned.dispose();
        
              // 5. Calculate threshold
              final thresholdResult = _thresholdCalculator.calculate(bubbleResult.allValues);
        
              // 6. Extract answers
              final answers = extractAnswers(bubbleResult.bubbleValues, thresholdResult.threshold);
        
              stopwatch.stop();
              return OmrResult(
                success: true,
                markerResult: markers,
                answers: answers,
                thresholdResult: thresholdResult,
                processingTimeMs: stopwatch.elapsedMilliseconds,
              );
            } catch (e) {
              return OmrResult(success: false, errorMessage: e.toString());
            }
          }
        
          void dispose() {
            _markerDetector.dispose();
          }
        }
        
        ```
        
    - [ ]  7.2 Update `lib/main.dart` with test UI:
        
        ```dart
        // Simple UI with:
        // - Button: "Load Test Image (Blank)"
        // - Button: "Load Test Image (Filled)"
        // - Button: "Pick from Gallery" (for real photos)
        // - Button: "Run OMR Pipeline"
        // - Display: Original image
        // - Display: Processing status / errors
        // - Display: Results
        
        ```
        
    - [ ]  7.3 Implement image loading from assets:
        
        ```dart
        Future<Uint8List> _loadAsset(String path) async {
          final data = await rootBundle.load(path);
          return data.buffer.asUint8List();
        }
        
        ```
        
    - [ ]  7.4 Implement image picking from gallery using `image_picker`
    - [ ]  7.5 Display results UI:
        - Marker detection: ✅ Found (4/4) or ❌ Failed
        - Confidence scores for each marker
        - Threshold value and confidence
        - Extracted answers: Q1: B ✅, Q2: BLANK ⚠️, Q3: A ✅, etc.
        - Processing time in milliseconds
    - [ ]  7.6 Add error state UI:
        - If markers not found → "Could not detect answer sheet. Ensure all 4 corner markers are visible."
        - If processing fails → Show error message
    - [ ]  7.7 Test UI on Android device
    - [ ]  7.8 Test UI on iOS device
- [ ]  **8.0 End-to-End Validation & Go/No-Go Decision**
    - [ ]  8.1 Create additional test images (3-5 variations):
        - **Option A (Physical):** Print, fill, photograph with different conditions:
            - Good lighting
            - Dim lighting
            - Slight rotation (~10-15°)
            - Different fill darkness (pencil vs pen)
        - **Option B (Digital fallback):** Create variations in image editor:
            - Rotate original
            - Adjust brightness/contrast
            - Add noise
    - [ ]  8.2 Run pipeline on all test images and record results:
        
        
        | Image | Markers Found | Confidence | Answers Correct | Time (ms) |
        | --- | --- | --- | --- | --- |
        | test_sheet_filled.png | 4/4 | 0.85 | 5/5 | 320 |
        | rotated_10deg.png | ?/4 | ? | ?/5 | ? |
        | dim_lighting.png | ?/4 | ? | ?/5 | ? |
        | ... | ... | ... | ... | ... |
    - [ ]  8.3 Calculate overall metrics:
        - Marker detection rate: X% of images
        - Bubble accuracy: X% correct (compare against known answers)
        - Average processing time: X ms
    - [ ]  8.4 Document any failure cases discovered
    - [ ]  8.5 **Make Go/No-Go Decision:**
        
        
        | Criteria | Target | Actual | Pass? |
        | --- | --- | --- | --- |
        | Markers detected | >90% of images | ? | ? |
        | Bubble accuracy | >95% correct | ? | ? |
        | Processing time | <500ms | ? | ? |
        | Build stability | No crashes in 10 runs | ? | ? |
        | Android support | Works | ? | ? |
        | iOS support | Works | ? | ? |
        - ✅ **GO** if: All criteria pass
        - ⚠️ **CONDITIONAL GO** if: Minor issues that can be fixed with parameter tuning
        - ❌ **NO-GO** if: Fundamental failures, <80% accuracy, crashes
    - [ ]  8.6 Create `SPIKE_RESULTS.md` documenting:
        - Decision: GO / CONDITIONAL GO / NO-GO
        - What worked well
        - What didn't work / issues found
        - Recommended parameter values (minConfidence, scales, minJump, etc.)
        - Any code changes needed for production
        - SDK version requirements confirmed
    - [ ]  8.7 If **GO** → Archive spike code for reference when building real QuizziO

---

## 📊 Success Criteria Summary

| Metric | Target | Measurement |
| --- | --- | --- |
| Markers detected | >90% of test images | Pipeline output |
| Bubble accuracy | >95% correct | Compare to known answers |
| Processing time | <500ms per image | Pipeline output |
| Build stability | No crashes | Run 10+ times on each platform |
| Platform support | iOS + Android | Test on both physical devices |


