import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import '../models/event_model.dart';

/// Servicio para gestionar recordatorios de eventos
class ReminderService {
  static final ReminderService instance = ReminderService._internal();

  factory ReminderService() => instance;

  ReminderService._internal();

  static const String _remindersKey = 'event_reminders';
  List<EventReminder> _reminders = [];
  Timer? _checkTimer;
  final List<Function(EventReminder)> _reminderCallbacks = [];

  /// Inicializar servicio
  Future<void> initialize() async {
    await _loadReminders();
    _startChecking();
  }

  /// Cargar recordatorios desde almacenamiento
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList(_remindersKey) ?? [];
    _reminders = remindersJson
        .map((json) => EventReminder.fromJson(json))
        .where((r) => !r.isSent && r.isEnabled)
        .toList();
  }

  /// Guardar recordatorios
  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders.map((r) => r.toJson()).toList();
    await prefs.setStringList(_remindersKey, remindersJson);
  }

  /// Iniciar verificación periódica
  void _startChecking() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkReminders();
    });
  }

  /// Verificar recordatorios pendientes
  void _checkReminders() {
    final now = DateTime.now();
    final dueReminders = _reminders.where((r) {
      return !r.isSent &&
             r.isEnabled &&
             r.reminderTime.isBefore(now);
    }).toList();

    for (final reminder in dueReminders) {
      _triggerReminder(reminder);
    }
  }

  /// Disparar recordatorio
  void _triggerReminder(EventReminder reminder) {
    // Marcar como enviado
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder.copyWith(isSent: true);
      _saveReminders();
    }

    // Notificar a callbacks
    for (final callback in _reminderCallbacks) {
      callback(reminder);
    }
  }

  /// Registrar callback para recordatorios
  void registerCallback(Function(EventReminder) callback) {
    _reminderCallbacks.add(callback);
  }

  /// Desregistrar callback
  void unregisterCallback(Function(EventReminder) callback) {
    _reminderCallbacks.remove(callback);
  }

  /// Crear recordatorios para un evento
  Future<List<EventReminder>> createRemindersForEvent(
    CalendarEvent event,
    List<int> minutesBefore,
  ) async {
    final reminders = <EventReminder>[];

    for (final minutes in minutesBefore) {
      final reminderTime = event.startTime.subtract(Duration(minutes: minutes));

      // No crear recordatorios en el pasado
      if (reminderTime.isAfter(DateTime.now())) {
        final reminder = EventReminder(
          id: '${event.id}_$minutes',
          eventId: event.id,
          reminderTime: reminderTime,
          type: ReminderType.notification,
        );
        reminders.add(reminder);
        _reminders.add(reminder);
      }
    }

    await _saveReminders();
    return reminders;
  }

  /// Actualizar recordatorios de un evento
  Future<void> updateRemindersForEvent(
    CalendarEvent event,
    List<int> minutesBefore,
  ) async {
    // Eliminar recordatorios antiguos
    await deleteRemindersForEvent(event.id);

    // Crear nuevos recordatorios
    await createRemindersForEvent(event, minutesBefore);
  }

  /// Eliminar recordatorios de un evento
  Future<void> deleteRemindersForEvent(String eventId) async {
    _reminders.removeWhere((r) => r.eventId == eventId);
    await _saveReminders();
  }

  /// Obtener recordatorios de un evento
  List<EventReminder> getRemindersForEvent(String eventId) {
    return _reminders.where((r) => r.eventId == eventId).toList();
  }

  /// Obtener todos los recordatorios pendientes
  List<EventReminder> getPendingReminders() {
    return _reminders.where((r) => !r.isSent && r.isEnabled).toList();
  }

  /// Marcar recordatorio como leído
  Future<void> markAsRead(String reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(isSent: true);
      await _saveReminders();
    }
  }

  /// Habilitar/deshabilitar recordatorio
  Future<void> toggleReminder(String reminderId, bool enabled) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(isEnabled: enabled);
      await _saveReminders();
    }
  }

  /// Posponer recordatorio
  Future<void> snoozeReminder(String reminderId, int minutes) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      final newTime = DateTime.now().add(Duration(minutes: minutes));
      _reminders[index] = _reminders[index].copyWith(
        reminderTime: newTime,
        isSent: false,
      );
      await _saveReminders();
    }
  }

  /// Limpiar recordatorios antiguos
  Future<void> cleanOldReminders() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _reminders.removeWhere((r) =>
      r.isSent && r.reminderTime.isBefore(cutoff)
    );
    await _saveReminders();
  }

  /// Obtener estadísticas de recordatorios
  Map<String, dynamic> getStatistics() {
    final total = _reminders.length;
    final pending = _reminders.where((r) => !r.isSent && r.isEnabled).length;
    final sent = _reminders.where((r) => r.isSent).length;
    final disabled = _reminders.where((r) => !r.isEnabled).length;

    return {
      'total': total,
      'pending': pending,
      'sent': sent,
      'disabled': disabled,
    };
  }

  /// Exportar recordatorios a JSON
  String exportToJson() {
    final data = _reminders.map((r) => r.toMap()).toList();
    return json.encode(data);
  }

  /// Importar recordatorios desde JSON
  Future<void> importFromJson(String jsonString) async {
    try {
      final List<dynamic> data = json.decode(jsonString);
      final imported = data.map((item) => EventReminder.fromMap(item)).toList();

      // Agregar recordatorios no duplicados
      for (final reminder in imported) {
        if (!_reminders.any((r) => r.id == reminder.id)) {
          _reminders.add(reminder);
        }
      }

      await _saveReminders();
    } catch (e) {
      throw Exception('Error al importar recordatorios: $e');
    }
  }

  /// Detener servicio
  void dispose() {
    _checkTimer?.cancel();
    _reminderCallbacks.clear();
  }
}
