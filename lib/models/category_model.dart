import 'package:flutter/material.dart';

class EventCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;

  EventCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'isCustom': isCustom,
    };
  }

  factory EventCategory.fromMap(Map<String, dynamic> map) {
    return EventCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(
        map['iconCodePoint'] as int,
        fontFamily: map['iconFontFamily'] as String?,
      ),
      color: Color(map['colorValue'] as int),
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  EventCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isCustom,
  }) {
    return EventCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

// Categorías predefinidas
class DefaultCategories {
  static final List<EventCategory> categories = [
    EventCategory(
      id: 'work',
      name: 'Trabajo',
      icon: Icons.work,
      color: Colors.blue,
    ),
    EventCategory(
      id: 'personal',
      name: 'Personal',
      icon: Icons.person,
      color: Colors.green,
    ),
    EventCategory(
      id: 'family',
      name: 'Familia',
      icon: Icons.family_restroom,
      color: Colors.pink,
    ),
    EventCategory(
      id: 'health',
      name: 'Salud',
      icon: Icons.favorite,
      color: Colors.red,
    ),
    EventCategory(
      id: 'study',
      name: 'Estudio',
      icon: Icons.school,
      color: Colors.purple,
    ),
    EventCategory(
      id: 'sport',
      name: 'Deporte',
      icon: Icons.sports_soccer,
      color: Colors.orange,
    ),
    EventCategory(
      id: 'travel',
      name: 'Viaje',
      icon: Icons.flight,
      color: Colors.teal,
    ),
    EventCategory(
      id: 'meeting',
      name: 'Reunión',
      icon: Icons.meeting_room,
      color: Colors.indigo,
    ),
    EventCategory(
      id: 'birthday',
      name: 'Cumpleaños',
      icon: Icons.cake,
      color: Colors.amber,
    ),
    EventCategory(
      id: 'other',
      name: 'Otro',
      icon: Icons.label,
      color: Colors.grey,
    ),
  ];

  static EventCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
