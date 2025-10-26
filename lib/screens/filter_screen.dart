import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_provider.dart';
import '../models/event_model.dart';
import '../widgets/event_list_item.dart';
import 'event_detail_screen.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  Set<Color> _selectedColors = {};
  DateTimeRange? _dateRange;
  bool _showRecurring = true;
  bool _showNonRecurring = true;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrar Eventos'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Limpiar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Filtrar por Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((color) {
                    final isSelected = _selectedColors.contains(color);
                    return FilterChip(
                      label: const SizedBox(width: 32, height: 20),
                      backgroundColor: color.withOpacity(0.3),
                      selectedColor: color,
                      selected: isSelected,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedColors.add(color);
                          } else {
                            _selectedColors.remove(color);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Filtrar por Rango de Fechas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.date_range),
                    title: Text(
                      _dateRange == null
                          ? 'Seleccionar rango de fechas'
                          : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                    ),
                    trailing: _dateRange != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _dateRange = null;
                              });
                            },
                          )
                        : null,
                    onTap: _selectDateRange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tipo de Eventos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Eventos Recurrentes'),
                  value: _showRecurring,
                  onChanged: (value) {
                    setState(() {
                      _showRecurring = value ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Eventos No Recurrentes'),
                  value: _showNonRecurring,
                  onChanged: (value) {
                    setState(() {
                      _showNonRecurring = value ?? true;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Consumer<CalendarProvider>(
                  builder: (context, provider, child) {
                    final filteredEvents = _applyFilters(provider.events);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resultados: ${filteredEvents.length} evento(s)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...filteredEvents.map((event) {
                          return EventListItem(
                            event: event,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailScreen(event: event),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CalendarEvent> _applyFilters(List<CalendarEvent> events) {
    return events.where((event) {
      // Filter by color
      if (_selectedColors.isNotEmpty) {
        if (!_selectedColors.any((selectedColor) =>
            selectedColor.value == event.color.value)) {
          return false;
        }
      }

      // Filter by date range
      if (_dateRange != null) {
        if (event.startTime.isBefore(_dateRange!.start) ||
            event.startTime.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Filter by recurrence
      final isRecurring = event.recurrenceType != RecurrenceType.none;
      if (isRecurring && !_showRecurring) {
        return false;
      }
      if (!isRecurring && !_showNonRecurring) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedColors.clear();
      _dateRange = null;
      _showRecurring = true;
      _showNonRecurring = true;
    });
  }
}
