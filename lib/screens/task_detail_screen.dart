import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService.instance;
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Tarea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTask(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Título y estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _task.status == TaskStatus.completed,
                onChanged: (value) => _toggleCompletion(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _task.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: _task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(_task.status),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _task.getPriorityColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _task.getPriorityText(),
                  style: TextStyle(
                    color: _task.getPriorityColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Descripción
          if (_task.description != null && _task.description!.isNotEmpty) ...[
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _task.description!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Información
          const Text(
            'Información',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (_task.dueDate != null)
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: _isOverdue() ? Colors.red : Colors.blue,
                    ),
                    title: const Text('Fecha de vencimiento'),
                    subtitle: Text(
                      _formatDate(_task.dueDate!),
                      style: TextStyle(
                        color: _isOverdue() ? Colors.red : null,
                        fontWeight: _isOverdue() ? FontWeight.bold : null,
                      ),
                    ),
                    trailing: _isOverdue()
                        ? const Chip(
                            label: Text('VENCIDA'),
                            backgroundColor: Colors.red,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.blue),
                  title: const Text('Creada'),
                  subtitle: Text(_formatDate(_task.createdAt)),
                ),
                if (_task.completedAt != null)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Completada'),
                    subtitle: Text(_formatDate(_task.completedAt!)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subtareas
          if (_task.subTasks.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtareas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_task.subTasks.where((st) => st.isCompleted).length}/${_task.subTasks.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _task.getCompletionPercentage(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_task.getPriorityColor()),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _task.subTasks.map((subTask) {
                  return CheckboxListTile(
                    title: Text(
                      subTask.title,
                      style: TextStyle(
                        decoration: subTask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    value: subTask.isCompleted,
                    onChanged: (value) => _toggleSubTask(subTask.id),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Etiquetas
          if (_task.tags.isNotEmpty) ...[
            const Text(
              'Etiquetas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _task.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  avatar: const Icon(Icons.label, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Acciones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _task.status != TaskStatus.completed
                      ? () => _markAsCompleted()
                      : () => _reopenTask(),
                  icon: Icon(_task.status != TaskStatus.completed
                      ? Icons.check_circle
                      : Icons.replay),
                  label: Text(_task.status != TaskStatus.completed
                      ? 'Marcar como completada'
                      : 'Reabrir tarea'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isOverdue() {
    return _task.dueDate != null &&
        _task.dueDate!.isBefore(DateTime.now()) &&
        _task.status != TaskStatus.completed;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  Future<void> _toggleCompletion() async {
    if (_task.status == TaskStatus.completed) {
      await _taskService.reopenTask(_task.id);
    } else {
      await _taskService.completeTask(_task.id);
    }
    final updated = await _taskService.getTask(_task.id);
    if (updated != null) {
      setState(() {
        _task = updated;
      });
    }
  }

  Future<void> _toggleSubTask(String subTaskId) async {
    await _taskService.toggleSubTask(_task.id, subTaskId);
    final updated = await _taskService.getTask(_task.id);
    if (updated != null) {
      setState(() {
        _task = updated;
      });
    }
  }

  Future<void> _markAsCompleted() async {
    await _taskService.completeTask(_task.id);
    final updated = await _taskService.getTask(_task.id);
    if (updated != null) {
      setState(() {
        _task = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea marcada como completada')),
        );
      }
    }
  }

  Future<void> _reopenTask() async {
    await _taskService.reopenTask(_task.id);
    final updated = await _taskService.getTask(_task.id);
    if (updated != null) {
      setState(() {
        _task = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea reabierta')),
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: _task),
      ),
    );

    if (result == true) {
      final updated = await _taskService.getTask(_task.id);
      if (updated != null) {
        setState(() {
          _task = updated;
        });
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: const Text('¿Estás seguro de eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _taskService.deleteTask(_task.id);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada')),
        );
      }
    }
  }
}
