import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleCalendarService {
  static final GoogleCalendarService instance = GoogleCalendarService._init();

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  gcal.CalendarApi? _calendarApi;

  GoogleCalendarService._init() {
    // Google Sign-In no funciona en web sin configuración adicional
    if (!kIsWeb) {
      try {
        _googleSignIn = GoogleSignIn(
          scopes: [
            gcal.CalendarApi.calendarScope,
          ],
        );
      } catch (e) {
        print('Google Sign-In not available: $e');
        _googleSignIn = null;
      }
    }
  }

  Future<bool> signIn() async {
    if (_googleSignIn == null) return false;

    try {
      final account = await _googleSignIn!.signIn();
      if (account == null) return false;

      _currentUser = account;
      final auth.AuthClient? httpClient = await _getAuthClient();
      if (httpClient == null) return false;

      _calendarApi = gcal.CalendarApi(httpClient);
      return true;
    } catch (error) {
      print('Error signing in: $error');
      return false;
    }
  }

  Future<void> signOut() async {
    if (_googleSignIn == null) return;
    await _googleSignIn!.signOut();
    _currentUser = null;
    _calendarApi = null;
  }

  bool isSignedIn() {
    return _currentUser != null && _calendarApi != null;
  }

  Future<auth.AuthClient?> _getAuthClient() async {
    if (_currentUser == null) return null;

    final googleAuth = await _currentUser!.authentication;

    if (googleAuth.accessToken == null) return null;

    final credentials = auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        googleAuth.accessToken!,
        DateTime.now().add(const Duration(hours: 1)).toUtc(),
      ),
      null,
      [gcal.CalendarApi.calendarScope],
    );

    return auth.authenticatedClient(http.Client(), credentials);
  }

  // Sync local event to Google Calendar
  Future<String?> createGoogleEvent(CalendarEvent event) async {
    if (_calendarApi == null) return null;

    try {
      final gcalEvent = _convertToGoogleEvent(event);
      final created = await _calendarApi!.events.insert(gcalEvent, 'primary');
      return created.id;
    } catch (error) {
      print('Error creating Google event: $error');
      return null;
    }
  }

  // Update event in Google Calendar
  Future<bool> updateGoogleEvent(CalendarEvent event) async {
    if (_calendarApi == null || event.googleEventId == null) return false;

    try {
      final gcalEvent = _convertToGoogleEvent(event);
      await _calendarApi!.events.update(gcalEvent, 'primary', event.googleEventId!);
      return true;
    } catch (error) {
      print('Error updating Google event: $error');
      return false;
    }
  }

  // Delete event from Google Calendar
  Future<bool> deleteGoogleEvent(String googleEventId) async {
    if (_calendarApi == null) return false;

    try {
      await _calendarApi!.events.delete('primary', googleEventId);
      return true;
    } catch (error) {
      print('Error deleting Google event: $error');
      return false;
    }
  }

  // Import events from Google Calendar
  Future<List<CalendarEvent>> importGoogleEvents(DateTime start, DateTime end) async {
    if (_calendarApi == null) return [];

    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items?.map((e) => _convertFromGoogleEvent(e)).whereType<CalendarEvent>().toList() ?? [];
    } catch (error) {
      print('Error importing Google events: $error');
      return [];
    }
  }

  // Convert local event to Google Calendar event
  gcal.Event _convertToGoogleEvent(CalendarEvent event) {
    final gcalEvent = gcal.Event();
    gcalEvent.summary = event.title;
    gcalEvent.description = event.description;
    gcalEvent.location = event.location;

    if (event.isAllDay) {
      gcalEvent.start = gcal.EventDateTime(
        date: DateTime(event.startTime.year, event.startTime.month, event.startTime.day),
      );
      gcalEvent.end = gcal.EventDateTime(
        date: DateTime(event.endTime.year, event.endTime.month, event.endTime.day),
      );
    } else {
      gcalEvent.start = gcal.EventDateTime(dateTime: event.startTime.toUtc());
      gcalEvent.end = gcal.EventDateTime(dateTime: event.endTime.toUtc());
    }

    // Handle recurrence
    if (event.recurrenceType != RecurrenceType.none) {
      gcalEvent.recurrence = [_convertRecurrenceRule(event)];
    }

    // Handle reminders
    if (event.hasNotification && event.notificationMinutesBefore != null) {
      gcalEvent.reminders = gcal.EventReminders(
        useDefault: false,
        overrides: [
          gcal.EventReminder(
            method: 'popup',
            minutes: event.notificationMinutesBefore,
          ),
        ],
      );
    }

    return gcalEvent;
  }

  // Convert Google Calendar event to local event
  CalendarEvent? _convertFromGoogleEvent(gcal.Event gcalEvent) {
    if (gcalEvent.start == null || gcalEvent.end == null) return null;

    final startTime = gcalEvent.start!.dateTime ?? gcalEvent.start!.date!;
    final endTime = gcalEvent.end!.dateTime ?? gcalEvent.end!.date!;

    return CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: gcalEvent.summary ?? 'Untitled',
      description: gcalEvent.description,
      startTime: startTime,
      endTime: endTime,
      color: Colors.blue,
      isAllDay: gcalEvent.start!.dateTime == null,
      location: gcalEvent.location,
      googleEventId: gcalEvent.id,
      isSynced: true,
      hasNotification: gcalEvent.reminders?.overrides?.isNotEmpty ?? false,
      notificationMinutesBefore: gcalEvent.reminders?.overrides?.first.minutes,
    );
  }

  // Convert recurrence rule
  String _convertRecurrenceRule(CalendarEvent event) {
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

    String rrule = 'RRULE:FREQ=$freq';

    if (event.recurrenceInterval != null && event.recurrenceInterval! > 1) {
      rrule += ';INTERVAL=${event.recurrenceInterval}';
    }

    if (event.recurrenceEndDate != null) {
      final endDate = event.recurrenceEndDate!.toUtc();
      final formatted = '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}T${endDate.hour.toString().padLeft(2, '0')}${endDate.minute.toString().padLeft(2, '0')}${endDate.second.toString().padLeft(2, '0')}Z';
      rrule += ';UNTIL=$formatted';
    }

    if (event.recurrenceType == RecurrenceType.weekly && event.recurrenceDaysOfWeek != null) {
      final days = event.recurrenceDaysOfWeek!.map((d) {
        switch (d) {
          case 1: return 'MO';
          case 2: return 'TU';
          case 3: return 'WE';
          case 4: return 'TH';
          case 5: return 'FR';
          case 6: return 'SA';
          case 7: return 'SU';
          default: return 'MO';
        }
      }).join(',');
      rrule += ';BYDAY=$days';
    }

    return rrule;
  }
}
