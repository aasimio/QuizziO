import 'package:injectable/injectable.dart';

import '../domain/entities/omr_template.dart';
import '../domain/repositories/template_repository.dart';

@lazySingleton
class TemplateManager {
  final TemplateRepository _repository;

  TemplateManager(this._repository);

  Future<OmrTemplate> getTemplate(String id) {
    return _repository.getById(id);
  }

  List<String> getAvailableTemplateIds() {
    return _repository.getAvailableTemplateIds();
  }

  Future<List<OmrTemplate>> getAllTemplates() {
    return _repository.getAll();
  }
}
