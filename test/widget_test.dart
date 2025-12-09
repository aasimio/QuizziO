// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizzio/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify home screen elements: title text, camera test button, and icon
    expect(find.byKey(const Key('home_title_text')), findsOneWidget);
    expect(find.byKey(const Key('camera_test_button')), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
