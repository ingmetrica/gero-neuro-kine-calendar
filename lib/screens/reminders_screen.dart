import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../models/event_model.dart';
import '../services/reminder_service.dart';
import '../services/calendar_provider.dart';
import 'event_detail_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes', icon: Icon(Icons.schedule)),
            Tab(text: 'Enviados', icon: Icon(Icons.done)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Limpiar antiguos',
            onPressed: () async {
              await ReminderService.instance.cleanOldReminders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recordatorios antiguos eliminados'),
                  ),
                );
                setState(() {});
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'stats') {
                _showStatistics();
              } else if (value == 'export') {
                _exportReminders();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Estadísticas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Exportar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingReminders(),
          _buildSentReminders(),
        ],
      ),
    );
  }

  Widget _buildPendingReminders() {
    final reminders = ReminderService.instance.getPendingReminders();
    reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));

    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay recordatorios pendientes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        return _buildReminderCard(reminders[index], isPending: true);
      },
    );
  }

  Widget _buildSentReminders() {
    final allReminders = ReminderService.instance.getPendingReminders();
    final reminders = allReminders.where((r) => r.isSent).toList();
    reminders.sort((a, b) => b.reminderTime.compareTo(a.reminderTime));

    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay recordatorios enviados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        return _buildReminderCard(reminders[index], isPending: false);
      },
    );
  }

  Widget _buildReminderCard(EventReminder reminder, {required bool isPending}) {
    final provider = context.read<CalendarProvider>();
    final events = provider.events;
    final event = events.firstWhere(
      (e) => e.id == reminder.eventId,
      orElse: () => CalendarEvent(
        id: '',
        title: 'Evento eliminado',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        color: Colors.grey,
        isAllDay: false,
        recurrenceType: RecurrenceType.none,
      ),
    );

    final now = DateTime.now();
    final isPast = reminder.reminderTime.isBefore(now);
    final timeUntil = reminder.reminderTime.difference(now);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPending
                ? (isPast ? Icons.notification_important : Icons.schedule)
                : Icons.done,
            color: event.color,
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: event.id.isEmpty ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(reminder.reminderTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (isPending && !isPast) ...[
              const SizedBox(height: 4),
              Text(
                _getTimeUntilText(timeUntil),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending)
              Switch(
                value: reminder.isEnabled,
                onChanged: (value) async {
                  await ReminderService.instance.toggleReminder(
                    reminder.id,
                    value,
                  );
                  setState(() {});
                },
              ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'view' && event.id.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(event: event),
                    ),
                  );
                } else if (value == 'snooze') {
                  _showSnoozeDialog(reminder);
                } else if (value == 'delete') {
                  await ReminderService.instance.deleteRemindersForEvent(
                    reminder.eventId,
                  );
                  setState(() {});
                }
              },
              itemBuilder: (context) => [
                if (event.id.isNotEmpty)
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.open_in_new),
                      title: Text('Ver evento'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (isPending)
                  const PopupMenuItem(
                    value: 'snooze',
                    child: ListTile(
                      leading: Icon(Icons.snooze),
                      title: Text('Posponer'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: event.id.isNotEmpty
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                );
              }
            : null,
      ),
    );
  }

  String _getTimeUntilText(Duration duration) {
    if (duration.isNegative) return 'Vencido';

    if (duration.inDays > 0) {
      return 'En ${duration.inDays} día${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return 'En ${duration.inHours} hora${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return 'En ${duration.inMinutes} minuto${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora';
    }
  }

  void _showSnoozeDialog(EventReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Posponer Recordatorio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('5 minutos'),
              onTap: () {
                ReminderService.instance.snoozeReminder(reminder.id, 5);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('15 minutos'),
              onTap: () {
                ReminderService.instance.snoozeReminder(reminder.id, 15);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('30 minutos'),
              onTap: () {
                ReminderService.instance.snoozeReminder(reminder.id, 30);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              title: const Text('1 hora'),
              onTap: () {
                ReminderService.instance.snoozeReminder(reminder.id, 60);
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    final stats = ReminderService.instance.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Recordatorios'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total', stats['total']),
            _buildStatRow('Pendientes', stats['pending']),
            _buildStatRow('Enviados', stats['sent']),
            _buildStatRow('Deshabilitados', stats['disabled']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _exportReminders() {
    try {
      final json = ReminderService.instance.exportToJson();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exportar Recordatorios'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Datos exportados en formato JSON:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  json,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }
}
