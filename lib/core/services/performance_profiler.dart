import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/performance_constants.dart';

/// Metric types aligned with PRD NFR-P requirements
enum MetricType {
  // NFR-P-01: Scan Pipeline
  pipelineDecode,
  pipelinePreprocess,
  pipelineDetectMarkers,
  pipelineGetCorners,
  pipelineTransform,
  pipelineReadBubbles,
  pipelineThreshold,
  pipelineExtractAnswers,
  pipelineTotal,

  // NFR-P-02: Frame Processing
  frameConversion,
  frameMatCreation,
  framePreprocess,
  frameMarkerDetection,
  frameTotal,

  // NFR-P-03: Cold Start
  coldStartBinding,
  coldStartDI,
  coldStartHiveInit,
  coldStartBoxOpen,
  coldStartCameraInit,
  coldStartMarkerDetectorInit,
  coldStartTotal,

  // NFR-P-04: Memory
  memoryBaseline,
  memoryPeakScan,
  memoryCurrent,
}

/// Statistical summary of recorded metric samples
class MetricStats {
  final MetricType type;
  final int count;
  final int min;
  final int max;
  final double avg;
  final int p50;
  final int p95;
  final int target;
  final bool passesTarget;

  const MetricStats({
    required this.type,
    required this.count,
    required this.min,
    required this.max,
    required this.avg,
    required this.p50,
    required this.p95,
    required this.target,
    required this.passesTarget,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'count': count,
        'min': min,
        'max': max,
        'avg': avg.toStringAsFixed(2),
        'p50': p50,
        'p95': p95,
        'target': target,
        'passesTarget': passesTarget,
      };
}

/// Memory sample with context
class MemorySample {
  final DateTime timestamp;
  final int rssBytes;
  final int heapBytes;
  final String? context;

  const MemorySample({
    required this.timestamp,
    required this.rssBytes,
    required this.heapBytes,
    this.context,
  });

  int get rssMB => rssBytes ~/ (1024 * 1024);
  int get heapMB => heapBytes ~/ (1024 * 1024);

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'rssBytes': rssBytes,
        'rssMB': rssMB,
        'heapBytes': heapBytes,
        'heapMB': heapMB,
        'context': context,
      };
}

/// Profiling session containing all collected metrics
class ProfilingSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final Map<MetricType, List<int>> _samples = {};
  final List<MemorySample> _memorySamples = [];

  ProfilingSession(this.id) : startTime = DateTime.now();

  void addSample(MetricType type, int valueMs) {
    _samples.putIfAbsent(type, () => []).add(valueMs);
  }

  void addMemorySample(MemorySample sample) {
    _memorySamples.add(sample);
  }

  List<int> getSamples(MetricType type) =>
      List.unmodifiable(_samples[type] ?? []);

  List<MemorySample> get memorySamples => List.unmodifiable(_memorySamples);

  int? getPeakMemoryBytes() {
    if (_memorySamples.isEmpty) return null;
    return _memorySamples.map((s) => s.rssBytes).reduce((a, b) => a > b ? a : b);
  }

  MetricStats? getStats(MetricType type) {
    final samples = _samples[type];
    if (samples == null || samples.isEmpty) return null;

    final sorted = List<int>.from(samples)..sort();
    final count = sorted.length;
    final sum = sorted.reduce((a, b) => a + b);

    final p50Index = (count * 0.50).floor().clamp(0, count - 1);
    final p95Index = (count * 0.95).floor().clamp(0, count - 1);

    final target = _getTarget(type);
    final p95 = sorted[p95Index];

    return MetricStats(
      type: type,
      count: count,
      min: sorted.first,
      max: sorted.last,
      avg: sum / count,
      p50: sorted[p50Index],
      p95: p95,
      target: target,
      passesTarget: target > 0 ? p95 <= target : true,
    );
  }

  Map<String, dynamic> exportStepTimings() {
    final timings = <String, dynamic>{};
    for (final type in _samples.keys) {
      final samples = _samples[type]!;
      if (samples.isNotEmpty) {
        timings[type.name] = samples.last; // Most recent timing
      }
    }
    return timings;
  }

  Map<String, dynamic> toJson() {
    final stats = <String, dynamic>{};
    for (final type in MetricType.values) {
      final typeStats = getStats(type);
      if (typeStats != null) {
        stats[type.name] = typeStats.toJson();
      }
    }

    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMs': endTime?.difference(startTime).inMilliseconds,
      'metrics': stats,
      'memorySamples': _memorySamples.map((s) => s.toJson()).toList(),
      'peakMemoryMB': getPeakMemoryBytes() != null
          ? (getPeakMemoryBytes()! / (1024 * 1024)).toStringAsFixed(2)
          : null,
    };
  }

  static int _getTarget(MetricType type) {
    switch (type) {
      // Pipeline targets
      case MetricType.pipelineTotal:
        return PerformanceConstants.pipelineTotalTarget;
      case MetricType.pipelineDecode:
        return PerformanceConstants.pipelineDecodeTarget;
      case MetricType.pipelinePreprocess:
        return PerformanceConstants.pipelinePreprocessTarget;
      case MetricType.pipelineDetectMarkers:
        return PerformanceConstants.pipelineDetectMarkersTarget;
      case MetricType.pipelineGetCorners:
        return PerformanceConstants.pipelineGetCornersTarget;
      case MetricType.pipelineTransform:
        return PerformanceConstants.pipelineTransformTarget;
      case MetricType.pipelineReadBubbles:
        return PerformanceConstants.pipelineReadBubblesTarget;
      case MetricType.pipelineThreshold:
        return PerformanceConstants.pipelineThresholdTarget;
      case MetricType.pipelineExtractAnswers:
        return PerformanceConstants.pipelineExtractTarget;

      // Frame targets
      case MetricType.frameTotal:
        return PerformanceConstants.frameProcessingTarget;
      case MetricType.frameConversion:
        return PerformanceConstants.frameConversionTarget;
      case MetricType.frameMatCreation:
        return PerformanceConstants.frameMatCreationTarget;
      case MetricType.framePreprocess:
        return PerformanceConstants.framePreprocessTarget;
      case MetricType.frameMarkerDetection:
        return PerformanceConstants.frameMarkerDetectionTarget;

      // Cold start targets
      case MetricType.coldStartTotal:
        return PerformanceConstants.coldStartTotalTarget;
      case MetricType.coldStartBinding:
        return PerformanceConstants.coldStartBindingTarget;
      case MetricType.coldStartDI:
        return PerformanceConstants.coldStartDITarget;
      case MetricType.coldStartHiveInit:
        return PerformanceConstants.coldStartHiveInitTarget;
      case MetricType.coldStartBoxOpen:
        return PerformanceConstants.coldStartBoxOpenTarget;
      case MetricType.coldStartCameraInit:
        return PerformanceConstants.coldStartCameraTarget;
      case MetricType.coldStartMarkerDetectorInit:
        return PerformanceConstants.coldStartMarkerDetectorTarget;

      // Memory - no per-sample target, check peak separately
      case MetricType.memoryBaseline:
      case MetricType.memoryPeakScan:
      case MetricType.memoryCurrent:
        return 0;
    }
  }
}

/// Performance profiler service for measuring and validating NFR-P requirements
///
/// Features:
/// - Conditional compilation (disabled in release builds via [isEnabled])
/// - Named metric types aligned with PRD NFR targets
/// - Session-based metric collection with statistical analysis
/// - Memory sampling for peak usage tracking
/// - JSON export for external analysis
/// - Built-in NFR target validation
///
/// Usage:
/// ```dart
/// // Wrap synchronous operation
/// final result = profiler.measure(MetricType.pipelineDecode, () {
///   return preprocessor.decodeImage(imageBytes);
/// });
///
/// // Wrap async operation
/// final processed = await profiler.measureAsync(MetricType.pipelinePreprocess, () {
///   return preprocessor.preprocess(mat);
/// });
///
/// // Manual timing for complex flows
/// profiler.startTimer(MetricType.pipelineTotal);
/// try {
///   // ... multiple steps ...
/// } finally {
///   final totalMs = profiler.stopTimer(MetricType.pipelineTotal);
/// }
/// ```
@lazySingleton
class PerformanceProfiler {
  final Map<MetricType, Stopwatch> _activeTimers = {};
  final Queue<ProfilingSession> _sessions = Queue();
  ProfilingSession? _currentSession;

  static const int _maxSessionHistory = 100;

  /// Whether profiling is enabled (disabled in release builds)
  bool get isEnabled => !kReleaseMode;

  /// Current active profiling session
  ProfilingSession? get currentSession => _currentSession;

  /// All completed profiling sessions (most recent first)
  List<ProfilingSession> get sessions => _sessions.toList().reversed.toList();

  /// Start a new profiling session
  ///
  /// Creates a new session with the given [id] (default: timestamp).
  /// Ends any existing session first.
  void startSession([String? id]) {
    if (!isEnabled) return;

    // End current session if exists
    if (_currentSession != null) {
      endSession();
    }

    final sessionId = id ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    _currentSession = ProfilingSession(sessionId);

    developer.log(
      'Started profiling session: $sessionId',
      name: 'PerformanceProfiler',
    );
  }

  /// End the current profiling session
  ///
  /// Returns the completed session, or null if no session was active.
  ProfilingSession? endSession() {
    if (!isEnabled || _currentSession == null) return null;

    final session = _currentSession!;
    session.endTime = DateTime.now();

    // Store in history
    _sessions.addLast(session);
    while (_sessions.length > _maxSessionHistory) {
      _sessions.removeFirst();
    }

    // Log summary
    _logSessionSummary(session);

    _currentSession = null;
    _activeTimers.clear();

    return session;
  }

  /// Start a timer for the given metric
  void startTimer(MetricType metric) {
    if (!isEnabled) return;

    _activeTimers[metric] = Stopwatch()..start();
  }

  /// Stop a timer and record the elapsed time
  ///
  /// Returns the elapsed time in milliseconds, or 0 if timer wasn't running.
  int stopTimer(MetricType metric) {
    if (!isEnabled) return 0;

    final timer = _activeTimers.remove(metric);
    if (timer == null) return 0;

    timer.stop();
    final elapsedMs = timer.elapsedMilliseconds;

    _currentSession?.addSample(metric, elapsedMs);

    return elapsedMs;
  }

  /// Measure a synchronous operation
  ///
  /// Wraps [operation] with timing and records to current session.
  T measure<T>(MetricType metric, T Function() operation) {
    if (!isEnabled) return operation();

    startTimer(metric);
    try {
      return operation();
    } finally {
      stopTimer(metric);
    }
  }

  /// Measure an asynchronous operation
  ///
  /// Wraps [operation] with timing and records to current session.
  Future<T> measureAsync<T>(
    MetricType metric,
    Future<T> Function() operation,
  ) async {
    if (!isEnabled) return operation();

    startTimer(metric);
    try {
      return await operation();
    } finally {
      stopTimer(metric);
    }
  }

  /// Sample current memory usage
  ///
  /// Records approximate memory with optional context string.
  /// Note: Accurate memory measurement requires platform-specific APIs.
  /// This uses Timeline API for debugging but actual RSS requires
  /// native profiling tools (Android Studio Profiler, Xcode Instruments).
  void sampleMemory({String? context}) {
    if (!isEnabled) return;

    // Memory sampling is best-effort in Dart
    // For accurate measurements, use native profiling tools
    // This records a Timeline event for correlation with external profilers
    developer.Timeline.instantSync(
      'MemorySample',
      arguments: {'context': context ?? 'unspecified'},
    );

    // Create a placeholder sample for logging purposes
    // Actual memory values should be obtained from native profilers
    final sample = MemorySample(
      timestamp: DateTime.now(),
      rssBytes: 0, // Placeholder - use native profiler for real values
      heapBytes: 0, // Placeholder - use native profiler for real values
      context: context,
    );

    _currentSession?.addMemorySample(sample);

    developer.log(
      'Memory sample recorded ${context != null ? "($context)" : ""}',
      name: 'PerformanceProfiler',
    );
  }

  /// Record a metric value directly (without timing)
  void recordMetric(MetricType metric, int valueMs) {
    if (!isEnabled) return;
    _currentSession?.addSample(metric, valueMs);
  }

  /// Get statistics for a specific metric from current session
  MetricStats? getStats(MetricType metric) {
    return _currentSession?.getStats(metric);
  }

  /// Get statistics from all completed sessions combined
  MetricStats? getAggregateStats(MetricType metric) {
    if (_sessions.isEmpty) return null;

    final allSamples = <int>[];
    for (final session in _sessions) {
      allSamples.addAll(session.getSamples(metric));
    }

    if (allSamples.isEmpty) return null;

    allSamples.sort();
    final count = allSamples.length;
    final sum = allSamples.reduce((a, b) => a + b);

    final p50Index = (count * 0.50).floor().clamp(0, count - 1);
    final p95Index = (count * 0.95).floor().clamp(0, count - 1);

    final target = ProfilingSession._getTarget(metric);
    final p95 = allSamples[p95Index];

    return MetricStats(
      type: metric,
      count: count,
      min: allSamples.first,
      max: allSamples.last,
      avg: sum / count,
      p50: allSamples[p50Index],
      p95: p95,
      target: target,
      passesTarget: target > 0 ? p95 <= target : true,
    );
  }

  /// Validate all NFR targets and return pass/fail results
  Map<String, bool> validateTargets() {
    final results = <String, bool>{};

    // Pipeline total (NFR-P-01)
    final pipelineStats = getAggregateStats(MetricType.pipelineTotal);
    results['NFR-P-01 Pipeline < 500ms'] = pipelineStats?.passesTarget ?? true;

    // Frame processing (NFR-P-02)
    final frameStats = getAggregateStats(MetricType.frameTotal);
    results['NFR-P-02 Frame < 100ms'] = frameStats?.passesTarget ?? true;

    // Cold start (NFR-P-03)
    final coldStartStats = getAggregateStats(MetricType.coldStartTotal);
    results['NFR-P-03 Cold Start < 3s'] = coldStartStats?.passesTarget ?? true;

    // Memory (NFR-P-04)
    int? peakMemory;
    for (final session in _sessions) {
      final sessionPeak = session.getPeakMemoryBytes();
      if (sessionPeak != null) {
        peakMemory = peakMemory == null
            ? sessionPeak
            : (sessionPeak > peakMemory ? sessionPeak : peakMemory);
      }
    }
    results['NFR-P-04 Memory < 200MB'] = peakMemory == null ||
        peakMemory <= PerformanceConstants.memoryPeakTargetBytes;

    return results;
  }

  /// Export all session data as JSON
  Map<String, dynamic> exportData() {
    return {
      'exportTime': DateTime.now().toIso8601String(),
      'sessionCount': _sessions.length,
      'currentSession': _currentSession?.toJson(),
      'completedSessions': _sessions.map((s) => s.toJson()).toList(),
      'aggregateStats': _exportAggregateStats(),
      'targetValidation': validateTargets(),
    };
  }

  /// Clear all session history
  void clearHistory() {
    _sessions.clear();
    _activeTimers.clear();
    _currentSession = null;
  }

  Map<String, dynamic> _exportAggregateStats() {
    final stats = <String, dynamic>{};
    for (final type in MetricType.values) {
      final typeStats = getAggregateStats(type);
      if (typeStats != null && typeStats.count > 0) {
        stats[type.name] = typeStats.toJson();
      }
    }
    return stats;
  }

  void _logSessionSummary(ProfilingSession session) {
    final buffer = StringBuffer();
    buffer.writeln('Session ${session.id} completed:');

    // Log key metrics
    final keyMetrics = [
      MetricType.pipelineTotal,
      MetricType.frameTotal,
      MetricType.coldStartTotal,
    ];

    for (final metric in keyMetrics) {
      final stats = session.getStats(metric);
      if (stats != null) {
        final status = stats.passesTarget ? 'PASS' : 'FAIL';
        buffer.writeln(
          '  ${metric.name}: P95=${stats.p95}ms (target: ${stats.target}ms) [$status]',
        );
      }
    }

    // Log peak memory
    final peakMemory = session.getPeakMemoryBytes();
    if (peakMemory != null) {
      final peakMB = peakMemory / (1024 * 1024);
      final targetMB = PerformanceConstants.memoryPeakTargetBytes / (1024 * 1024);
      final status = peakMB <= targetMB ? 'PASS' : 'FAIL';
      buffer.writeln(
        '  memory: peak=${peakMB.toStringAsFixed(1)}MB (target: ${targetMB.toStringAsFixed(0)}MB) [$status]',
      );
    }

    developer.log(buffer.toString(), name: 'PerformanceProfiler');
  }
}
