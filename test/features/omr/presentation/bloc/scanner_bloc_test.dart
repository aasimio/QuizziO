import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizzio/core/services/camera_service.dart';
import 'package:quizzio/core/services/performance_profiler.dart';
import 'package:quizzio/features/omr/domain/entities/answer_status.dart';
import 'package:quizzio/features/omr/domain/entities/omr_template.dart';
import 'package:quizzio/features/omr/domain/entities/scan_result.dart';
import 'package:quizzio/features/omr/domain/repositories/scan_repository.dart';
import 'package:quizzio/features/omr/models/detection_result.dart';
import 'package:quizzio/features/omr/presentation/bloc/scanner_bloc.dart';
import 'package:quizzio/features/omr/presentation/bloc/scanner_event.dart';
import 'package:quizzio/features/omr/presentation/bloc/scanner_state.dart';
import 'package:quizzio/features/omr/services/grading_service.dart';
import 'package:quizzio/features/omr/services/image_preprocessor.dart';
import 'package:quizzio/features/omr/services/marker_detector.dart';
import 'package:quizzio/features/omr/services/omr_scanner_service.dart';
import 'package:quizzio/features/omr/services/perspective_transformer.dart';
import 'package:quizzio/features/omr/services/template_manager.dart';
import 'package:quizzio/features/quiz/domain/entities/quiz.dart';
import 'package:uuid/uuid.dart';

// Mock classes
class MockCameraService extends Mock implements CameraService {}

class MockMarkerDetector extends Mock implements MarkerDetector {}

class MockImagePreprocessor extends Mock implements ImagePreprocessor {}

class MockOmrPipeline extends Mock implements OmrPipeline {}

class MockGradingService extends Mock implements GradingService {}

class MockScanRepository extends Mock implements ScanRepository {}

class MockTemplateManager extends Mock implements TemplateManager {}

class MockPerspectiveTransformer extends Mock
    implements PerspectiveTransformer {}

class MockPerformanceProfiler extends Mock implements PerformanceProfiler {}

void main() {
  // Register fallback values for custom types used with any() matcher
  setUpAll(() {
    registerFallbackValue(MetricType.pipelineTotal);
  });

  group('ScannerBloc', () {
    late MockCameraService mockCameraService;
    late MockMarkerDetector mockMarkerDetector;
    late MockImagePreprocessor mockImagePreprocessor;
    late MockOmrPipeline mockOmrPipeline;
    late MockGradingService mockGradingService;
    late MockScanRepository mockScanRepository;
    late MockTemplateManager mockTemplateManager;
    late MockPerspectiveTransformer mockPerspectiveTransformer;
    late MockPerformanceProfiler mockPerformanceProfiler;

    final testUuid = const Uuid();
    late Quiz testQuiz;

    setUp(() {
      mockCameraService = MockCameraService();
      mockMarkerDetector = MockMarkerDetector();
      mockImagePreprocessor = MockImagePreprocessor();
      mockOmrPipeline = MockOmrPipeline();
      mockGradingService = MockGradingService();
      mockScanRepository = MockScanRepository();
      mockTemplateManager = MockTemplateManager();
      mockPerspectiveTransformer = MockPerspectiveTransformer();
      mockPerformanceProfiler = MockPerformanceProfiler();

      // Default stub for cleanup - called on bloc close
      when(() => mockCameraService.stopImageStream()).thenAnswer((_) async {});

      // Default stubs for performance profiler
      when(() => mockPerformanceProfiler.isEnabled).thenReturn(false);
      when(() => mockPerformanceProfiler.sampleMemory(
          context: any(named: 'context'))).thenReturn(null);
      when(() => mockPerformanceProfiler.startTimer(any())).thenAnswer((_) {});
      when(() => mockPerformanceProfiler.stopTimer(any())).thenReturn(0);

      testQuiz = Quiz(
        id: 'test-quiz-id',
        name: 'Test Quiz',
        templateId: 'template-20q',
        createdAt: DateTime.now(),
        answerKey: {
          'q1': 'A',
          'q2': 'B',
          'q3': 'C',
        },
      );
    });

    group('InitCamera event', () {
      blocTest<ScannerBloc, ScannerState>(
        'emits [Initializing, Previewing] when initialization succeeds',
        setUp: () {
          when(() => mockCameraService.initialize()).thenAnswer((_) async {});
          when(() => mockMarkerDetector.initialize()).thenAnswer((_) async {});
          when(() => mockTemplateManager.getTemplate(any()))
              .thenAnswer((_) async => _buildTestTemplate());
          when(() => mockCameraService.startImageStream()).thenReturn(null);
          when(() => mockCameraService.imageStream)
              .thenAnswer((_) => const Stream.empty());
        },
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        act: (bloc) => bloc.add(ScannerInitCamera(quiz: testQuiz)),
        expect: () => [
          const ScannerInitializing(),
          const ScannerPreviewing(markersDetected: 0, avgConfidence: 0.0),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'emits error when camera initialization fails',
        setUp: () {
          when(() => mockCameraService.initialize())
              .thenThrow(Exception('Camera unavailable'));
        },
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        act: (bloc) => bloc.add(ScannerInitCamera(quiz: testQuiz)),
        expect: () => [
          const ScannerInitializing(),
          isA<ScannerError>()
              .having((state) => state.type, 'type',
                  ScannerErrorType.cameraInitialization)
              .having((state) => state.message, 'message',
                  contains('Failed to initialize camera')),
        ],
      );
    });

    group('MarkersUpdated event', () {
      blocTest<ScannerBloc, ScannerState>(
        'transitions from Previewing to Aligning when all markers detected',
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        seed: () =>
            const ScannerPreviewing(markersDetected: 0, avgConfidence: 0.0),
        act: (bloc) => bloc.add(ScannerMarkersUpdated(
          detectionResult: _buildMarkerDetectionResult(
            allMarkersFound: true,
            markersDetectedCount: 4,
            avgConfidence: 1.0,
          ),
        )),
        expect: () => [
          const ScannerAligning(
            markersDetected: 4,
            avgConfidence: 1.0,
            stabilityMs: 0,
          ),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'updates marker count in Previewing state',
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        seed: () =>
            const ScannerPreviewing(markersDetected: 0, avgConfidence: 0.0),
        act: (bloc) => bloc.add(ScannerMarkersUpdated(
          detectionResult: _buildMarkerDetectionResult(
            allMarkersFound: false,
            markersDetectedCount: 2,
            avgConfidence: 0.5,
          ),
        )),
        expect: () => [
          const ScannerPreviewing(markersDetected: 2, avgConfidence: 0.5),
        ],
      );
    });

    group('Stability and Capture flow', () {
      blocTest<ScannerBloc, ScannerState>(
        'transitions to Capturing on stability achieved',
        setUp: () {
          when(() => mockCameraService.initialize()).thenAnswer((_) async {});
          when(() => mockMarkerDetector.initialize()).thenAnswer((_) async {});
          when(() => mockTemplateManager.getTemplate(any()))
              .thenAnswer((_) async => _buildTestTemplate());
          when(() => mockCameraService.startImageStream()).thenReturn(null);
          when(() => mockCameraService.imageStream)
              .thenAnswer((_) => const Stream.empty());
          when(() => mockCameraService.captureImage())
              .thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
        },
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        act: (bloc) async {
          bloc.add(ScannerInitCamera(quiz: testQuiz));
          await Future.delayed(const Duration(milliseconds: 50));
          // Transition to Aligning state first
          bloc.add(ScannerMarkersUpdated(
            detectionResult: _buildMarkerDetectionResult(
              allMarkersFound: true,
              markersDetectedCount: 4,
              avgConfidence: 1.0,
            ),
          ));
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(const ScannerStabilityAchieved());
        },
        skip: 3, // Skip [Initializing, Previewing, Aligning]
        expect: () => [
          const ScannerCapturing(),
          isA<ScannerProcessing>(),
          // Processing fails without full pipeline mocks - that's ok for state machine test
          isA<ScannerError>(),
        ],
      );
    });

    group('Error states', () {
      blocTest<ScannerBloc, ScannerState>(
        'emits error state on capture failure',
        setUp: () {
          when(() => mockCameraService.captureImage())
              .thenThrow(Exception('Capture failed'));
        },
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        seed: () => const ScannerAligning(
          markersDetected: 4,
          avgConfidence: 1.0,
          stabilityMs: 500,
        ),
        act: (bloc) => bloc.add(const ScannerStabilityAchieved()),
        expect: () => [
          const ScannerCapturing(),
          isA<ScannerError>()
              .having(
                  (state) => state.type, 'type', ScannerErrorType.imageCapture)
              .having((state) => state.message, 'message',
                  contains('Failed to capture image')),
        ],
      );
    });

    group('ResultDismissed event', () {
      blocTest<ScannerBloc, ScannerState>(
        'returns to Previewing when result dismissed',
        setUp: () {
          when(() => mockCameraService.startImageStream()).thenReturn(null);
          when(() => mockCameraService.imageStream)
              .thenAnswer((_) => const Stream.empty());
        },
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        seed: () => ScannerResult(
          scanResult: _buildTestScanResult(),
          processingTimeMs: 500,
        ),
        act: (bloc) => bloc.add(ScannerResultDismissed()),
        expect: () => [
          const ScannerPreviewing(markersDetected: 0, avgConfidence: 0.0),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'ProcessingComplete event emits ScannerResult',
        build: () => ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        ),
        act: (bloc) => bloc.add(ScannerProcessingComplete(
          scanResult: _buildTestScanResult(),
          processingTimeMs: 500,
        )),
        expect: () => [
          isA<ScannerResult>(),
        ],
      );
    });

    group('Cleanup on close', () {
      test('cancels timers and subscriptions on close', () async {
        when(() => mockCameraService.initialize()).thenAnswer((_) async {});
        when(() => mockMarkerDetector.initialize()).thenAnswer((_) async {});
        when(() => mockTemplateManager.getTemplate(any()))
            .thenAnswer((_) async => _buildTestTemplate());
        when(() => mockCameraService.startImageStream()).thenReturn(null);
        when(() => mockCameraService.imageStream)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockCameraService.stopImageStream())
            .thenAnswer((_) async {});

        final bloc = ScannerBloc(
          mockCameraService,
          mockMarkerDetector,
          mockImagePreprocessor,
          mockOmrPipeline,
          mockGradingService,
          mockScanRepository,
          mockTemplateManager,
          mockPerspectiveTransformer,
          mockPerformanceProfiler,
          uuid: testUuid,
        );

        bloc.add(ScannerInitCamera(quiz: testQuiz));
        await Future.delayed(const Duration(milliseconds: 100));
        await bloc.close();

        // Verify cleanup was called
        verify(() => mockCameraService.stopImageStream())
            .called(greaterThan(0));
      });
    });
  });
}

// Helper functions
MarkerDetectionResult _buildMarkerDetectionResult({
  required bool allMarkersFound,
  required int markersDetectedCount,
  required double avgConfidence,
}) {
  // Create perMarkerConfidence list based on markersDetectedCount
  final perMarkerConfidence = List<double>.filled(4, 0.0);
  for (int i = 0; i < markersDetectedCount; i++) {
    perMarkerConfidence[i] = 1.0;
  }

  return MarkerDetectionResult(
    markerCenters: List.filled(4, const Point(0, 0)),
    allMarkersFound: allMarkersFound,
    avgConfidence: avgConfidence,
    perMarkerConfidence: perMarkerConfidence,
  );
}

OmrTemplate _buildTestTemplate() {
  return const OmrTemplate(
    id: 'test-template',
    name: 'Test Template',
    version: '1.0',
    questionCount: 3,
    pageWidth: 800,
    pageHeight: 1100,
    pageDpi: 300,
    bubbleWidth: 20,
    bubbleHeight: 20,
    nameRegionX: 100,
    nameRegionY: 100,
    nameRegionWidth: 600,
    nameRegionHeight: 100,
    fieldBlocks: [],
  );
}

ScanResult _buildTestScanResult() {
  return ScanResult(
    id: 'test-scan-id',
    quizId: 'test-quiz-id',
    scannedAt: DateTime.now(),
    nameRegionImage: Uint8List.fromList([1, 2, 3]),
    detectedAnswers: {
      'q1': AnswerStatus.valid('A'),
      'q2': AnswerStatus.valid('B'),
      'q3': AnswerStatus.valid('C'),
    },
    score: 3,
    total: 3,
    percentage: 100.0,
    scanConfidence: 1.0,
    rawBubbleValues: null,
  );
}
