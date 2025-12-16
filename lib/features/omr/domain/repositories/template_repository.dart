import '../entities/omr_template.dart';

abstract class TemplateRepository {
  Future<OmrTemplate> getById(String id);
  Future<List<OmrTemplate>> getAll();
  List<String> getAvailableTemplateIds();
}
