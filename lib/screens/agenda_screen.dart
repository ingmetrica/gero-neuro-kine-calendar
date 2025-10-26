import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_provider.dart';
import '../models/event_model.dart';
import '../widgets/event_list_item.dart';
import 'event_detail_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({Key? key}) : super(key: key);

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _showPastEvents = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: Icon(_showPastEvents ? Icons.history : Icons.access_time),
            onPressed: () {
              setState(() {
                _showPastEvents = !_showPastEvents;
              });
            },
            tooltip: _showPastEvents ? 'Mostrar próximos' : 'Mostrar pasados',
          ),
        ],
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          final events = provider.events.where((event) {
            if (_showPastEvents) {
              return event.startTime.isBefore(now);
            } else {
              return event.startTime.isAfter(now) ||
                  event.startTime.isAtSameMomentAs(now);
            }
          }).toList()
            ..sort((a, b) {
              if (_showPastEvents) {
                return b.startTime.compareTo(a.startTime);
              }
              return a.startTime.compareTo(b.startTime);
            });

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showPastEvents ? Icons.history_toggle_off : Icons.event_busy,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showPastEvents
                        ? 'No hay eventos pasados'
                        : 'No hay eventos próximos',
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
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final showDateHeader = index == 0 ||
                  !_isSameDay(events[index - 1].startTime, event.startTime);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDateHeader) _buildDateHeader(event.startTime),
                  EventListItem(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    String headerText;
    if (eventDate == today) {
      headerText = 'Hoy';
    } else if (eventDate == tomorrow) {
      headerText = 'Mañana';
    } else {
      headerText = DateFormat.yMMMMd('es').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[200],
      child: Text(
        headerText,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
