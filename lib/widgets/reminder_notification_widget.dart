import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../models/event_model.dart';
import '../services/reminder_service.dart';
import '../services/calendar_provider.dart';
import '../screens/event_detail_screen.dart';

/// Widget para mostrar notificaciones de recordatorios
class ReminderNotificationWidget extends StatefulWidget {
  const ReminderNotificationWidget({Key? key}) : super(key: key);

  @override
  State<ReminderNotificationWidget> createState() =>
      _ReminderNotificationWidgetState();
}

class _ReminderNotificationWidgetState
    extends State<ReminderNotificationWidget> {
  EventReminder? _currentReminder;
  CalendarEvent? _currentEvent;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _setupReminderListener();
  }

  void _setupReminderListener() {
    ReminderService.instance.registerCallback(_onReminderTriggered);
  }

  @override
  void dispose() {
    ReminderService.instance.unregisterCallback(_onReminderTriggered);
    super.dispose();
  }

  void _onReminderTriggered(EventReminder reminder) {
    // Buscar el evento asociado
    final provider = context.read<CalendarProvider>();
    final events = provider.events;
    final event = events.firstWhere(
      (e) => e.id == reminder.eventId,
      orElse: () => CalendarEvent(
        id: '',
        title: 'Evento no encontrado',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        color: Colors.grey,
        isAllDay: false,
        recurrenceType: RecurrenceType.none,
      ),
    );

    setState(() {
      _currentReminder = reminder;
      _currentEvent = event;
      _isVisible = true;
    });

    // Auto-ocultar después de 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isVisible) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _dismiss() {
    if (_currentReminder != null) {
      ReminderService.instance.markAsRead(_currentReminder!.id);
    }
    setState(() {
      _isVisible = false;
    });
  }

  void _snooze(int minutes) {
    if (_currentReminder != null) {
      ReminderService.instance.snoozeReminder(_currentReminder!.id, minutes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recordatorio pospuesto $minutes minutos'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    setState(() {
      _isVisible = false;
    });
  }

  void _viewEvent() {
    if (_currentEvent != null && _currentEvent!.id.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailScreen(event: _currentEvent!),
        ),
      );
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentEvent == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 350,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _currentEvent!.color,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentEvent!.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(9),
                    topRight: Radius.circular(9),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Recordatorio de Evento',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _dismiss,
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentEvent!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentEvent!.description != null &&
                        _currentEvent!.description!.isNotEmpty) ...[
                      Text(
                        _currentEvent!.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentEvent!.startTime.hour.toString().padLeft(2, '0')}:${_currentEvent!.startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    if (_currentEvent!.location != null &&
                        _currentEvent!.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _currentEvent!.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<int>(
                      child: TextButton.icon(
                        icon: const Icon(Icons.snooze, size: 16),
                        label: const Text('Posponer'),
                        onPressed: null,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 5, child: Text('5 minutos')),
                        const PopupMenuItem(value: 10, child: Text('10 minutos')),
                        const PopupMenuItem(value: 15, child: Text('15 minutos')),
                        const PopupMenuItem(value: 30, child: Text('30 minutos')),
                        const PopupMenuItem(value: 60, child: Text('1 hora')),
                      ],
                      onSelected: _snooze,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Ver'),
                      onPressed: _viewEvent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
