import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_provider.dart';
import '../models/event_model.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          final stats = _calculateStatistics(provider.events);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard(
                'Total de Eventos',
                stats['total'].toString(),
                Icons.event,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Eventos Este Mes',
                stats['thisMonth'].toString(),
                Icons.calendar_month,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Eventos Esta Semana',
                stats['thisWeek'].toString(),
                Icons.calendar_today,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Eventos Próximos',
                stats['upcoming'].toString(),
                Icons.access_time,
                Colors.purple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Eventos por Mes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMonthlyChart(stats['byMonth'] as Map<int, int>),
              const SizedBox(height: 24),
              const Text(
                'Duración Promedio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Duración Promedio de Eventos',
                _formatDuration(stats['avgDuration'] as Duration),
                Icons.timer,
                Colors.teal,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Evento Más Largo',
                _formatDuration(stats['maxDuration'] as Duration),
                Icons.trending_up,
                Colors.red,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Evento Más Corto',
                _formatDuration(stats['minDuration'] as Duration),
                Icons.trending_down,
                Colors.indigo,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(Map<int, int> byMonth) {
    final maxCount = byMonth.values.isEmpty ? 1 : byMonth.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(12, (index) {
            final month = index + 1;
            final count = byMonth[month] ?? 0;
            final percentage = maxCount > 0 ? count / maxCount : 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      DateFormat.MMM('es').format(DateTime(2000, month)),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage.toDouble(),
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStatistics(List<CalendarEvent> events) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekEnd = thisWeekStart.add(const Duration(days: 7));

    var totalDuration = Duration.zero;
    var maxDuration = Duration.zero;
    var minDuration = const Duration(days: 365);
    final byMonth = <int, int>{};

    var thisMonth = 0;
    var thisWeek = 0;
    var upcoming = 0;

    for (var event in events) {
      final duration = event.endTime.difference(event.startTime);
      totalDuration += duration;

      if (duration > maxDuration) maxDuration = duration;
      if (duration < minDuration && duration > Duration.zero) minDuration = duration;

      final month = event.startTime.month;
      byMonth[month] = (byMonth[month] ?? 0) + 1;

      if (event.startTime.isAfter(thisMonthStart) && event.startTime.isBefore(thisMonthEnd)) {
        thisMonth++;
      }

      if (event.startTime.isAfter(thisWeekStart) && event.startTime.isBefore(thisWeekEnd)) {
        thisWeek++;
      }

      if (event.startTime.isAfter(now)) {
        upcoming++;
      }
    }

    final avgDuration = events.isEmpty
        ? Duration.zero
        : Duration(milliseconds: totalDuration.inMilliseconds ~/ events.length);

    if (minDuration == const Duration(days: 365)) {
      minDuration = Duration.zero;
    }

    return {
      'total': events.length,
      'thisMonth': thisMonth,
      'thisWeek': thisWeek,
      'upcoming': upcoming,
      'avgDuration': avgDuration,
      'maxDuration': maxDuration,
      'minDuration': minDuration,
      'byMonth': byMonth,
    };
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
}
