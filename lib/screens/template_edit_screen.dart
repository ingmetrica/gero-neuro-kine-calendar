import 'package:flutter/material.dart';
import '../models/event_template.dart';
import '../models/event_model.dart';
import '../models/category_model.dart';
import '../services/template_service.dart';
import '../services/category_service.dart';

class TemplateEditScreen extends StatefulWidget {
  final EventTemplate? template;

  const TemplateEditScreen({Key? key, this.template}) : super(key: key);

  @override
  State<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  final TemplateService _templateService = TemplateService.instance;
  final CategoryService _categoryService = CategoryService.instance;

  Color _selectedColor = Colors.blue;
  Duration _duration = const Duration(hours: 1);
  RecurrenceType _recurrenceType = RecurrenceType.none;
  int? _recurrenceInterval;
  DateTime? _recurrenceEndDate;
  List<String> _reminderMinutes = ['15'];
  String? _selectedCategoryId;
  List<EventCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _titleController.text = widget.template!.title;
      _descriptionController.text = widget.template!.description ?? '';
      _locationController.text = widget.template!.location ?? '';
      _notesController.text = widget.template!.notes ?? '';
      _selectedColor = widget.template!.color;
      _duration = widget.template!.duration;
      _recurrenceType = widget.template!.recurrenceType;
      _recurrenceInterval = widget.template!.recurrenceInterval;
      _recurrenceEndDate = widget.template!.recurrenceEndDate;
      _reminderMinutes = List.from(widget.template!.reminderMinutes);
      _selectedCategoryId = widget.template!.categoryId;
    }
  }

  Future<void> _loadCategories() async {
    _categories = await _categoryService.getAllCategories();
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Plantilla' : 'Nueva Plantilla'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre de la plantilla
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Plantilla',
                helperText: 'Nombre identificador de la plantilla',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre para la plantilla';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Título del evento
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del Evento',
                helperText: 'Título que tendrán los eventos creados',
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

            // Descripción
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

            // Ubicación
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Duración
            ListTile(
              title: const Text('Duración'),
              subtitle: Text(_formatDuration(_duration)),
              leading: const Icon(Icons.access_time),
              trailing: const Icon(Icons.edit),
              onTap: _selectDuration,
            ),
            const Divider(),

            // Color
            ListTile(
              title: const Text('Color'),
              leading: const Icon(Icons.color_lens),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              onTap: _selectColor,
            ),
            const Divider(),

            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sin categoría'),
                ),
                ..._categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 20),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Recurrencia
            DropdownButtonFormField<RecurrenceType>(
              value: _recurrenceType,
              decoration: const InputDecoration(
                labelText: 'Recurrencia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: RecurrenceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getRecurrenceTypeText(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _recurrenceType = value!;
                  if (_recurrenceType != RecurrenceType.none) {
                    _recurrenceInterval ??= 1;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Recordatorios
            const Text(
              'Recordatorios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._reminderMinutes.map((minutes) {
                  return Chip(
                    label: Text(_formatReminderTime(minutes)),
                    onDeleted: () {
                      setState(() {
                        _reminderMinutes.remove(minutes);
                      });
                    },
                  );
                }).toList(),
                ActionChip(
                  label: const Text('+ Agregar'),
                  onPressed: _addReminder,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Vista previa
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vista Previa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleController.text.isEmpty
                                    ? 'Título del evento'
                                    : _titleController.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(_duration),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón guardar
            ElevatedButton(
              onPressed: _saveTemplate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                isEditing ? 'Guardar Cambios' : 'Crear Plantilla',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDuration() async {
    int hours = _duration.inHours;
    int minutes = _duration.inMinutes % 60;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar Duración'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('Horas'),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (hours > 0) {
                                    setDialogState(() => hours--);
                                  }
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  hours.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setDialogState(() => hours++);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Minutos'),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (minutes >= 15) {
                                    setDialogState(() => minutes -= 15);
                                  }
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  minutes.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  if (minutes < 45) {
                                    setDialogState(() => minutes += 15);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, {'hours': hours, 'minutes': minutes}),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _duration = Duration(
          hours: result['hours']!,
          minutes: result['minutes']!,
        );
      });
    }
  }

  Future<void> _selectColor() async {
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    final color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color
                        ? Colors.black
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  Future<void> _addReminder() async {
    final minutes = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Agregar Recordatorio'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '5'),
            child: const Text('5 minutos antes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '10'),
            child: const Text('10 minutos antes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '15'),
            child: const Text('15 minutos antes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '30'),
            child: const Text('30 minutos antes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '60'),
            child: const Text('1 hora antes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '120'),
            child: const Text('2 horas antes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '1440'),
            child: const Text('1 día antes'),
          ),
        ],
      ),
    );

    if (minutes != null && !_reminderMinutes.contains(minutes)) {
      setState(() {
        _reminderMinutes.add(minutes);
        _reminderMinutes.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final template = EventTemplate(
      id: widget.template?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      location: _locationController.text.isNotEmpty
          ? _locationController.text.trim()
          : null,
      duration: _duration,
      notes: _notesController.text.isNotEmpty
          ? _notesController.text.trim()
          : null,
      color: _selectedColor,
      recurrenceType: _recurrenceType,
      recurrenceInterval: _recurrenceInterval,
      recurrenceEndDate: _recurrenceEndDate,
      reminderMinutes: _reminderMinutes,
      categoryId: _selectedCategoryId,
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      usageCount: widget.template?.usageCount ?? 0,
      lastUsedAt: widget.template?.lastUsedAt,
    );

    try {
      if (widget.template != null) {
        await _templateService.updateTemplate(template);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plantilla actualizada')),
          );
        }
      } else {
        await _templateService.createTemplate(template);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plantilla creada')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatReminderTime(String minutes) {
    final mins = int.parse(minutes);
    if (mins < 60) {
      return '$mins min';
    } else if (mins < 1440) {
      return '${mins ~/ 60} h';
    } else {
      return '${mins ~/ 1440} día';
    }
  }

  String _getRecurrenceTypeText(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'No se repite';
      case RecurrenceType.daily:
        return 'Diario';
      case RecurrenceType.weekly:
        return 'Semanal';
      case RecurrenceType.monthly:
        return 'Mensual';
      case RecurrenceType.yearly:
        return 'Anual';
    }
  }
}
