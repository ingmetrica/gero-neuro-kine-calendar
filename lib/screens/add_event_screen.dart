import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/event_template.dart';
import '../services/calendar_provider.dart';
import '../services/template_service.dart';
import 'templates_screen.dart';

class AddEventScreen extends StatefulWidget {
  final CalendarEvent? event;

  const AddEventScreen({Key? key, this.event}) : super(key: key);

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  Color _selectedColor = Colors.blue;
  bool _hasNotification = false;
  int _notificationMinutes = 15;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  DateTime? _recurrenceEndDate;
  int _recurrenceInterval = 1;
  List<int> _selectedWeekDays = [];

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
  ];

  final List<int> _notificationOptions = [5, 10, 15, 30, 60, 120, 1440]; // minutes

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.event != null) {
      // Edit mode
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description ?? '';
      _locationController.text = widget.event!.location ?? '';
      _startDate = widget.event!.startTime;
      _startTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _endDate = widget.event!.endTime;
      _endTime = TimeOfDay.fromDateTime(widget.event!.endTime);
      _isAllDay = widget.event!.isAllDay;
      _selectedColor = widget.event!.color;
      _hasNotification = widget.event!.hasNotification;
      _notificationMinutes = widget.event!.notificationMinutesBefore ?? 15;
      _recurrenceType = widget.event!.recurrenceType;
      _recurrenceEndDate = widget.event!.recurrenceEndDate;
      _recurrenceInterval = widget.event!.recurrenceInterval ?? 1;
      _selectedWeekDays = widget.event!.recurrenceDaysOfWeek ?? [];
    } else {
      // Add mode
      final now = DateTime.now();
      final provider = context.read<CalendarProvider>();
      _startDate = provider.selectedDay;
      _startTime = TimeOfDay(hour: now.hour + 1, minute: 0);
      _endDate = provider.selectedDay;
      _endTime = TimeOfDay(hour: now.hour + 2, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Nuevo Evento' : 'Editar Evento'),
        actions: [
          if (widget.event == null)
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: _loadFromTemplate,
              tooltip: 'Cargar desde plantilla',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Todo el día'),
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDateTimePicker(
              'Fecha de inicio',
              _startDate,
              _startTime,
              (date) => setState(() => _startDate = date),
              (time) => setState(() => _startTime = time),
            ),
            const SizedBox(height: 16),
            _buildDateTimePicker(
              'Fecha de fin',
              _endDate,
              _endTime,
              (date) => setState(() => _endDate = date),
              (time) => setState(() => _endTime = time),
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notificación'),
              value: _hasNotification,
              onChanged: (value) {
                setState(() {
                  _hasNotification = value;
                });
              },
            ),
            if (_hasNotification) ...[
              DropdownButtonFormField<int>(
                value: _notificationMinutes,
                decoration: const InputDecoration(
                  labelText: 'Notificar con anticipación',
                  border: OutlineInputBorder(),
                ),
                items: _notificationOptions.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text(_getNotificationLabel(minutes)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _notificationMinutes = value!;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceType>(
              value: _recurrenceType,
              decoration: const InputDecoration(
                labelText: 'Repetir',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getRecurrenceLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _recurrenceType = value!;
                });
              },
            ),
            if (_recurrenceType != RecurrenceType.none) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _recurrenceInterval.toString(),
                decoration: InputDecoration(
                  labelText: 'Repetir cada',
                  border: const OutlineInputBorder(),
                  suffixText: _getIntervalSuffix(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _recurrenceInterval = int.tryParse(value) ?? 1;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Termina'),
                subtitle: Text(
                  _recurrenceEndDate == null
                      ? 'Nunca'
                      : DateFormat.yMMMd().format(_recurrenceEndDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectRecurrenceEndDate(context),
              ),
              if (_recurrenceType == RecurrenceType.weekly) ...[
                const SizedBox(height: 16),
                const Text('Repetir los días:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final day = index + 1; // 1-7 for Monday-Sunday
                    final dayName = ['L', 'M', 'X', 'J', 'V', 'S', 'D'][index];
                    final isSelected = _selectedWeekDays.contains(day);
                    return ChoiceChip(
                      label: Text(dayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeekDays.add(day);
                          } else {
                            _selectedWeekDays.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(
    String label,
    DateTime date,
    TimeOfDay time,
    Function(DateTime) onDateChanged,
    Function(TimeOfDay) onTimeChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            title: Text(label),
            subtitle: Text(DateFormat.yMMMd().format(date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                onDateChanged(picked);
              }
            },
          ),
        ),
        if (!_isAllDay)
          Expanded(
            child: ListTile(
              title: const Text('Hora'),
              subtitle: Text(time.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) {
                  onTimeChanged(picked);
                }
              },
            ),
          ),
      ],
    );
  }

  Future<void> _selectRecurrenceEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  String _getNotificationLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes minutos antes';
    } else if (minutes < 1440) {
      return '${minutes ~/ 60} horas antes';
    } else {
      return '${minutes ~/ 1440} días antes';
    }
  }

  String _getRecurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'No repetir';
      case RecurrenceType.daily:
        return 'Diariamente';
      case RecurrenceType.weekly:
        return 'Semanalmente';
      case RecurrenceType.monthly:
        return 'Mensualmente';
      case RecurrenceType.yearly:
        return 'Anualmente';
    }
  }

  String _getIntervalSuffix() {
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        return 'días';
      case RecurrenceType.weekly:
        return 'semanas';
      case RecurrenceType.monthly:
        return 'meses';
      case RecurrenceType.yearly:
        return 'años';
      default:
        return '';
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _isAllDay ? 0 : _startTime.hour,
      _isAllDay ? 0 : _startTime.minute,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _isAllDay ? 23 : _endTime.hour,
      _isAllDay ? 59 : _endTime.minute,
    );

    final event = CalendarEvent(
      id: widget.event?.id ?? '',
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      color: _selectedColor,
      isAllDay: _isAllDay,
      location: _locationController.text.isEmpty ? null : _locationController.text,
      recurrenceType: _recurrenceType,
      recurrenceEndDate: _recurrenceEndDate,
      recurrenceInterval: _recurrenceType != RecurrenceType.none ? _recurrenceInterval : null,
      recurrenceDaysOfWeek: _recurrenceType == RecurrenceType.weekly ? _selectedWeekDays : null,
      hasNotification: _hasNotification,
      notificationMinutesBefore: _hasNotification ? _notificationMinutes : null,
      googleEventId: widget.event?.googleEventId,
      isSynced: widget.event?.isSynced ?? false,
    );

    final provider = context.read<CalendarProvider>();

    if (widget.event == null) {
      await provider.createEvent(event);
    } else {
      await provider.updateEvent(event);
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _loadFromTemplate() async {
    final templateService = TemplateService.instance;
    final templates = await templateService.getAllTemplates();

    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay plantillas disponibles'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final template = await showDialog<EventTemplate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Plantilla'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(t.name),
                subtitle: Text(t.title),
                onTap: () => Navigator.pop(context, t),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemplatesScreen(),
                ),
              );
            },
            child: const Text('Administrar'),
          ),
        ],
      ),
    );

    if (template != null && mounted) {
      // Cargar datos de la plantilla en el formulario
      setState(() {
        _titleController.text = template.title;
        _descriptionController.text = template.description ?? '';
        _locationController.text = template.location ?? '';
        _selectedColor = template.color;
        _recurrenceType = template.recurrenceType;
        _recurrenceInterval = template.recurrenceInterval ?? 1;
        _recurrenceEndDate = template.recurrenceEndDate;

        // Calcular tiempos basados en la duración de la plantilla
        final now = DateTime.now();
        _startTime = TimeOfDay.fromDateTime(now);
        _endTime = TimeOfDay.fromDateTime(now.add(template.duration));

        // Si la duración es mayor a un día, ajustar fechas
        if (template.duration.inDays > 0) {
          _endDate = _startDate.add(Duration(days: template.duration.inDays));
        }
      });

      // Registrar uso de la plantilla
      await templateService.useTemplate(template.id, DateTime.now());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plantilla "${template.name}" cargada'),
          ),
        );
      }
    }
  }
}
