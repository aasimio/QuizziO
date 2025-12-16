import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependency injection
  configureDependencies();

  // Initialize Hive
  await Hive.initFlutter();

  // Open boxes (untyped for now, will be typed when models are created in Phase 1)
  await Hive.openBox(HiveBoxes.quizzes);
  await Hive.openBox(HiveBoxes.scanResults);

  runApp(const QuizziOApp());
}
