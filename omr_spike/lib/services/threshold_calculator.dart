class ThresholdResult {
  final double threshold;
  final double confidence;
  final double maxGap;

  const ThresholdResult({
    required this.threshold,
    required this.confidence,
    required this.maxGap,
  });

  @override
  String toString() {
    return 'ThresholdResult(threshold: ${threshold.toStringAsFixed(2)}, '
        'confidence: ${confidence.toStringAsFixed(3)}, '
        'maxGap: ${maxGap.toStringAsFixed(2)})';
  }
}

enum AnswerStatus { valid, blank, multipleMark }

class ExtractedAnswer {
  final String? value;
  final AnswerStatus status;

  const ExtractedAnswer({required this.value, required this.status});

  @override
  String toString() {
    return 'ExtractedAnswer(value: $value, status: $status)';
  }
}

class ThresholdCalculator {
  final int minJump;
  final int looseness;

  ThresholdCalculator({this.minJump = 20, this.looseness = 4});

  ThresholdResult calculate(List<double> allBubbleValues) {
    if (allBubbleValues.isEmpty) {
      return const ThresholdResult(threshold: 128, confidence: 0, maxGap: 0);
    }

    // Sort values ascending
    final sorted = [...allBubbleValues]..sort();

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
    final threshold = maxGap > 0
        ? (smoothed[maxGapIndex] + smoothed[maxGapIndex + 1]) / 2
        : 128.0;

    // Compute confidence using actual max value from input data
    // Expected input range: 0-255 (grayscale intensity from bubble_reader)
    // Using actual max makes code robust to input range changes and prevents confidence > 1.0
    final actualMax = sorted.isNotEmpty ? sorted.last : 0.0;
    final divisor = actualMax > 0
        ? actualMax
        : 1.0; // Fallback to 1.0 if max is zero
    final confidence = (maxGap / divisor).clamp(0.0, 1.0);

    return ThresholdResult(
      threshold: threshold,
      confidence: confidence,
      maxGap: maxGap,
    );
  }

  List<double> _smooth(List<double> values, int windowSize) {
    if (values.isEmpty || windowSize <= 1) {
      return values;
    }

    final smoothed = <double>[];
    for (int i = 0; i < values.length; i++) {
      final start = (i - windowSize ~/ 2).clamp(0, values.length);
      final end = (i + windowSize ~/ 2 + 1).clamp(0, values.length);
      final window = values.sublist(start, end);
      final average = window.reduce((a, b) => a + b) / window.length;
      smoothed.add(average);
    }

    return smoothed;
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
        results[question] = const ExtractedAnswer(
          value: null,
          status: AnswerStatus.blank,
        );
      } else if (filledIndices.length == 1) {
        final index = filledIndices.first;
        // Validate index is within bounds of options array
        if (index >= 0 && index < options.length && options.isNotEmpty) {
          results[question] = ExtractedAnswer(
            value: options[index],
            status: AnswerStatus.valid,
          );
        } else {
          // Invalid index - mark as blank to avoid crash
          results[question] = const ExtractedAnswer(
            value: null,
            status: AnswerStatus.blank,
          );
        }
      } else {
        results[question] = const ExtractedAnswer(
          value: null,
          status: AnswerStatus.multipleMark,
        );
      }
    }

    return results;
  }
}
