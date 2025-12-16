import '../entities/scan_result.dart';

abstract class ScanRepository {
  Future<List<ScanResult>> getByQuizId(String quizId);
  Future<ScanResult?> getById(String id);
  Future<void> save(ScanResult result);
  Future<void> update(ScanResult result);
  Future<void> delete(String id);
  Future<void> deleteByQuizId(String quizId);
}
