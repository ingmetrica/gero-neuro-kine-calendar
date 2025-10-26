import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_provider.dart';

class YearViewScreen extends StatefulWidget {
  const YearViewScreen({Key? key}) : super(key: key);

  @override
  State<YearViewScreen> createState() => _YearViewScreenState();
}

class _YearViewScreenState extends State<YearViewScreen> {
  int _currentYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Año $_currentYear'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _currentYear--;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _currentYear = DateTime.now().year;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _currentYear++;
              });
            },
          ),
        ],
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              return _buildMonthCard(index + 1, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthCard(int month, CalendarProvider provider) {
    final firstDay = DateTime(_currentYear, month, 1);
    final lastDay = DateTime(_currentYear, month + 1, 0);
    final daysInMonth = lastDay.day;

    final events = provider.getEventsForMonth(firstDay);

    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.withOpacity(0.1),
            child: Text(
              DateFormat.MMMM('es').format(firstDay),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(_currentYear, month, day);
                final hasEvents = events.any((event) =>
                    event.startTime.year == date.year &&
                    event.startTime.month == date.month &&
                    event.startTime.day == date.day);

                final isToday = DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;

                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.blue.withOpacity(0.3)
                        : (hasEvents ? Colors.blue.withOpacity(0.1) : null),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (hasEvents)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
