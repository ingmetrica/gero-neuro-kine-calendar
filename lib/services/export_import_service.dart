import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class ExportImportService {
  static final ExportImportService instance = ExportImportService._init();

  ExportImportService._init();

  // Exportar a formato ICS (iCalendar)
  String exportToICS(List<CalendarEvent> events) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Calendar App//ES');
    buffer.writeln('CALSCALE:GREGORIAN');

    for (var event in events) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${event.id}@calendar-app.com');
      buffer.writeln('DTSTAMP:${_formatDateTimeICS(DateTime.now())}');
      buffer.writeln('DTSTART:${_formatDateTimeICS(event.startTime)}');
      buffer.writeln('DTEND:${_formatDateTimeICS(event.endTime)}');
      buffer.writeln('SUMMARY:${_escapeICS(event.title)}');

      if (event.description != null && event.description!.isNotEmpty) {
        buffer.writeln('DESCRIPTION:${_escapeICS(event.description!)}');
      }

      if (event.location != null && event.location!.isNotEmpty) {
        buffer.writeln('LOCATION:${_escapeICS(event.location!)}');
      }

      // Recurrencia
      if (event.recurrenceType != RecurrenceType.none) {
        buffer.writeln('RRULE:${_formatRecurrenceRule(event)}');
      }

      // Alarma
      if (event.hasNotification && event.notificationMinutesBefore != null) {
        buffer.writeln('BEGIN:VALARM');
        buffer.writeln('TRIGGER:-PT${event.notificationMinutesBefore}M');
        buffer.writeln('ACTION:DISPLAY');
        buffer.writeln('DESCRIPTION:Recordatorio');
        buffer.writeln('END:VALARM');
      }

      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  // Exportar a CSV
  String exportToCSV(List<CalendarEvent> events) {
    final buffer = StringBuffer();

    // Encabezados
    buffer.writeln('Título,Descripción,Fecha Inicio,Hora Inicio,Fecha Fin,Hora Fin,Ubicación,Todo el Día,Color,Recurrente');

    for (var event in events) {
      final row = [
        _escapeCSV(event.title),
        _escapeCSV(event.description ?? ''),
        DateFormat('dd/MM/yyyy').format(event.startTime),
        DateFormat('HH:mm').format(event.startTime),
        DateFormat('dd/MM/yyyy').format(event.endTime),
        DateFormat('HH:mm').format(event.endTime),
        _escapeCSV(event.location ?? ''),
        event.isAllDay ? 'Sí' : 'No',
        event.color.value.toRadixString(16),
        event.recurrenceType != RecurrenceType.none ? 'Sí' : 'No',
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  // Exportar a JSON
  String exportToJSON(List<CalendarEvent> events) {
    final eventsList = events.map((e) => e.toMap()).toList();
    return json.encode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'events': eventsList,
    });
  }

  // Importar desde JSON
  List<CalendarEvent> importFromJSON(String jsonString) {
    try {
      final data = json.decode(jsonString);
      final eventsList = data['events'] as List;
      return eventsList.map((e) => CalendarEvent.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Error al importar JSON: $e');
    }
  }

  // Importar desde CSV
  List<CalendarEvent> importFromCSV(String csvString) {
    try {
      final lines = csvString.split('\n');
      final events = <CalendarEvent>[];

      // Saltar encabezado
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final fields = _parseCSVLine(line);
        if (fields.length < 10) continue;

        final startDate = DateFormat('dd/MM/yyyy').parse(fields[2]);
        final startTime = DateFormat('HH:mm').parse(fields[3]);
        final endDate = DateFormat('dd/MM/yyyy').parse(fields[4]);
        final endTime = DateFormat('HH:mm').parse(fields[5]);

        final event = CalendarEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          title: fields[0],
          description: fields[1].isEmpty ? null : fields[1],
          startTime: DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute),
          endTime: DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute),
          location: fields[6].isEmpty ? null : fields[6],
          isAllDay: fields[7] == 'Sí',
        );

        events.add(event);
      }

      return events;
    } catch (e) {
      throw Exception('Error al importar CSV: $e');
    }
  }

  String _formatDateTimeICS(DateTime dateTime) {
    return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dateTime.toUtc());
  }

  String _escapeICS(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
  }

  String _escapeCSV(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    var inQuotes = false;
    var field = StringBuffer();

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(field.toString());
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    fields.add(field.toString());

    return fields;
  }

  String _formatRecurrenceRule(CalendarEvent event) {
    String freq;
    switch (event.recurrenceType) {
      case RecurrenceType.daily:
        freq = 'DAILY';
        break;
      case RecurrenceType.weekly:
        freq = 'WEEKLY';
        break;
      case RecurrenceType.monthly:
        freq = 'MONTHLY';
        break;
      case RecurrenceType.yearly:
        freq = 'YEARLY';
        break;
      default:
        freq = 'DAILY';
    }

    String rrule = 'FREQ=$freq';

    if (event.recurrenceInterval != null && event.recurrenceInterval! > 1) {
      rrule += ';INTERVAL=${event.recurrenceInterval}';
    }

    if (event.recurrenceEndDate != null) {
      rrule += ';UNTIL=${_formatDateTimeICS(event.recurrenceEndDate!)}';
    }

    return rrule;
  }
}
