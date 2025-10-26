import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../services/task_service.dart';
import '../services/category_service.dart';

class TaskEditScreen extends StatefulWidget {
  final Task? task;

  const TaskEditScreen({Key? key, this.task}) : super(key: key);

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TaskService _taskService = TaskService.instance;
  final CategoryService _categoryService = CategoryService.instance;

  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  DateTime? _dueDate;
  String? _selectedCategoryId;
  List<String> _tags = [];
  List<SubTask> _subTasks = [];
  List<EventCategory> _categories = [];

  final _tagController = TextEditingController();
  final _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _priority = widget.task!.priority;
      _status = widget.task!.status;
      _dueDate = widget.task!.dueDate;
      _selectedCategoryId = widget.task!.categoryId;
      _tags = List.from(widget.task!.tags);
      _subTasks = List.from(widget.task!.subTasks);
    }
  }

  Future<void> _loadCategories() async {
    _categories = await _categoryService.getAllCategories();
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarea' : 'Nueva Tarea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
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

            // Prioridad
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: _getPriorityColor(priority)),
                      const SizedBox(width: 8),
                      Text(_getPriorityText(priority)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Estado
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: TaskStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusText(status)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Fecha de vencimiento
            ListTile(
              title: const Text('Fecha de vencimiento'),
              subtitle: Text(_dueDate != null
                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} ${_dueDate!.hour.toString().padLeft(2, '0')}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                  : 'No establecida'),
              leading: const Icon(Icons.calendar_today),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                    )
                  : null,
              onTap: _selectDueDate,
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

            // Tags
            const Text(
              'Etiquetas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  );
                }).toList(),
                ActionChip(
                  label: const Text('+ Agregar'),
                  onPressed: _addTag,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SubTareas
            const Text(
              'Subtareas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._subTasks.map((subTask) {
              return CheckboxListTile(
                title: Text(subTask.title),
                value: subTask.isCompleted,
                onChanged: (value) {
                  setState(() {
                    final index = _subTasks.indexOf(subTask);
                    _subTasks[index] = subTask.copyWith(isCompleted: value ?? false);
                  });
                },
                secondary: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _subTasks.remove(subTask);
                    });
                  },
                ),
              );
            }).toList(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Agregar subtarea'),
              onTap: _addSubTask,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                isEditing ? 'Guardar Cambios' : 'Crear Tarea',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _addTag() async {
    final tag = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Etiqueta'),
          content: TextField(
            controller: _tagController,
            decoration: const InputDecoration(labelText: 'Etiqueta'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _tagController.text);
                _tagController.clear();
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (tag != null && tag.isNotEmpty) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  Future<void> _addSubTask() async {
    final subTaskTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Subtarea'),
          content: TextField(
            controller: _subTaskController,
            decoration: const InputDecoration(labelText: 'Título de subtarea'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _subTaskController.text);
                _subTaskController.clear();
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (subTaskTitle != null && subTaskTitle.isNotEmpty) {
      setState(() {
        _subTasks.add(SubTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: subTaskTitle,
        ));
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      categoryId: _selectedCategoryId,
      tags: _tags,
      subTasks: _subTasks,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      completedAt: _status == TaskStatus.completed ? DateTime.now() : null,
    );

    try {
      if (widget.task != null) {
        await _taskService.updateTask(task);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea actualizada')),
          );
        }
      } else {
        await _taskService.createTask(task);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea creada')),
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

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'Por hacer';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.completed:
        return 'Completada';
      case TaskStatus.cancelled:
        return 'Cancelada';
    }
  }
}
