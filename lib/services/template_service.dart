import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_template.dart';
import '../models/event_model.dart';

/// Servicio para gestionar plantillas de eventos
class TemplateService {
  static final TemplateService instance = TemplateService._internal();

  factory TemplateService() {
    return instance;
  }

  TemplateService._internal();

  static const String _storageKey = 'event_templates';
  SharedPreferences? _prefs;
  List<EventTemplate> _customTemplates = [];
  bool _initialized = false;

  /// Asegurar que el servicio esté inicializado
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      await _loadTemplates();
      _initialized = true;
    }
  }

  /// Cargar plantillas desde almacenamiento
  Future<void> _loadTemplates() async {
    final String? templatesJson = _prefs?.getString(_storageKey);
    if (templatesJson != null && templatesJson.isNotEmpty) {
      try {
        final List<dynamic> templatesList = json.decode(templatesJson);
        _customTemplates = templatesList
            .map((json) => EventTemplate.fromMap(json))
            .toList();
      } catch (e) {
        print('Error al cargar plantillas: $e');
        _customTemplates = [];
      }
    }
  }

  /// Guardar plantillas en almacenamiento
  Future<void> _saveTemplates() async {
    final List<Map<String, dynamic>> templatesList =
        _customTemplates.map((template) => template.toMap()).toList();
    await _prefs?.setString(_storageKey, json.encode(templatesList));
  }

  /// Obtener todas las plantillas (predefinidas + personalizadas)
  Future<List<EventTemplate>> getAllTemplates() async {
    await _ensureInitialized();
    return [...DefaultTemplates.templates, ..._customTemplates];
  }

  /// Obtener solo plantillas personalizadas
  Future<List<EventTemplate>> getCustomTemplates() async {
    await _ensureInitialized();
    return List.from(_customTemplates);
  }

  /// Obtener plantillas predefinidas
  List<EventTemplate> getDefaultTemplates() {
    return List.from(DefaultTemplates.templates);
  }

  /// Obtener plantilla por ID
  Future<EventTemplate?> getTemplate(String id) async {
    await _ensureInitialized();

    // Buscar en plantillas predefinidas
    try {
      return DefaultTemplates.templates.firstWhere((t) => t.id == id);
    } catch (e) {
      // Si no está en predefinidas, buscar en personalizadas
      try {
        return _customTemplates.firstWhere((t) => t.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  /// Crear nueva plantilla
  Future<EventTemplate> createTemplate(EventTemplate template) async {
    await _ensureInitialized();
    _customTemplates.add(template);
    await _saveTemplates();
    return template;
  }

  /// Crear plantilla desde evento existente
  Future<EventTemplate> createTemplateFromEvent(
    CalendarEvent event,
    String templateName,
  ) async {
    await _ensureInitialized();
    final template = EventTemplate.fromEvent(event, templateName);
    _customTemplates.add(template);
    await _saveTemplates();
    return template;
  }

  /// Actualizar plantilla existente
  Future<void> updateTemplate(EventTemplate template) async {
    await _ensureInitialized();

    // No se pueden actualizar plantillas predefinidas
    final isDefault = DefaultTemplates.templates.any((t) => t.id == template.id);
    if (isDefault) {
      throw Exception('No se pueden modificar plantillas predefinidas');
    }

    final index = _customTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _customTemplates[index] = template;
      await _saveTemplates();
    }
  }

  /// Eliminar plantilla
  Future<void> deleteTemplate(String id) async {
    await _ensureInitialized();

    // No se pueden eliminar plantillas predefinidas
    final isDefault = DefaultTemplates.templates.any((t) => t.id == id);
    if (isDefault) {
      throw Exception('No se pueden eliminar plantillas predefinidas');
    }

    _customTemplates.removeWhere((t) => t.id == id);
    await _saveTemplates();
  }

  /// Usar una plantilla (incrementar contador de uso)
  Future<void> useTemplate(String id, DateTime usedAt) async {
    await _ensureInitialized();

    // Solo actualizar si es plantilla personalizada
    final index = _customTemplates.indexWhere((t) => t.id == id);
    if (index != -1) {
      _customTemplates[index] = _customTemplates[index].copyWith(
        usageCount: _customTemplates[index].usageCount + 1,
        lastUsedAt: usedAt,
      );
      await _saveTemplates();
    }
  }

  /// Obtener plantillas más usadas
  Future<List<EventTemplate>> getMostUsedTemplates({int limit = 5}) async {
    await _ensureInitialized();
    final allTemplates = await getAllTemplates();

    // Ordenar por uso
    final sorted = List<EventTemplate>.from(allTemplates)
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));

    return sorted.take(limit).toList();
  }

  /// Obtener plantillas usadas recientemente
  Future<List<EventTemplate>> getRecentlyUsedTemplates({int limit = 5}) async {
    await _ensureInitialized();
    final allTemplates = await getAllTemplates();

    // Filtrar las que tienen lastUsedAt
    final used = allTemplates.where((t) => t.lastUsedAt != null).toList();

    // Ordenar por fecha de último uso
    used.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

    return used.take(limit).toList();
  }

  /// Buscar plantillas por nombre
  Future<List<EventTemplate>> searchTemplates(String query) async {
    await _ensureInitialized();
    if (query.isEmpty) {
      return await getAllTemplates();
    }

    final allTemplates = await getAllTemplates();
    final lowerQuery = query.toLowerCase();

    return allTemplates.where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
          template.title.toLowerCase().contains(lowerQuery) ||
          (template.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Duplicar plantilla
  Future<EventTemplate> duplicateTemplate(String id) async {
    await _ensureInitialized();

    final original = await getTemplate(id);
    if (original == null) {
      throw Exception('Plantilla no encontrada');
    }

    final duplicate = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${original.name} (Copia)',
      createdAt: DateTime.now(),
      lastUsedAt: null,
      usageCount: 0,
    );

    _customTemplates.add(duplicate);
    await _saveTemplates();
    return duplicate;
  }

  /// Obtener estadísticas de plantillas
  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureInitialized();
    final allTemplates = await getAllTemplates();

    final totalCustom = _customTemplates.length;
    final totalDefault = DefaultTemplates.templates.length;
    final totalUsage = _customTemplates.fold<int>(
      0,
      (sum, template) => sum + template.usageCount,
    );

    final mostUsed = await getMostUsedTemplates(limit: 1);
    final avgUsage = totalCustom > 0 ? totalUsage / totalCustom : 0;

    return {
      'total': allTemplates.length,
      'custom': totalCustom,
      'default': totalDefault,
      'totalUsage': totalUsage,
      'averageUsage': avgUsage.toStringAsFixed(1),
      'mostUsed': mostUsed.isNotEmpty ? mostUsed.first.name : 'N/A',
    };
  }

  /// Exportar plantillas a JSON
  Future<String> exportTemplates() async {
    await _ensureInitialized();
    final List<Map<String, dynamic>> templatesList =
        _customTemplates.map((template) => template.toMap()).toList();
    return json.encode(templatesList);
  }

  /// Importar plantillas desde JSON
  Future<int> importTemplates(String jsonString) async {
    await _ensureInitialized();

    try {
      final List<dynamic> templatesList = json.decode(jsonString);
      int imported = 0;

      for (var templateMap in templatesList) {
        try {
          final template = EventTemplate.fromMap(templateMap);
          // Generar nuevo ID para evitar conflictos
          final newTemplate = template.copyWith(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_$imported',
            createdAt: DateTime.now(),
          );
          _customTemplates.add(newTemplate);
          imported++;
        } catch (e) {
          print('Error al importar plantilla: $e');
        }
      }

      if (imported > 0) {
        await _saveTemplates();
      }

      return imported;
    } catch (e) {
      throw Exception('Error al importar plantillas: $e');
    }
  }

  /// Limpiar todas las plantillas personalizadas
  Future<void> clearCustomTemplates() async {
    await _ensureInitialized();
    _customTemplates.clear();
    await _saveTemplates();
  }
}
