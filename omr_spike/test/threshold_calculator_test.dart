import 'package:flutter_test/flutter_test.dart';
import 'package:omr_spike/services/threshold_calculator.dart';

void main() {
  group('ThresholdCalculator', () {
    late ThresholdCalculator calculator;

    setUp(() {
      calculator = ThresholdCalculator(minJump: 20, looseness: 4);
    });

    test('should find threshold with clear bimodal distribution', () {
      // Arrange: clear separation between filled (low) and unfilled (high) bubbles
      // Simulating 5 questions with 5 bubbles each (25 total)
      // Questions 1-3: answer B filled (3 filled, 12 unfilled)
      // Questions 4-5: answer D filled (2 filled, 8 unfilled)
      final values = [
        // Q1: A, B*, C, D, E
        200.0, 45.0, 210.0, 220.0, 230.0,
        // Q2: A, B*, C, D, E
        205.0, 50.0, 215.0, 225.0, 235.0,
        // Q3: A, B*, C, D, E
        195.0, 40.0, 205.0, 215.0, 225.0,
        // Q4: A, B, C, D*, E
        210.0, 220.0, 230.0, 48.0, 240.0,
        // Q5: A, B, C, D*, E
        215.0, 225.0, 235.0, 52.0, 245.0,
      ];

      // Act
      final result = calculator.calculate(values);

      // Assert
      expect(result.threshold, greaterThan(52.0));
      expect(result.threshold, lessThan(195.0));
      expect(result.maxGap, greaterThanOrEqualTo(20.0));
      expect(result.confidence, greaterThan(0.0));
    });

    test('should handle all high values (no marks)', () {
      // Arrange: all bubbles are unfilled (high intensity)
      final values = [200.0, 210.0, 220.0, 230.0, 240.0];

      // Act
      final result = calculator.calculate(values);

      // Assert
      // Should still calculate, but with low confidence (no clear gap >= minJump)
      expect(result.threshold, isNotNull);
      expect(result.maxGap, lessThan(20.0)); // No gap meets minJump threshold
    });

    test('should handle all low values (all filled)', () {
      // Arrange: all bubbles are filled (low intensity)
      final values = [30.0, 35.0, 40.0, 45.0, 50.0];

      // Act
      final result = calculator.calculate(values);

      // Assert
      // Should still calculate, but with low confidence (no clear gap >= minJump)
      expect(result.threshold, isNotNull);
      expect(result.maxGap, lessThan(20.0)); // No gap meets minJump threshold
    });

    test('should handle single value', () {
      // Arrange: edge case with only one value
      final values = [128.0];

      // Act
      final result = calculator.calculate(values);

      // Assert
      // Should default to 128 since no gap can be found
      expect(result.threshold, equals(128.0));
      expect(result.maxGap, equals(0.0));
      expect(result.confidence, equals(0.0));
    });

    test('should handle empty list', () {
      // Arrange: edge case with empty list
      final values = <double>[];

      // Act
      final result = calculator.calculate(values);

      // Assert
      expect(result.threshold, equals(128.0));
      expect(result.maxGap, equals(0.0));
      expect(result.confidence, equals(0.0));
    });
  });

  group('ThresholdCalculator - extractAnswers', () {
    late ThresholdCalculator calculator;

    setUp(() {
      calculator = ThresholdCalculator();
    });

    test('should extract valid answer when one bubble is filled', () {
      // Arrange: Q1 has bubble B filled (low intensity)
      final bubbleValues = {
        'q1': [200.0, 50.0, 210.0, 220.0, 230.0], // B is filled
      };
      final threshold = 100.0;

      // Act
      final results = calculator.extractAnswers(bubbleValues, threshold);

      // Assert
      expect(results['q1']?.value, equals('B'));
      expect(results['q1']?.status, equals(AnswerStatus.valid));
    });

    test('should detect blank answer when no bubble is filled', () {
      // Arrange: all bubbles unfilled (high intensity)
      final bubbleValues = {
        'q1': [200.0, 210.0, 220.0, 230.0, 240.0],
      };
      final threshold = 100.0;

      // Act
      final results = calculator.extractAnswers(bubbleValues, threshold);

      // Assert
      expect(results['q1']?.value, isNull);
      expect(results['q1']?.status, equals(AnswerStatus.blank));
    });

    test('should detect multiple marks when multiple bubbles are filled', () {
      // Arrange: bubbles A and C filled (low intensity)
      final bubbleValues = {
        'q1': [50.0, 210.0, 55.0, 220.0, 230.0], // A and C filled
      };
      final threshold = 100.0;

      // Act
      final results = calculator.extractAnswers(bubbleValues, threshold);

      // Assert
      expect(results['q1']?.value, isNull);
      expect(results['q1']?.status, equals(AnswerStatus.multipleMark));
    });

    test('should handle multiple questions', () {
      // Arrange: multiple questions with different statuses
      final bubbleValues = {
        'q1': [50.0, 210.0, 220.0, 230.0, 240.0],   // A filled
        'q2': [200.0, 210.0, 220.0, 230.0, 240.0],  // Blank
        'q3': [200.0, 210.0, 55.0, 230.0, 240.0],   // C filled
        'q4': [50.0, 55.0, 220.0, 230.0, 240.0],    // Multiple (A, B)
        'q5': [200.0, 210.0, 220.0, 230.0, 45.0],   // E filled
      };
      final threshold = 100.0;

      // Act
      final results = calculator.extractAnswers(bubbleValues, threshold);

      // Assert
      expect(results['q1']?.value, equals('A'));
      expect(results['q1']?.status, equals(AnswerStatus.valid));

      expect(results['q2']?.value, isNull);
      expect(results['q2']?.status, equals(AnswerStatus.blank));

      expect(results['q3']?.value, equals('C'));
      expect(results['q3']?.status, equals(AnswerStatus.valid));

      expect(results['q4']?.value, isNull);
      expect(results['q4']?.status, equals(AnswerStatus.multipleMark));

      expect(results['q5']?.value, equals('E'));
      expect(results['q5']?.status, equals(AnswerStatus.valid));
    });
  });
}
