import 'package:flutter/material.dart';
import 'event_model.dart';

// Categorías predefinidas
enum EventCategory {
  work,
  personal,
  health,
  family,
  study,
  sport,
  travel,
  meeting,
  birthday,
  other,
}

extension EventCategoryExtension on EventCategory {
  String get name {
    switch (this) {
      case EventCategory.work:
        return 'Trabajo';
      case EventCategory.personal:
        return 'Personal';
      case EventCategory.health:
        return 'Salud';
      case EventCategory.family:
        return 'Familia';
      case EventCategory.study:
        return 'Estudio';
      case EventCategory.sport:
        return 'Deporte';
      case EventCategory.travel:
        return 'Viaje';
      case EventCategory.meeting:
        return 'Reunión';
      case EventCategory.birthday:
        return 'Cumpleaños';
      case EventCategory.other:
        return 'Otro';
    }
  }

  IconData get icon {
    switch (this) {
      case EventCategory.work:
        return Icons.work;
      case EventCategory.personal:
        return Icons.person;
      case EventCategory.health:
        return Icons.health_and_safety;
      case EventCategory.family:
        return Icons.family_restroom;
      case EventCategory.study:
        return Icons.school;
      case EventCategory.sport:
        return Icons.sports;
      case EventCategory.travel:
        return Icons.flight;
      case EventCategory.meeting:
        return Icons.meeting_room;
      case EventCategory.birthday:
        return Icons.cake;
      case EventCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get defaultColor {
    switch (this) {
      case EventCategory.work:
        return Colors.blue;
      case EventCategory.personal:
        return Colors.green;
      case EventCategory.health:
        return Colors.red;
      case EventCategory.family:
        return Colors.purple;
      case EventCategory.study:
        return Colors.orange;
      case EventCategory.sport:
        return Colors.teal;
      case EventCategory.travel:
        return Colors.indigo;
      case EventCategory.meeting:
        return Colors.brown;
      case EventCategory.birthday:
        return Colors.pink;
      case EventCategory.other:
        return Colors.grey;
    }
  }
}

// Recordatorio
class EventReminder {
  final int minutesBefore;
  final String? customMessage;

  EventReminder({
    required this.minutesBefore,
    this.customMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'minutesBefore': minutesBefore,
      'customMessage': customMessage,
    };
  }

  factory EventReminder.fromMap(Map<String, dynamic> map) {
    return EventReminder(
      minutesBefore: map['minutesBefore'],
      customMessage: map['customMessage'],
    );
  }
}

// Plantilla de evento
class EventTemplate {
  final String id;
  final String name;
  final String title;
  final String? description;
  final Duration duration;
  final Color color;
  final EventCategory? category;
  final List<EventReminder> reminders;
  final String? location;

  EventTemplate({
    required this.id,
    required this.name,
    required this.title,
    this.description,
    required this.duration,
    this.color = Colors.blue,
    this.category,
    this.reminders = const [],
    this.location,
  });

  CalendarEvent toEvent(DateTime startTime) {
    return CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startTime: startTime,
      endTime: startTime.add(duration),
      color: color,
      location: location,
      hasNotification: reminders.isNotEmpty,
      notificationMinutesBefore: reminders.isNotEmpty ? reminders.first.minutesBefore : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'durationMinutes': duration.inMinutes,
      'color': color.value,
      'category': category?.index,
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'location': location,
    };
  }

  factory EventTemplate.fromMap(Map<String, dynamic> map) {
    return EventTemplate(
      id: map['id'],
      name: map['name'],
      title: map['title'],
      description: map['description'],
      duration: Duration(minutes: map['durationMinutes']),
      color: Color(map['color']),
      category: map['category'] != null ? EventCategory.values[map['category']] : null,
      reminders: (map['reminders'] as List?)
              ?.map((r) => EventReminder.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      location: map['location'],
    );
  }
}
