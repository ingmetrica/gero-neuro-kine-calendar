import 'package:flutter/material.dart';
import 'dart:convert';
import 'event_model.dart';

/// Representa una plantilla de evento reutilizable
class EventTemplate {
  final String id;
  final String name;
  final String? description;
  final String title;
  final String? location;
  final Duration duration;
  final String? notes;
  final Color color;
  final RecurrenceType recurrenceType;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final List<String> reminderMinutes;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;

  EventTemplate({
    required this.id,
    required this.name,
    required this.title,
    this.description,
    this.location,
    this.duration = const Duration(hours: 1),
    this.notes,
    this.color = Colors.blue,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.reminderMinutes = const ['15'],
    this.categoryId,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  /// Crear evento desde esta plantilla
  CalendarEvent createEvent({
    required DateTime startTime,
    DateTime? endTime,
  }) {
    return CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime ?? startTime.add(duration),
      location: location,
      color: color,
      isAllDay: false,
      recurrenceType: recurrenceType,
      recurrenceInterval: recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate,
      hasNotification: reminderMinutes.isNotEmpty,
      notificationMinutesBefore: reminderMinutes.isNotEmpty ? int.parse(reminderMinutes.first) : null,
    );
  }

  /// Crear plantilla desde un evento existente
  static EventTemplate fromEvent(CalendarEvent event, String templateName) {
    final duration = event.endTime.difference(event.startTime);

    // Convertir notificationMinutesBefore a lista de strings
    final reminderMinutes = event.hasNotification && event.notificationMinutesBefore != null
        ? [event.notificationMinutesBefore.toString()]
        : <String>['15'];

    return EventTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: templateName,
      title: event.title,
      description: event.description,
      location: event.location,
      duration: duration,
      notes: null, // CalendarEvent no tiene campo notes
      color: event.color,
      recurrenceType: event.recurrenceType,
      recurrenceInterval: event.recurrenceInterval,
      recurrenceEndDate: event.recurrenceEndDate,
      reminderMinutes: reminderMinutes,
      categoryId: null, // CalendarEvent no tiene categoryId
      createdAt: DateTime.now(),
      usageCount: 0,
    );
  }

  /// Copiar plantilla con modificaciones
  EventTemplate copyWith({
    String? id,
    String? name,
    String? title,
    String? description,
    String? location,
    Duration? duration,
    String? notes,
    Color? color,
    RecurrenceType? recurrenceType,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    List<String>? reminderMinutes,
    String? categoryId,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return EventTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Convertir a mapa para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'location': location,
      'durationMinutes': duration.inMinutes,
      'notes': notes,
      'color': color.value,
      'recurrenceType': recurrenceType.toString(),
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'reminderMinutes': reminderMinutes,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  /// Crear desde mapa
  static EventTemplate fromMap(Map<String, dynamic> map) {
    return EventTemplate(
      id: map['id'],
      name: map['name'],
      title: map['title'],
      description: map['description'],
      location: map['location'],
      duration: Duration(minutes: map['durationMinutes'] ?? 60),
      notes: map['notes'],
      color: Color(map['color']),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == map['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      recurrenceInterval: map['recurrenceInterval'],
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.parse(map['recurrenceEndDate'])
          : null,
      reminderMinutes: List<String>.from(map['reminderMinutes'] ?? []),
      categoryId: map['categoryId'],
      createdAt: DateTime.parse(map['createdAt']),
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.parse(map['lastUsedAt'])
          : null,
      usageCount: map['usageCount'] ?? 0,
    );
  }

  /// Convertir a JSON
  String toJson() => json.encode(toMap());

  /// Crear desde JSON
  static EventTemplate fromJson(String source) =>
      fromMap(json.decode(source));
}

/// Plantillas predefinidas del sistema
class DefaultTemplates {
  static final List<EventTemplate> templates = [
    EventTemplate(
      id: 'default_meeting',
      name: 'Reunión de Trabajo',
      title: 'Reunión',
      description: 'Reunión de trabajo',
      duration: const Duration(hours: 1),
      color: Colors.blue,
      reminderMinutes: ['15', '5'],
      createdAt: DateTime.now(),
    ),
    EventTemplate(
      id: 'default_lunch',
      name: 'Almuerzo',
      title: 'Almuerzo',
      duration: const Duration(hours: 1),
      color: Colors.orange,
      reminderMinutes: ['15'],
      createdAt: DateTime.now(),
    ),
    EventTemplate(
      id: 'default_exercise',
      name: 'Ejercicio',
      title: 'Tiempo de Ejercicio',
      description: 'Sesión de ejercicio',
      duration: const Duration(hours: 1),
      color: Colors.green,
      reminderMinutes: ['30', '15'],
      createdAt: DateTime.now(),
    ),
    EventTemplate(
      id: 'default_study',
      name: 'Estudio',
      title: 'Sesión de Estudio',
      description: 'Tiempo dedicado al estudio',
      duration: const Duration(hours: 2),
      color: Colors.purple,
      reminderMinutes: ['15'],
      createdAt: DateTime.now(),
    ),
    EventTemplate(
      id: 'default_call',
      name: 'Llamada Telefónica',
      title: 'Llamada',
      duration: const Duration(minutes: 30),
      color: Colors.teal,
      reminderMinutes: ['10'],
      createdAt: DateTime.now(),
    ),
  ];
}
