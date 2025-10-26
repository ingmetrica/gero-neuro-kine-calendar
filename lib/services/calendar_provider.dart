import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'google_calendar_service.dart';
import 'package:uuid/uuid.dart';

class CalendarProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notifications = NotificationService.instance;
  GoogleCalendarService? _googleCalendar;

  List<CalendarEvent> _events = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;
  bool _isLoading = false;
  bool _isGoogleCalendarConnected = false;

  List<CalendarEvent> get events => _events;
  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;
  CalendarViewMode get viewMode => _viewMode;
  bool get isLoading => _isLoading;
  bool get isGoogleCalendarConnected => _isGoogleCalendarConnected;

  CalendarProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _notifications.initialize();
    await loadEvents();

    // Try to initialize Google Calendar (may fail on web without config)
    try {
      _googleCalendar = GoogleCalendarService.instance;
      _isGoogleCalendarConnected = _googleCalendar!.isSignedIn();
    } catch (e) {
      print('Google Calendar not available: $e');
      _googleCalendar = null;
      _isGoogleCalendarConnected = false;
    }

    notifyListeners();
  }

  // Load all events from database
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    _events = await _db.getAllEvents();

    _isLoading = false;
    notifyListeners();
  }

  // Get events for a specific day (including recurring events)
  List<CalendarEvent> getEventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

    List<CalendarEvent> dayEvents = [];

    for (var event in _events) {
      if (event.recurrenceType == RecurrenceType.none) {
        // Non-recurring event
        if ((event.startTime.isAfter(dayStart) || event.startTime.isAtSameMomentAs(dayStart)) &&
            event.startTime.isBefore(dayEnd)) {
          dayEvents.add(event);
        } else if (event.startTime.isBefore(dayStart) && event.endTime.isAfter(dayStart)) {
          // Multi-day event
          dayEvents.add(event);
        }
      } else {
        // Recurring event
        final occurrences = event.getOccurrences(dayStart, dayEnd);
        if (occurrences.isNotEmpty) {
          dayEvents.add(event);
        }
      }
    }

    dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return dayEvents;
  }

  // Get events for a week
  List<CalendarEvent> getEventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _events.where((event) {
      if (event.recurrenceType == RecurrenceType.none) {
        return event.startTime.isAfter(weekStart) && event.startTime.isBefore(weekEnd);
      } else {
        final occurrences = event.getOccurrences(weekStart, weekEnd);
        return occurrences.isNotEmpty;
      }
    }).toList();
  }

  // Get events for a month
  List<CalendarEvent> getEventsForMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _events.where((event) {
      if (event.recurrenceType == RecurrenceType.none) {
        return event.startTime.isAfter(monthStart) && event.startTime.isBefore(monthEnd);
      } else {
        final occurrences = event.getOccurrences(monthStart, monthEnd);
        return occurrences.isNotEmpty;
      }
    }).toList();
  }

  // Create new event
  Future<void> createEvent(CalendarEvent event) async {
    _isLoading = true;
    notifyListeners();

    final newEvent = event.copyWith(id: const Uuid().v4());
    await _db.createEvent(newEvent);

    // Schedule notification
    if (newEvent.hasNotification) {
      if (newEvent.recurrenceType != RecurrenceType.none) {
        final rangeEnd = newEvent.recurrenceEndDate ?? DateTime.now().add(const Duration(days: 365));
        await _notifications.scheduleRecurringNotifications(newEvent, DateTime.now(), rangeEnd);
      } else {
        await _notifications.scheduleEventNotification(newEvent);
      }
    }

    // Sync to Google Calendar
    if (_isGoogleCalendarConnected && _googleCalendar != null) {
      final googleEventId = await _googleCalendar!.createGoogleEvent(newEvent);
      if (googleEventId != null) {
        final syncedEvent = newEvent.copyWith(
          googleEventId: googleEventId,
          isSynced: true,
        );
        await _db.updateEvent(syncedEvent);
      }
    }

    await loadEvents();
  }

  // Update event
  Future<void> updateEvent(CalendarEvent event) async {
    _isLoading = true;
    notifyListeners();

    await _db.updateEvent(event);

    // Update notification
    await _notifications.cancelNotification(event.id);
    if (event.hasNotification) {
      if (event.recurrenceType != RecurrenceType.none) {
        final rangeEnd = event.recurrenceEndDate ?? DateTime.now().add(const Duration(days: 365));
        await _notifications.scheduleRecurringNotifications(event, DateTime.now(), rangeEnd);
      } else {
        await _notifications.scheduleEventNotification(event);
      }
    }

    // Update in Google Calendar
    if (_isGoogleCalendarConnected && _googleCalendar != null && event.isSynced) {
      await _googleCalendar!.updateGoogleEvent(event);
    }

    await loadEvents();
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    final event = _events.firstWhere((e) => e.id == eventId);

    await _db.deleteEvent(eventId);
    await _notifications.cancelNotification(eventId);

    // Delete from Google Calendar
    if (_isGoogleCalendarConnected && _googleCalendar != null && event.isSynced && event.googleEventId != null) {
      await _googleCalendar!.deleteGoogleEvent(event.googleEventId!);
    }

    await loadEvents();
  }

  // Search events
  Future<List<CalendarEvent>> searchEvents(String query) async {
    return await _db.searchEvents(query);
  }

  // Change selected day
  void selectDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  // Change focused day
  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  // Change view mode
  void setViewMode(CalendarViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  // Google Calendar integration
  Future<bool> connectGoogleCalendar() async {
    if (_googleCalendar == null) return false;

    final success = await _googleCalendar!.signIn();
    _isGoogleCalendarConnected = success;
    notifyListeners();
    return success;
  }

  Future<void> disconnectGoogleCalendar() async {
    if (_googleCalendar == null) return;

    await _googleCalendar!.signOut();
    _isGoogleCalendarConnected = false;
    notifyListeners();
  }

  Future<void> syncWithGoogleCalendar() async {
    if (!_isGoogleCalendarConnected || _googleCalendar == null) return;

    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month + 2, 0);

    final googleEvents = await _googleCalendar!.importGoogleEvents(start, end);

    for (var event in googleEvents) {
      // Check if event already exists
      final existing = _events.where((e) => e.googleEventId == event.googleEventId).toList();
      if (existing.isEmpty) {
        await _db.createEvent(event);
      }
    }

    await loadEvents();
  }
}

enum CalendarViewMode {
  day,
  week,
  month,
}
