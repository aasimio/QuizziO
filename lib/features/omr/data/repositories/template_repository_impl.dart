import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/omr_template.dart';
import '../../domain/repositories/template_repository.dart';

@LazySingleton(as: TemplateRepository)
class TemplateRepositoryImpl implements TemplateRepository {
  static const Map<String, String> _templatePaths = {
    'std_10q': 'assets/templates/template_10q.json',
    'std_20q': 'assets/templates/template_20q.json',
    'std_50q': 'assets/templates/template_50q.json',
  };

  final Map<String, OmrTemplate> _cache = {};

  @override
  Future<OmrTemplate> getById(String id) async {
    if (_cache.containsKey(id)) {
      return _cache[id]!;
    }

    final path = _templatePaths[id];
    if (path == null) {
      throw ArgumentError('Unknown template ID: $id');
    }

    final jsonString = await rootBundle.loadString(path);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    final template = OmrTemplate.fromJson(jsonMap);

    _cache[id] = template;
    return template;
  }

  @override
  Future<List<OmrTemplate>> getAll() async {
    final templates = <OmrTemplate>[];
    for (final id in _templatePaths.keys) {
      final template = await getById(id);
      templates.add(template);
    }
    return templates;
  }

  @override
  List<String> getAvailableTemplateIds() {
    return _templatePaths.keys.toList();
  }
}
