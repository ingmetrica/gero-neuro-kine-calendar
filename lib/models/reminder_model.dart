import 'dart:convert';

/// Modelo para recordatorios de eventos
class EventReminder {
  final String id;
  final String eventId;
  final DateTime reminderTime;
  final ReminderType type;
  final String? customMessage;
  final bool isEnabled;
  final bool isSent;

  EventReminder({
    required this.id,
    required this.eventId,
    required this.reminderTime,
    this.type = ReminderType.notification,
    this.customMessage,
    this.isEnabled = true,
    this.isSent = false,
  });

  /// Copiar con modificaciones
  EventReminder copyWith({
    String? id,
    String? eventId,
    DateTime? reminderTime,
    ReminderType? type,
    String? customMessage,
    bool? isEnabled,
    bool? isSent,
  }) {
    return EventReminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      reminderTime: reminderTime ?? this.reminderTime,
      type: type ?? this.type,
      customMessage: customMessage ?? this.customMessage,
      isEnabled: isEnabled ?? this.isEnabled,
      isSent: isSent ?? this.isSent,
    );
  }

  /// Convertir a mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'reminderTime': reminderTime.toIso8601String(),
      'type': type.toString(),
      'customMessage': customMessage,
      'isEnabled': isEnabled,
      'isSent': isSent,
    };
  }

  /// Crear desde mapa
  static EventReminder fromMap(Map<String, dynamic> map) {
    return EventReminder(
      id: map['id'],
      eventId: map['eventId'],
      reminderTime: DateTime.parse(map['reminderTime']),
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ReminderType.notification,
      ),
      customMessage: map['customMessage'],
      isEnabled: map['isEnabled'] ?? true,
      isSent: map['isSent'] ?? false,
    );
  }

  /// Convertir a JSON
  String toJson() => json.encode(toMap());

  /// Crear desde JSON
  static EventReminder fromJson(String source) => fromMap(json.decode(source));
}

/// Tipos de recordatorios
enum ReminderType {
  notification, // Notificación del sistema
  email, // Email (futuro)
  popup, // Popup en la app
}

/// Configuración de recordatorio rápido
class QuickReminder {
  final String label;
  final int minutesBefore;

  const QuickReminder(this.label, this.minutesBefore);
}

/// Recordatorios predefinidos
class DefaultReminders {
  static const List<QuickReminder> quick = [
    QuickReminder('En el momento', 0),
    QuickReminder('5 minutos antes', 5),
    QuickReminder('10 minutos antes', 10),
    QuickReminder('15 minutos antes', 15),
    QuickReminder('30 minutos antes', 30),
    QuickReminder('1 hora antes', 60),
    QuickReminder('2 horas antes', 120),
    QuickReminder('1 día antes', 1440),
    QuickReminder('2 días antes', 2880),
    QuickReminder('1 semana antes', 10080),
  ];
}
