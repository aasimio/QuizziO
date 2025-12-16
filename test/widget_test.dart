import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizzio/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuizziOApp());

    // Verify home screen elements: title and FAB
    expect(find.text('My Quizzes'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
