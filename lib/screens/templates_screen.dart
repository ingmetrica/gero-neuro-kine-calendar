import 'package:flutter/material.dart';
import '../models/event_template.dart';
import '../services/template_service.dart';
import 'template_edit_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({Key? key}) : super(key: key);

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with SingleTickerProviderStateMixin {
  final TemplateService _templateService = TemplateService.instance;
  late TabController _tabController;

  List<EventTemplate> _allTemplates = [];
  List<EventTemplate> _defaultTemplates = [];
  List<EventTemplate> _customTemplates = [];
  List<EventTemplate> _mostUsed = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    _allTemplates = await _templateService.getAllTemplates();
    _defaultTemplates = _templateService.getDefaultTemplates();
    _customTemplates = await _templateService.getCustomTemplates();
    _mostUsed = await _templateService.getMostUsedTemplates();
    _statistics = await _templateService.getStatistics();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Eventos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Todas (${_allTemplates.length})'),
            Tab(text: 'Predefinidas (${_defaultTemplates.length})'),
            Tab(text: 'Personalizadas (${_customTemplates.length})'),
            Tab(text: 'Más Usadas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateTemplate(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'stats') {
                _showStatistics();
              } else if (value == 'export') {
                _exportTemplates();
              } else if (value == 'import') {
                _importTemplates();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Estadísticas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Exportar Plantillas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Importar Plantillas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTemplateList(_allTemplates),
                _buildTemplateList(_defaultTemplates),
                _buildTemplateList(_customTemplates),
                _buildMostUsedList(_mostUsed),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTemplate(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateList(List<EventTemplate> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay plantillas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateTemplate(),
              icon: const Icon(Icons.add),
              label: const Text('Crear Plantilla'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildMostUsedList(List<EventTemplate> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay plantillas usadas aún',
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
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template, showUsage: true);
      },
    );
  }

  Widget _buildTemplateCard(EventTemplate template, {bool showUsage = false}) {
    final isCustom = !_defaultTemplates.any((t) => t.id == template.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => _useTemplate(template),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: template.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                template.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isCustom)
                              Chip(
                                label: const Text('Personalizada'),
                                backgroundColor:
                                    Colors.purple.withOpacity(0.2),
                                labelStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                ),
                                padding: const EdgeInsets.all(2),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (template.description != null &&
                            template.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            template.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isCustom)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToEditTemplate(template);
                        } else if (value == 'duplicate') {
                          _duplicateTemplate(template);
                        } else if (value == 'delete') {
                          _deleteTemplate(template);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Editar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: ListTile(
                            leading: Icon(Icons.copy),
                            title: Text('Duplicar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Eliminar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _duplicateTemplate(template),
                      tooltip: 'Duplicar plantilla',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(template.duration),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (template.location != null &&
                      template.location!.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        template.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ],
              ),
              if (showUsage && template.usageCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Usada ${template.usageCount} ${template.usageCount == 1 ? "vez" : "veces"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (template.lastUsedAt != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Última vez: ${_formatDate(template.lastUsedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _navigateToCreateTemplate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TemplateEditScreen(),
      ),
    );

    if (result == true) {
      _loadTemplates();
    }
  }

  Future<void> _navigateToEditTemplate(EventTemplate template) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditScreen(template: template),
      ),
    );

    if (result == true) {
      _loadTemplates();
    }
  }

  Future<void> _useTemplate(EventTemplate template) async {
    // Mostrar diálogo para seleccionar fecha y hora
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // Registrar uso
        await _templateService.useTemplate(template.id, DateTime.now());

        // Retornar evento creado
        if (mounted) {
          Navigator.pop(context, template.createEvent(startTime: startTime));
        }
      }
    }
  }

  Future<void> _duplicateTemplate(EventTemplate template) async {
    try {
      await _templateService.duplicateTemplate(template.id);
      _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla duplicada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(EventTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plantilla'),
        content: Text('¿Estás seguro de eliminar "${template.name}"?'),
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
      try {
        await _templateService.deleteTemplate(template.id);
        _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plantilla eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Plantillas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total de plantillas', _statistics['total'].toString()),
            _buildStatRow('Predefinidas', _statistics['default'].toString()),
            _buildStatRow('Personalizadas', _statistics['custom'].toString()),
            const Divider(),
            _buildStatRow('Usos totales', _statistics['totalUsage'].toString()),
            _buildStatRow('Promedio de usos', _statistics['averageUsage'].toString()),
            _buildStatRow('Más usada', _statistics['mostUsed'].toString()),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTemplates() async {
    try {
      final json = await _templateService.exportTemplates();
      // Aquí podrías implementar compartir o guardar el archivo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exportadas ${_customTemplates.length} plantillas'),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('JSON Exportado'),
                    content: SingleChildScrollView(
                      child: SelectableText(json),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  Future<void> _importTemplates() async {
    final controller = TextEditingController();

    final json = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Plantillas'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Pegar JSON aquí',
            border: OutlineInputBorder(),
          ),
          maxLines: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (json != null && json.isNotEmpty) {
      try {
        final count = await _templateService.importTemplates(json);
        _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Importadas $count plantillas')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al importar: $e')),
          );
        }
      }
    }
  }
}
