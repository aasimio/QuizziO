import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'core/services/performance_profiler.dart';
import 'features/omr/data/models/scan_result_model.dart';
import 'features/quiz/data/models/quiz_model.dart';
import 'injection.dart';

Future<void> main() async {
  // Start profiling cold start (only in debug/profile mode)
  late final PerformanceProfiler profiler;
  final shouldProfile = !kReleaseMode;

  if (shouldProfile) {
    // Create profiler manually before DI is configured
    profiler = PerformanceProfiler();
    profiler.startSession('cold_start');
    profiler.startTimer(MetricType.coldStartTotal);
    profiler.startTimer(MetricType.coldStartBinding);
  }

  WidgetsFlutterBinding.ensureInitialized();

  if (shouldProfile) {
    profiler.stopTimer(MetricType.coldStartBinding);
    profiler.startTimer(MetricType.coldStartDI);
  }

  // Configure dependency injection
  configureDependencies();

  if (shouldProfile) {
    profiler.stopTimer(MetricType.coldStartDI);
    profiler.startTimer(MetricType.coldStartHiveInit);
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters before opening boxes
  Hive.registerAdapter(QuizModelAdapter());
  Hive.registerAdapter(ScanResultModelAdapter());

  if (shouldProfile) {
    profiler.stopTimer(MetricType.coldStartHiveInit);
    profiler.startTimer(MetricType.coldStartBoxOpen);
  }

  // Open typed boxes (parallel for performance)
  await Future.wait([
    Hive.openBox<QuizModel>(HiveBoxes.quizzes),
    Hive.openBox<ScanResultModel>(HiveBoxes.scanResults),
  ]);

  if (shouldProfile) {
    profiler.stopTimer(MetricType.coldStartBoxOpen);
    final coldStartMs = profiler.stopTimer(MetricType.coldStartTotal);
    developer.log(
      'Cold start to runApp: ${coldStartMs}ms',
      name: 'PerformanceProfiler',
    );
  }

  runApp(const QuizziOApp());

  // Measure first frame render time
  if (shouldProfile) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('First frame rendered', name: 'PerformanceProfiler');
      profiler.endSession();
    });
  }
}
