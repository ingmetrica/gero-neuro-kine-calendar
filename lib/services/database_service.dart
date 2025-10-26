import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

// Servicio de base de datos que funciona tanto en web como en m\u00f3vil
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static SharedPreferences? _prefs;
  static List<CalendarEvent> _events = [];
  static bool _initialized = false;

  DatabaseService._init();

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      await _loadEvents();
      _initialized = true;
    }
  }

  Future<void> _loadEvents() async {
    final eventsJson = _prefs!.getString('events');
    if (eventsJson != null && eventsJson.isNotEmpty) {
      try {
        final List<dynamic> eventsList = json.decode(eventsJson);
        _events = eventsList.map((e) => CalendarEvent.fromMap(e as Map<String, dynamic>)).toList();
      } catch (e) {
        print('Error loading events: $e');
        _events = [];
      }
    }
  }

  Future<void> _saveEvents() async {
    final eventsList = _events.map((e) => e.toMap()).toList();
    await _prefs!.setString('events', json.encode(eventsList));
  }

  // Create
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    await _ensureInitialized();
    _events.add(event);
    await _saveEvents();
    return event;
  }

  // Read single event
  Future<CalendarEvent?> getEvent(String id) async {
    await _ensureInitialized();
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Read all events
  Future<List<CalendarEvent>> getAllEvents() async {
    await _ensureInitialized();
    return List.from(_events);
  }

  // Read events by date range
  Future<List<CalendarEvent>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    await _ensureInitialized();
    return _events.where((event) {
      return event.startTime.isAfter(start) && event.startTime.isBefore(end);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Read events for a specific day
  Future<List<CalendarEvent>> getEventsByDay(DateTime day) async {
    await _ensureInitialized();
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

    return _events.where((event) {
      return (event.startTime.isAfter(start) || event.startTime.isAtSameMomentAs(start)) &&
          (event.startTime.isBefore(end) || event.startTime.isAtSameMomentAs(end));
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Update
  Future<int> updateEvent(CalendarEvent event) async {
    await _ensureInitialized();
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      await _saveEvents();
      return 1;
    }
    return 0;
  }

  // Delete
  Future<int> deleteEvent(String id) async {
    await _ensureInitialized();
    final initialLength = _events.length;
    _events.removeWhere((e) => e.id == id);
    if (_events.length < initialLength) {
      await _saveEvents();
      return 1;
    }
    return 0;
  }

  // Delete all events
  Future<int> deleteAllEvents() async {
    await _ensureInitialized();
    final count = _events.length;
    _events.clear();
    await _saveEvents();
    return count;
  }

  // Search events
  Future<List<CalendarEvent>> searchEvents(String query) async {
    await _ensureInitialized();
    final lowerQuery = query.toLowerCase();
    return _events.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
          (event.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (event.location?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Get upcoming events with notifications
  Future<List<CalendarEvent>> getUpcomingNotifications() async {
    await _ensureInitialized();
    final now = DateTime.now();
    return _events.where((event) {
      return event.hasNotification && event.startTime.isAfter(now);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Close database (no-op for web)
  Future<void> close() async {
    // No need to close anything
  }
}
