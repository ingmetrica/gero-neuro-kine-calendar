import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/event_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    // Navigate to event detail screen
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleEventNotification(CalendarEvent event) async {
    if (!event.hasNotification || event.notificationMinutesBefore == null) {
      return;
    }

    final notificationTime = event.startTime.subtract(
      Duration(minutes: event.notificationMinutesBefore!),
    );

    // Don't schedule past notifications
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'calendar_events',
      'Calendar Events',
      channelDescription: 'Notifications for calendar events',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      event.id.hashCode,
      event.title,
      event.description ?? 'Event starting in ${event.notificationMinutesBefore} minutes',
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: event.id,
    );
  }

  Future<void> cancelNotification(String eventId) async {
    await _notifications.cancel(eventId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleRecurringNotifications(CalendarEvent event, DateTime rangeStart, DateTime rangeEnd) async {
    if (!event.hasNotification || event.recurrenceType == RecurrenceType.none) {
      return;
    }

    final occurrences = event.getOccurrences(rangeStart, rangeEnd);

    for (int i = 0; i < occurrences.length; i++) {
      final occurrence = occurrences[i];
      final notificationTime = occurrence.subtract(
        Duration(minutes: event.notificationMinutesBefore ?? 0),
      );

      if (notificationTime.isBefore(DateTime.now())) {
        continue;
      }

      const androidDetails = AndroidNotificationDetails(
        'calendar_events',
        'Calendar Events',
        channelDescription: 'Notifications for calendar events',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use unique ID for each occurrence
      final notificationId = '${event.id}_$i'.hashCode;

      await _notifications.zonedSchedule(
        notificationId,
        event.title,
        event.description ?? 'Event starting in ${event.notificationMinutesBefore} minutes',
        tz.TZDateTime.from(notificationTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: event.id,
      );
    }
  }
}
