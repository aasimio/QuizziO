import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'features/omr/data/models/scan_result_model.dart';
import 'features/quiz/data/models/quiz_model.dart';
import 'injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependency injection
  configureDependencies();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters before opening boxes
  Hive.registerAdapter(QuizModelAdapter());
  Hive.registerAdapter(ScanResultModelAdapter());

  // Open typed boxes
  await Hive.openBox<QuizModel>(HiveBoxes.quizzes);
  await Hive.openBox<ScanResultModel>(HiveBoxes.scanResults);

  runApp(const QuizziOApp());
}
