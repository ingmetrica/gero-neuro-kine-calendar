import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskService {
  static final TaskService instance = TaskService._init();
  TaskService._init();

  static const String _tasksKey = 'tasks';
  SharedPreferences? _prefs;
  List<Task> _tasks = [];
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      await _loadTasks();
      _isInitialized = true;
    }
  }

  Future<void> _loadTasks() async {
    final String? tasksJson = _prefs?.getString(_tasksKey);
    if (tasksJson != null && tasksJson.isNotEmpty) {
      final List<dynamic> tasksList = json.decode(tasksJson);
      _tasks = tasksList.map((e) => Task.fromMap(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _saveTasks() async {
    final tasksList = _tasks.map((e) => e.toMap()).toList();
    await _prefs?.setString(_tasksKey, json.encode(tasksList));
  }

  Future<List<Task>> getAllTasks() async {
    await _ensureInitialized();
    return List.from(_tasks);
  }

  Future<Task?> getTask(String id) async {
    await _ensureInitialized();
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> createTask(Task task) async {
    await _ensureInitialized();
    _tasks.add(task);
    await _saveTasks();
  }

  Future<void> updateTask(Task task) async {
    await _ensureInitialized();
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String id) async {
    await _ensureInitialized();
    _tasks.removeWhere((task) => task.id == id);
    await _saveTasks();
  }

  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    await _ensureInitialized();
    return _tasks.where((task) => task.status == status).toList();
  }

  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    await _ensureInitialized();
    return _tasks.where((task) => task.priority == priority).toList();
  }

  Future<List<Task>> getTasksByCategory(String categoryId) async {
    await _ensureInitialized();
    return _tasks.where((task) => task.categoryId == categoryId).toList();
  }

  Future<List<Task>> getOverdueTasks() async {
    await _ensureInitialized();
    final now = DateTime.now();
    return _tasks.where((task) {
      return task.dueDate != null &&
          task.dueDate!.isBefore(now) &&
          task.status != TaskStatus.completed &&
          task.status != TaskStatus.cancelled;
    }).toList();
  }

  Future<List<Task>> getTodayTasks() async {
    await _ensureInitialized();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  Future<List<Task>> searchTasks(String query) async {
    await _ensureInitialized();
    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          (task.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<void> toggleSubTask(String taskId, String subTaskId) async {
    await _ensureInitialized();
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final subTaskIndex = task.subTasks.indexWhere((st) => st.id == subTaskId);
      if (subTaskIndex != -1) {
        final subTask = task.subTasks[subTaskIndex];
        final updatedSubTask = subTask.copyWith(isCompleted: !subTask.isCompleted);
        final updatedSubTasks = List<SubTask>.from(task.subTasks);
        updatedSubTasks[subTaskIndex] = updatedSubTask;
        final updatedTask = task.copyWith(subTasks: updatedSubTasks);
        _tasks[taskIndex] = updatedTask;
        await _saveTasks();
      }
    }
  }

  Future<void> completeTask(String id) async {
    await _ensureInitialized();
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      await _saveTasks();
    }
  }

  Future<void> reopenTask(String id) async {
    await _ensureInitialized();
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.todo,
        completedAt: null,
      );
      await _saveTasks();
    }
  }

  // Estadísticas
  Future<Map<String, dynamic>> getStatistics() async {
    await _ensureInitialized();
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.status == TaskStatus.completed).length;
    final inProgress = _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final todo = _tasks.where((t) => t.status == TaskStatus.todo).length;
    final overdue = await getOverdueTasks();

    return {
      'total': total,
      'completed': completed,
      'inProgress': inProgress,
      'todo': todo,
      'overdue': overdue.length,
      'completionRate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
    };
  }
}
