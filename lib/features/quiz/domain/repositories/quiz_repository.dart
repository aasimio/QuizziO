import '../entities/quiz.dart';

abstract class QuizRepository {
  Future<List<Quiz>> getAll();
  Future<Quiz?> getById(String id);
  Future<void> save(Quiz quiz);
  Future<void> delete(String id);
}
