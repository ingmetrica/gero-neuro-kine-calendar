import 'package:flutter/material.dart';

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final bool isAllDay;
  final String? location;
  final List<String>? participants;

  // Recurrence
  final RecurrenceType recurrenceType;
  final DateTime? recurrenceEndDate;
  final int? recurrenceInterval;
  final List<int>? recurrenceDaysOfWeek; // 1-7 for Monday-Sunday

  // Notifications
  final bool hasNotification;
  final int? notificationMinutesBefore;

  // Google Calendar
  final String? googleEventId;
  final bool isSynced;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.color = Colors.blue,
    this.isAllDay = false,
    this.location,
    this.participants,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceEndDate,
    this.recurrenceInterval,
    this.recurrenceDaysOfWeek,
    this.hasNotification = false,
    this.notificationMinutesBefore,
    this.googleEventId,
    this.isSynced = false,
  });

  // Convert to Map for Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'color': color.value,
      'isAllDay': isAllDay ? 1 : 0,
      'location': location,
      'participants': participants?.join(','),
      'recurrenceType': recurrenceType.index,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceInterval': recurrenceInterval,
      'recurrenceDaysOfWeek': recurrenceDaysOfWeek?.join(','),
      'hasNotification': hasNotification ? 1 : 0,
      'notificationMinutesBefore': notificationMinutesBefore,
      'googleEventId': googleEventId,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Create from Map (Database)
  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      color: Color(map['color']),
      isAllDay: map['isAllDay'] == 1,
      location: map['location'],
      participants: map['participants']?.split(','),
      recurrenceType: RecurrenceType.values[map['recurrenceType']],
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.parse(map['recurrenceEndDate'])
          : null,
      recurrenceInterval: map['recurrenceInterval'],
      recurrenceDaysOfWeek: map['recurrenceDaysOfWeek']?.split(',').map<int>((e) => int.parse(e)).toList(),
      hasNotification: map['hasNotification'] == 1,
      notificationMinutesBefore: map['notificationMinutesBefore'],
      googleEventId: map['googleEventId'],
      isSynced: map['isSynced'] == 1,
    );
  }

  // Copy with method for updates
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    bool? isAllDay,
    String? location,
    List<String>? participants,
    RecurrenceType? recurrenceType,
    DateTime? recurrenceEndDate,
    int? recurrenceInterval,
    List<int>? recurrenceDaysOfWeek,
    bool? hasNotification,
    int? notificationMinutesBefore,
    String? googleEventId,
    bool? isSynced,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      participants: participants ?? this.participants,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek ?? this.recurrenceDaysOfWeek,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationMinutesBefore: notificationMinutesBefore ?? this.notificationMinutesBefore,
      googleEventId: googleEventId ?? this.googleEventId,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Get all occurrences of a recurring event within a date range
  List<DateTime> getOccurrences(DateTime rangeStart, DateTime rangeEnd) {
    if (recurrenceType == RecurrenceType.none) {
      return [startTime];
    }

    List<DateTime> occurrences = [];
    DateTime current = startTime;
    DateTime effectiveEnd = recurrenceEndDate ?? rangeEnd;

    while (current.isBefore(effectiveEnd) && current.isBefore(rangeEnd)) {
      if (current.isAfter(rangeStart) || current.isAtSameMomentAs(rangeStart)) {
        // Check if day matches for weekly recurrence
        if (recurrenceType == RecurrenceType.weekly) {
          if (recurrenceDaysOfWeek == null ||
              recurrenceDaysOfWeek!.contains(current.weekday)) {
            occurrences.add(current);
          }
        } else {
          occurrences.add(current);
        }
      }

      // Calculate next occurrence
      switch (recurrenceType) {
        case RecurrenceType.daily:
          current = current.add(Duration(days: recurrenceInterval ?? 1));
          break;
        case RecurrenceType.weekly:
          current = current.add(Duration(days: 7 * (recurrenceInterval ?? 1)));
          break;
        case RecurrenceType.monthly:
          current = DateTime(
            current.year,
            current.month + (recurrenceInterval ?? 1),
            current.day,
            current.hour,
            current.minute,
          );
          break;
        case RecurrenceType.yearly:
          current = DateTime(
            current.year + (recurrenceInterval ?? 1),
            current.month,
            current.day,
            current.hour,
            current.minute,
          );
          break;
        case RecurrenceType.none:
          break;
      }
    }

    return occurrences;
  }
}
