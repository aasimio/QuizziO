import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:quizzio/app.dart';
import 'package:quizzio/core/constants/hive_boxes.dart';
import 'package:quizzio/features/omr/data/models/scan_result_model.dart';
import 'package:quizzio/features/quiz/data/models/quiz_model.dart';
import 'package:quizzio/injection.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('./test/hive_test');

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QuizModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScanResultModelAdapter());
    }

    // Open boxes
    await Hive.openBox<QuizModel>(HiveBoxes.quizzes);
    await Hive.openBox<ScanResultModel>(HiveBoxes.scanResults);

    // Configure DI
    configureDependencies();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuizziOApp());

    // Allow the BLoC to load
    await tester.pump();

    // Verify home screen elements: title and FAB
    expect(find.text('Quizzes'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
