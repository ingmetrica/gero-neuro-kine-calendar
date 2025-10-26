import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/event_template.dart';
import '../services/calendar_provider.dart';
import '../services/template_service.dart';
import 'add_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final CalendarEvent event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventScreen(event: event),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context);
              } else if (value == 'template') {
                _createTemplateFromEvent(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'template',
                child: ListTile(
                  leading: Icon(Icons.layers),
                  title: Text('Guardar como plantilla'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: event.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              Icons.access_time,
              'Fecha y hora',
              _getDateTimeText(),
            ),
            if (event.location != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on,
                'Ubicación',
                event.location!,
              ),
            ],
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.description,
                'Descripción',
                event.description!,
              ),
            ],
            if (event.recurrenceType != RecurrenceType.none) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.repeat,
                'Repetición',
                _getRecurrenceText(),
              ),
            ],
            if (event.hasNotification) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.notifications_active,
                'Notificación',
                _getNotificationText(),
              ),
            ],
            if (event.isSynced) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.cloud_done,
                'Sincronización',
                'Sincronizado con Google Calendar',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDateTimeText() {
    if (event.isAllDay) {
      if (event.startTime.day == event.endTime.day &&
          event.startTime.month == event.endTime.month &&
          event.startTime.year == event.endTime.year) {
        return '${DateFormat.yMMMd().format(event.startTime)} - Todo el día';
      }
      return '${DateFormat.yMMMd().format(event.startTime)} - ${DateFormat.yMMMd().format(event.endTime)} (Todo el día)';
    }

    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();

    if (event.startTime.day == event.endTime.day &&
        event.startTime.month == event.endTime.month &&
        event.startTime.year == event.endTime.year) {
      return '${dateFormat.format(event.startTime)}\n${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}';
    }

    return '${dateFormat.format(event.startTime)} ${timeFormat.format(event.startTime)}\n${dateFormat.format(event.endTime)} ${timeFormat.format(event.endTime)}';
  }

  String _getRecurrenceText() {
    String text = '';
    switch (event.recurrenceType) {
      case RecurrenceType.daily:
        text = 'Diariamente';
        break;
      case RecurrenceType.weekly:
        text = 'Semanalmente';
        break;
      case RecurrenceType.monthly:
        text = 'Mensualmente';
        break;
      case RecurrenceType.yearly:
        text = 'Anualmente';
        break;
      default:
        return 'No se repite';
    }

    if (event.recurrenceInterval != null && event.recurrenceInterval! > 1) {
      text += ' (cada ${event.recurrenceInterval})';
    }

    if (event.recurrenceEndDate != null) {
      text += '\nHasta ${DateFormat.yMMMd().format(event.recurrenceEndDate!)}';
    }

    if (event.recurrenceType == RecurrenceType.weekly &&
        event.recurrenceDaysOfWeek != null &&
        event.recurrenceDaysOfWeek!.isNotEmpty) {
      final days = event.recurrenceDaysOfWeek!.map((d) {
        switch (d) {
          case 1:
            return 'Lun';
          case 2:
            return 'Mar';
          case 3:
            return 'Mié';
          case 4:
            return 'Jue';
          case 5:
            return 'Vie';
          case 6:
            return 'Sáb';
          case 7:
            return 'Dom';
          default:
            return '';
        }
      }).join(', ');
      text += '\nDías: $days';
    }

    return text;
  }

  String _getNotificationText() {
    if (event.notificationMinutesBefore == null) {
      return 'Activada';
    }

    final minutes = event.notificationMinutesBefore!;
    if (minutes < 60) {
      return '$minutes minutos antes';
    } else if (minutes < 1440) {
      return '${minutes ~/ 60} horas antes';
    } else {
      return '${minutes ~/ 1440} días antes';
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('¿Estás seguro de que deseas eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<CalendarProvider>().deleteEvent(event.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _createTemplateFromEvent(BuildContext context) async {
    final controller = TextEditingController();

    final templateName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar como Plantilla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dale un nombre a esta plantilla:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre de la plantilla',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (templateName != null && templateName.isNotEmpty) {
      try {
        final templateService = TemplateService.instance;
        await templateService.createTemplateFromEvent(event, templateName);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plantilla "$templateName" creada correctamente'),
              action: SnackBarAction(
                label: 'Ver',
                onPressed: () {
                  // Aquí podrías navegar a la pantalla de plantillas
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear plantilla: $e')),
          );
        }
      }
    }
  }
}
