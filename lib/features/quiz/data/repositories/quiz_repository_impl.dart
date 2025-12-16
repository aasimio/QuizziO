import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../models/quiz_model.dart';

@LazySingleton(as: QuizRepository)
class QuizRepositoryImpl implements QuizRepository {
  Box<QuizModel> get _box => Hive.box<QuizModel>(HiveBoxes.quizzes);

  @override
  Future<List<Quiz>> getAll() async {
    return _box.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Quiz?> getById(String id) async {
    final model = _box.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(Quiz quiz) async {
    final model = QuizModel.fromEntity(quiz);
    await _box.put(quiz.id, model);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
