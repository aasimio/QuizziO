import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_repository.dart';
import '../models/scan_result_model.dart';

@LazySingleton(as: ScanRepository)
class ScanRepositoryImpl implements ScanRepository {
  Box<ScanResultModel> get _box =>
      Hive.box<ScanResultModel>(HiveBoxes.scanResults);

  @override
  Future<List<ScanResult>> getByQuizId(String quizId) async {
    return _box.values
        .where((model) => model.quizId == quizId)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<ScanResult?> getById(String id) async {
    final model = _box.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(ScanResult result) async {
    final model = ScanResultModel.fromEntity(result);
    await _box.put(result.id, model);
  }

  @override
  Future<void> update(ScanResult result) async {
    final model = ScanResultModel.fromEntity(result);
    await _box.put(result.id, model);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteByQuizId(String quizId) async {
    final keysToDelete = _box
        .toMap()
        .entries
        .where((entry) => entry.value.quizId == quizId)
        .map((entry) => entry.key)
        .toList();
    await _box.deleteAll(keysToDelete);
  }
}
